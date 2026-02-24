import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AIGenerationPreview extends StatelessWidget {
  final List<Map<String, dynamic>> tree;
  final void Function(int unitIdx, int? chapterIdx, int? topicIdx)?
      onRemoveNode;

  const AIGenerationPreview({
    super.key,
    required this.tree,
    this.onRemoveNode,
  });

  @override
  Widget build(BuildContext context) {
    if (tree.isEmpty) {
      return const Center(child: Text('No syllabus data generated.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tree.length,
      itemBuilder: (context, unitIdx) {
        final unit = tree[unitIdx];
        return _buildUnit(context, unit, unitIdx);
      },
    );
  }

  Widget _buildUnit(
      BuildContext context, Map<String, dynamic> unit, int unitIdx) {
    final chapters =
        List<Map<String, dynamic>>.from(unit['chapters'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Text(
          unit['title'] ?? 'Unit ${unitIdx + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${chapters.length} chapters  •  ${unit['estimated_periods'] ?? 0} periods',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRemoveNode != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onRemoveNode!(unitIdx, null, null),
                tooltip: 'Remove unit',
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          for (var ci = 0; ci < chapters.length; ci++)
            _buildChapter(context, chapters[ci], unitIdx, ci),
        ],
      ),
    );
  }

  Widget _buildChapter(BuildContext context, Map<String, dynamic> chapter,
      int unitIdx, int chapterIdx) {
    final topics =
        List<Map<String, dynamic>>.from(chapter['topics'] ?? []);

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.menu_book_outlined,
              color: AppColors.info, size: 16),
        ),
        title: Text(
          chapter['title'] ?? 'Chapter ${chapterIdx + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${topics.length} topics  •  ${chapter['estimated_periods'] ?? 0} periods',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRemoveNode != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () =>
                    onRemoveNode!(unitIdx, chapterIdx, null),
                tooltip: 'Remove chapter',
              ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
        children: [
          for (var ti = 0; ti < topics.length; ti++)
            _buildTopic(context, topics[ti], unitIdx, chapterIdx, ti),
        ],
      ),
    );
  }

  Widget _buildTopic(BuildContext context, Map<String, dynamic> topic,
      int unitIdx, int chapterIdx, int topicIdx) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 8),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.topic_outlined,
            color: AppColors.success, size: 14),
      ),
      title: Text(
        topic['title'] ?? 'Topic ${topicIdx + 1}',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${topic['estimated_periods'] ?? 1} period(s)',
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      ),
      trailing: onRemoveNode != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: () =>
                  onRemoveNode!(unitIdx, chapterIdx, topicIdx),
              tooltip: 'Remove topic',
            )
          : null,
    );
  }
}
