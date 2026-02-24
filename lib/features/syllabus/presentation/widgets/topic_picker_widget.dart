import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/syllabus_topic.dart';
import '../../providers/syllabus_provider.dart';

/// Reusable widget: shows a chip with topic title.
/// Tap opens a bottom sheet with searchable topic list.
class TopicPickerWidget extends ConsumerStatefulWidget {
  final String? subjectId;
  final String? classId;
  final String? selectedTopicId;
  final String? selectedTopicTitle;
  final ValueChanged<SyllabusTopic?> onTopicSelected;

  const TopicPickerWidget({
    super.key,
    this.subjectId,
    this.classId,
    this.selectedTopicId,
    this.selectedTopicTitle,
    required this.onTopicSelected,
  });

  @override
  ConsumerState<TopicPickerWidget> createState() => _TopicPickerWidgetState();
}

class _TopicPickerWidgetState extends ConsumerState<TopicPickerWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.topic_outlined,
              size: 18,
              color: widget.selectedTopicId != null
                  ? AppColors.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.selectedTopicTitle ?? 'Link to topic (optional)',
                style: TextStyle(
                  color: widget.selectedTopicId != null
                      ? null
                      : Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.selectedTopicId != null)
              GestureDetector(
                onTap: () => widget.onTopicSelected(null),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              )
            else
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TopicSearchSheet(
        subjectId: widget.subjectId,
        classId: widget.classId,
        onSelected: (topic) {
          widget.onTopicSelected(topic);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _TopicSearchSheet extends ConsumerStatefulWidget {
  final String? subjectId;
  final String? classId;
  final ValueChanged<SyllabusTopic> onSelected;

  const _TopicSearchSheet({
    this.subjectId,
    this.classId,
    required this.onSelected,
  });

  @override
  ConsumerState<_TopicSearchSheet> createState() => _TopicSearchSheetState();
}

class _TopicSearchSheetState extends ConsumerState<_TopicSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _query = value);
              },
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? const Center(
                    child: Text(
                      'Type at least 2 characters to search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final resultsAsync = ref.watch(topicSearchProvider(_query));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (topics) {
        if (topics.isEmpty) {
          return const Center(
            child: Text('No topics found', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return ListTile(
              leading: Icon(topic.level.icon, color: AppColors.primary),
              title: Text(topic.title),
              subtitle: Text(
                '${topic.level.label} • ${topic.subjectName ?? ''} ${topic.className ?? ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () => widget.onSelected(topic),
            );
          },
        );
      },
    );
  }
}
