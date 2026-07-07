/// Explicit regression coverage for the `student_checkins` RLS leak.
///
/// The generic `test/integration/tenant_isolation_test.dart` harness already
/// auto-covers cross-tenant SELECT/INSERT for every `tenant_id`-having table,
/// including `student_checkins` (it's not in that file's `_skipTables`), so
/// this file's cross-tenant cases are partly redundant by design — they
/// exist to name the regression explicitly so it isn't silently lost if
/// `student_checkins` is ever added to that skip-list. The `checked_by`
/// RESTRICTIVE-policy case below is NOT covered by the generic harness at
/// all, since that harness doesn't know about column-level business rules.
///
/// Fixed by migration 00074 (dropped `USING (true)` SELECT policy and the
/// tenant-unscoped INSERT check; added a RESTRICTIVE INSERT policy requiring
/// `checked_by = auth.uid()`).
///
/// Gated by `INTEGRATION=1`, same convention as tenant_isolation_test.dart.
///
/// Required env vars (same names as tenant_isolation_test.dart so both files
/// can share one CI env block):
///   INTEGRATION                = "1" to enable
///   ISOLATION_SUPABASE_URL
///   ISOLATION_SUPABASE_ANON_KEY
///   ISOLATION_SERVICE_KEY      = service_role key (bypasses RLS for setup/cleanup)
///   ISOLATION_TENANT_A_EMAIL   / ISOLATION_TENANT_A_PASSWORD
///   ISOLATION_TENANT_B_EMAIL   / ISOLATION_TENANT_B_PASSWORD
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gateEnv = String.fromEnvironment('INTEGRATION', defaultValue: '');

