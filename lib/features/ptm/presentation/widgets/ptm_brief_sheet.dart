import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_insights/providers/ptm_brief_provider.dart';

/// Sprint 1.1 — bottom sheet that surfaces an AI-generated 6-bullet brief
/// for a PTM appointment. Opens from "Generate brief" on the appointment card.
class PtmBriefSheet extends ConsumerWidget {
  final String studentId;
  final String tenantId;
  final String studentName;

  const PtmBriefSheet({
    super.key,
    required this.studentId,
    required this.tenantId,
    required this.studentName,
  });

  static Future<void> show(
    BuildContext context, {
    required String studentId,
    required String tenantId,
    required String studentName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: PtmBriefSheet(
            studentId: studentId,
            tenantId: tenantId,
            studentName: studentName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = PtmBriefArgs(studentId: studentId, tenantId: tenantId);
    final brief = ref.watch(ptmBriefProvider(args));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PTM Prep',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  Text(
                    studentName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Refresh stays in a fixed trailing slot. Copy slots in BEFORE
            // refresh when data is available — reserving the slot prevents
            // the refresh button from sliding around between states (spatial-
            // memory protection on a phone in landscape).
            brief.maybeWhen(
              data: (_) => _CopyButton(
                onPressed: () async {
                  final value = brief.value?.text ?? '';
                  if (value.isEmpty) return;
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Brief copied')),
                  );
                },
              ),
              orElse: () => const SizedBox(width: 48),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Regenerate',
              onPressed: () => ref.invalidate(ptmBriefProvider(args)),
            ),
          ],
        ),
        const Divider(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: brief.when(
            loading: () => Padding(
              key: const ValueKey('loading'),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Semantics(
                  label: 'Generating PTM brief, please wait',
                  liveRegion: true,
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
            error: (e, _) => _ErrorBox(
              key: const ValueKey('error'),
              onRetry: () => ref.invalidate(ptmBriefProvider(args)),
            ),
            data: (result) => _BriefBullets(
              key: const ValueKey('data'),
              text: result.text,
              cached: result.isFromCache,
              llmGenerated: result.isLLMGenerated,
            ),
          ),
        ),
      ],
    );
  }
}

class _BriefBullets extends StatelessWidget {
  final String text;
  final bool cached;
  final bool llmGenerated;

  const _BriefBullets({
    super.key,
    required this.text,
    required this.cached,
    required this.llmGenerated,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!llmGenerated)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI quota reached or unavailable — showing a generic template.',
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (cached)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Cached result · tap refresh to regenerate',
              style: TextStyle(fontSize: 12),
            ),
          ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.replaceFirst(RegExp(r'^[-•]\s*'), ''),
                    style: const TextStyle(fontSize: 14, height: 1.43),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Generated by AI · verify before sharing.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CopyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.copy_rounded),
        tooltip: 'Copy brief',
        onPressed: onPressed,
      );
}

class _ErrorBox extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBox({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Couldn\'t prepare the brief. Check your connection and tap retry.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
