import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/campaign_status_badge.dart';
import '../widgets/channel_selector.dart';

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});

  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(campaignsNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campaignsAsync = ref.watch(campaignsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Draft'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCampaignList(theme, campaigns),
              _buildCampaignList(
                theme,
                campaigns
                    .where((c) => c.status == CampaignStatus.draft)
                    .toList(),
              ),
              _buildCampaignList(
                theme,
                campaigns
                    .where((c) => c.status == CampaignStatus.scheduled)
                    .toList(),
              ),
              _buildCampaignList(
                theme,
                campaigns
                    .where((c) =>
                        c.status == CampaignStatus.sent ||
                        c.status == CampaignStatus.sending)
                    .toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(campaignsNotifierProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/communication/campaigns/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCampaignList(
      ThemeData theme, List<CommunicationCampaign> campaigns) {
    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No campaigns found',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(campaignsNotifierProvider.notifier).load();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          return _CampaignListCard(
            campaign: campaigns[index],
            onTap: () => Navigator.pushNamed(
              context,
              '/communication/campaigns/${campaigns[index].id}',
            ),
            onSend: campaigns[index].status == CampaignStatus.draft
                ? () => _confirmSend(campaigns[index])
                : null,
            onCancel:
                campaigns[index].status == CampaignStatus.scheduled
                    ? () => _confirmCancel(campaigns[index])
                    : null,
            onDelete: campaigns[index].status == CampaignStatus.draft
                ? () => _confirmDelete(campaigns[index])
                : null,
          );
        },
      ),
    );
  }

  void _confirmSend(CommunicationCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Campaign'),
        content: Text(
            'Send "${campaign.name}" to ${campaign.targetType.label} now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(campaignsNotifierProvider.notifier)
                  .send(campaign.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Send Now',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(CommunicationCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Campaign'),
        content: Text('Cancel the scheduled campaign "${campaign.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(campaignsNotifierProvider.notifier)
                  .cancel(campaign.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel Campaign',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CommunicationCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Delete "${campaign.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(campaignsNotifierProvider.notifier)
                  .delete(campaign.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CampaignListCard extends StatelessWidget {
  final CommunicationCampaign campaign;
  final VoidCallback onTap;
  final VoidCallback? onSend;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const _CampaignListCard({
    required this.campaign,
    required this.onTap,
    this.onSend,
    this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM d, yyyy - h:mm a');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
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
          const SizedBox(height: 12),

          // Meta info
          Row(
            children: [
              Icon(Icons.group_outlined,
                  size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                campaign.targetType.label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              ChannelIndicatorRow(channels: campaign.channels),
              const Spacer(),
              if (campaign.createdAt != null)
                Text(
                  dateFormatter.format(campaign.createdAt!),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
            ],
          ),

          // Stats bar
          if (campaign.stats.total > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: campaign.stats.total > 0
                            ? campaign.stats.delivered / campaign.stats.total
                            : 0,
                        backgroundColor: AppColors.borderLight,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${campaign.stats.delivered}/${campaign.stats.total} delivered',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],

          // Scheduled time
          if (campaign.status == CampaignStatus.scheduled &&
              campaign.scheduledAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${dateFormatter.format(campaign.scheduledAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (onSend != null || onCancel != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onSend != null)
                  TextButton.icon(
                    onPressed: onSend,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
