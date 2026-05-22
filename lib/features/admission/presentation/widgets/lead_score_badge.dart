import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admission_lead_score_provider.dart';

/// Sprint 2.1 — color-coded 0-100 lead score chip with a tooltip explaining
/// the top reasons. Tapping opens a bottom-sheet breakdown.
class LeadScoreBadge extends ConsumerWidget {
  final String inquiryId;
  final bool compact;

  const LeadScoreBadge({
    super.key,
    required this.inquiryId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leadScoreProvider(inquiryId));
    return async.when(
      loading: () => _BadgeShell(
        label: '…',
        bg: Colors.grey.shade200,
        fg: Colors.grey.shade700,
        compact: compact,
        tooltip: 'Computing lead score…',
      ),
      error: (e, _) => _BadgeShell(
        label: '?',
        bg: Colors.grey.shade200,
        fg: Colors.grey.shade700,
        compact: compact,
        tooltip: 'Could not compute lead score',
      ),
      data: (score) {
        final (bg, fg, label) = _bandStyle(context, score.band);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showReasonsSheet(context, score),
          child: _BadgeShell(
            label: compact
                ? '${score.score}'
                : '${score.score} · $label',
            bg: bg,
            fg: fg,
            compact: compact,
            tooltip: score.reasons.isEmpty
                ? '$label lead — tap for details'
                : 'Top reasons:\n${_topReasons(score.reasons).join('\n')}',
          ),
        );
      },
    );
  }

  (Color, Color, String) _bandStyle(BuildContext context, String band) {
    switch (band) {
      case 'HOT':
        return (Colors.red.shade100, Colors.red.shade800, 'HOT');
      case 'WARM':
        return (Colors.orange.shade100, Colors.orange.shade800, 'WARM');
      default:
        return (Colors.blue.shade50, Colors.blue.shade800, 'COLD');
    }
  }

  List<String> _topReasons(List<String> reasons) =>
      reasons.take(3).toList(growable: false);

  void _showReasonsSheet(BuildContext context, LeadScore score) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Lead score: ${score.score}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _bandStyle(context, score.band).$1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    score.band,
                    style: TextStyle(
                      color: _bandStyle(context, score.band).$2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'How this lead was scored',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            if (score.reasons.isEmpty)
              Text(
                'No contributing factors — inquiry has minimal information yet.',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final r in score.reasons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, right: 8),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(r,
                            style: const TextStyle(
                                fontSize: 14, height: 1.43)),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _BadgeShell extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool compact;
  final String tooltip;

  const _BadgeShell({
    required this.label,
    required this.bg,
    required this.fg,
    required this.compact,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 11 : 12,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
