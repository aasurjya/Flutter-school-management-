import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/syllabus_topic.dart';
import '../../../../features/academic/providers/academic_provider.dart';
import '../../providers/syllabus_provider.dart';

class TopicFormScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String classId;
  final String academicYearId;
  final String? parentTopicId;
  final String? topicId;
  final String? parentLevel;

  const TopicFormScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
    this.parentTopicId,
    this.topicId,
    this.parentLevel,
  });

  @override
  ConsumerState<TopicFormScreen> createState() => _TopicFormScreenState();
}

class _TopicFormScreenState extends ConsumerState<TopicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _periodsController = TextEditingController(text: '1');
  final _objectiveController = TextEditingController();
  final _tagController = TextEditingController();

  final List<String> _learningObjectives = [];
  final List<String> _tags = [];
  String? _selectedTermId;
  bool _isLoading = false;
  bool _isEditMode = false;
  SyllabusTopic? _existingTopic;

  TopicLevel get _level {
    if (_isEditMode && _existingTopic != null) {
      return _existingTopic!.level;
    }
    if (widget.parentLevel != null) {
      final parentLevel = TopicLevel.fromString(widget.parentLevel!);
      return parentLevel.childLevel ?? TopicLevel.topic;
    }
    if (widget.parentTopicId == null) {
      return TopicLevel.unit;
    }
    return TopicLevel.topic;
  }

  String get _appBarTitle {
    if (_isEditMode) return 'Edit Topic';
    return 'Add ${_level.label}';
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.topicId != null;
    if (_isEditMode) {
      _loadExistingTopic();
    }
  }

  Future<void> _loadExistingTopic() async {
    setState(() => _isLoading = true);
    try {
      final topic = await ref
          .read(syllabusRepositoryProvider)
          .getTopicById(widget.topicId!);
      if (topic != null && mounted) {
        setState(() {
          _existingTopic = topic;
          _titleController.text = topic.title;
          _descriptionController.text = topic.description ?? '';
          _periodsController.text = topic.estimatedPeriods.toString();
          _learningObjectives.addAll(topic.learningObjectives);
          _tags.addAll(topic.tags);
          _selectedTermId = topic.termId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load topic: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _periodsController.dispose();
    _objectiveController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final academicYearsAsync = ref.watch(academicYearsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _appBarTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.forestGradient,
                ),
              ),
            ),
            actions: [
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _saveTopic,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading && _isEditMode)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level indicator
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _levelColor(_level)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _level.icon,
                                  color: _levelColor(_level),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Creating: ${_level.label}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _levelColor(_level),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'Enter ${_level.label.toLowerCase()} title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            hintText: 'Describe this ${_level.label.toLowerCase()}...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 56),
                              child: Icon(Icons.description_outlined),
                            ),
                            alignLabelWithHint: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Learning Objectives
                        Text(
                          'Learning Objectives',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _objectiveController,
                                decoration: InputDecoration(
                                  hintText: 'Add an objective...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onSubmitted: (_) => _addObjective(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addObjective,
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_learningObjectives.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _learningObjectives
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Chip(
                                    label: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _learningObjectives
                                            .removeAt(entry.key);
                                      });
                                    },
                                    deleteIconColor: AppColors.error,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Estimated Periods
                        TextFormField(
                          controller: _periodsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Estimated Periods',
                            hintText: '1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.schedule),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Term Selector
                        academicYearsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (years) {
                            // Find the matching academic year to get its terms
                            return _buildTermDropdown(context);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        Text(
                          'Tags',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tagController,
                                decoration: InputDecoration(
                                  hintText: 'Add a tag...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _addTag(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addTag,
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onDeleted: () {
                                      setState(() => _tags.remove(tag));
                                    },
                                    deleteIconColor: AppColors.error,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermDropdown(BuildContext context) {
    // Since there is no dedicated terms provider, we use a simple dropdown
    // that can be populated with term data. For now, the term ID can be set
    // manually or left null.
    return DropdownButtonFormField<String>(
      initialValue: _selectedTermId,
      decoration: InputDecoration(
        labelText: 'Term (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.calendar_month),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: null,
          child: Text('No term selected'),
        ),
        // In a full implementation, terms would be loaded from a provider.
        // This placeholder allows the user to clear the selection.
      ],
      onChanged: (value) {
        setState(() => _selectedTermId = value);
      },
    );
  }

  void _addObjective() {
    final text = _objectiveController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _learningObjectives.add(text);
        _objectiveController.clear();
      });
    }
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  Future<void> _saveTopic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'subject_id': widget.subjectId,
        'class_id': widget.classId,
        'academic_year_id': widget.academicYearId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'learning_objectives': _learningObjectives,
        'estimated_periods':
            int.tryParse(_periodsController.text.trim()) ?? 1,
        'term_id': _selectedTermId,
        'tags': _tags,
        'level': _level.dbValue,
      };

      if (widget.parentTopicId != null) {
        data['parent_topic_id'] = widget.parentTopicId;
      }

      final repository = ref.read(syllabusRepositoryProvider);

      if (_isEditMode && widget.topicId != null) {
        await repository.updateTopic(widget.topicId!, data);
      } else {
        await repository.createTopic(data);
      }

      // Invalidate the tree provider to refresh
      ref.invalidate(syllabusTreeProvider(SyllabusFilter(
        subjectId: widget.subjectId,
        classId: widget.classId,
        academicYearId: widget.academicYearId,
      )));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Topic updated' : '${_level.label} created',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _levelColor(TopicLevel level) {
    switch (level) {
      case TopicLevel.unit:
        return AppColors.primary;
      case TopicLevel.chapter:
        return AppColors.info;
      case TopicLevel.topic:
        return AppColors.secondary;
      case TopicLevel.subtopic:
        return AppColors.textSecondaryLight;
    }
  }
}
