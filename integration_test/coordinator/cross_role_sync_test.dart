/// Head Coordinator: Cross-role sync integration tests.
///
/// Logs in as a "writer" role, performs an action, then switches to a
/// "reader" role and verifies the data is visible.
///
/// Run after all role agents complete:
///   flutter test integration_test/coordinator/cross_role_sync_test.dart \
///     --dart-define=TEST_SUPABASE_URL=... \
///     --dart-define=TEST_SUPABASE_ANON_KEY=...
import 'package:flutter_test/flutter_test.dart';

import '../helpers/data_factory.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await initIntegrationTest();
  });

  tearDownAll(() async {
    await signOut();
  });

  // ── Sync #1: Admin creates notice → Teacher sees it ──

  test('Admin creates notice → visible to teacher', () async {
    await signInAsRole('tenant_admin');
    final notice = await createTestNotice(title: 'Sync Test #1');
    final noticeId = notice['id'] as String;

    await signOutAndSwitch('teacher');
    final notices = await fetchNotices();
    expect(notices.any((n) => n['id'] == noticeId), isTrue,
        reason: 'Teacher should see notice created by admin');

    await signOutAndSwitch('tenant_admin');
    await deleteTestNotice(noticeId);
  });

  // ── Sync #2: Admin creates notice → Student sees it ──

  test('Admin creates notice → visible to student', () async {
    await signInAsRole('tenant_admin');
    final notice = await createTestNotice(title: 'Sync Test #2');
    final noticeId = notice['id'] as String;

    await signOutAndSwitch('student');
    final notices = await fetchNotices();
    expect(notices.any((n) => n['id'] == noticeId), isTrue);

    await signOutAndSwitch('tenant_admin');
    await deleteTestNotice(noticeId);
  });

  // ── Sync #3: Admin creates notice → Parent sees it ──

  test('Admin creates notice → visible to parent', () async {
    await signInAsRole('tenant_admin');
    final notice = await createTestNotice(title: 'Sync Test #3');
    final noticeId = notice['id'] as String;

    await signOutAndSwitch('parent');
    final notices = await fetchNotices();
    expect(notices.any((n) => n['id'] == noticeId), isTrue);

    await signOutAndSwitch('tenant_admin');
    await deleteTestNotice(noticeId);
  });

  // ── Sync #4: Admin notice → Operational staff see it ──

  for (final role in [
    'accountant',
    'librarian',
    'transport_manager',
    'hostel_warden',
    'canteen_staff',
    'receptionist',
  ]) {
    test('Admin creates notice → visible to $role', () async {
      await signInAsRole('tenant_admin');
      final notice = await createTestNotice(title: 'Sync $role');
      final noticeId = notice['id'] as String;

      await signOutAndSwitch(role);
      final notices = await fetchNotices();
      expect(notices.any((n) => n['id'] == noticeId), isTrue,
          reason: '$role should see admin notice');

      await signOutAndSwitch('tenant_admin');
      await deleteTestNotice(noticeId);
    });
  }

  // ── Sync #5: All 12 roles authenticate ──

  test('All 12 roles can sign in successfully', () async {
    for (final role in roleCredentials.keys) {
      final response = await signInAsRole(role);
      expect(response.user, isNotNull, reason: '"$role" should sign in');
      expect(currentUserRole, role);
      await signOut();
    }
  });

  // ── Sync #6: Student count changes after admin creates one ──

  test('Admin creates student → count increases', () async {
    await signInAsRole('tenant_admin');
    final before = await countRows('students');

    final student = await createTestStudent(
      name: 'Sync Student',
      admissionNumber: 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
    );

    final after = await countRows('students');
    expect(after, before + 1);

    await deleteTestStudent(student['id'] as String);
  });

  // ── Sync #7: Admin creates event → teacher sees it ──

  test('Admin creates event → teacher can see it', () async {
    await signInAsRole('tenant_admin');
    final event = await createTestEvent(title: 'Sync Event');
    final eventId = event['id'] as String;

    await signOutAndSwitch('teacher');
    expect(await rowExists('calendar_events', eventId), isTrue);

    await signOutAndSwitch('tenant_admin');
    await deleteTestEvent(eventId);
  });

  // ── Completeness Report ──

  test('Print sync test summary', () {
    // ignore: avoid_print
    print('''
=== CROSS-ROLE SYNC REPORT ===
Tested:
  - Admin → Teacher/Student/Parent/OpStaff (notice visibility)
  - All 12 role authentication
  - Student count consistency
  - Event cross-role visibility

Not yet tested (requires UI):
  - Teacher marks attendance → parent/student sees it
  - Teacher enters marks → student/parent sees results
  - Admin generates invoice → parent sees in fees
  - Receptionist checks in visitor → admin sees in log
  - Librarian issues book → student sees in "my books"

Known broken:
  - No real-time sync (subscriptions exist but unused)
  - All cross-role updates require manual refresh
  - No push notifications wired
===
''');
  });
}
