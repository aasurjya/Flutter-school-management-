import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/early_warning_alert.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/early_warning_provider.dart';
import '../widgets/alert_severity_badge.dart';

/// Detail screen for a single [EarlyWarningAlert].
///
/// Shows the full alert information including severity, category, student info,
/// AI-generated explanation, trigger conditions, and action buttons to progress
/// the alert through its lifecycle (new -> acknowledged -> in_progress -> resolved).
class AlertDetailScreen extends ConsumerStatefulWidget {
  final String alertId;

  const AlertDetailScreen({
    super.key,
    required this.alertId,
  });

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  final _resolutionController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertAsync = ref.watch(enrichedAlertDetailProvider(widget.alertId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Detail'),
      ),
      body: alertAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load alert',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '$error',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (alert) {
          if (alert == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Alert not found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Info Card
                _buildAlertInfoCard(context, alert),
                const SizedBox(height: 16),

                // Student Info Card
                _buildStudentInfoCard(context, alert),
                const SizedBox(height: 16),

                // AI Explanation Card
                _buildAiExplanationCard(context, alert),
                const SizedBox(height: 16),

                // Trigger Conditions Card
                if (alert.triggerConditions.isNotEmpty) ...[
                  _buildTriggerConditionsCard(context, alert),
                  const SizedBox(height: 16),
                ],

                // Status & Actions Section
                _buildStatusActionsSection(context, alert),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Alert Info Card
  // -----------------------------------------------------------------------
  Widget _buildAlertInfoCard(BuildContext context, EarlyWarningAlert alert) {
    final dateFormat = DateFormat('MMM dd, yyyy  hh:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notification_important_outlined,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Alert Information',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          // Severity badge + title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AlertSeverityBadge(severity: alert.severity),
            ],
          ),
          if (alert.description != null &&
              alert.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              alert.description!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Category chip
          Row(
            children: [
              Icon(alert.category.icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.category.displayLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (alert.confidenceLabel != null)
                Text(
                  'Confidence: ${alert.confidenceLabel}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Created date
          if (alert.createdAt != null)
            Text(
              'Created: ${dateFormat.format(alert.createdAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Student Info Card
  // -----------------------------------------------------------------------
  Widget _buildStudentInfoCard(
      BuildContext context, EarlyWarningAlert alert) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline,
                  size: 20, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Student Information',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Name',
            alert.studentName ?? 'Unknown',
          ),
          if (alert.admissionNumber != null)
            _buildInfoRow(
              'Admission No.',
              alert.admissionNumber!,
            ),
          if (alert.className != null || alert.sectionName != null)
            _buildInfoRow(
              'Class / Section',
              '${alert.className ?? ''} ${alert.sectionName ?? ''}'.trim(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // AI Explanation Card
  // -----------------------------------------------------------------------
  Widget _buildAiExplanationCard(
      BuildContext context, EarlyWarningAlert alert) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 20, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          if (alert.aiExplanation != null &&
              alert.aiExplanation!.isNotEmpty)
            Text(
              alert.aiExplanation!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Generating analysis...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Trigger Conditions Card
  // -----------------------------------------------------------------------
  Widget _buildTriggerConditionsCard(
      BuildContext context, EarlyWarningAlert alert) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rule_outlined,
                  size: 20, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Trigger Conditions',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          ...alert.triggerConditions.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      _formatConditionKey(entry.key),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Converts a snake_case key to a readable label.
  String _formatConditionKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  // -----------------------------------------------------------------------
  // Status & Actions Section
  // -----------------------------------------------------------------------
  Widget _buildStatusActionsSection(
      BuildContext context, EarlyWarningAlert alert) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.playlist_add_check_outlined,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Status & Actions',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),

          // Current status chip
          Row(
            children: [
              const Text(
                'Current Status:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: alert.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: alert.status.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  alert.status.displayLabel,
                  style: TextStyle(
                    color: alert.status.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons based on current status
          if (alert.status == AlertStatus.newAlert) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(alert.id, 'acknowledged'),
                icon: const Icon(Icons.visibility, size: 18),
                label: _isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Acknowledge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (alert.status == AlertStatus.acknowledged) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(alert.id, 'in_progress'),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: _isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start Working'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (alert.status == AlertStatus.inProgress) ...[
            TextField(
              controller: _resolutionController,
              decoration: InputDecoration(
                labelText: 'Resolution Notes',
                hintText: 'Describe what was done to resolve this alert...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.inputFillLight,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(
                          alert.id,
                          'resolved',
                          resolutionNotes: _resolutionController.text.trim(),
                        ),
                icon: const Icon(Icons.check_circle, size: 18),
                label: _isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (alert.status == AlertStatus.resolved) ...[
            if (alert.resolutionNotes != null &&
                alert.resolutionNotes!.isNotEmpty) ...[
              Text(
                'Resolution Notes:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  alert.resolutionNotes!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (alert.resolvedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Resolved on: ${DateFormat('MMM dd, yyyy  hh:mm a').format(alert.resolvedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],

          // Mark false positive (available for all non-resolved statuses)
          if (alert.status != AlertStatus.resolved &&
              alert.status != AlertStatus.falsePositive) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(alert.id, 'false_positive'),
                icon: Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                label: Text(
                  'Mark as False Positive',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Status Update Handler
  // -----------------------------------------------------------------------
  Future<void> _updateStatus(
    String alertId,
    String newStatus, {
    String? resolutionNotes,
  }) async {
    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(earlyWarningRepositoryProvider);
      await repo.updateAlertStatus(
        alertId: alertId,
        status: newStatus,
        resolutionNotes: resolutionNotes,
      );

      if (mounted) {
        context.showSuccessSnackBar(
          'Alert status updated to ${AlertStatus.fromDbValue(newStatus).displayLabel}',
        );
        // Invalidate providers so the list and detail reload
        ref.invalidate(enrichedAlertDetailProvider(alertId));
        ref.invalidate(alertsProvider(const AlertsFilter()));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to update status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}
