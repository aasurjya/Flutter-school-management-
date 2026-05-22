import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/ai_usage_dashboard_provider.dart';

/// Sprint 2.4 — super-admin AI cost & usage dashboard.
/// Reads from tenant_ai_usage via SECURITY DEFINER RPCs. Super-admin only.
class AiUsageDashboardScreen extends ConsumerStatefulWidget {
  const AiUsageDashboardScreen({super.key});

  @override
  ConsumerState<AiUsageDashboardScreen> createState() =>
      _AiUsageDashboardScreenState();
}

class _AiUsageDashboardScreenState
    extends ConsumerState<AiUsageDashboardScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(aiUsageOverviewProvider);
    final tenantRows = ref.watch(aiUsageByTenantProvider(_days));
    final featureRows = ref.watch(aiUsageByFeatureProvider(_days));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Usage'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Time window',
            initialValue: _days,
            onSelected: (v) => setState(() => _days = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                const Icon(Icons.date_range_rounded, size: 18),
                const SizedBox(width: 4),
                Text('${_days}d'),
              ]),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aiUsageOverviewProvider);
          ref.invalidate(aiUsageByTenantProvider(_days));
          ref.invalidate(aiUsageByFeatureProvider(_days));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            overview.when(
              loading: () => const _OverviewSkeleton(),
              error: (e, _) => _ErrorBox(message: 'Couldn\'t load overview: $e'),
              data: (o) => _OverviewCards(o: o),
            ),
            const SizedBox(height: 24),
            Text('Per-tenant spend (last ${_days}d)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            tenantRows.when(
              loading: () => const _ListSkeleton(),
              error: (e, _) => _ErrorBox(message: 'Tenant rollup failed: $e'),
              data: (rows) => _TenantTable(rows: rows),
            ),
            const SizedBox(height: 24),
            Text('Spend by feature (last ${_days}d)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            featureRows.when(
              loading: () => const _ListSkeleton(),
              error: (e, _) => _ErrorBox(message: 'Feature rollup failed: $e'),
              data: (rows) => _FeatureTable(rows: rows),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview cards
// ---------------------------------------------------------------------------

class _OverviewCards extends StatelessWidget {
  final AiUsageOverview o;
  const _OverviewCards({required this.o});

  @override
  Widget build(BuildContext context) {
    final delta = o.projectedMonthUsd - o.costLastMonthUsd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Spend this month',
                value: '\$${o.costMtdUsd.toStringAsFixed(2)}',
                hint:
                    'projected ~\$${o.projectedMonthUsd.toStringAsFixed(2)} by month end',
                hintColor: _projectionColor(context, delta),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Last month',
                value: '\$${o.costLastMonthUsd.toStringAsFixed(2)}',
                hint: delta == 0
                    ? 'flat'
                    : delta > 0
                        ? '+\$${delta.toStringAsFixed(2)} projected'
                        : '-\$${(-delta).toStringAsFixed(2)} projected',
                hintColor: _projectionColor(context, delta),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Calls',
                value: '${o.callsMtd}',
                hint: '${o.cacheHitsMtd} cache hits',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Blocked',
                value: '${o.blockedCallsMtd}',
                hint: 'quota / rate-limit / feature-off',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Tenants',
                value: '${o.tenantsWithActivity}',
                hint: 'active this month',
              ),
            ),
          ],
        ),
        if (o.mostExpensiveFeature != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top cost driver: ${o.mostExpensiveFeature} '
                  '(${o.mostExpensiveProvider ?? "—"})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Color _projectionColor(BuildContext context, double delta) {
    final scheme = Theme.of(context).colorScheme;
    if (delta > 0) return scheme.error;
    if (delta < 0) return Colors.green.shade800;
    return scheme.onSurfaceVariant;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color? hintColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(hint,
              style: TextStyle(
                  fontSize: 12,
                  color: hintColor ?? scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tenant table
// ---------------------------------------------------------------------------

class _TenantTable extends StatelessWidget {
  final List<AiUsageTenantRow> rows;
  const _TenantTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyTile(text: 'No usage in this window.');
    }
    return Column(
      children: [
        for (final r in rows) _TenantRow(row: r),
      ],
    );
  }
}

class _TenantRow extends StatelessWidget {
  final AiUsageTenantRow row;
  const _TenantRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = row.usedPctOfBudget;
    final barColor = pct >= 100
        ? scheme.error
        : pct >= 80
            ? Colors.orange.shade800
            : scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(
          '/super-admin/tenants/${row.tenantId}/ai-settings'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(row.tenantName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Text(
                  '\$${row.usedUsdPeriod.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Pill(text: row.tier ?? '—', color: barColor),
                const SizedBox(width: 8),
                Text(
                  '${row.callsPeriod} calls · ${row.blockedPeriod} blocked',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  row.budgetUsd > 0
                      ? '${pct.toStringAsFixed(1)}% of \$${row.budgetUsd.toStringAsFixed(0)}'
                      : 'no budget',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: row.budgetUsd > 0 ? (pct / 100).clamp(0.0, 1.0) : 0,
                color: barColor,
                minHeight: 4,
              ),
            ),
            const Divider(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature table
// ---------------------------------------------------------------------------

class _FeatureTable extends StatelessWidget {
  final List<AiUsageFeatureRow> rows;
  const _FeatureTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyTile(text: 'No feature usage in this window.');
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    r.featureType,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${r.calls} calls',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${r.costUsd.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bits
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget cell(double w, double h) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    return Column(
      children: [
        Row(children: [
          Expanded(child: cell(double.infinity, 80)),
          Expanded(child: cell(double.infinity, 80)),
        ]),
        Row(children: [
          Expanded(child: cell(double.infinity, 64)),
          Expanded(child: cell(double.infinity, 64)),
          Expanded(child: cell(double.infinity, 64)),
        ]),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer)),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final String text;
  const _EmptyTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
