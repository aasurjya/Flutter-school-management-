import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';

class CertificateScreen extends ConsumerWidget {
  final String enrollmentId;

  const CertificateScreen({super.key, required this.enrollmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certAsync = ref.watch(certificateProvider(enrollmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Certificate',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: certAsync.when(
        data: (certificate) {
          if (certificate == null) {
            return _NoCertificateView(
              enrollmentId: enrollmentId,
              onGenerate: () =>
                  _generateCertificate(context, ref),
            );
          }
          return _CertificateView(certificate: certificate);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error: $e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(certificateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateCertificate(
      BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(lmsRepositoryProvider);
      final certNumber =
          'CERT-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      await repo.issueCertificate(
        enrollmentId: enrollmentId,
        certificateNumber: certNumber,
        templateData: {
          'style': 'modern',
          'theme_color': '#6366F1',
        },
      );
      ref.invalidate(certificateProvider);
      ref.invalidate(myCertificatesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate generated!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _NoCertificateView extends StatelessWidget {
  final String enrollmentId;
  final VoidCallback onGenerate;

  const _NoCertificateView({
    required this.enrollmentId,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 80, color: AppColors.accent.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'Certificate Available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have completed the course. Generate your certificate of completion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Generate Certificate'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateView extends StatelessWidget {
  final CourseCertificate certificate;

  const _CertificateView({required this.certificate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, y');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Certificate card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF4F46E5),
                  Color(0xFF3730A3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Border ornament
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.workspace_premium,
                        size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CERTIFICATE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'OF COMPLETION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This is to certify that',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    certificate.studentName ?? 'Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'has successfully completed the course',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    certificate.courseName ?? 'Course',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Issued on ${dateFormat.format(certificate.issuedAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Certificate No: ${certificate.certificateNumber}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Details card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                    label: 'Certificate Number',
                    value: certificate.certificateNumber),
                _DetailRow(
                  label: 'Issued Date',
                  value: dateFormat.format(certificate.issuedAt),
                ),
                _DetailRow(
                    label: 'Course',
                    value: certificate.courseName ?? 'N/A'),
                _DetailRow(
                    label: 'Recipient',
                    value: certificate.studentName ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('PDF download coming soon')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Share coming soon')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
