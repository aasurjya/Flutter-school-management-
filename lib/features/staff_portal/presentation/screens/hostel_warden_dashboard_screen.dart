import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../hostel/providers/hostel_provider.dart';

class HostelWardenDashboardScreen extends ConsumerWidget {
  const HostelWardenDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final statsAsync = ref.watch(hostelStatsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.badge_rounded, color: Colors.white),
                tooltip: 'My ID Card',
                onPressed: () => context.push(AppRoutes.staffIdCard),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _logout(context, ref),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.grey800],
                  ),
                ),
                child: SafeArea(
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
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  currentUser?.initials ?? 'HW',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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
                                    currentUser?.fullName ?? 'Hostel Warden',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.apartment_outlined, size: 14, color: Colors.white70),
                              SizedBox(width: 6),
                              Text(
                                'Hostel Management',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: statsAsync.when(
                    loading: () => const [
                      _StatCard(label: 'Rooms Filled', value: '--', icon: Icons.meeting_room_outlined, iconColor: Color(0xFF10B981)),
                      _StatCard(label: 'Available Beds', value: '--', icon: Icons.bed_outlined, iconColor: AppColors.primary),
                      _StatCard(label: 'Occupancy', value: '--', icon: Icons.pie_chart_outline, iconColor: Color(0xFFF59E0B)),
                      _StatCard(label: 'Total Hostels', value: '--', icon: Icons.apartment_outlined, iconColor: AppColors.error),
                    ],
                    error: (_, __) => const [
                      _StatCard(label: 'Rooms Filled', value: '--', icon: Icons.meeting_room_outlined, iconColor: Color(0xFF10B981)),
                      _StatCard(label: 'Available Beds', value: '--', icon: Icons.bed_outlined, iconColor: AppColors.primary),
                      _StatCard(label: 'Occupancy', value: '--', icon: Icons.pie_chart_outline, iconColor: Color(0xFFF59E0B)),
                      _StatCard(label: 'Total Hostels', value: '--', icon: Icons.apartment_outlined, iconColor: AppColors.error),
                    ],
                    data: (stats) => [
                      _StatCard(
                        label: 'Rooms Filled',
                        value: '${stats['total_occupied'] ?? 0}/${stats['total_capacity'] ?? 0}',
                        icon: Icons.meeting_room_outlined,
                        iconColor: const Color(0xFF10B981),
                      ),
                      _StatCard(
                        label: 'Available Beds',
                        value: '${stats['available_beds'] ?? 0}',
                        icon: Icons.bed_outlined,
                        iconColor: AppColors.primary,
                      ),
                      _StatCard(
                        label: 'Occupancy',
                        value: '${stats['occupancy_rate'] ?? 0}%',
                        icon: Icons.pie_chart_outline,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                      _StatCard(
                        label: 'Total Hostels',
                        value: '${stats['total_hostels'] ?? 0}',
                        icon: Icons.apartment_outlined,
                        iconColor: AppColors.error,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 12),

                _QuickAction(
                  icon: Icons.person_add_outlined,
                  label: 'Allocate Room',
                  subtitle: 'Assign a student to a room',
                  onTap: () => context.push(AppRoutes.hostel),
                ),
                _QuickAction(
                  icon: Icons.door_back_door_outlined,
                  label: 'Room List',
                  subtitle: 'View all rooms and occupancy',
                  onTap: () => context.push(AppRoutes.hostel),
                ),
                _QuickAction(
                  icon: Icons.build_circle_outlined,
                  label: 'Maintenance Requests',
                  subtitle: 'View and handle requests',
                  onTap: () => context.push(AppRoutes.hostel),
                ),
                _QuickAction(
                  icon: Icons.bedroom_parent_outlined,
                  label: 'My Hostel',
                  subtitle: 'Overview of assigned hostel',
                  onTap: () => context.push(AppRoutes.hostelMyRoom),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.grey900)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.grey400, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }
}
