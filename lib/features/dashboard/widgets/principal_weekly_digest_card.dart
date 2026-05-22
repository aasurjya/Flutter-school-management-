import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../ai_insights/providers/principal_digest_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../id_card/providers/id_card_provider.dart';

/// Sprint 1.2 — pinned-to-top weekly executive briefing for tenant_admin /
/// principal. Pulls KPIs + AI narrative from [principalDigestProvider].
class PrincipalWeeklyDigestCard extends ConsumerWidget {
  const PrincipalWeeklyDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(currentTenantIdProvider);
    final user = ref.watch(currentUserProvider);
    if (tenantId == null) return const SizedBox.shrink();
    if (user == null) return const SizedBox.shrink();

    // Only show to roles with the admin equivalence — same gate as the RLS
    // policy uses server-side. Cheap belt-and-braces UX guard.
    final role = user.primaryRole;
    if (role != 'tenant_admin' && role != 'principal') {
      return const SizedBox.shrink();
    }

    final schoolName =
        ref.watch(currentTenantProvider).valueOrNull?.name ?? 'your school';
    final args = PrincipalDigestArgs(
      tenantId: tenantId,
      schoolName: schoolName,
    );
    final async = ref.watch(principalDigestProvider(args));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            isLoading: async.isLoading,
            onRefresh: () => ref.invalidate(principalDigestProvider(args)),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: async.when(
              loading: () => const _DigestSkeleton(key: ValueKey('loading')),
              error: (e, _) => _DigestError(
                key: const ValueKey('error'),
                onRetry: () =>
                    ref.invalidate(principalDigestProvider(args)),
              ),
              data: (digest) => _DigestBody(
                key: const ValueKey('data'),
                digest: digest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton — holds layout so the dashboard doesn't jump.
// ---------------------------------------------------------------------------

class _DigestSkeleton extends StatelessWidget {
  const _DigestSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmerColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget block(double w, double h) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(right: 8, top: 4),
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    return Semantics(
      label: 'Loading weekly digest',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [block(72, 56), block(72, 56), block(72, 56)]),
            const SizedBox(height: 12),
            block(double.infinity, 16),
            const SizedBox(height: 8),
            block(double.infinity, 16),
            const SizedBox(height: 8),
            block(220, 16),
          ],
        ),
      ),
    );
  }
}

class _DigestError extends StatelessWidget {
  final VoidCallback onRetry;
  const _DigestError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Couldn\'t load this week\'s digest. Check connection and retry.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isLoading;
  const _Header({required this.onRefresh, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Your week in 30 seconds',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        // Touch target is the full 48dp default — no compact density.
        // Disabled while loading to prevent double-tap re-invalidations.
        Semantics(
          label: 'Regenerate digest',
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Regenerate',
            onPressed: isLoading ? null : onRefresh,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _DigestBody extends StatelessWidget {
  final PrincipalDigest digest;
  const _DigestBody({super.key, required this.digest});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI strip
        if (_hasAnyKpi(digest))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (digest.attendancePct != null)
                    _Kpi(
                      label: 'Attendance',
                      value: '${digest.attendancePct}%',
                      delta: digest.attendanceDeltaPct,
                      deltaSuffix: 'pp',
                    ),
                  if (digest.feePct != null)
                    _Kpi(
                      label: 'Fees',
                      value: '${digest.feePct}%',
                      delta: digest.feeDeltaPct,
                      deltaSuffix: 'pp',
                    ),
                  if (digest.incidentsCount != null)
                    _Kpi(
                      label: 'Incidents',
                      value: '${digest.incidentsCount}',
                      delta: digest.incidentsDelta,
                      invertColor: true,
                    ),
                  if (digest.escalatingCount != null)
                    _Kpi(
                      label: 'Escalating',
                      value: '${digest.escalatingCount}',
                      delta: null,
                      invertColor: true,
                    ),
                  if (digest.atRiskCount != null)
                    _Kpi(
                      label: 'At-risk',
                      value: '${digest.atRiskCount}',
                      delta: null,
                      invertColor: true,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        // AI provenance label — small but clear; principal needs to know
        // the narrative is machine-generated, not a human report.
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.auto_awesome_rounded,
                  size: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Text(
              'AI summary',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Narrative
        Text(
          digest.narrative,
          style: const TextStyle(fontSize: 14, height: 1.43),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (digest.fromCache) ...[
              ExcludeSemantics(
                child: Icon(Icons.cached_outlined,
                    size: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Text(
                'cached',
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
            ],
            if (!digest.aiGenerated)
              Text(
                'AI unavailable — fallback shown',
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            const Spacer(),
            Text(
              'Week of ${_formatWeekOf(digest.weekStart)}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _hasAnyKpi(PrincipalDigest d) =>
      d.attendancePct != null ||
      d.feePct != null ||
      d.incidentsCount != null ||
      d.escalatingCount != null ||
      d.atRiskCount != null;

  String _formatWeekOf(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// KPI chip
// ---------------------------------------------------------------------------

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final int? delta;
  final String deltaSuffix;
  final bool invertColor;

  const _Kpi({
    required this.label,
    required this.value,
    required this.delta,
    this.deltaSuffix = '',
    this.invertColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUpGood = !invertColor;
    Color? deltaColor;
    String? deltaText;
    String? deltaSemantic;
    if (delta != null && delta != 0) {
      final goingUp = delta! > 0;
      final positive = goingUp == isUpGood;
      // Colors.green is too light for AA contrast on white surfaces — shade800.
      deltaColor = positive ? Colors.green.shade800 : scheme.error;
      deltaText = '${goingUp ? '▲' : '▼'} ${delta!.abs()}$deltaSuffix';
      deltaSemantic = goingUp ? 'up by' : 'down by';
    }

    return Semantics(
      label: deltaText != null
          ? '$label: $value, $deltaSemantic ${delta!.abs()}'
          : '$label: $value',
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            if (deltaText != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(deltaText,
                      style: TextStyle(
                          fontSize: 12,
                          color: deltaColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
