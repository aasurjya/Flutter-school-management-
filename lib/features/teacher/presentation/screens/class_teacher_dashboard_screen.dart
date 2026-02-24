import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../students/providers/students_provider.dart';
import '../../../qr_scan/providers/qr_scan_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';

/// Dashboard for class teachers – shows section overview, student list,
/// attendance summary, check-in log, and quick actions.
class ClassTeacherDashboardScreen extends ConsumerWidget {
  final String sectionId;
  final String? sectionName;

  const ClassTeacherDashboardScreen({
    super.key,
    required this.sectionId,
    this.sectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsBySectionProvider(sectionId));
    final checkinsAsync = ref.watch(sectionCheckinsProvider(sectionId));
    final attendanceAsync = ref.watch(
      sectionDailyAttendanceProvider(
        SectionDateFilter(sectionId: sectionId, date: DateTime.now()),
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.oceanGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          sectionName ?? 'My Class',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Class Teacher Dashboard',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                tooltip: 'QR Scanner',
                onPressed: () => context.push(
                  '/qr-scanner?mode=attendance&sectionId=$sectionId',
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Attendance summary
                _buildAttendanceSummary(context, attendanceAsync),
                const SizedBox(height: 20),

                // Quick actions
                _buildQuickActions(context),
                const SizedBox(height: 20),

                // Students list
                _buildStudentsList(context, studentsAsync),
                const SizedBox(height: 20),

                // Check-in log
                _buildCheckinLog(context, checkinsAsync),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> attendanceAsync,
  ) {
    return attendanceAsync.when(
      loading: () => const GlassCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final present = (data?['present_count'] as num?)?.toInt() ?? 0;
        final absent = (data?['absent_count'] as num?)?.toInt() ?? 0;
        final total = (data?['total_students'] as num?)?.toInt() ?? 0;
        final pct = total > 0 ? (present * 100 ~/ total) : 0;

        return Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'Attendance',
                value: '$pct%',
                icon: Icons.check_circle,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'Present / Absent',
                value: '$present / $absent',
                icon: Icons.people,
                iconColor: AppColors.info,
                subtitle: '$total total students',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                context.push('/attendance/mark/$sectionId'),
            icon: const Icon(Icons.fact_check),
            label: const Text('Mark Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push(
              '/qr-scanner?mode=checkin&sectionId=$sectionId',
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('QR Check-in'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(
    BuildContext context,
    AsyncValue studentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Students',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        studentsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load students: $e'),
          data: (students) {
            if (students.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No students enrolled')),
                ),
              );
            }
            return GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: (students as List).take(10).map<Widget>((s) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        s.initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(s.fullName),
                    subtitle:
                        Text('ADM: ${s.admissionNumber}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/students/${s.id}'),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCheckinLog(
    BuildContext context,
    AsyncValue checkinsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Check-ins",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        checkinsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load check-ins: $e'),
          data: (checkins) {
            if (checkins.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No check-ins yet today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }
            return GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: (checkins as List).take(10).map<Widget>((c) {
                  final isIn = c.checkType.dbValue == 'check_in';
                  return ListTile(
                    leading: Icon(
                      isIn ? Icons.login : Icons.logout,
                      color: isIn ? AppColors.success : AppColors.accent,
                    ),
                    title: Text(c.studentName ?? 'Unknown'),
                    subtitle: Text(
                      '${c.checkType.displayName} • ${_formatTime(c.checkedAt)}',
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
