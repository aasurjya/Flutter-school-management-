import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
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
              leading: const Icon(Icons.badge_rounded, color: AppColors.primary),
              title: const Text('My ID Card'),
              subtitle: const Text('View your staff identity card'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.staffIdCard);
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Professional Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.grey800],
                      ),
                    ),
                  ),
                  // Subtle decorative elements
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    currentUser?.initials ?? 'T',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      currentUser?.fullName ?? 'Faculty Member',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  'Academic Year 2023-24',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                tooltip: 'Student Search',
                onPressed: () => context.push('/qr-scanner?mode=lookup'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onPressed: () => _showSettingsMenu(context, ref),
                ),
              ),
            ],
          ),

          // Main Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Summary Stats Grid
                _buildProfessionalStatsGrid(context),
                const SizedBox(height: 32),
                
                // Active Class Teacher Section (if applicable)
                _buildClassTeacherSection(context, ref),

                // Today's Schedule - Elevated
                _buildSectionHeader(context, "Academic Schedule", "See Timeline"),
                const SizedBox(height: 16),
                _buildTodaySchedule(context),
                const SizedBox(height: 32),

                // Syllabus & Curriculum Progress
                _buildSyllabusProgress(context, ref),

                // AI Insights & Interventions
                _buildInsightSection(context, ref),

                // Faculty Resources & Tools
                _buildSectionHeader(context, 'Curriculum Tools', null),
                const SizedBox(height: 16),
                _buildAIToolsGrid(context),
                const SizedBox(height: 32),

                // Administrative Tasks
                _buildSectionHeader(context, 'Administrative Tasks', 'View All'),
                const SizedBox(height: 16),
                _buildPendingTasksList(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalStatsGrid(BuildContext context) {
    return Row(
      children: [
        _TeacherStatTile(
          label: 'Classes',
          value: '04',
          icon: Icons.groups_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _TeacherStatTile(
          label: 'Attendance',
          value: '92%',
          icon: Icons.fact_check_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _TeacherStatTile(
          label: 'Alerts',
          value: '03',
          icon: Icons.auto_awesome_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String? actionLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                fontSize: 18,
              ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            child: Row(
              children: [
                Text(actionLabel),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInsightSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 32),
        _buildSectionHeader(context, "Student Insights", "Analytics"),
        const SizedBox(height: 16),
        _buildAtRiskSection(context, ref),
        _buildEarlyWarningSection(context, ref),
      ],
    );
  }

  Widget _buildAIToolsGrid(BuildContext context) {
    final tools = [
      {'icon': Icons.auto_fix_high, 'label': 'AI Remarks', 'color': AppColors.primary, 'route': AppRoutes.generateRemarks},
      {'icon': Icons.auto_awesome, 'label': 'AI Composer', 'color': AppColors.info, 'route': AppRoutes.aiMessageComposer},
      {'icon': Icons.insights, 'label': 'Class Intel', 'color': AppColors.secondary, 'route': AppRoutes.classIntelligence},
      {'icon': Icons.quiz_outlined, 'label': 'Q. Gen', 'color': AppColors.warning, 'route': AppRoutes.questionPaperList},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _AIToolCard(
          icon: tool['icon'] as IconData,
          label: tool['label'] as String,
          color: tool['color'] as Color,
          onTap: () {
            final route = tool['route'] as String;
            if (route == AppRoutes.classIntelligence) {
              context.push(route.replaceFirst(':sectionId', 'default'));
            } else {
              context.push(route);
            }
          },
        );
      },
    );
  }

  Widget _buildPendingTasksList(BuildContext context) {
    final tasks = [
      {'title': 'Finalize Grades', 'desc': 'Class 10-A Mathematics', 'date': 'Today', 'icon': Icons.task_alt_rounded},
      {'title': 'Attendance Audit', 'desc': 'Weekly summary report', 'date': 'Due 2h', 'icon': Icons.fact_check_rounded},
      {'title': 'Enter Unit Marks', 'desc': 'Unit Test 2 - All Sections', 'date': 'Tomorrow', 'icon': Icons.edit_note_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tasks.asMap().entries.map((entry) {
          final isLast = entry.key == tasks.length - 1;
          final task = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(task['icon'] as IconData, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  task['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900),
                ),
                subtitle: Text(
                  task['desc'] as String,
                  style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task['date'] as String,
                    style: const TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                onTap: () {},
              ),
              if (!isLast) const Divider(height: 1, indent: 70, endIndent: 20, color: AppColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClassTeacherSection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final sectionsAsync = ref.watch(classTeacherSectionsProvider(currentUser.id));

    return sectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sections) {
        if (sections.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Primary Class Management', 'Manage'),
            const SizedBox(height: 16),
            ...sections.map((section) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => context.push(
                      '/class-teacher/${section.id}?name=${Uri.encodeComponent(section.displayName)}',
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.grey900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Class Teacher Control Panel',
                                style: TextStyle(
                                  color: AppColors.grey500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppColors.grey300, size: 16),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
        );
      },
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
              color: isCurrent ? AppColors.primary : (isBreak ? AppColors.warning.withValues(alpha: 0.05) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent
                    ? AppColors.primary
                    : (isBreak ? AppColors.warning.withValues(alpha: 0.2) : AppColors.borderLight),
              ),
              boxShadow: [
                if (isCurrent)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? Colors.white70 : AppColors.grey400,
                  ),
                ),
                const Spacer(),
                Text(
                  item.className,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isCurrent ? Colors.white : (isBreak ? AppColors.warning : AppColors.grey900),
                  ),
                ),
                if (!isBreak) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subject,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCurrent ? Colors.white70 : AppColors.grey500,
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

  Widget _buildAtRiskSection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final academicYearAsync = ref.watch(currentAcademicYearProvider);

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
                _buildSectionHeader(context, 'Critical: At-Risk Students', 'View All'),
                const SizedBox(height: 16),
                ...students.map((student) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => context.push('/students/${student.id}'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.studentName ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  Text(
                                    'Risk Score: ${student.overallRiskScore}',
                                    style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            RiskScoreBadge(riskScore: student),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEarlyWarningSection(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider(const AlertsFilter(status: 'new', limit: 2)));

    return alertsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'System Alerts', 'Review'),
            const SizedBox(height: 16),
            ...alerts.map((alert) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.earlyWarningAlerts),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.studentName ?? 'Unknown Student',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              Text(
                                alert.title,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.grey300),
                      ],
                    ),
                  ),
                )),
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
                _buildSectionHeader(context, 'Syllabus Progress', null),
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
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.grey700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TeacherStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
                fontWeight: FontWeight.w600,
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
