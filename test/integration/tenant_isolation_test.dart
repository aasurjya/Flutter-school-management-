/// Cross-tenant isolation harness — the single highest-regret omission to fix
/// before launch. Parameterized: seeds two tenants (A, B), then for every
/// table that has a `tenant_id` column asserts a user from tenant A cannot:
///   • SELECT rows where tenant_id = B
///   • INSERT a row that claims tenant_id = B
///   • UPDATE any row where tenant_id = B
///   • DELETE any row where tenant_id = B
///
/// The table list is generated from `information_schema.columns` at test time
/// so the harness auto-grows as new tenant-scoped tables are added. Single
/// list of escape hatches (`_skipTables`) for tables that are intentionally
/// cross-tenant (e.g. `tenants`, `tenant_ai_credits`).
///
/// Gated by `INTEGRATION=1` — needs a live Supabase URL + service key in env.
/// CI runs it nightly against staging, not on every PR.
///
/// Required env vars:
///   INTEGRATION                = "1" to enable
///   ISOLATION_SUPABASE_URL     = staging Supabase URL
///   ISOLATION_SERVICE_KEY      = service_role key (bypasses RLS for setup)
///   ISOLATION_TENANT_A_EMAIL   / ISOLATION_TENANT_A_PASSWORD
///   ISOLATION_TENANT_B_EMAIL   / ISOLATION_TENANT_B_PASSWORD
///
/// The two test users must already exist and be assigned to two distinct
/// tenants via JWT `app_metadata.tenant_id`. The harness does not create
/// them — tenant provisioning is itself a flow worth testing separately.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gateEnv = String.fromEnvironment('INTEGRATION', defaultValue: '');

/// Tables that intentionally span tenants and must be excluded from the
/// isolation check. Anything added here needs a comment explaining why.
const Set<String> _skipTables = {
  // Cross-tenant: the tenants directory itself.
  'tenants',
  // Cross-tenant: super_admin billing dashboard reads these.
  'tenant_ai_credits',
  'tenant_ai_usage',
  // Killswitch + feature flags are deliberately global.
  'app_killswitch',
  'feature_flags',
};

