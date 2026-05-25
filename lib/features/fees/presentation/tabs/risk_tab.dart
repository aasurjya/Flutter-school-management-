import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/providers/ai_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/fee_default_prediction.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/fees_provider.dart';

/// Risk tab on the Fees screen. Lists every at-risk fee account, summary
/// header with totals + filter chips, expandable card per student.
///
/// Extracted from `fees_screen.dart` (Stage 3 / fees-screen split).
/// Surface area: this file is everything the Risk tab needs — list,
/// per-row card, reminder dialog, summary widgets. Other tabs reach in
/// only via the top-level [RiskTab] class.
class RiskTab extends ConsumerStatefulWidget {
  const RiskTab({super.key});

  @override
  ConsumerState<RiskTab> createState() => _RiskTabState();
}

class _RiskTabState extends ConsumerState<RiskTab> {
  FeeRiskLevel? _filterLevel;

  @override
  Widget build(BuildContext context) {
    final predictionsAsync = ref.watch(feeDefaultPredictionsProvider);

    return predictionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(WarmCopy.loadFailed('risk data')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(feeDefaultPredictionsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (predictions) {
        final summary = FeeDefaultSummary.from(predictions);
        final filtered = _filterLevel == null
            ? predictions
            : predictions
                .where((p) => p.riskLevel == _filterLevel)
                .toList();

        return Column(
          children: [
            _buildSummaryHeader(context, summary),
            _buildFilterChips(summary),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _PredictionCard(prediction: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(
      BuildContext context, FeeDefaultSummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.8),
            Colors.orange.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fee Collection Risk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${summary.totalAtRisk} accounts at risk',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.formattedAmountAtRisk} at stake',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RiskCountBadge(
                  label: 'High',
                  count: summary.highRiskCount,
                  color: Colors.red[200]!),
              const SizedBox(width: 8),
              _RiskCountBadge(
                  label: 'Medium',
                  count: summary.mediumRiskCount,
                  color: Colors.orange[200]!),
              const SizedBox(width: 8),
              _RiskCountBadge(
                  label: 'Low',
                  count: summary.lowRiskCount,
                  color: Colors.green[200]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(FeeDefaultSummary summary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All (${summary.totalAtRisk})',
            selected: _filterLevel == null,
            color: Colors.grey,
            onTap: () => setState(() => _filterLevel = null),
          ),
          const SizedBox(width: 8),
          ...FeeRiskLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label:
                      '${level.label.split(" ").first} (${level == FeeRiskLevel.high ? summary.highRiskCount : level == FeeRiskLevel.medium ? summary.mediumRiskCount : summary.lowRiskCount})',
                  selected: _filterLevel == level,
                  color: level.color,
                  onTap: () =>
                      setState(() => _filterLevel = level),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle,
              size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          const Text(
            'No at-risk accounts!',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _filterLevel == null
                ? 'All fee accounts are in good standing.'
                : 'No ${_filterLevel!.label.toLowerCase()} accounts found.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Prediction Card — expandable per-student row
// =============================================================

class _PredictionCard extends ConsumerStatefulWidget {
  final FeeDefaultPrediction prediction;

  const _PredictionCard({required this.prediction});

  @override
  ConsumerState<_PredictionCard> createState() =>
      _PredictionCardState();
}

class _PredictionCardState extends ConsumerState<_PredictionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final level = p.riskLevel;
    final dateStr = DateFormat('d MMM yyyy').format(p.dueDate);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: level.bgColor,
                      border: Border.all(
                          color: level.borderColor, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${p.riskScore}',
                        style: TextStyle(
                          color: level.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: level.bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: level.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(level.icon,
                                      size: 11, color: level.color),
                                  const SizedBox(width: 3),
                                  Text(
                                    level.label.split(' ').first,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: level.color,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${p.className} • ${p.invoiceNumber}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${_formatAmount(p.amountDue)} due',
                              style: TextStyle(
                                color: level.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.isOverdue
                                  ? '${p.daysOverdue}d overdue'
                                  : 'Due $dateStr',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: p.isOverdue
                                      ? Colors.red
                                      : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.riskScore / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(level.color),
                minHeight: 4,
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.riskFactors.isNotEmpty) ...[
                    const Text(
                      'Risk Factors',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...p.riskFactors.map((factor) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right,
                                  size: 16, color: level.color),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(factor,
                                    style: const TextStyle(
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: AppColors.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.recommendedAction,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (p.lastReminderAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last reminder: ${DateFormat("d MMM, hh:mm a").format(p.lastReminderAt!.toLocal())}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: p.reminderSentRecently
                              ? null
                              : () => _showReminderDialog(context),
                          icon: const Icon(Icons.message_outlined,
                              size: 16),
                          label: Text(p.reminderSentRecently
                              ? 'Sent Today'
                              : 'Send Reminder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showInstallmentDialog(context),
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Create Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: level.color,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          _ReminderDialog(prediction: widget.prediction),
    );
  }

  void _showInstallmentDialog(BuildContext context) {
    final p = widget.prediction;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Installment Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${p.studentName}'),
            Text('Invoice: ${p.invoiceNumber}'),
            Text('Amount: ₹${_formatAmount(p.amountDue)}'),
            const SizedBox(height: 12),
            const Text(
              'Split this amount into monthly installments and set a payment '
              'schedule for this family.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.feeManagement);
            },
            child: const Text('Create Plan'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(0);
  }
}

// =============================================================
// Reminder Dialog — AI-generated reminder message
// =============================================================

class _ReminderDialog extends ConsumerStatefulWidget {
  final FeeDefaultPrediction prediction;

  const _ReminderDialog({required this.prediction});

  @override
  ConsumerState<_ReminderDialog> createState() =>
      _ReminderDialogState();
}

class _ReminderDialogState extends ConsumerState<_ReminderDialog> {
  bool _loading = true;
  bool _sending = false;
  String _message = '';
  bool _isAiGenerated = false;

  @override
  void initState() {
    super.initState();
    _generateMessage();
  }

  Future<void> _generateMessage() async {
    final p = widget.prediction;
    final ai = ref.read(aiTextGeneratorProvider);

    final dueDateStr = DateFormat('d MMM yyyy').format(p.dueDate);
    final overdueText = p.isOverdue
        ? 'overdue by ${p.daysOverdue} day(s)'
        : 'due on $dueDateStr';
    final fallback =
        'Dear Parent,\n\nThis is a reminder that the fee payment of '
        '₹${p.amountDue.toStringAsFixed(0)} for ${p.studentName} '
        '(${p.className}) is $overdueText. '
        'Please arrange payment at the earliest to avoid inconvenience.\n\n'
        'Regards,\n[School Name]';

    final result = await ai.generateFeeReminderMessage(
      parentName: 'Parent',
      studentName: p.studentName,
      className: p.className,
      amountDue: p.amountDue,
      daysOverdue: p.daysOverdue,
      riskScore: p.riskScore,
      recommendedAction: p.recommendedAction,
      riskFactors: p.riskFactors,
      fallback: fallback,
    );

    if (mounted) {
      setState(() {
        _message = result.text;
        _isAiGenerated = result.isLLMGenerated;
        _loading = false;
      });
    }
  }

  Future<void> _sendReminder() async {
    setState(() => _sending = true);
    try {
      final repo = ref.read(feeRepositoryProvider);
      await repo.logReminderSent(
        invoiceId: widget.prediction.invoiceId,
        studentId: widget.prediction.studentId,
        messageText: _message,
        riskScore: widget.prediction.riskScore,
      );
      ref.invalidate(feeDefaultPredictionsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder logged successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WarmCopy.saveFailed('the reminder'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.message_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Fee Reminder Message')),
          if (_isAiGenerated && !_loading)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high,
                      size: 10, color: AppColors.accent),
                  SizedBox(width: 2),
                  Text('AI',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.accent)),
                ],
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For: ${widget.prediction.studentName} '
                    '(${widget.prediction.className})',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
      ),
      actions: _loading
          ? null
          : [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendReminder,
                icon: _sending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, size: 16),
                label: const Text('Log & Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
    );
  }
}

// =============================================================
// Small helpers — risk badge + filter chip
// =============================================================

class _RiskCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RiskCountBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: selected ? 0 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
