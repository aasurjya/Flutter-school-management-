import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/campaign_status_badge.dart';
import '../widgets/channel_selector.dart';

class CommunicationDashboardScreen extends ConsumerStatefulWidget {
  const CommunicationDashboardScreen({super.key});

  @override
  ConsumerState<CommunicationDashboardScreen> createState() =>
      _CommunicationDashboardScreenState();
}

class _CommunicationDashboardScreenState
    extends ConsumerState<CommunicationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(campaignsNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(communicationDashboardStatsProvider);
    final campaignsAsync = ref.watch(campaignsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Communication Log',
            onPressed: () => Navigator.pushNamed(context, '/communication/log'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communicationDashboardStatsProvider);
          await ref.read(campaignsNotifierProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats section
            statsAsync.when(
              data: (stats) => _buildStatsSection(theme, stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _buildErrorCard('Failed to load stats: $e'),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(theme),

            const SizedBox(height: 20),

            // Recent Campaigns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Campaigns',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/communication/campaigns'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            campaignsAsync.when(
              data: (campaigns) => _buildCampaignsList(theme, campaigns),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) =>
                  _buildErrorCard('Failed to load campaigns: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/communication/campaigns/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.campaign_outlined, color: Colors.white),
        label: const Text('New Campaign',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsSection(
      ThemeData theme, CommunicationDashboardStats stats) {
    return Column(
      children: [
        // Message count cards
        Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'Today',
                value: '${stats.sentToday}',
                icon: Icons.today_outlined,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'This Week',
                value: '${stats.sentThisWeek}',
                icon: Icons.date_range_outlined,
                iconColor: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'This Month',
                value: '${stats.sentThisMonth}',
                icon: Icons.calendar_month_outlined,
                iconColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'Delivery Rate',
                value: '${stats.deliveryRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outlined,
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Channel breakdown
        if (stats.channelBreakdown.isNotEmpty)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channel Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...stats.channelBreakdown.entries.map((entry) {
                  final total = stats.sentThisMonth;
                  final percentage =
                      total > 0 ? (entry.value / total * 100) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.borderLight,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${entry.value}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Active items summary
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                theme,
                '${stats.activeCampaigns}',
                'Active',
                Icons.campaign_outlined,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStat(
                theme,
                '${stats.scheduledCampaigns}',
                'Scheduled',
                Icons.schedule_outlined,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStat(
                theme,
                '${stats.activeRules}',
                'Auto Rules',
                Icons.auto_awesome_outlined,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      _QuickAction(
        icon: Icons.description_outlined,
        label: 'Templates',
        color: AppColors.primary,
        route: '/communication/templates',
      ),
      _QuickAction(
        icon: Icons.campaign_outlined,
        label: 'Campaigns',
        color: AppColors.secondary,
        route: '/communication/campaigns',
      ),
      _QuickAction(
        icon: Icons.auto_awesome_outlined,
        label: 'Auto Rules',
        color: AppColors.warning,
        route: '/communication/auto-rules',
      ),
      _QuickAction(
        icon: Icons.sms_outlined,
        label: 'SMS Settings',
        color: AppColors.info,
        route: '/communication/sms-settings',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                onTap: () => Navigator.pushNamed(context, action.route),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(action.icon, color: action.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCampaignsList(
      ThemeData theme, List<CommunicationCampaign> campaigns) {
    if (campaigns.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.campaign_outlined,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No campaigns yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first communication campaign to get started.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final recent = campaigns.take(5).toList();
    return Column(
      children: recent.map((campaign) {
        return _CampaignCard(campaign: campaign);
      }).toList(),
    );
  }

  Widget _buildErrorCard(String message) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.sms_outlined),
                  title: const Text('SMS Gateway Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/communication/sms-settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, '/communication/email-settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Auto Notification Rules'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/communication/auto-rules');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Communication Log'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/communication/log');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _CampaignCard extends StatelessWidget {
  final CommunicationCampaign campaign;

  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM d, h:mm a');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.pushNamed(
        context,
        '/communication/campaigns/${campaign.id}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CampaignStatusBadge(status: campaign.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campaign.body,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChannelIndicatorRow(channels: campaign.channels),
              const SizedBox(width: 8),
              Text(
                campaign.targetType.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              const Spacer(),
              Text(
                campaign.createdAt != null
                    ? dateFormatter.format(campaign.createdAt!)
                    : '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          if (campaign.stats.total > 0) ...[
            const SizedBox(height: 8),
            _buildMiniProgress(campaign.stats),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniProgress(CampaignStats stats) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: stats.total > 0
                    ? stats.delivered / stats.total
                    : 0,
                backgroundColor: AppColors.borderLight,
                color: AppColors.success,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${stats.delivered}/${stats.total}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
