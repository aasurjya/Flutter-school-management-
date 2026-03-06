import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';

/// A visual badge widget for a checked-in visitor
class VisitorBadgeWidget extends StatelessWidget {
  final VisitorLog log;

  const VisitorBadgeWidget({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitor = log.visitor;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'VISITOR PASS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                if (log.badgeNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Badge #${log.badgeNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Visitor photo / initials
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: visitor?.photoUrl != null
                ? NetworkImage(visitor!.photoUrl!)
                : null,
            child: visitor?.photoUrl == null
                ? Text(
                    visitor?.initials ?? '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            visitor?.fullName ?? 'Unknown Visitor',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (visitor?.company != null) ...[
            const SizedBox(height: 4),
            Text(
              visitor!.company!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Details
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailRow(
              context, 'Purpose', log.purpose.label, Icons.category),
          if (log.personToMeetName != null)
            _buildDetailRow(
                context, 'Meeting', log.personToMeetName!, Icons.person),
          if (log.department != null)
            _buildDetailRow(
                context, 'Department', log.department!, Icons.business),
          _buildDetailRow(
            context,
            'Check-in',
            _formatTime(log.checkInTime),
            Icons.login,
          ),
          if (log.vehicleNumber != null)
            _buildDetailRow(context, 'Vehicle', log.vehicleNumber!,
                Icons.directions_car),
          const SizedBox(height: 8),

          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor(log.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              log.status.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: _statusColor(log.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiaryLight),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _statusColor(VisitorLogStatus status) {
    switch (status) {
      case VisitorLogStatus.checkedIn:
        return AppColors.success;
      case VisitorLogStatus.checkedOut:
        return AppColors.info;
      case VisitorLogStatus.denied:
        return AppColors.error;
      case VisitorLogStatus.preRegistered:
        return AppColors.warning;
    }
  }
}
