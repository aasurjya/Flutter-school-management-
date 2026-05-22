import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Truthful-labeling badge for AI-generated content.
///
/// Wraps any block of model output so users know they're reading an AI
/// summary, not a fact. Tap → bottom sheet with source disclosure.
///
/// Three flavors:
///   • [AiContentBadge.inline] — small chip beside a heading.
///   • [AiContentBadge.wrap]   — wraps a block of content with the chip on top.
///   • [AiContentBadge.tile]   — full-row banner above an AI block.
///
/// Always pair with a meaningful [sourceSummary] (one sentence on what data
/// drove the output) so the "verify" affordance has substance.
class AiContentBadge extends StatelessWidget {
  final String sourceSummary;
  final Widget? child;
  final AiBadgeStyle style;
  final bool isCached;

  const AiContentBadge.inline({
    super.key,
    required this.sourceSummary,
    this.isCached = false,
  })  : child = null,
        style = AiBadgeStyle.inline;

  const AiContentBadge.wrap({
    super.key,
    required this.sourceSummary,
    required Widget this.child,
    this.isCached = false,
  }) : style = AiBadgeStyle.wrap;

  const AiContentBadge.tile({
    super.key,
    required this.sourceSummary,
    this.isCached = false,
  })  : child = null,
        style = AiBadgeStyle.tile;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AiBadgeStyle.inline:
        return _Chip(
          isCached: isCached,
          onTap: () => _openSheet(context),
        );
      case AiBadgeStyle.tile:
        return _Tile(
          isCached: isCached,
          onTap: () => _openSheet(context),
        );
      case AiBadgeStyle.wrap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Chip(
              isCached: isCached,
              onTap: () => _openSheet(context),
            ),
            const SizedBox(height: 8),
            child!,
          ],
        );
    }
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DisclosureSheet(
        sourceSummary: sourceSummary,
        isCached: isCached,
      ),
    );
  }
}

enum AiBadgeStyle { inline, wrap, tile }

class _Chip extends StatelessWidget {
  final bool isCached;
  final VoidCallback onTap;

  const _Chip({required this.isCached, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.info.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCached
                  ? Icons.bolt_outlined
                  : Icons.auto_awesome_outlined,
              size: 12,
              color: AppColors.info,
            ),
            const SizedBox(width: 4),
            Text(
              isCached ? 'AI · cached' : 'AI summary',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.info_outline,
                size: 12, color: AppColors.info),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final bool isCached;
  final VoidCallback onTap;

  const _Tile({required this.isCached, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.info.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(
              isCached
                  ? Icons.bolt_outlined
                  : Icons.auto_awesome_outlined,
              size: 16,
              color: AppColors.info,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI-generated — verify before acting on it.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.info_outline,
                size: 14, color: AppColors.info),
          ],
        ),
      ),
    );
  }
}

class _DisclosureSheet extends StatelessWidget {
  final String sourceSummary;
  final bool isCached;

  const _DisclosureSheet({
    required this.sourceSummary,
    required this.isCached,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('About this AI summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 12),
            _Row(
              icon: Icons.source_outlined,
              title: 'Built from',
              body: sourceSummary,
            ),
            const SizedBox(height: 16),
            const _Row(
              icon: Icons.psychology_alt_outlined,
              title: 'How it works',
              body:
                  'A language model writes a short narrative from the data above. '
                  'It can make small mistakes, mis-state numbers, or miss context.',
            ),
            const SizedBox(height: 16),
            _Row(
              icon: isCached
                  ? Icons.bolt_outlined
                  : Icons.fact_check_outlined,
              title: 'Freshness',
              body: isCached
                  ? 'Reused from cache for speed and cost — the source numbers '
                      'may be a few minutes stale.'
                  : 'Generated just now from the current data.',
            ),
            const SizedBox(height: 16),
            const _Row(
              icon: Icons.shield_outlined,
              title: 'Use it as',
              body:
                  'A starting point — not a substitute for reviewing the '
                  'underlying student records yourself.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Row({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.grey600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 2),
              Text(body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