void main() {
  final enabled = _gateEnv == '1' || Platform.environment['INTEGRATION'] == '1';
  if (!enabled) {
    test('student_checkins RLS (gated — set INTEGRATION=1 to enable)', () {},
        skip: 'set INTEGRATION=1 to run');
    return;
  }

  final env = Platform.environment;
  final url = env['ISOLATION_SUPABASE_URL'];
  final anonKey = env['ISOLATION_SUPABASE_ANON_KEY'];
  final serviceKey = env['ISOLATION_SERVICE_KEY'];
  final emailA = env['ISOLATION_TENANT_A_EMAIL'];
  final passA = env['ISOLATION_TENANT_A_PASSWORD'];
  final emailB = env['ISOLATION_TENANT_B_EMAIL'];
  final passB = env['ISOLATION_TENANT_B_PASSWORD'];

  if ([url, anonKey, serviceKey, emailA, passA, emailB, passB].any((v) => v == null)) {
    test('student_checkins RLS requires ISOLATION_* env vars', () {
      fail('missing one of ISOLATION_SUPABASE_URL / SUPABASE_ANON_KEY / '
          'SERVICE_KEY / TENANT_A_EMAIL / TENANT_A_PASSWORD / '
          'TENANT_B_EMAIL / TENANT_B_PASSWORD');
    });
    return;
  }

  late SupabaseClient adminClient;
  late SupabaseClient clientA;
  late String userIdA;
  late String tenantA;
  late String tenantB;
  String? seededCheckinIdB;

  setUpAll(() async {
    adminClient = SupabaseClient(url!, serviceKey!);
    clientA = SupabaseClient(url, anonKey!);
    final authA = await clientA.auth.signInWithPassword(email: emailA!, password: passA!);
    userIdA = authA.user!.id;
    tenantA = (authA.user!.appMetadata['tenant_id'] as String?) ?? '';

    final clientB = SupabaseClient(url, anonKey);
    final authB = await clientB.auth.signInWithPassword(email: emailB!, password: passB!);
    tenantB = (authB.user!.appMetadata['tenant_id'] as String?) ?? '';
    await clientB.auth.signOut();

    if (tenantA.isEmpty || tenantB.isEmpty || tenantA == tenantB) {
      fail('tenant A and B must be distinct non-empty tenant ids '
          '(got A=$tenantA B=$tenantB)');
    }

    // Seed one real check-in row under tenant B via the service-role client
    // so there's something for tenant A to try (and fail) to read.
    final student = await adminClient
        .from('students')
        .select('id, tenant_id, student_enrollments(section_id)')
        .eq('tenant_id', tenantB)
        .limit(1)
        .maybeSingle();
    if (student == null) {
      fail('no student found for tenant B — seed data required for this test');
    }
    final enrollments = student['student_enrollments'] as List;
    if (enrollments.isEmpty) {
      fail('tenant B student has no section enrollment — seed data required');
    }
    final inserted = await adminClient
        .from('student_checkins')
        .insert({
          'tenant_id': tenantB,
          'student_id': student['id'],
          'section_id': (enrollments.first as Map)['section_id'],
          'check_type': 'check_in',
          'method': 'manual',
        })
        .select('id')
        .single();
    seededCheckinIdB = inserted['id'] as String;
  });

  tearDownAll(() async {
    if (seededCheckinIdB != null) {
      await adminClient.from('student_checkins').delete().eq('id', seededCheckinIdB!);
    }
    await clientA.auth.signOut();
  });

  test('tenant-A user cannot SELECT tenant-B check-ins', () async {
    final rows =
        await clientA.from('student_checkins').select('id').eq('tenant_id', tenantB);
    expect(rows, isEmpty, reason: 'student_checkins leaked rows from tenant B to tenant A');
  });

  test('tenant-A user cannot INSERT a check-in claiming tenant_id = B', () async {
    var rejected = false;
    try {
      await clientA.from('student_checkins').insert({
        'tenant_id': tenantB,
        'student_id': '00000000-0000-0000-0000-000000000000',
        'section_id': '00000000-0000-0000-0000-000000000000',
        'check_type': 'check_in',
        'checked_by': userIdA,
        'method': 'manual',
      });
    } on PostgrestException catch (e) {
      rejected = true;
      expect(e.code, isNotNull);
    }
    expect(rejected, isTrue, reason: 'insert with a foreign tenant_id must be rejected');
  });

  test('tenant-A user cannot INSERT a same-tenant check-in with checked_by != self', () async {
    final ownStudent = await adminClient
        .from('students')
        .select('id, student_enrollments(section_id)')
        .eq('tenant_id', tenantA)
        .limit(1)
        .maybeSingle();
    if (ownStudent == null) {
      fail('no student found for tenant A — seed data required for this test');
    }
    final enrollments = ownStudent['student_enrollments'] as List;
    if (enrollments.isEmpty) {
      fail('tenant A student has no section enrollment — seed data required');
    }

    var rejected = false;
    try {
      await clientA.from('student_checkins').insert({
        'tenant_id': tenantA,
        'student_id': ownStudent['id'],
        'section_id': (enrollments.first as Map)['section_id'],
        'check_type': 'check_in',
        'checked_by': '00000000-0000-0000-0000-000000000000', // not self
        'method': 'manual',
      });
    } on PostgrestException catch (e) {
      rejected = true;
      expect(e.code, isNotNull);
    }
    expect(rejected, isTrue,
        reason: 'the RESTRICTIVE checked_by = auth.uid() policy must still hold');
  });

  test('tenant-A user CAN insert a valid same-tenant check-in with checked_by = self', () async {
    final ownStudent = await adminClient
        .from('students')
        .select('id, student_enrollments(section_id)')
        .eq('tenant_id', tenantA)
        .limit(1)
        .maybeSingle();
    if (ownStudent == null) {
      fail('no student found for tenant A — seed data required for this test');
    }
    final enrollments = ownStudent['student_enrollments'] as List;
    if (enrollments.isEmpty) {
      fail('tenant A student has no section enrollment — seed data required');
    }

    final inserted = await clientA
        .from('student_checkins')
        .insert({
          'tenant_id': tenantA,
          'student_id': ownStudent['id'],
          'section_id': (enrollments.first as Map)['section_id'],
          'check_type': 'check_in',
          'checked_by': userIdA,
          'method': 'manual',
        })
        .select('id')
        .single();

    expect(inserted['id'], isNotNull,
        reason: 'the fix must not have broken the legitimate same-tenant, self checked_by path');

    await adminClient.from('student_checkins').delete().eq('id', inserted['id'] as String);
  });
}
