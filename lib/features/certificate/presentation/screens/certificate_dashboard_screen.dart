import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/certificate_provider.dart';
import '../widgets/certificate_card.dart';

class CertificateDashboardScreen extends ConsumerWidget {
  const CertificateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(certificateStatsProvider);
    final recentAsync = ref.watch(issuedCertificatesProvider(
        const CertificateFilter(limit: 5)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(certificateStatsProvider);
              ref.invalidate(issuedCertificatesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(certificateStatsProvider);
          ref.invalidate(issuedCertificatesProvider);
        },
        child: ListView(
          children: [
            const SizedBox(height: 8),

            // Stats
            statsAsync.when(
              data: (stats) => _StatsSection(stats: stats),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle,
                      label: 'Issue Certificate',
                      color: AppColors.success,
                      onTap: () =>
                          context.push(AppRoutes.issueCertificate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.design_services,
                      label: 'Templates',
                      color: AppColors.primary,
                      onTap: () =>
                          context.push(AppRoutes.certificateTemplates),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.list_alt,
                      label: 'All Certificates',
                      color: AppColors.info,
                      onTap: () =>
                          context.push(AppRoutes.certificateList),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.verified_user,
                      label: 'Verify',
                      color: AppColors.accent,
                      onTap: () =>
                          context.push(AppRoutes.verifyCertificate),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent certificates
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Certificates',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.certificateList),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            recentAsync.when(
              data: (certs) {
                if (certs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 48,
                              color: AppColors.textTertiaryLight),
                          const SizedBox(height: 8),
                          Text(
                            'No certificates issued yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: certs
                      .map((cert) => CertificateCard(
                            certificate: cert,
                            onTap: () => context.push(
                              AppRoutes.certificatePreview
                                  .replaceFirst(':certId', cert.id),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final CertificateStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GlassStatCard(
              title: 'Total Issued',
              value: '${stats.totalIssued}',
              icon: Icons.description,
              iconColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassStatCard(
              title: 'Active',
              value: '${stats.issued}',
              icon: Icons.check_circle,
              iconColor: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassStatCard(
              title: 'Templates',
              value: '${stats.templatesCount}',
              icon: Icons.design_services,
              iconColor: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textTertiaryLight),
        ],
      ),
    );
  }
}
