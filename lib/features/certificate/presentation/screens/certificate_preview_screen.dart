import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/certificate_provider.dart';
import '../widgets/certificate_pdf_builder.dart';

class CertificatePreviewScreen extends ConsumerWidget {
  final String certId;

  const CertificatePreviewScreen({super.key, required this.certId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final certAsync = ref.watch(certificateByIdProvider(certId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Preview'),
        actions: [
          certAsync.whenOrNull(
                data: (cert) {
                  if (cert == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cert.status == CertificateStatus.draft)
                        IconButton(
                          icon: const Icon(Icons.check_circle),
                          tooltip: 'Mark as Issued',
                          onPressed: () =>
                              _markAsIssued(context, ref, cert),
                        ),
                      IconButton(
                        icon: const Icon(Icons.print),
                        tooltip: 'Print / Download',
                        onPressed: () => _printCertificate(cert),
                      ),
                      if (cert.status == CertificateStatus.issued)
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          tooltip: 'Revoke',
                          color: AppColors.error,
                          onPressed: () =>
                              _revokeCertificate(context, ref, cert),
                        ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: certAsync.when(
        data: (cert) {
          if (cert == null) {
            return const Center(child: Text('Certificate not found'));
          }

          return Column(
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: _statusColor(cert.status).withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _statusIcon(cert.status),
                      color: _statusColor(cert.status),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cert.status.label} | ${cert.certificateNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _statusColor(cert.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // PDF Preview
              Expanded(
                child: cert.template != null
                    ? PdfPreview(
                        build: (format) =>
                            CertificatePdfBuilder.buildCertificatePdf(
                          certificate: cert,
                          template: cert.template!,
                          schoolName: 'School Name',
                          schoolAddress:
                              'School Address, City, State',
                        ),
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        pdfFileName:
                            '${cert.certificateNumber}.pdf',
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48,
                                color: AppColors.textTertiaryLight),
                            const SizedBox(height: 8),
                            Text(
                              'Template not found for this certificate',
                              style:
                                  theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Details footer
              GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _FooterItem(
                      label: 'Student',
                      value: cert.studentName ?? 'Unknown',
                    ),
                    _FooterItem(
                      label: 'Type',
                      value: cert.template?.type.label ?? 'N/A',
                    ),
                    _FooterItem(
                      label: 'Issued By',
                      value: cert.issuedByName ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _printCertificate(IssuedCertificate cert) async {
    if (cert.template == null) return;

    final pdfBytes = await CertificatePdfBuilder.buildCertificatePdf(
      certificate: cert,
      template: cert.template!,
      schoolName: 'School Name',
      schoolAddress: 'School Address, City, State',
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: cert.certificateNumber,
    );
  }

  Future<void> _markAsIssued(
    BuildContext context,
    WidgetRef ref,
    IssuedCertificate cert,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Issued?'),
        content: const Text(
            'This will finalize the certificate. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Issue'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(issuedCertificateNotifierProvider.notifier)
            .markAsIssued(cert.id);
        ref.invalidate(certificateByIdProvider(certId));
        ref.invalidate(certificateStatsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate marked as issued'),
              backgroundColor: AppColors.success,
            ),
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

  Future<void> _revokeCertificate(
    BuildContext context,
    WidgetRef ref,
    IssuedCertificate cert,
  ) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Certificate?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This action cannot be easily undone.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for revocation *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      try {
        await ref
            .read(issuedCertificateNotifierProvider.notifier)
            .revoke(cert.id, reasonController.text.trim());
        ref.invalidate(certificateByIdProvider(certId));
        ref.invalidate(certificateStatsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate revoked'),
              backgroundColor: AppColors.error,
            ),
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
    reasonController.dispose();
  }

  Color _statusColor(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.draft:
        return AppColors.warning;
      case CertificateStatus.issued:
        return AppColors.success;
      case CertificateStatus.revoked:
        return AppColors.error;
    }
  }

  IconData _statusIcon(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.draft:
        return Icons.edit_note;
      case CertificateStatus.issued:
        return Icons.check_circle;
      case CertificateStatus.revoked:
        return Icons.cancel;
    }
  }
}

class _FooterItem extends StatelessWidget {
  final String label;
  final String value;

  const _FooterItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}
