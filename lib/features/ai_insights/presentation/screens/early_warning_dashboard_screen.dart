import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/early_warning_provider.dart';
import '../widgets/alert_card.dart';

/// Main dashboard screen for browsing early warning alerts.
///
/// Provides a tabbed interface to filter alerts by severity (All, Critical,
/// Warning, Info). Each tab loads its data independently through Riverpod
/// providers. Tapping an alert navigates to its detail page.
class EarlyWarningDashboardScreen extends ConsumerStatefulWidget {
  const EarlyWarningDashboardScreen({super.key});

  @override
  ConsumerState<EarlyWarningDashboardScreen> createState() =>
      _EarlyWarningDashboardScreenState();
}

class _EarlyWarningDashboardScreenState
    extends ConsumerState<EarlyWarningDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    Tab(text: 'All'),
    Tab(text: 'Critical'),
    Tab(text: 'Warning'),
    Tab(text: 'Info'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Early Warning Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.error, AppColors.warning],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Alert Rules',
                onPressed: () => context.push('/ai/alert-rules'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: _tabs,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            // All alerts
            _AlertsTab(filter: AlertsFilter()),
            // Critical only
            _AlertsTab(
              filter: AlertsFilter(severity: 'critical'),
            ),
            // Warning only
            _AlertsTab(
              filter: AlertsFilter(severity: 'warning'),
            ),
            // Info only
            _AlertsTab(
              filter: AlertsFilter(severity: 'info'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tab showing a filtered list of alerts.
class _AlertsTab extends ConsumerWidget {
  final AlertsFilter filter;

  const _AlertsTab({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlerts = ref.watch(alertsProvider(filter));

    return asyncAlerts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load alerts',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No alerts',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Everything looks good!',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(alertsProvider(filter));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return AlertCard(
                alert: alert,
                onTap: () => context.push('/ai/alerts/${alert.id}'),
              );
            },
          ),
        );
      },
    );
  }
}
