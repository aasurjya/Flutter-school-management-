import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.fullName ?? 'Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                // Stats Grid
                _buildStatsGrid(context),
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildSectionHeader(context, 'Quick Actions'),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                
                // Today's Summary
                _buildSectionHeader(context, "Today's Summary"),
                const SizedBox(height: 12),
                _buildTodaySummary(context),
                const SizedBox(height: 24),
                
                // Recent Activity
                _buildSectionHeader(context, 'Recent Activity'),
                const SizedBox(height: 12),
                _buildRecentActivity(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        GlassStatCard(
          title: 'Total Students',
          value: '2,456',
          icon: Icons.people,
          iconColor: AppColors.primary,
          subtitle: '+12 this month',
        ),
        GlassStatCard(
          title: 'Teachers',
          value: '124',
          icon: Icons.school,
          iconColor: AppColors.secondary,
          subtitle: '98% present today',
        ),
        GlassStatCard(
          title: 'Attendance',
          value: '94.2%',
          icon: Icons.fact_check,
          iconColor: AppColors.success,
          subtitle: 'Today\'s average',
        ),
        GlassStatCard(
          title: 'Fee Collection',
          value: '₹12.5L',
          icon: Icons.currency_rupee,
          iconColor: AppColors.accent,
          subtitle: 'This month',
        ),
      ],
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

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickActionCard(
            icon: Icons.person_add,
            label: 'Add Student',
            color: AppColors.primary,
            onTap: () => context.push(AppRoutes.students),
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: Icons.fact_check,
            label: 'Mark Attendance',
            color: AppColors.secondary,
            onTap: () => context.push(AppRoutes.attendance),
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: Icons.receipt_long,
            label: 'Generate Invoice',
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.fees),
          ),
          const SizedBox(width: 12),
          _QuickActionCard(
            icon: Icons.campaign,
            label: 'Announcement',
            color: AppColors.info,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.people_outline,
            label: 'Students Present',
            value: '2,312 / 2,456',
            color: AppColors.success,
          ),
          const Divider(height: 24),
          _SummaryRow(
            icon: Icons.school_outlined,
            label: 'Teachers Present',
            value: '121 / 124',
            color: AppColors.success,
          ),
          const Divider(height: 24),
          _SummaryRow(
            icon: Icons.pending_actions,
            label: 'Pending Fee',
            value: '₹4.2L',
            color: AppColors.warning,
          ),
          const Divider(height: 24),
          _SummaryRow(
            icon: Icons.calendar_today,
            label: 'Events Today',
            value: '3',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      _ActivityItem(
        title: 'Fee Payment Received',
        subtitle: 'John Doe paid ₹25,000',
        time: '5 min ago',
        icon: Icons.payment,
        color: AppColors.success,
      ),
      _ActivityItem(
        title: 'New Admission',
        subtitle: 'Sarah Smith enrolled in Class 10-A',
        time: '1 hour ago',
        icon: Icons.person_add,
        color: AppColors.primary,
      ),
      _ActivityItem(
        title: 'Exam Results Published',
        subtitle: 'Mid-term results for Class 12',
        time: '2 hours ago',
        icon: Icons.assignment_turned_in,
        color: AppColors.info,
      ),
      _ActivityItem(
        title: 'Leave Request',
        subtitle: 'Mr. Kumar requested leave for tomorrow',
        time: '3 hours ago',
        icon: Icons.event_busy,
        color: AppColors.warning,
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: activities.map((activity) => _buildActivityTile(activity)).toList(),
      ),
    );
  }

  Widget _buildActivityTile(_ActivityItem activity) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: activity.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(activity.icon, color: activity.color, size: 20),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        activity.subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        activity.time,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}
