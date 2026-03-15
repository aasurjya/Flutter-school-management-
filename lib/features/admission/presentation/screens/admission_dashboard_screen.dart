import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/admission_provider.dart';
import '../widgets/admission_pipeline_chart.dart';
import '../widgets/admission_stat_card.dart';
import '../widgets/application_status_badge.dart';

class AdmissionDashboardScreen extends ConsumerWidget {
  const AdmissionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(currentAdmissionStatsProvider);
    final recentAppsAsync = ref.watch(
      admissionApplicationsProvider(
        const ApplicationFilter(limit: 5),
      ),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Admission Settings',
            onPressed: () => context.push(AppRoutes.admissionSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentAdmissionStatsProvider);
          ref.invalidate(admissionApplicationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick action buttons
            _buildQuickActions(context),
            const SizedBox(height: 16),

            // Stats cards
            statsAsync.when(
              data: (stats) => _buildStatsGrid(stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading stats: $e'),
              ),
            ),

            const SizedBox(height: 16),

            // Pipeline chart
            statsAsync.when(
              data: (stats) => AdmissionPipelineChart(stats: stats),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Recent applications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Applications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.admissionApplications),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recentAppsAsync.when(
              data: (apps) => apps.isEmpty
                  ? GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.inbox,
                                size: 48, color: AppColors.textTertiaryLight),
                            const SizedBox(height: 12),
                            Text(
                              'No applications yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children:
                          apps.map((app) => _buildApplicationTile(context, app)).toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.admissionApplicationForm),
        icon: const Icon(Icons.add),
        label: const Text('New Application'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.contact_mail,
            label: 'Inquiries',
            color: const Color(0xFF6366F1),
            onTap: () => context.push(AppRoutes.admissionInquiries),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.description,
            label: 'Applications',
            color: const Color(0xFF3B82F6),
            onTap: () => context.push(AppRoutes.admissionApplications),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.event,
            label: 'Interviews',
            color: const Color(0xFFF97316),
            onTap: () => context.push(AppRoutes.admissionInterviews),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AdmissionStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        AdmissionStatCard(
          title: 'Total Applications',
          value: '${stats.totalApplications}',
          icon: Icons.description,
          color: AppColors.primary,
        ),
        AdmissionStatCard(
          title: 'Pending Review',
          value: '${stats.pendingReview}',
          icon: Icons.hourglass_empty,
          color: AppColors.warning,
        ),
        AdmissionStatCard(
          title: 'Accepted',
          value: '${stats.accepted}',
          icon: Icons.check_circle,
          color: AppColors.success,
          subtitle: '${stats.enrolled} enrolled',
        ),
        AdmissionStatCard(
          title: 'Open Inquiries',
          value: '${stats.openInquiries}',
          icon: Icons.contact_mail,
          color: AppColors.info,
          subtitle: '${stats.totalInquiries} total',
        ),
      ],
    );
  }

  Widget _buildApplicationTile(
      BuildContext context, AdmissionApplication app) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(
        AppRoutes.admissionApplicationDetail
            .replaceAll(':applicationId', app.id),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              app.studentName.isNotEmpty
                  ? app.studentName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.studentName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${app.applicationNumber ?? "Draft"} | ${app.className ?? "Class N/A"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          ApplicationStatusBadge(status: app.status),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
