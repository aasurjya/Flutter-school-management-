import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

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
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.forestGradient,
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  currentUser?.initials ?? 'S',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser?.fullName ?? 'Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Class 10-A • Roll No: 15',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                // Stats Cards
                _buildStatsRow(context),
                const SizedBox(height: 24),

                // Today's Schedule
                _buildSectionHeader(context, "Today's Classes"),
                const SizedBox(height: 12),
                _buildTodayClasses(context),
                const SizedBox(height: 24),

                // Performance Overview
                _buildSectionHeader(context, 'Performance Overview'),
                const SizedBox(height: 12),
                _buildPerformanceCard(context),
                const SizedBox(height: 24),

                // Upcoming
                _buildSectionHeader(context, 'Upcoming'),
                const SizedBox(height: 12),
                _buildUpcoming(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Attendance',
            value: '94%',
            icon: Icons.calendar_today,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Avg Score',
            value: '87%',
            icon: Icons.trending_up,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Rank',
            value: '#5',
            icon: Icons.emoji_events,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayClasses(BuildContext context) {
    final classes = [
      {'time': '08:30', 'subject': 'Mathematics', 'teacher': 'Mr. Kumar', 'room': '101'},
      {'time': '09:30', 'subject': 'Physics', 'teacher': 'Mrs. Sharma', 'room': '102'},
      {'time': '10:30', 'subject': 'Chemistry', 'teacher': 'Dr. Patel', 'room': 'Lab 1'},
      {'time': '11:30', 'subject': 'English', 'teacher': 'Ms. Wilson', 'room': '103'},
      {'time': '12:30', 'subject': 'History', 'teacher': 'Mr. Singh', 'room': '104'},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: classes.asMap().entries.map((entry) {
          final index = entry.key;
          final cls = entry.value;
          final isCurrentClass = index == 0;

          return Container(
            margin: EdgeInsets.only(bottom: index < classes.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentClass
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isCurrentClass
                  ? Border.all(color: AppColors.secondary.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  child: Column(
                    children: [
                      Text(
                        cls['time']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCurrentClass ? AppColors.secondary : null,
                        ),
                      ),
                      if (isCurrentClass)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls['subject']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${cls['teacher']} • Room ${cls['room']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    final subjects = [
      {'name': 'Mathematics', 'score': 92, 'color': AppColors.primary},
      {'name': 'Physics', 'score': 88, 'color': AppColors.secondary},
      {'name': 'Chemistry', 'score': 85, 'color': AppColors.accent},
      {'name': 'English', 'score': 90, 'color': AppColors.info},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last Exam Results',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Rank #5',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...subjects.map((subject) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(subject['name'] as String, style: const TextStyle(fontSize: 13)),
                      Text(
                        '${subject['score']}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: subject['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (subject['score'] as int) / 100,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(subject['color'] as Color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUpcoming(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _UpcomingItem(
            icon: Icons.assignment,
            title: 'Physics Assignment Due',
            subtitle: 'Chapter 5 - Wave Optics',
            time: 'Tomorrow',
            color: AppColors.warning,
          ),
          const Divider(height: 24),
          _UpcomingItem(
            icon: Icons.quiz,
            title: 'Chemistry Quiz',
            subtitle: 'Organic Chemistry',
            time: 'In 3 days',
            color: AppColors.info,
          ),
          const Divider(height: 24),
          _UpcomingItem(
            icon: Icons.event,
            title: 'Parent-Teacher Meeting',
            subtitle: 'Annual Review',
            time: 'Next Week',
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _UpcomingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
