import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../providers/notice_board_provider.dart';

class NoticeDetailScreen extends ConsumerWidget {
  final String noticeId;

  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticeAsync = ref.watch(noticeByIdProvider(noticeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Notice')),
      body: noticeAsync.when(
        data: (notice) {
          if (notice == null) {
            return const Center(child: Text('Notice not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        notice.category.label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        notice.audience.label,
                        style: const TextStyle(
                          color: AppColors.grey700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (notice.isPinned) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.push_pin,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notice.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (notice.authorName != null)
                  Text(
                    'Posted by ${notice.authorName} · ${notice.timeAgo}',
                    style: const TextStyle(
                        color: AppColors.grey500, fontSize: 13),
                  ),
                if (notice.expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires: ${notice.expiresAt!.toLocal().toString().split('.')[0]}',
                    style: const TextStyle(
                        color: AppColors.warning, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  notice.body,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                if (notice.attachmentUrl != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(notice.attachmentName ?? 'Attachment'),
                    subtitle: const Text('Tap to open'),
                    tileColor: AppColors.grey50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Opening ${notice.attachmentName ?? 'attachment'}...'),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
    );
  }
}
