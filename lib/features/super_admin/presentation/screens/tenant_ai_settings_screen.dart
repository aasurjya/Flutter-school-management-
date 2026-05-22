import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tenant_ai_settings_provider.dart';

/// Super-admin UI for managing AI governance per tenant:
///  - view current month usage vs budget
///  - upgrade/downgrade tier (free / standard / premium / tutor_addon)
///  - toggle individual features on/off
///  - set preferred provider per feature
///
/// Route: /super-admin/tenants/:tenantId/ai-settings
class TenantAiSettingsScreen extends ConsumerWidget {
  final String tenantId;

  const TenantAiSettingsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(tenantAiCreditsProvider(tenantId));
    final settings = ref.watch(tenantAiSettingsProvider(tenantId));

    return Scaffold(
      appBar: AppBar(title: const Text('AI Governance')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tenantAiCreditsProvider(tenantId));
          ref.invalidate(tenantAiSettingsProvider(tenantId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            credits.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Semantics(
                    label: 'Loading credits',
                    liveRegion: true,
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => _ErrorTile(
                message: 'Couldn\'t load credits — tap retry.',
                onRetry: () =>
                    ref.invalidate(tenantAiCreditsProvider(tenantId)),
              ),
              data: (c) => _CreditsCard(
                credits: c,
                tenantId: tenantId,
              ),
            ),
            const SizedBox(height: 32),
            Text('Per-feature toggles',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Features above the current tier still toggle, but the gateway '
              'will block them at runtime until the tenant is upgraded.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            settings.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Semantics(
                    label: 'Loading feature settings',
                    liveRegion: true,
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => _ErrorTile(
                message: 'Couldn\'t load feature settings — tap retry.',
                onRetry: () =>
                    ref.invalidate(tenantAiSettingsProvider(tenantId)),
              ),
              data: (rows) => _FeatureToggleList(
                tenantId: tenantId,
                existing: rows,
                currentTier: credits.valueOrNull?.tier ?? 'free',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Credits card
// ---------------------------------------------------------------------------

class _CreditsCard extends ConsumerWidget {
  final TenantAiCredits? credits;
  final String tenantId;

  const _CreditsCard({required this.credits, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (credits == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No credits row exists for this tenant.'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _seedFree(ref),
                child: const Text('Seed free tier'),
              ),
            ],
          ),
        ),
      );
    }

    final c = credits!;
    final pctText = c.budgetUsd > 0
        ? '${(c.usedPct * 100).toStringAsFixed(1)}%'
        : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(label: c.tier.toUpperCase()),
                const Spacer(),
                Text('Cycle: ${c.cycleStart.toIso8601String().substring(0, 10)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            _MetricRow(label: 'Budget',
                value: '\$${c.budgetUsd.toStringAsFixed(2)}'),
            _MetricRow(label: 'Used this cycle',
                value: '\$${c.usedUsd.toStringAsFixed(4)} ($pctText)'),
            _MetricRow(label: 'Calls',
                value: '${c.callsUsed} / ${c.callsLimit}'),
            _MetricRow(label: 'Soft cap',  value: '${c.softCapPct}%'),
            _MetricRow(label: 'Hard cap',  value: '${c.hardCapPct}%'),
            _MetricRow(label: 'Burst limit', value: '${c.burstPerMin} / min'),
            const SizedBox(height: 8),
            Semantics(
              label: c.budgetUsd > 0
                  ? 'Budget used ${(c.usedPct * 100).toStringAsFixed(0)} percent'
                  : 'No budget set for this tenant',
              child: LinearProgressIndicator(
                value: c.budgetUsd > 0 ? c.usedPct.clamp(0, 1) : 0,
                color: c.usedPct >= 1
                    ? Colors.red.shade700
                    : c.usedPct >= (c.softCapPct / 100)
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tier in const [
                  'free', 'standard', 'premium', 'tutor_addon'
                ])
                  // Active tier renders as FilledButton so the current
                  // state is unmistakable; inactive tiers are outlined.
                  if (c.tier == tier)
                    FilledButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(_prettyTierName(tier)),
                      onPressed: null,
                    )
                  else
                    OutlinedButton(
                      onPressed: () => _setTier(context, ref, tier),
                      child: Text('Set ${_prettyTierName(tier)}'),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedFree(WidgetRef ref) async {
    await ref.read(tenantAiSettingsRepositoryProvider).updateCredits(
      tenantId: tenantId,
      tier: 'free',
      budgetUsd: 0,
      callsLimit: 150,
    );
    ref.invalidate(tenantAiCreditsProvider(tenantId));
  }

  Future<void> _setTier(
    BuildContext context,
    WidgetRef ref,
    String tier,
  ) async {
    // Tier → default budget mapping. Matches the plan's pricing tiers.
    const budgets = {
      'free':        (budget: 0.0,   calls: 150),
      'standard':    (budget: 15.0,  calls: 8000),
      'premium':     (budget: 60.0,  calls: 30000),
      'tutor_addon': (budget: 100.0, calls: 50000),
    };
    final cfg = budgets[tier]!;

    final isDowngrade = _isDowngradeFrom(credits?.tier, tier);
    final confirmed = await _confirmTierChange(
      context,
      currentTier: credits?.tier ?? '—',
      newTier: tier,
      newBudget: cfg.budget,
      isDowngrade: isDowngrade,
    );
    if (confirmed != true) return;

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errColor = Theme.of(context).colorScheme.error;

    // Show an immediate "Changing tier…" SnackBar so the super-admin gets
    // feedback BEFORE the Supabase round-trip completes — fixes the 1-3s
    // "did anything happen?" gap reported in interaction review.
    final pending = messenger?.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Changing tier…'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      await ref.read(tenantAiSettingsRepositoryProvider).updateCredits(
        tenantId: tenantId,
        tier: tier,
        budgetUsd: cfg.budget,
        callsLimit: cfg.calls,
      );
      ref.invalidate(tenantAiCreditsProvider(tenantId));
      pending?.close();
      messenger?.showSnackBar(
        SnackBar(content: Text('Tier changed to ${_prettyTierName(tier)}')),
      );
    } catch (e) {
      pending?.close();
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Couldn\'t change tier: $e'),
          backgroundColor: errColor,
        ),
      );
    }
  }

  String _prettyTierName(String tier) {
    switch (tier) {
      case 'free':
        return 'Free';
      case 'standard':
        return 'Standard';
      case 'premium':
        return 'Premium';
      case 'tutor_addon':
        return 'Tutor add-on';
      default:
        return tier;
    }
  }

  bool _isDowngradeFrom(String? from, String to) {
    const rank = {'free': 0, 'standard': 1, 'premium': 2, 'tutor_addon': 3};
    final f = rank[from ?? ''] ?? -1;
    final t = rank[to] ?? -1;
    return f > t;
  }

  Future<bool?> _confirmTierChange(
    BuildContext context, {
    required String currentTier,
    required String newTier,
    required double newBudget,
    required bool isDowngrade,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDowngrade ? 'Downgrade tier?' : 'Change tier?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: $currentTier'),
            Text('New: $newTier  ·  budget \$${newBudget.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            if (isDowngrade)
              Text(
                'Downgrading will reduce this tenant\'s monthly AI budget '
                'and call cap immediately. Live AI features may stop working.',
                style: TextStyle(color: scheme.error),
              )
            else
              const Text(
                'This will reset the monthly budget and call cap for this '
                'tenant to the new tier\'s defaults.',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDowngrade ? scheme.error : scheme.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isDowngrade ? 'Downgrade' : 'Change'),
          ),
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Feature toggle list
// ---------------------------------------------------------------------------

class _FeatureToggleList extends ConsumerWidget {
  final String tenantId;
  final List<TenantAiFeatureSetting> existing;
  final String currentTier;

  const _FeatureToggleList({
    required this.tenantId,
    required this.existing,
    required this.currentTier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byKey = {for (final s in existing) s.featureType: s};

    return Column(
      children: [
        for (final entry in kAiFeatureCatalogue.entries)
          _FeatureToggleRow(
            tenantId: tenantId,
            featureType: entry.key,
            label: entry.value,
            current: byKey[entry.key],
            requiredTier: kFeatureMinTier[entry.key] ?? 'free',
            currentTier: currentTier,
          ),
      ],
    );
  }
}

/// Minimum tier required for each feature. Used to surface a lock hint when
/// the tenant's tier is below this. Keep in sync with the gateway-side tier
/// gating logic.
const Map<String, String> kFeatureMinTier = {
  // free tier features: none enabled by default — every LLM call still costs
  // money; super-admin must explicitly raise the tier to unlock budget.
  // Standard tier: all single-shot LLM features sized under ~400 tokens out.
  'parent_digest':        'standard',
  'report_card_remark':   'standard',
  'parent_message':       'standard',
  'lesson_plan_json':     'standard',
  'syllabus_structure':   'standard',
  'risk_explanation':     'standard',
  'fee_reminder':         'standard',
  'attendance_narrative': 'standard',
  'early_warning_alert':  'standard',
  'class_performance':    'standard',
  'study_recommendation': 'standard',
  'trend_narrative':      'standard',
  'school_health':        'standard',
  'platform_health':      'standard',
  'ptm_brief':            'standard',
  // Premium-only: structured-JSON heavy outputs + agentic features.
  'question_paper_json': 'premium',
  'admissions_chatbot':  'premium',
  'principal_digest':    'premium',
  // Add-on metered: multi-turn tutor.
  'ai_tutor':            'tutor_addon',
};

const Map<String, int> _kTierRank = {
  'free': 0,
  'standard': 1,
  'premium': 2,
  'tutor_addon': 3,
};

bool _isTierBelow(String current, String required) {
  return (_kTierRank[current] ?? 0) < (_kTierRank[required] ?? 0);
}

class _FeatureToggleRow extends ConsumerStatefulWidget {
  final String tenantId;
  final String featureType;
  final String label;
  final TenantAiFeatureSetting? current;
  final String requiredTier;
  final String currentTier;

  const _FeatureToggleRow({
    required this.tenantId,
    required this.featureType,
    required this.label,
    required this.current,
    required this.requiredTier,
    required this.currentTier,
  });

  @override
  ConsumerState<_FeatureToggleRow> createState() => _FeatureToggleRowState();
}

class _FeatureToggleRowState extends ConsumerState<_FeatureToggleRow> {
  late bool _enabled;
  late String _provider;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.current?.enabled ?? true;
    _provider = widget.current?.preferredProvider ?? 'auto';
  }

  Future<void> _save({
    required bool prevEnabled,
    required String prevProvider,
  }) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errColor = Theme.of(context).colorScheme.error;
    try {
      await ref.read(tenantAiSettingsRepositoryProvider).upsertSetting(
        tenantId: widget.tenantId,
        featureType: widget.featureType,
        enabled: _enabled,
        preferredProvider: _provider,
        maxTokensOut: widget.current?.maxTokensOut ?? 1024,
        maxCostPerCallUsd: widget.current?.maxCostPerCallUsd ?? 0.05,
        cacheTtlSeconds: widget.current?.cacheTtlSeconds ?? 3600,
      );
      ref.invalidate(tenantAiSettingsProvider(widget.tenantId));
      messenger?.showSnackBar(
        SnackBar(
          content: Text('${widget.label}: saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Revert the optimistic UI state so the switch reflects DB truth.
      if (mounted) {
        setState(() {
          _enabled = prevEnabled;
          _provider = prevProvider;
        });
      }
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Couldn\'t save ${widget.label}: $e'),
          backgroundColor: errColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locked = _isTierBelow(widget.currentTier, widget.requiredTier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.label,
                            style:
                                Theme.of(context).textTheme.titleSmall),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        // warning_amber instead of lock — lock would
                        // wrongly imply the toggle is disabled. Amber
                        // says "caution: gateway will block this until
                        // tier is upgraded."
                        Tooltip(
                          message:
                              'Toggle permitted, but the gateway will block this feature until the tenant is on ${_prettyTier(widget.requiredTier)}+',
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Requires ${_prettyTier(widget.requiredTier)}+',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // The raw featureType key is shown for super-admin
                  // debugging context. Monospace + "key:" prefix signals it
                  // is read-only internal metadata, not an editable field.
                  Text(
                    'key: ${widget.featureType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Provider preference for ${widget.label}',
              // Labels intentionally vendor-agnostic. The gateway maps
              // these to a specific model in `routing matrix`; if we
              // swap DeepSeek for another model the label stays correct.
              child: DropdownButton<String>(
                value: _provider,
                items: const [
                  DropdownMenuItem(
                      value: 'auto',
                      child: Text('Auto (recommended)')),
                  DropdownMenuItem(
                      value: 'cheap',
                      child: Text('Fast (lower cost)')),
                  DropdownMenuItem(
                      value: 'quality',
                      child: Text('Accurate (higher quality)')),
                ],
                onChanged: _saving || !_enabled
                    ? null
                    : (v) {
                        if (v == null) return;
                        final prevProvider = _provider;
                        setState(() => _provider = v);
                        _save(
                            prevEnabled: _enabled,
                            prevProvider: prevProvider);
                      },
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: '${widget.label} enabled',
              toggled: _enabled,
              child: Switch(
                value: _enabled,
                onChanged: _saving
                    ? null
                    : (v) {
                        final prevEnabled = _enabled;
                        setState(() => _enabled = v);
                        _save(
                            prevEnabled: prevEnabled,
                            prevProvider: _provider);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyTier(String t) {
    switch (t) {
      case 'standard':
        return 'Standard';
      case 'premium':
        return 'Premium';
      case 'tutor_addon':
        return 'Tutor add-on';
      default:
        return t;
    }
  }
}

// ---------------------------------------------------------------------------
// Small UI bits
// ---------------------------------------------------------------------------

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorTile({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
