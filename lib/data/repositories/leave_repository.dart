import '../models/leave.dart';
import 'base_repository.dart';

class LeaveRepository extends BaseRepository {
  LeaveRepository(super.client);

  Future<List<LeaveApplication>> getLeaveApplications({
    String? applicantId,
    String? applicantType,
    String? status,
    bool pendingOnly = false,
  }) async {
    var query = client
        .from('leave_applications')
        .select('''
          *,
          approver:users!approved_by(full_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (applicantId != null) {
      query = query.eq('applicant_id', applicantId);
    }
    if (applicantType != null) {
      query = query.eq('applicant_type', applicantType);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (pendingOnly) {
      query = query.eq('status', 'pending');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => LeaveApplication.fromJson(json))
        .toList();
  }

  Future<LeaveApplication?> getLeaveApplicationById(String id) async {
    final response = await client
        .from('leave_applications')
        .select('''
          *,
          approver:users!approved_by(full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return LeaveApplication.fromJson(response);
  }

  Future<LeaveApplication> applyForLeave({
    required String applicantId,
    required String applicantType,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentUrl,
  }) async {
    final response = await client
        .from('leave_applications')
        .insert({
          'tenant_id': tenantId,
          'applicant_id': applicantId,
          'applicant_type': applicantType,
          'leave_type': leaveType,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'reason': reason,
          'attachment_url': attachmentUrl,
          'status': 'pending',
        })
        .select()
        .single();

    return LeaveApplication.fromJson(response);
  }

  Future<void> approveLeave(String applicationId) async {
    await client.from('leave_applications').update({
      'status': 'approved',
      'approved_by': currentUserId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);

    // Update leave balance
    final application = await getLeaveApplicationById(applicationId);
    if (application != null) {
      await _updateLeaveBalance(
        application.applicantId,
        application.leaveType,
        application.duration,
      );
    }
  }

  Future<void> rejectLeave(String applicationId, {String? reason}) async {
    await client.from('leave_applications').update({
      'status': 'rejected',
      'approved_by': currentUserId,
      'approved_at': DateTime.now().toIso8601String(),
      'rejection_reason': reason,
    }).eq('id', applicationId);
  }

  Future<void> cancelLeave(String applicationId) async {
    await client.from('leave_applications').update({
      'status': 'cancelled',
    }).eq('id', applicationId);
  }

  Future<void> _updateLeaveBalance(
    String userId,
    String leaveType,
    int days,
  ) async {
    final currentYear = DateTime.now().year;

    final existing = await client
        .from('leave_balance')
        .select()
        .eq('user_id', userId)
        .eq('leave_type', leaveType)
        .eq('academic_year', currentYear)
        .maybeSingle();

    if (existing != null) {
      await client.from('leave_balance').update({
        'used_days': (existing['used_days'] as int) + days,
      }).eq('id', existing['id']);
    }
  }

  Future<List<LeaveBalance>> getLeaveBalance(String userId) async {
    final currentYear = DateTime.now().year;

    final response = await client
        .from('leave_balance')
        .select()
        .eq('user_id', userId)
        .eq('academic_year', currentYear);

    return (response as List)
        .map((json) => LeaveBalance.fromJson(json))
        .toList();
  }
}
