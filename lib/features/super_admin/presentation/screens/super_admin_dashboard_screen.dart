import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../ai_insights/presentation/widgets/platform_ai_health_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/tenant_provider.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tenantsNotifierProvider.notifier).loadTenants();
    });
  }

  Future<void> _logout() => confirmLogout(context, ref);

  Future<void> _refresh() async {
    ref.invalidate(platformStatsProvider);
    await ref.read(tenantsNotifierProvider.notifier).loadTenants();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Premium header ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: const Color(0xFF0F172A),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refresh,
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 80, 20),
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
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    currentUser?.initials ?? 'SA',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Platform Admin',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      currentUser?.fullName ?? 'Super Admin',
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
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined,
                                    size: 16, color: Colors.white70),
                                SizedBox(width: 6),
                                Text(
                                  'Campusly Platform',
                                  style: TextStyle(
                                    color: Colors.white70,
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
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPlatformStats(theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildPlatformAIHealth(),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, theme),
                  const SizedBox(height: 24),
                  _buildTenantOverview(context, theme, colorScheme),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Platform stats ──────────────────────────────────────────────────────────

  Widget _buildPlatformStats(ThemeData theme, ColorScheme colorScheme) {
    final statsAsync = ref.watch(platformStatsProvider);

    return statsAsync.when(
      loading: () => Row(
        children: [
          Expanded(child: _StatCardLoading(theme: theme)),
          const SizedBox(width: 12),
          Expanded(child: _StatCardLoading(theme: theme)),
        ],
      ),
      error: (error, _) => GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Failed to load stats: $error',
                  style: const TextStyle(color: AppColors.error)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(platformStatsProvider),
            ),
          ],
        ),
      ),
      data: (stats) => Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Tenants',
              value: '${stats['total_tenants'] ?? 0}',
              icon: Icons.business_outlined,
              color: const Color(0xFF6366F1),
              subtitle: '${stats['active_tenants'] ?? 0} active',
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Total Users',
              value: '${stats['total_users'] ?? 0}',
              icon: Icons.people_outlined,
              color: const Color(0xFF10B981),
              subtitle: '${stats['suspended_tenants'] ?? 0} suspended',
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  // ── Platform AI Health ─────────────────────────────────────────────────────

  Widget _buildPlatformAIHealth() {
    final statsAsync = ref.watch(platformStatsProvider);
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => PlatformAIHealthCard(
        tenantCount: (stats['total_tenants'] as num?)?.toInt() ?? 0,
        totalUsers: (stats['total_users'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_business_outlined,
                label: 'New Tenant',
                onTap: () => context.push(AppRoutes.createTenant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.list_alt_outlined,
                label: 'All Tenants',
                onTap: () => context.push(AppRoutes.tenantsList),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Tenant list ─────────────────────────────────────────────────────────────

  Widget _buildTenantOverview(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final tenantsAsync = ref.watch(tenantsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Tenants',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push(AppRoutes.tenantsList),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        tenantsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 32),
                const SizedBox(height: 8),
                Text('Failed to load tenants: $error',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(tenantsNotifierProvider.notifier).loadTenants(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (tenants) {
            if (tenants.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.business_outlined,
                        size: 48,
                        color: theme.textTheme.bodySmall?.color),
                    const SizedBox(height: 12),
                    Text(
                      'No tenants yet',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first school tenant to get started',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.createTenant),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Tenant'),
                    ),
                  ],
                ),
              );
            }

            final recentTenants = tenants.take(5).toList();
            return Column(
              children: recentTenants
                  .map((tenant) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () => context.push(
                                '${AppRoutes.tenantsList}/${tenant.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tenant.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tenant.name,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      Text(
                                        '${tenant.slug} \u00b7 ${tenant.subscriptionPlan}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tenant.isActive
                                        ? const Color(0xFF10B981)
                                            .withValues(alpha: 0.12)
                                        : AppColors.error
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tenant.isActive ? 'Active' : 'Suspended',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tenant.isActive
                                          ? const Color(0xFF10B981)
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final ThemeData theme;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Stat card skeleton ─────────────────────────────────────────────────────────

class _StatCardLoading extends StatelessWidget {
  final ThemeData theme;

  const _StatCardLoading({required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final shimmerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.grey200;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          Container(
              height: 28,
              width: 56,
              decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

// ── Action card ────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF6366F1);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