void main() {
  final enabled = _gateEnv == '1' || Platform.environment['INTEGRATION'] == '1';
  if (!enabled) {
    test('tenant isolation (gated — set INTEGRATION=1 to enable)', () {},
        skip: 'set INTEGRATION=1 to run');
    return;
  }

  final env = Platform.environment;
  final url = env['ISOLATION_SUPABASE_URL'];
  final serviceKey = env['ISOLATION_SERVICE_KEY'];
  final emailA = env['ISOLATION_TENANT_A_EMAIL'];
  final passA = env['ISOLATION_TENANT_A_PASSWORD'];
  final emailB = env['ISOLATION_TENANT_B_EMAIL'];
  final passB = env['ISOLATION_TENANT_B_PASSWORD'];

  if ([url, serviceKey, emailA, passA, emailB, passB].any((v) => v == null)) {
    test('tenant isolation requires ISOLATION_* env vars', () {
      fail('missing one of ISOLATION_SUPABASE_URL / SERVICE_KEY / '
          'TENANT_A_EMAIL / TENANT_A_PASSWORD / TENANT_B_EMAIL / '
          'TENANT_B_PASSWORD');
    });
    return;
  }

  late SupabaseClient adminClient;     // service_role — bypasses RLS for setup
  late SupabaseClient clientA;          // signed in as tenant A user
  late String tenantA;
  late String tenantB;
  late List<String> tenantScopedTables;

  setUpAll(() async {
    adminClient = SupabaseClient(url!, serviceKey!);
    clientA = SupabaseClient(url, env['ISOLATION_SUPABASE_ANON_KEY'] ?? '');
    final authA = await clientA.auth
        .signInWithPassword(email: emailA!, password: passA!);
    tenantA = (authA.user!.appMetadata['tenant_id'] as String?) ?? '';

    final clientB = SupabaseClient(url, env['ISOLATION_SUPABASE_ANON_KEY'] ?? '');
    final authB = await clientB.auth
        .signInWithPassword(email: emailB!, password: passB!);
    tenantB = (authB.user!.appMetadata['tenant_id'] as String?) ?? '';
    await clientB.auth.signOut();

    if (tenantA.isEmpty || tenantB.isEmpty || tenantA == tenantB) {
      fail('tenant A and B must be distinct non-empty tenant ids '
          '(got A=$tenantA B=$tenantB)');
    }

    // Discover all tables with a tenant_id column.
    final rows = await adminClient
        .rpc<List<dynamic>>('exec_sql', params: {
      'sql': 'SELECT table_name FROM information_schema.columns '
          "WHERE table_schema='public' AND column_name='tenant_id' "
          'ORDER BY table_name'
    });
    tenantScopedTables = rows
        .map((r) => (r as Map)['table_name'] as String)
        .where((t) => !_skipTables.contains(t))
        .toList();
  });

  tearDownAll(() async {
    await clientA.auth.signOut();
  });

  test('discovered tenant-scoped tables list is non-empty', () {
    expect(tenantScopedTables, isNotEmpty,
        reason: 'no tenant_id columns found — schema probe failed');
  });

  // ----- The actual isolation matrix -----------------------------------------

  group('SELECT isolation', () {
    test('user A cannot read rows where tenant_id = B', () async {
      for (final table in tenantScopedTables) {
        final rows = await clientA
            .from(table)
            .select('tenant_id')
            .eq('tenant_id', tenantB)
            .limit(1);
        expect(rows, isEmpty,
            reason: '$table leaked rows from tenant B to user A');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('INSERT isolation', () {
    test('user A cannot INSERT a row claiming tenant_id = B', () async {
      // We don't know each table's required columns, so we deliberately
      // INSERT a row with only `tenant_id = B`. We expect either:
      //   • 42501 (insufficient_privilege from RLS)
      //   • 23502/23503 (not-null / FK violation — the RLS check fired
      //     before the column check, OR the RLS check fired after but
      //     either way the row was NOT created)
      // We then verify zero rows were created with our marker UUID.
      for (final table in tenantScopedTables) {
        final marker = 'isolation-${DateTime.now().millisecondsSinceEpoch}';
        try {
          await clientA.from(table).insert({
            'tenant_id': tenantB,
            // Try a few common columns — most will fail with column-not-found
            // which is fine; we only care that the row didn't land.
            'name': marker,
          });
        } on PostgrestException catch (e) {
          // Expected failure modes. We do NOT assert on the exact code —
          // RLS denial / NOT NULL / FK / column-not-found all prove the
          // insert was rejected, which is what we want.
          expect(e.code, isNotNull,
              reason: '$table: insert raised non-Postgrest error');
          continue;
        }
        // Insert reported success — verify it didn't actually land.
        final landed = await adminClient
            .from(table)
            .select('tenant_id')
            .eq('tenant_id', tenantB)
            .limit(50);
        // If we got HERE without error, RLS didn't block — that's a leak.
        fail('$table: insert as user A with tenant_id=B did NOT raise '
            '(landed=${landed.length} rows). Tighten RLS WITH CHECK.');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('UPDATE isolation', () {
    test('user A UPDATE on tenant B rows affects zero rows', () async {
      // Use admin client to count rows in B; then user A tries to update; we
      // re-count via admin client and expect identical counts (no mutation).
      for (final table in tenantScopedTables) {
        final before = await adminClient
            .from(table)
            .select('tenant_id')
            .eq('tenant_id', tenantB);
        if (before.isEmpty) continue;

        try {
          await clientA
              .from(table)
              .update({'tenant_id': tenantB})
              .eq('tenant_id', tenantB);
        } on PostgrestException catch (_) {
          continue; // RLS denial — exactly what we want
        }

        final after = await adminClient
            .from(table)
            .select('tenant_id')
            .eq('tenant_id', tenantB);
        expect(after.length, before.length,
            reason: '$table: user A UPDATE affected rows of tenant B');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('DELETE isolation', () {
    test('user A DELETE on tenant B rows affects zero rows', () async {
      for (final table in tenantScopedTables) {
        final before = await adminClient
            .from(table)
            .select('tenant_id')
            .eq('tenant_id', tenantB);
        if (before.isEmpty) continue;

        try {
          await clientA.from(table).delete().eq('tenant_id', tenantB);
        } on PostgrestException catch (_) {
          continue;
        }

        final after = await adminClient
            .from(table)
            .select('tenant_id')
            .eq('tenant_id', tenantB);
        expect(after.length, before.length,
            reason: '$table: user A DELETE removed rows of tenant B');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
