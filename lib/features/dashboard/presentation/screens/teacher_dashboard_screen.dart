import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';

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
                // TODO: Navigate to profile screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.secondary),
              title: const Text('Settings'),
              subtitle: const Text('App preferences'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to settings screen
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
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
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
                
                // My Classes
                _buildSectionHeader(context, 'My Classes'),
                const SizedBox(height: 12),
                _buildMyClasses(context),
                const SizedBox(height: 24),
                
                // Quick Stats
                _buildQuickStats(context),
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
          onPressed: () {},
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

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassStatCard(
            title: 'Attendance Marked',
            value: '3/5',
            icon: Icons.check_circle,
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
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

class _ScheduleItem {
  final String time;
  final String className;
  final String subject;
  final String period;

  _ScheduleItem(this.time, this.className, this.subject, this.period);
}
