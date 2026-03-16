import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../transport/providers/transport_provider.dart';
import '../../../bus_tracking/providers/bus_tracking_provider.dart';

class TransportManagerDashboardScreen extends ConsumerWidget {
  const TransportManagerDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) => confirmLogout(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final transportAsync = ref.watch(transportStatsProvider);
    final busAsync = ref.watch(busTrackingStatsProvider);

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
                                  currentUser?.initials ?? 'TM',
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
                                    currentUser?.fullName ?? 'Transport Manager',
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
                              Icon(Icons.directions_bus_outlined, size: 14, color: Colors.white70),
                              SizedBox(width: 6),
                              Text(
                                'Transport Management',
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
                  children: _buildStatCards(transportAsync, busAsync),
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
                  icon: Icons.route_outlined,
                  label: 'View Routes',
                  subtitle: 'Manage all bus routes',
                  onTap: () => context.push(AppRoutes.transport),
                ),
                _QuickAction(
                  icon: Icons.directions_bus_filled_outlined,
                  label: 'Manage Vehicles',
                  subtitle: 'Vehicle fleet overview',
                  onTap: () => context.push(AppRoutes.transport),
                ),
                _QuickAction(
                  icon: Icons.map_outlined,
                  label: 'Live Map',
                  subtitle: 'Real-time bus locations',
                  onTap: () => context.push(AppRoutes.transport),
                ),
                _QuickAction(
                  icon: Icons.assignment_outlined,
                  label: 'My Route',
                  subtitle: 'View assigned route details',
                  onTap: () => context.push(AppRoutes.transportMyRoute),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatCards(
    AsyncValue<Map<String, dynamic>> transportAsync,
    AsyncValue<Map<String, dynamic>> busAsync,
  ) {
    final transportStats = transportAsync.valueOrNull;
    final busStats = busAsync.valueOrNull;
    final isLoading = transportAsync.isLoading || busAsync.isLoading;

    if (isLoading && transportStats == null && busStats == null) {
      return const [
        _StatCard(label: 'Active Routes', value: '--', icon: Icons.route_outlined, iconColor: Color(0xFF10B981)),
        _StatCard(label: 'Vehicles', value: '--', icon: Icons.directions_bus_outlined, iconColor: AppColors.primary),
        _StatCard(label: 'Students', value: '--', icon: Icons.people_outlined, iconColor: Color(0xFFF59E0B)),
        _StatCard(label: 'Active Trips', value: '--', icon: Icons.gps_fixed_outlined, iconColor: Color(0xFF10B981)),
      ];
    }

    return [
      _StatCard(
        label: 'Active Routes',
        value: '${transportStats?['total_routes'] ?? 0}',
        icon: Icons.route_outlined,
        iconColor: const Color(0xFF10B981),
      ),
      _StatCard(
        label: 'Vehicles',
        value: '${busStats?['total_vehicles'] ?? 0}',
        icon: Icons.directions_bus_outlined,
        iconColor: AppColors.primary,
      ),
      _StatCard(
        label: 'Students',
        value: '${transportStats?['total_students'] ?? 0}',
        icon: Icons.people_outlined,
        iconColor: const Color(0xFFF59E0B),
      ),
      _StatCard(
        label: 'Active Trips',
        value: '${busStats?['active_trips'] ?? 0}',
        icon: Icons.gps_fixed_outlined,
        iconColor: const Color(0xFF10B981),
      ),
    ];
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
