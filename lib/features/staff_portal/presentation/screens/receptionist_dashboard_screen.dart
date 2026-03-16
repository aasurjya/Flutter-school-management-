import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../visitor/providers/visitor_provider.dart';

class ReceptionistDashboardScreen extends ConsumerWidget {
  const ReceptionistDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) => confirmLogout(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final statsAsync = ref.watch(visitorStatsProvider);

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
                tooltip: 'More options',
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
                                  currentUser?.initials ?? 'RC',
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
                                    currentUser?.fullName ?? 'Receptionist',
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
                              Icon(Icons.badge_outlined, size: 14, color: Colors.white70),
                              SizedBox(width: 6),
                              Text(
                                'Visitor Management',
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
                      _StatCard(label: 'Visitors Today', value: '--', icon: Icons.people_outlined, iconColor: AppColors.primary),
                      _StatCard(label: 'On Premises', value: '--', icon: Icons.location_on_outlined, iconColor: Color(0xFF10B981)),
                      _StatCard(label: 'Pre-Registered', value: '--', icon: Icons.event_available_outlined, iconColor: Color(0xFFF59E0B)),
                      _StatCard(label: 'Checked Out', value: '--', icon: Icons.logout_outlined, iconColor: AppColors.grey500),
                    ],
                    error: (_, __) => const [
                      _StatCard(label: 'Visitors Today', value: '--', icon: Icons.people_outlined, iconColor: AppColors.primary),
                      _StatCard(label: 'On Premises', value: '--', icon: Icons.location_on_outlined, iconColor: Color(0xFF10B981)),
                      _StatCard(label: 'Pre-Registered', value: '--', icon: Icons.event_available_outlined, iconColor: Color(0xFFF59E0B)),
                      _StatCard(label: 'Checked Out', value: '--', icon: Icons.logout_outlined, iconColor: AppColors.grey500),
                    ],
                    data: (stats) => [
                      _StatCard(label: 'Visitors Today', value: '${stats.todayTotal}', icon: Icons.people_outlined, iconColor: AppColors.primary),
                      _StatCard(label: 'On Premises', value: '${stats.currentlyCheckedIn}', icon: Icons.location_on_outlined, iconColor: const Color(0xFF10B981)),
                      _StatCard(label: 'Pre-Registered', value: '${stats.preRegisteredToday}', icon: Icons.event_available_outlined, iconColor: const Color(0xFFF59E0B)),
                      _StatCard(label: 'Checked Out', value: '${stats.checkedOutToday}', icon: Icons.logout_outlined, iconColor: AppColors.grey500),
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
                  icon: Icons.how_to_reg_outlined,
                  label: 'Check In Visitor',
                  subtitle: 'Register an incoming visitor',
                  onTap: () => context.push(AppRoutes.visitorCheckIn),
                ),
                _QuickAction(
                  icon: Icons.event_outlined,
                  label: 'Pre-Registration',
                  subtitle: 'Register an upcoming visitor',
                  onTap: () => context.push(AppRoutes.visitorPreRegister),
                ),
                _QuickAction(
                  icon: Icons.list_alt_outlined,
                  label: 'Visitor Log',
                  subtitle: 'View today\'s visitor history',
                  onTap: () => context.push(AppRoutes.visitorLog),
                ),
                _QuickAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                  subtitle: 'View school events',
                  onTap: () => context.push(AppRoutes.calendar),
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
