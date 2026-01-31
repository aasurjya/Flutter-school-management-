import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/leave.dart';
import '../../../data/repositories/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(Supabase.instance.client);
});

final leaveApplicationsProvider =
    FutureProvider.family<List<LeaveApplication>, LeaveFilter>(
  (ref, filter) async {
    final repository = ref.watch(leaveRepositoryProvider);
    return repository.getLeaveApplications(
      applicantId: filter.applicantId,
      applicantType: filter.applicantType,
      status: filter.status,
      pendingOnly: filter.pendingOnly,
    );
  },
);

final leaveApplicationByIdProvider =
    FutureProvider.family<LeaveApplication?, String>(
  (ref, id) async {
    final repository = ref.watch(leaveRepositoryProvider);
    return repository.getLeaveApplicationById(id);
  },
);

final leaveBalanceProvider =
    FutureProvider.family<List<LeaveBalance>, String>(
  (ref, userId) async {
    final repository = ref.watch(leaveRepositoryProvider);
    return repository.getLeaveBalance(userId);
  },
);

class LeaveFilter {
  final String? applicantId;
  final String? applicantType;
  final String? status;
  final bool pendingOnly;

  const LeaveFilter({
    this.applicantId,
    this.applicantType,
    this.status,
    this.pendingOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveFilter &&
          other.applicantId == applicantId &&
          other.applicantType == applicantType &&
          other.status == status &&
          other.pendingOnly == pendingOnly;

  @override
  int get hashCode =>
      Object.hash(applicantId, applicantType, status, pendingOnly);
}
