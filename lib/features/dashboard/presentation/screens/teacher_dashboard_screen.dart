import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../ai_insights/providers/risk_score_provider.dart';
import '../../../ai_insights/providers/early_warning_provider.dart';
import '../../../ai_insights/presentation/widgets/risk_score_badge.dart';
import '../../../syllabus/providers/syllabus_provider.dart';
import '../../../syllabus/presentation/widgets/coverage_summary_card.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from your account'),
              onTap: () {
                Navigator.of(context).pop();
                _logout(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: const Text('Profile'),
              subtitle: const Text('View and edit your profile'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.secondary),
              title: const Text('Settings'),
              subtitle: const Text('App preferences'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.oceanGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Text(
                                currentUser?.initials ?? 'T',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Morning,',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currentUser?.fullName ?? 'Teacher',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                tooltip: 'Scan Student QR',
                onPressed: () => context.push('/qr-scanner?mode=lookup'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => _showSettingsMenu(context, ref),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Today's Schedule
                _buildSectionHeader(context, "Today's Schedule"),
                const SizedBox(height: 12),
                _buildTodaySchedule(context),
                const SizedBox(height: 24),
                
                // Class Teacher Section
                _buildClassTeacherSection(context, ref),

                // Syllabus Progress
                _buildSyllabusProgress(context, ref),

                // My Classes
                _buildSectionHeader(context, 'My Classes'),
                const SizedBox(height: 12),
                _buildMyClasses(context),
                const SizedBox(height: 24),

                // Quick Stats
                _buildQuickStats(context),
                const SizedBox(height: 24),

                // AI: At-Risk Students
                _buildAtRiskSection(context, ref),

                // AI: Early Warning Alerts
                _buildEarlyWarningSection(context, ref),

                // AI Tools Quick Actions
                _buildSectionHeader(context, 'AI Tools'),
                const SizedBox(height: 12),
                _buildAIToolsRow(context),
                const SizedBox(height: 24),

                // Pending Tasks
                _buildSectionHeader(context, 'Pending Tasks'),
                const SizedBox(height: 12),
                _buildPendingTasks(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTeacherSection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final sectionsAsync =
        ref.watch(classTeacherSectionsProvider(currentUser.id));

    return sectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sections) {
        if (sections.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'My Class (Class Teacher)'),
            const SizedBox(height: 12),
            ...sections.map((section) => GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push(
                    '/class-teacher/${section.id}?name=${Uri.encodeComponent(section.displayName)}',
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class Teacher Dashboard',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View all $title coming soon')),
          ),
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(BuildContext context) {
    final schedule = [
      _ScheduleItem('08:30 AM', 'Class 10-A', 'Mathematics', 'Period 1'),
      _ScheduleItem('09:30 AM', 'Class 9-B', 'Mathematics', 'Period 2'),
      _ScheduleItem('10:30 AM', 'Break', '', ''),
      _ScheduleItem('11:00 AM', 'Class 12-A', 'Mathematics', 'Period 4'),
      _ScheduleItem('12:00 PM', 'Class 11-B', 'Mathematics', 'Period 5'),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final item = schedule[index];
          final isBreak = item.subject.isEmpty;
          final isCurrent = index == 0;

          return Container(
            width: 140,
            margin: EdgeInsets.only(right: index < schedule.length - 1 ? 12 : 0),
            decoration: BoxDecoration(
              gradient: isCurrent ? AppColors.primaryGradient : null,
              color: isBreak ? AppColors.warning.withValues(alpha: 0.1) : (isCurrent ? null : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent
                    ? Colors.transparent
                    : (isBreak ? AppColors.warning : Colors.grey.withValues(alpha: 0.2)),
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrent ? Colors.white70 : Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  item.className,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.white : (isBreak ? AppColors.warning : null),
                  ),
                ),
                if (!isBreak) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrent ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyClasses(BuildContext context) {
    final classes = [
      {'name': 'Class 10-A', 'students': 42, 'attendance': 95},
      {'name': 'Class 9-B', 'students': 38, 'attendance': 92},
      {'name': 'Class 12-A', 'students': 35, 'attendance': 88},
      {'name': 'Class 11-B', 'students': 40, 'attendance': 94},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];
          return GestureDetector(
            onTap: () => context.push('/attendance/mark/${cls['name']}'),
            child: Container(
              width: 160,
              margin: EdgeInsets.only(right: index < classes.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cls['students']} students',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cls['attendance']}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAtRiskSection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    // Use a hardcoded academic year check — in production this would come from a provider
    final academicYearAsync =
        ref.watch(currentAcademicYearProvider);

    return academicYearAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (year) {
        if (year == null) return const SizedBox.shrink();

        final atRiskAsync = ref.watch(atRiskStudentsProvider(
          AtRiskFilter(academicYearId: year.id, limit: 3),
        ));

        return atRiskAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (students) {
            if (students.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            size: 20, color: Color(0xFFF97316)),
                        const SizedBox(width: 8),
                        Text(
                          'At-Risk Students',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push(
                        '${AppRoutes.riskDashboard}?yearId=${year.id}',
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...students.map((s) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      onTap: () => context.push(
                        '${AppRoutes.riskDashboard}/${s.studentId}'
                        '?yearId=${year.id}',
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                s.riskColor.withValues(alpha: 0.15),
                            child: Text(
                              '${s.overallRiskScore.round()}',
                              style: TextStyle(
                                color: s.riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.studentName ?? 'Student',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          RiskScoreBadge(riskScore: s),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEarlyWarningSection(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unresolvedAlertCountProvider);

    return countAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => context.push(AppRoutes.earlyWarningAlerts),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Badge(
                      label: Text(count > 99 ? '99+' : '$count'),
                      child: const Icon(
                        Icons.notification_important_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Early Warning Alerts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count unresolved alert${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSyllabusProgress(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final academicYearAsync = ref.watch(currentAcademicYearProvider);

    return academicYearAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (year) {
        if (year == null) return const SizedBox.shrink();

        final coverageAsync = ref.watch(
          teacherCoverageProvider((teacherId: currentUser.id, academicYearId: year.id)),
        );

        return coverageAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (summaries) {
            if (summaries.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Syllabus Progress'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < summaries.length - 1 ? 12 : 0,
                        ),
                        child: SizedBox(
                          width: 200,
                          child: CoverageSummaryCard(
                            summary: summary,
                            onTap: () => context.push(
                              '${AppRoutes.syllabusEditor}'
                              '?subjectId=${summary.subjectId}'
                              '&classId=${summary.classId}'
                              '&academicYearId=${year.id}',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: GlassStatCard(
            title: 'Attendance Marked',
            value: '3/5',
            icon: Icons.check_circle,
            iconColor: AppColors.success,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: GlassStatCard(
            title: 'Assignments',
            value: '8',
            icon: Icons.assignment,
            iconColor: AppColors.accent,
            subtitle: '3 pending review',
          ),
        ),
      ],
    );
  }

  Widget _buildAIToolsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AIToolCard(
            icon: Icons.auto_fix_high,
            label: 'AI Remarks',
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.generateRemarks),
          ),
          const SizedBox(width: 12),
          _AIToolCard(
            icon: Icons.auto_awesome,
            label: 'AI Message',
            color: AppColors.info,
            onTap: () => context.push(AppRoutes.aiMessageComposer),
          ),
          const SizedBox(width: 12),
          _AIToolCard(
            icon: Icons.insights,
            label: 'Class Intel',
            color: AppColors.secondary,
            onTap: () {
              // Navigate to class intelligence — in production, use actual sectionId
              context.push(
                AppRoutes.classIntelligence.replaceFirst(':sectionId', 'default'),
              );
            },
          ),
          const SizedBox(width: 12),
          _AIToolCard(
            icon: Icons.menu_book,
            label: 'Syllabus',
            color: AppColors.success,
            onTap: () => context.push(AppRoutes.syllabusList),
          ),
          const SizedBox(width: 12),
          _AIToolCard(
            icon: Icons.quiz_outlined,
            label: 'Q. Paper',
            color: Colors.deepPurple,
            onTap: () => context.push(AppRoutes.questionPaperList),
          ),
          const SizedBox(width: 12),
          _AIToolCard(
            icon: Icons.person_off_outlined,
            label: 'Report Absence',
            color: Colors.orange,
            onTap: () => context.push(AppRoutes.reportAbsence),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasks(BuildContext context) {
    final tasks = [
      {'title': 'Mark attendance - Class 12-A', 'time': 'Due in 2 hours', 'icon': Icons.fact_check},
      {'title': 'Grade assignments - Class 10-A', 'time': '5 pending', 'icon': Icons.grading},
      {'title': 'Enter marks - Unit Test 2', 'time': 'Due tomorrow', 'icon': Icons.edit_note},
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: tasks.map((task) {
          return ListTile(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${task['title']}')),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(task['icon'] as IconData, color: AppColors.warning, size: 20),
            ),
            title: Text(
              task['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            subtitle: Text(
              task['time'] as String,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          );
        }).toList(),
      ),
    );
  }
}

class _AIToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AIToolCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItem {
  final String time;
  final String className;
  final String subject;
  final String period;

  _ScheduleItem(this.time, this.className, this.subject, this.period);
}
