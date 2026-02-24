import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/syllabus_provider.dart';

/// Bottom sheet for linking existing content (assignments, quizzes, resources)
/// to a topic.
class TopicLinkSheet extends ConsumerStatefulWidget {
  final String topicId;
  final VoidCallback? onLinked;

  const TopicLinkSheet({
    super.key,
    required this.topicId,
    this.onLinked,
  });

  @override
  ConsumerState<TopicLinkSheet> createState() => _TopicLinkSheetState();
}

class _TopicLinkSheetState extends ConsumerState<TopicLinkSheet> {
  String _selectedType = 'assignment';
  bool _isLinking = false;

  final _entityTypes = [
    ('assignment', 'Assignments', Icons.assignment),
    ('quiz', 'Quizzes', Icons.quiz),
    ('study_resource', 'Resources', Icons.library_books),
    ('question_bank', 'Questions', Icons.help_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            child: Row(
              children: [
                const Icon(Icons.link, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Link Content to Topic',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Type filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _entityTypes.map((type) {
                  final isSelected = _selectedType == type.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(type.$3,
                          size: 16,
                          color:
                              isSelected ? Colors.white : AppColors.primary),
                      label: Text(type.$2),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontSize: 13,
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedType = type.$1);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          // Content list
          Expanded(
            child: _buildContentList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(BuildContext context) {
    // Load content based on selected type from Supabase
    // This is a simplified version - in production you'd fetch from
    // the respective repositories
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _entityTypes
                .firstWhere((t) => t.$1 == _selectedType)
                .$3,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select ${_entityTypes.firstWhere((t) => t.$1 == _selectedType).$2} to link',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Content linking will search your existing\n$_selectedType items to link to this topic.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 24),
          if (_isLinking)
            const CircularProgressIndicator()
          else
            OutlinedButton.icon(
              onPressed: () => _linkManually(context),
              icon: const Icon(Icons.add_link),
              label: const Text('Enter Entity ID'),
            ),
        ],
      ),
    );
  }

  void _linkManually(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link by ID'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Entity ID (UUID)',
            hintText: 'Paste the ID here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              await _link(controller.text);
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _link(String entityId) async {
    setState(() => _isLinking = true);
    try {
      final repository = ref.read(syllabusRepositoryProvider);
      await repository.linkEntity(
        topicId: widget.topicId,
        entityType: _selectedType,
        entityId: entityId,
      );
      ref.invalidate(topicLinksProvider);
      widget.onLinked?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content linked successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }
}
