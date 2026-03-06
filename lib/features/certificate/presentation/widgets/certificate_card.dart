import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../../../shared/widgets/glass_card.dart';

class CertificateCard extends StatelessWidget {
  final IssuedCertificate certificate;
  final VoidCallback? onTap;

  const CertificateCard({
    super.key,
    required this.certificate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _typeColor(certificate.template?.type ??
                          CertificateType.custom)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _typeIcon(certificate.template?.type ??
                      CertificateType.custom),
                  color: _typeColor(certificate.template?.type ??
                      CertificateType.custom),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate.template?.type.label ??
                          'Certificate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      certificate.certificateNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: certificate.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.person,
                  label: 'Student',
                  value: certificate.studentName ?? 'Unknown',
                ),
              ),
              Expanded(
                child: _DetailItem(
                  icon: Icons.calendar_today,
                  label: 'Issued',
                  value: dateFormat.format(certificate.issuedDate),
                ),
              ),
            ],
          ),
          if (certificate.className != null) ...[
            const SizedBox(height: 8),
            _DetailItem(
              icon: Icons.class_,
              label: 'Class',
              value: certificate.className!,
            ),
          ],
          if (certificate.purpose != null) ...[
            const SizedBox(height: 8),
            _DetailItem(
              icon: Icons.description,
              label: 'Purpose',
              value: certificate.purpose!,
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(CertificateType type) {
    switch (type) {
      case CertificateType.transfer:
        return AppColors.info;
      case CertificateType.bonafide:
        return AppColors.success;
      case CertificateType.character:
        return AppColors.accent;
      case CertificateType.migration:
        return AppColors.primaryLight;
      case CertificateType.achievement:
        return AppColors.gradeA;
      case CertificateType.participation:
        return AppColors.gradeB;
      case CertificateType.merit:
        return AppColors.gradeC;
      case CertificateType.custom:
        return AppColors.primary;
    }
  }

  IconData _typeIcon(CertificateType type) {
    switch (type) {
      case CertificateType.transfer:
        return Icons.swap_horiz;
      case CertificateType.bonafide:
        return Icons.verified;
      case CertificateType.character:
        return Icons.person_pin;
      case CertificateType.migration:
        return Icons.flight;
      case CertificateType.achievement:
        return Icons.emoji_events;
      case CertificateType.participation:
        return Icons.groups;
      case CertificateType.merit:
        return Icons.star;
      case CertificateType.custom:
        return Icons.description;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final CertificateStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case CertificateStatus.draft:
        return AppColors.warning;
      case CertificateStatus.issued:
        return AppColors.success;
      case CertificateStatus.revoked:
        return AppColors.error;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiaryLight),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
