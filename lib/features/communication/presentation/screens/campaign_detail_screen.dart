import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/campaign_status_badge.dart';
import '../widgets/channel_selector.dart';
import '../widgets/delivery_stats_card.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final campaignAsync = ref.watch(campaignByIdProvider(campaignId));
    final recipientsAsync = ref.watch(campaignRecipientsProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Details'),
        actions: [
          campaignAsync.whenOrNull(
                data: (campaign) {
                  if (campaign == null) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleAction(context, ref, action, campaign),
                    itemBuilder: (_) => [
                      if (campaign.status == CampaignStatus.draft)
                        const PopupMenuItem(
                          value: 'send',
                          child: ListTile(
                            leading: Icon(Icons.send, color: AppColors.primary),
                            title: Text('Send Now'),
                            dense: true,
                          ),
                        ),
                      if (campaign.status == CampaignStatus.sent &&
                          campaign.stats.failed > 0)
                        const PopupMenuItem(
                          value: 'retry',
                          child: ListTile(
                            leading: Icon(Icons.refresh,
                                color: AppColors.warning),
                            title: Text('Retry Failed'),
                            dense: true,
                          ),
                        ),
                      if (campaign.status == CampaignStatus.scheduled)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: ListTile(
                            leading:
                                Icon(Icons.cancel, color: AppColors.error),
                            title: Text('Cancel'),
                            dense: true,
                          ),
                        ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return const Center(child: Text('Campaign not found'));
          }
          return _buildContent(
            context,
            ref,
            theme,
            campaign,
            recipientsAsync,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    CommunicationCampaign campaign,
    AsyncValue<List<CampaignRecipient>> recipientsAsync,
  ) {
    final dateFormatter = DateFormat('MMM d, yyyy - h:mm a');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(campaignByIdProvider(campaignId));
        ref.invalidate(campaignRecipientsProvider(campaignId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CampaignStatusBadge(
                      status: campaign.status,
                      fontSize: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme,
                  Icons.group_outlined,
                  'Target',
                  campaign.targetType.label,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.send_outlined,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    const Text('Channels: '),
                    ChannelIndicatorRow(channels: campaign.channels),
                  ],
                ),
                const SizedBox(height: 8),
                if (campaign.createdAt != null)
                  _buildInfoRow(
                    theme,
                    Icons.calendar_today_outlined,
                    'Created',
                    dateFormatter.format(campaign.createdAt!),
                  ),
                if (campaign.sentAt != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    theme,
                    Icons.send_and_archive_outlined,
                    'Sent',
                    dateFormatter.format(campaign.sentAt!),
                  ),
                ],
                if (campaign.scheduledAt != null &&
                    campaign.status == CampaignStatus.scheduled) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    theme,
                    Icons.schedule_outlined,
                    'Scheduled',
                    dateFormatter.format(campaign.scheduledAt!),
                  ),
                ],
                if (campaign.createdByName != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    theme,
                    Icons.person_outline,
                    'Created by',
                    campaign.createdByName!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Message content
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (campaign.subject != null &&
                    campaign.subject!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Subject: ${campaign.subject}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    campaign.body,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Stats
          if (campaign.stats.total > 0) ...[
            DeliveryStatsCard(stats: campaign.stats),
            const SizedBox(height: 16),
          ],

          // Recipients
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recipients',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (campaign.stats.failed > 0)
                TextButton.icon(
                  onPressed: () => _retryFailed(context, ref, campaign),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Failed'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          recipientsAsync.when(
            data: (recipients) {
              if (recipients.isEmpty) {
                return GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          campaign.status == CampaignStatus.draft
                              ? 'Recipients will be resolved when campaign is sent'
                              : 'No recipients',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Status filter summary
                  _buildRecipientSummary(theme, recipients),
                  const SizedBox(height: 8),
                  // Recipient list
                  ...recipients.take(50).map((r) => _RecipientTile(
                        recipient: r,
                      )),
                  if (recipients.length > 50)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Showing 50 of ${recipients.length} recipients',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => GlassCard(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading recipients: $e'),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientSummary(
      ThemeData theme, List<CampaignRecipient> recipients) {
    final statusCounts = <RecipientStatus, int>{};
    for (final r in recipients) {
      statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statusCounts.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(entry.key).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.key.label}: ${entry.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(entry.key),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(RecipientStatus status) {
    switch (status) {
      case RecipientStatus.pending:
        return AppColors.textSecondaryLight;
      case RecipientStatus.sent:
        return AppColors.info;
      case RecipientStatus.delivered:
        return AppColors.success;
      case RecipientStatus.read:
        return AppColors.primary;
      case RecipientStatus.failed:
        return AppColors.error;
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action,
      CommunicationCampaign campaign) {
    switch (action) {
      case 'send':
        ref.read(campaignsNotifierProvider.notifier).send(campaign.id);
        ref.invalidate(campaignByIdProvider(campaignId));
        break;
      case 'retry':
        _retryFailed(context, ref, campaign);
        break;
      case 'cancel':
        ref.read(campaignsNotifierProvider.notifier).cancel(campaign.id);
        ref.invalidate(campaignByIdProvider(campaignId));
        break;
    }
  }

  void _retryFailed(BuildContext context, WidgetRef ref,
      CommunicationCampaign campaign) {
    ref.read(campaignsNotifierProvider.notifier).retryFailed(campaign.id);
    ref.invalidate(campaignRecipientsProvider(campaignId));
    ref.invalidate(campaignByIdProvider(campaignId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying failed recipients...'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final CampaignRecipient recipient;

  const _RecipientTile({required this.recipient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              (recipient.userName ?? recipient.userId)
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.userName ?? 'User',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (recipient.userEmail != null)
                  Text(
                    recipient.userEmail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            ChannelSelector.iconForChannel(recipient.channel),
            size: 16,
            color: ChannelSelector.colorForChannel(recipient.channel),
          ),
          const SizedBox(width: 8),
          RecipientStatusBadge(status: recipient.status),
        ],
      ),
    );
  }
}
