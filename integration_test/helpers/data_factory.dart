/// Test data factory for integration tests.
///
/// Creates and cleans up test data directly via the Supabase client,
/// bypassing the UI for fast setup in cross-role sync and agent tests.
library data_factory;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Tenant ID used by all demo seed users.
const testTenantId = '00000000-0000-0000-0000-000000000001';

/// Convenience accessor.
SupabaseClient get _client => Supabase.instance.client;

/// Creates a test student and returns the inserted row.
///
/// The student is linked to [testTenantId]. Call [deleteTestStudent]
/// in tearDown to clean up.
Future<Map<String, dynamic>> createTestStudent({
  String name = 'Test Student (Integration)',
  String admissionNumber = 'TEST-INT-001',
}) async {
  final response = await _client.from('students').insert({
    'tenant_id': testTenantId,
    'first_name': name.split(' ').first,
    'last_name': name.split(' ').skip(1).join(' '),
    'admission_number': admissionNumber,
    'date_of_birth': '2010-01-15',
    'gender': 'male',
    'is_active': true,
  }).select().single();

  return response;
}

/// Deletes a test student by ID.
Future<void> deleteTestStudent(String studentId) async {
  await _client.from('students').delete().eq('id', studentId);
}

/// Creates a test notice and returns the inserted row.
Future<Map<String, dynamic>> createTestNotice({
  String title = 'Integration Test Notice',
  String content = 'This is an auto-generated notice for testing.',
  bool isPinned = false,
}) async {
  final userId = _client.auth.currentUser!.id;

  final response = await _client.from('notices').insert({
    'tenant_id': testTenantId,
    'title': title,
    'content': content,
    'is_pinned': isPinned,
    'created_by': userId,
    'is_published': true,
  }).select().single();

  return response;
}

/// Deletes a test notice by ID.
Future<void> deleteTestNotice(String noticeId) async {
  await _client.from('notices').delete().eq('id', noticeId);
}

/// Marks attendance for a section and returns the inserted rows.
///
/// [records] is a list of `{student_id, status}` maps where status
/// is one of: 'present', 'absent', 'late', 'excused'.
Future<List<Map<String, dynamic>>> markTestAttendance({
  required String sectionId,
  required String date,
  required List<Map<String, String>> records,
}) async {
  final userId = _client.auth.currentUser!.id;
  final rows = records.map((r) => {
    'tenant_id': testTenantId,
    'section_id': sectionId,
    'student_id': r['student_id'],
    'date': date,
    'status': r['status'] ?? 'present',
    'marked_by': userId,
  }).toList();

  final response = await _client
      .from('attendance')
      .upsert(rows, onConflict: 'tenant_id,section_id,student_id,date')
      .select();

  return List<Map<String, dynamic>>.from(response);
}

/// Creates a test calendar event and returns the inserted row.
Future<Map<String, dynamic>> createTestEvent({
  String title = 'Integration Test Event',
  String? startDate,
  String? endDate,
}) async {
  final now = DateTime.now();
  final response = await _client.from('calendar_events').insert({
    'tenant_id': testTenantId,
    'title': title,
    'start_date': startDate ?? now.toIso8601String(),
    'end_date': endDate ?? now.add(const Duration(hours: 1)).toIso8601String(),
    'created_by': _client.auth.currentUser!.id,
  }).select().single();

  return response;
}

/// Deletes a test event by ID.
Future<void> deleteTestEvent(String eventId) async {
  await _client.from('calendar_events').delete().eq('id', eventId);
}

/// Fetches the count of a table filtered by tenant.
Future<int> countRows(String table) async {
  final response = await _client
      .from(table)
      .select('id')
      .eq('tenant_id', testTenantId);

  return (response as List).length;
}

/// Verifies that a row with [id] exists in [table].
Future<bool> rowExists(String table, String id) async {
  final response = await _client
      .from(table)
      .select('id')
      .eq('id', id)
      .maybeSingle();

  return response != null;
}

/// Fetches notices visible to current user for the tenant.
Future<List<Map<String, dynamic>>> fetchNotices() async {
  final response = await _client
      .from('notices')
      .select()
      .eq('tenant_id', testTenantId)
      .eq('is_published', true)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
}

/// Fetches attendance records for a student on a specific date.
Future<List<Map<String, dynamic>>> fetchStudentAttendance({
  required String studentId,
  required String date,
}) async {
  final response = await _client
      .from('attendance')
      .select()
      .eq('student_id', studentId)
      .eq('date', date);

  return List<Map<String, dynamic>>.from(response);
}
