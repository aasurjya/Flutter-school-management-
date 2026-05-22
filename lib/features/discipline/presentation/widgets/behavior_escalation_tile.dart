import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/glass_card.dart';
import '../../../ai_insights/providers/behavior_escalation_provider.dart';
import '../../../auth/providers/auth_provider.dart';

/// Sprint 1.4 — counselor-facing tile that surfaces the top 5 students
/// whose discipline incident rate has accelerated in the last 14 days.
///
/// Pure SQL heuristic (no LLM). Tap a student row to open their profile.
class BehaviorEscalationTile extends ConsumerWidget {
  const BehaviorEscalationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    if (tenantId == null) return const SizedBox.shrink();

    final summary = ref.watch(behaviorEscalationSummaryProvider(tenantId));
    final filter = BehaviorEscalationFilter(tenantId: tenantId, limit: 5);
    final rows = ref.watch(behaviorEscalationProvider(filter));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(summary: summary),
          const SizedBox(height: 12),
          rows.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Semantics(
                  label: 'Loading escalating students',
                  liveRegion: true,
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
            error: (e, _) => _ErrorRow(message: 'Unable to load: $e'),
            data: (list) {
              if (list.isEmpty) return const _EmptyState();
              return Column(
                children: [
                  for (final row in list)
                    _EscalationRow(
                      row: row,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(
                          '/discipline/students/${row.studentId}',
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  final AsyncValue<BehaviorEscalationSummary> summary;
  const _Header({required this.summary});

  void _showScoreLegend(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escalation score'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score = (weighted incidents in the last 14 days) − '
              '(weighted incidents in the prior 14 days).',
              style: TextStyle(height: 1.4),
            ),
            SizedBox(height: 12),
            Text('Severity weights:'),
            Text('  Minor = 1  ·  Moderate = 2  ·  Major = 4  ·  Critical = 8'),
            SizedBox(height: 12),
            Text('Bands:'),
            Text('  LOW = 1-2   ·   MED = 3-5   ·   HIGH = 6+'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Tooltip(
          message: 'Students whose incident rate is accelerating',
          child: Icon(Icons.trending_up_rounded, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escalating students (14 days)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 2),
              summary.maybeWhen(
                data: (s) {
                  final delta = s.trendDelta;
                  final arrow = delta > 0 ? '▲' : (delta < 0 ? '▼' : '–');
                  final scheme = Theme.of(context).colorScheme;
                  // Only the delta token is colored; the factual counts use
                  // a neutral on-surface variant to avoid implying alarm at
                  // a baseline-stable school.
                  final deltaColor = delta > 0
                      ? scheme.error
                      : (delta < 0 ? Colors.green.shade800 : scheme.onSurfaceVariant);
                  return RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                            text:
                                '${s.totalRecentIncidents} incidents · ${s.recentMajorOrCritical} major/critical · '),
                        TextSpan(
                          text: '$arrow ${delta.abs()} vs prior 14d',
                          style: TextStyle(
                              color: deltaColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const Text(
                  ' ',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Info icon at the trailing edge — secondary affordance for the
        // section. Was previously between the title and trending icon, where
        // it looked like it annotated the trending arrow.
        IconButton(
          icon: const Icon(Icons.info_outline, size: 18),
          tooltip: 'How is this scored?',
          onPressed: () => _showScoreLegend(context),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Row + states
// ---------------------------------------------------------------------------

class _EscalationRow extends StatelessWidget {
  final BehaviorEscalationRow row;
  final VoidCallback onTap;

  const _EscalationRow({required this.row, required this.onTap});

  /// Pretty-print the raw enum value the DB stores (e.g. "minor" → "Minor").
  String _prettyLastSeverity(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = row.escalationScore >= 6
        ? scheme.error
        : row.escalationScore >= 3
            ? Colors.orange.shade800
            : scheme.primary;

    // Critical → text label so color-blind counselors can still triage.
    final severityLabel = row.escalationScore >= 6
        ? 'HIGH'
        : row.escalationScore >= 3
            ? 'MED'
            : 'LOW';

    return Semantics(
      button: true,
      label:
          '${row.fullName}, $severityLabel severity, score ${row.escalationScore}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                // Severity badge — text + dot so color is supplementary, not load-bearing
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        severityLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${row.recentIncidentCount} recent · '
                        '${row.priorIncidentCount} prior · '
                        'last: ${_prettyLastSeverity(row.mostSevereRecent)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Escalation chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${row.escalationScore}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.check_circle_outline,
                color: Colors.green.shade800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No escalating students this fortnight.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends ConsumerWidget {
  final String message;
  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Couldn\'t load escalating students — pull to refresh or tap retry.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            onPressed: () {
              // Invalidate every variant of the family — cheap belt-and-braces.
              ref.invalidate(behaviorEscalationProvider);
              ref.invalidate(behaviorEscalationSummaryProvider);
            },
          ),
        ],
      ),
    );
  }
}
