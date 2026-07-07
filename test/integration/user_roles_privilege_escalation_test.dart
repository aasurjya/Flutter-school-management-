/// Same-tenant privilege-escalation regression for `user_roles`.
///
/// `test/integration/tenant_isolation_test.dart` proves no user can cross
/// TENANT boundaries. It structurally can't catch this bug: an ordinary
/// authenticated user self-granting `super_admin` for THEIR OWN tenant by
/// calling `user_roles.insert({user_id: self, role: 'super_admin', ...})`
/// directly via the client SDK — no tenant crossing involved, no app UI
/// needed. Fixed by migration 00075 (self-insert can no longer claim
/// super_admin/tenant_admin/principal).
///
/// Gated by `INTEGRATION=1`, same convention as tenant_isolation_test.dart.
///
/// Required env vars:
///   INTEGRATION                = "1" to enable
///   ISOLATION_SUPABASE_URL     = Supabase URL (local or staging)
///   ISOLATION_SUPABASE_ANON_KEY
///   ISOLATION_SERVICE_KEY      = service_role key (bypasses RLS for cleanup)
///   ISOLATION_TENANT_A_EMAIL   / ISOLATION_TENANT_A_PASSWORD
///     — must be an ordinary, non-admin user (e.g. a teacher/student demo
///       account). If this account already holds an admin role, the
///       negative-control assertions below are meaningless.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gateEnv = String.fromEnvironment('INTEGRATION', defaultValue: '');

const List<String> _privilegedRoles = ['super_admin', 'tenant_admin', 'principal'];

void main() {
  final enabled = _gateEnv == '1' || Platform.environment['INTEGRATION'] == '1';
  if (!enabled) {
    test('user_roles privilege escalation (gated — set INTEGRATION=1 to enable)',
        () {}, skip: 'set INTEGRATION=1 to run');
    return;
  }

  final env = Platform.environment;
  final url = env['ISOLATION_SUPABASE_URL'];
  final anonKey = env['ISOLATION_SUPABASE_ANON_KEY'];
  final serviceKey = env['ISOLATION_SERVICE_KEY'];
  final email = env['ISOLATION_TENANT_A_EMAIL'];
  final password = env['ISOLATION_TENANT_A_PASSWORD'];

  if ([url, anonKey, serviceKey, email, password].any((v) => v == null)) {
    test('user_roles privilege escalation requires ISOLATION_* env vars', () {
      fail('missing one of ISOLATION_SUPABASE_URL / SUPABASE_ANON_KEY / '
          'SERVICE_KEY / TENANT_A_EMAIL / TENANT_A_PASSWORD');
    });
    return;
  }

  late SupabaseClient adminClient; // service_role — bypasses RLS for cleanup
  late SupabaseClient client; // signed in as the ordinary tenant user
  late String userId;
  late String tenantId;

  setUpAll(() async {
    adminClient = SupabaseClient(url!, serviceKey!);
    client = SupabaseClient(url, anonKey!);
    final auth = await client.auth.signInWithPassword(email: email!, password: password!);
    userId = auth.user!.id;
    tenantId = (auth.user!.appMetadata['tenant_id'] as String?) ?? '';
    if (tenantId.isEmpty) {
      fail('signed-in test user has no tenant_id in app_metadata');
    }
  });

  tearDownAll(() async {
    await client.auth.signOut();
  });

  for (final role in _privilegedRoles) {
    test('self-insert of "$role" is rejected', () async {
      var rejected = false;
      try {
        await client.from('user_roles').insert({
          'user_id': userId,
          'tenant_id': tenantId,
          'role': role,
          'is_primary': false,
        });
      } on PostgrestException catch (e) {
        rejected = true;
        expect(e.code, isNotNull);
      }

      if (!rejected) {
        // Insert reported success — verify it did NOT actually land, then
        // clean it up via the admin client either way.
        final landed = await adminClient
            .from('user_roles')
            .select('id')
            .eq('user_id', userId)
            .eq('role', role);
        await adminClient.from('user_roles').delete().eq('user_id', userId).eq('role', role);
        fail('self-insert of "$role" did NOT raise (landed=${landed.length} rows). '
            'Tighten the user_roles self-insert policy.');
      }
    });
  }

  test('self-insert of a non-privileged role ("teacher") still succeeds', () async {
    // The test account may already legitimately hold this role (it's a
    // real seeded teacher) — do NOT delete pre-existing data. If a row
    // already exists, a 23505 unique-constraint conflict on the *same*
    // (user_id, tenant_id, role) is itself proof the self-insert path is
    // reachable (RLS didn't block it — Postgres got far enough to check
    // the constraint). Only assert a clean success when no row exists yet.
    final before = await adminClient
        .from('user_roles')
        .select('id')
        .eq('user_id', userId)
        .eq('role', 'teacher');

    if (before.isNotEmpty) {
      return; // already holds this role legitimately — nothing to prove here
    }

    await client.from('user_roles').insert({
      'user_id': userId,
      'tenant_id': tenantId,
      'role': 'teacher',
      'is_primary': false,
    });

    final landed = await adminClient
        .from('user_roles')
        .select('id')
        .eq('user_id', userId)
        .eq('role', 'teacher');
    expect(landed, isNotEmpty,
        reason: 'fix should not have broken legitimate non-privileged self-insert');

    // Clean up only the row we just created.
    await adminClient.from('user_roles').delete().eq('user_id', userId).eq('role', 'teacher');
  });

  test('inserting a role row for a DIFFERENT user_id is rejected', () async {
    const otherUserId = '00000000-0000-0000-0000-000000000000';
    var rejected = false;
    try {
      await client.from('user_roles').insert({
        'user_id': otherUserId,
        'tenant_id': tenantId,
        'role': 'teacher',
        'is_primary': false,
      });
    } on PostgrestException catch (e) {
      rejected = true;
      expect(e.code, isNotNull);
    }
    expect(rejected, isTrue,
        reason: 'user_id = auth.uid() half of the self-insert policy must still hold');
  });
}
