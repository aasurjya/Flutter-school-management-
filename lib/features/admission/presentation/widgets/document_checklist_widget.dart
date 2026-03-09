import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'application_status_badge.dart';

/// Document checklist showing upload + verification status for an application
class DocumentChecklistWidget extends StatelessWidget {
  final List<AdmissionDocument> documents;
  final List<String> requiredDocTypes;
  final bool canVerify;
  final bool canUpload;
  final void Function(AdmissionDocumentType type)? onUpload;
  final void Function(AdmissionDocument doc, DocumentStatus status)? onVerify;

  const DocumentChecklistWidget({
    super.key,
    required this.documents,
    required this.requiredDocTypes,
    this.canVerify = false,
    this.canUpload = false,
    this.onUpload,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build a map of document type -> document
    final docMap = <String, AdmissionDocument>{};
    for (final doc in documents) {
      docMap[doc.documentType.value] = doc;
    }

    final verified = documents.where((d) => d.status == DocumentStatus.verified).length;
    final total = requiredDocTypes.length;
    final progress = total > 0 ? verified / total : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$verified / $total verified',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Document list
          ...requiredDocTypes.map((typeStr) {
            final docType = AdmissionDocumentType.fromString(typeStr);
            final doc = docMap[typeStr];
            return _buildDocumentRow(context, docType, doc, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
    BuildContext context,
    AdmissionDocumentType type,
    AdmissionDocument? doc,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final hasDocument = doc != null;
    final status = doc?.status ?? DocumentStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconForDocType(type),
            size: 20,
            color: hasDocument ? AppColors.primary : AppColors.textTertiaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (doc?.fileName != null)
                  Text(
                    doc!.fileName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (hasDocument) ...[
            DocumentStatusBadge(status: status),
            if (canVerify && status == DocumentStatus.uploaded) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 20),
                onPressed: () => onVerify?.call(doc, DocumentStatus.verified),
                tooltip: 'Verify',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 20),
                onPressed: () => onVerify?.call(doc, DocumentStatus.rejected),
                tooltip: 'Reject',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ] else if (canUpload) ...[
            TextButton.icon(
              onPressed: () => onUpload?.call(type),
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Upload'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: AppColors.textTertiaryLight,
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForDocType(AdmissionDocumentType type) {
    switch (type) {
      case AdmissionDocumentType.birthCertificate:
        return Icons.cake;
      case AdmissionDocumentType.transferCertificate:
        return Icons.swap_horiz;
      case AdmissionDocumentType.reportCard:
        return Icons.assessment;
      case AdmissionDocumentType.addressProof:
        return Icons.home;
      case AdmissionDocumentType.photo:
        return Icons.photo_camera;
      case AdmissionDocumentType.parentId:
        return Icons.badge;
      case AdmissionDocumentType.medicalCertificate:
        return Icons.medical_information;
      case AdmissionDocumentType.casteCertificate:
        return Icons.article;
      case AdmissionDocumentType.incomeCertificate:
        return Icons.account_balance;
      case AdmissionDocumentType.migrationCertificate:
        return Icons.flight;
      case AdmissionDocumentType.other:
        return Icons.attach_file;
    }
  }
}
