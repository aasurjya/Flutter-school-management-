import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/syllabus_ai_provider.dart';

class LessonPlanFormScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String? topicTitle;
  final String? sectionId;
  final String? planId;

  const LessonPlanFormScreen({
    super.key,
    required this.topicId,
    this.topicTitle,
    this.sectionId,
    this.planId,
  });

  @override
  ConsumerState<LessonPlanFormScreen> createState() =>
      _LessonPlanFormScreenState();
}

class _LessonPlanFormScreenState
    extends ConsumerState<LessonPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _warmUpController = TextEditingController();
  final _mainActivityController = TextEditingController();
  final _assessmentController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _materialsController = TextEditingController();
  final _differentiationController = TextEditingController();
  int _durationMinutes = 40;
  bool _isLoading = false;
  bool _isEdit = false;
  bool _isAiGenerated = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.topicTitle ?? '';
    if (widget.planId != null) {
      _isEdit = true;
      _loadExistingPlan();
    }
  }

  Future<void> _loadExistingPlan() async {
    final repository = ref.read(syllabusRepositoryProvider);
    final plan = await repository.getLessonPlanById(widget.planId!);
    if (plan != null && mounted) {
      setState(() {
        _titleController.text = plan.title;
        _objectiveController.text = plan.objective ?? '';
        _warmUpController.text = plan.warmUp ?? '';
        _mainActivityController.text = plan.mainActivity ?? '';
        _assessmentController.text = plan.assessmentActivity ?? '';
        _homeworkController.text = plan.homework ?? '';
        _materialsController.text = plan.materialsNeeded ?? '';
        _differentiationController.text = plan.differentiationNotes ?? '';
        _durationMinutes = plan.durationMinutes;
        _isAiGenerated = plan.isAiGenerated;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _objectiveController.dispose();
    _warmUpController.dispose();
    _mainActivityController.dispose();
    _assessmentController.dispose();
    _homeworkController.dispose();
    _materialsController.dispose();
    _differentiationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Lesson Plan' : 'Create Lesson Plan'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Generate button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _generateWithAI,
                  icon: const Icon(Icons.auto_awesome, color: AppColors.accent),
                  label: const Text('Generate with AI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Lesson plan title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Duration
              Row(
                children: [
                  const Text('Duration: ', style: TextStyle(fontSize: 14)),
                  DropdownButton<int>(
                    value: _durationMinutes,
                    items: [20, 30, 35, 40, 45, 60, 80, 90]
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d min'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _durationMinutes = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  _objectiveController, 'Objective', Icons.flag, 2),
              _buildTextField(
                  _warmUpController, 'Warm Up Activity', Icons.wb_sunny, 3),
              _buildTextField(_mainActivityController, 'Main Activity',
                  Icons.play_circle, 5),
              _buildTextField(_assessmentController, 'Assessment Activity',
                  Icons.assessment, 3),
              _buildTextField(
                  _homeworkController, 'Homework', Icons.home_work, 2),
              _buildTextField(_materialsController, 'Materials Needed',
                  Icons.inventory_2, 2),
              _buildTextField(_differentiationController,
                  'Differentiation Notes', Icons.accessibility_new, 3),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, int maxLines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Future<void> _generateWithAI() async {
    setState(() => _isLoading = true);

    // Get topic info for context
    final repository = ref.read(syllabusRepositoryProvider);
    final topic = await repository.getTopicById(widget.topicId);

    final aiNotifier = ref.read(lessonPlanAIProvider.notifier);
    final result = await aiNotifier.generateLessonPlan(
      topicTitle: widget.topicTitle ?? topic?.title ?? 'Topic',
      subjectName: topic?.subjectName ?? 'Subject',
      className: topic?.className ?? 'Class',
      durationMinutes: _durationMinutes,
      learningObjectives: topic?.learningObjectives,
    );

    if (result != null && mounted) {
      setState(() {
        _objectiveController.text = result['objective'] ?? '';
        _warmUpController.text = result['warm_up'] ?? '';
        _mainActivityController.text = result['main_activity'] ?? '';
        _assessmentController.text = result['assessment_activity'] ?? '';
        _homeworkController.text = result['homework'] ?? '';
        _materialsController.text = result['materials_needed'] ?? '';
        _differentiationController.text =
            result['differentiation_notes'] ?? '';
        _isAiGenerated = true;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI generation failed. Fill in manually.')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(syllabusRepositoryProvider);
      final data = {
        'topic_id': widget.topicId,
        'section_id': widget.sectionId,
        'title': _titleController.text,
        'objective': _objectiveController.text,
        'warm_up': _warmUpController.text,
        'main_activity': _mainActivityController.text,
        'assessment_activity': _assessmentController.text,
        'homework': _homeworkController.text,
        'materials_needed': _materialsController.text,
        'differentiation_notes': _differentiationController.text,
        'duration_minutes': _durationMinutes,
        'is_ai_generated': _isAiGenerated,
      };

      if (_isEdit && widget.planId != null) {
        await repository.updateLessonPlan(widget.planId!, data);
      } else {
        await repository.createLessonPlan(data);
      }

      ref.invalidate(lessonPlansProvider);
      ref.invalidate(lessonPlanDetailProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Lesson plan ${_isEdit ? 'updated' : 'created'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
