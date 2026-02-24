import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/report_commentary_provider.dart';
import '../../../../data/models/report_commentary.dart';

class GenerateRemarksScreen extends ConsumerStatefulWidget {
  const GenerateRemarksScreen({super.key});

  @override
  ConsumerState<GenerateRemarksScreen> createState() =>
      _GenerateRemarksScreenState();
}

class _GenerateRemarksScreenState extends ConsumerState<GenerateRemarksScreen> {
  String? _selectedSectionId;
  String? _selectedExamId;
  bool _isGenerating = false;
  double _generationProgress = 0.0;

  // Mock data for section and exam dropdowns
  final _sections = const [
    {'id': 'sec-1', 'name': 'Class 10 - A'},
    {'id': 'sec-2', 'name': 'Class 10 - B'},
    {'id': 'sec-3', 'name': 'Class 9 - A'},
  ];

  final _exams = const [
    {'id': 'exam-1', 'name': 'Mid-Term Exam 2026'},
    {'id': 'exam-2', 'name': 'Unit Test 3'},
    {'id': 'exam-3', 'name': 'Final Exam 2025'},
  ];

  Future<void> _generateRemarks() async {
    if (_selectedSectionId == null || _selectedExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a section and an exam.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
    });

    final filter = SectionExamFilter(
      sectionId: _selectedSectionId!,
      examId: _selectedExamId!,
    );

    // Simulate progress while the provider runs
    final progressTimer = Stream.periodic(
      const Duration(milliseconds: 200),
      (i) => (i + 1) * 0.15,
    ).takeWhile((v) => v < 0.9).listen((progress) {
      if (mounted) {
        setState(() => _generationProgress = progress);
      }
    });

    try {
      final remarks =
          await ref.read(generateSectionRemarksProvider(filter).future);
      ref.read(remarksNotifierProvider.notifier).setRemarks(remarks);

      if (mounted) {
        setState(() => _generationProgress = 1.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate remarks: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      progressTimer.cancel();
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showEditDialog(ReportCommentary remark) {
    final controller = TextEditingController(text: remark.remark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Remark - ${remark.studentName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter report remark...',
            filled: true,
            fillColor: AppColors.inputFillLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref
                    .read(remarksNotifierProvider.notifier)
                    .updateRemark(remark.studentId, text);
              }
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _approveAll() {
    ref.read(remarksNotifierProvider.notifier).approveAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All remarks approved.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _saveAllApproved() {
    final approved = ref.read(remarksNotifierProvider.notifier).approved;
    if (approved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No approved remarks to save.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // In production, persist to Supabase here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${approved.length} approved remark(s) saved successfully.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remarks = ref.watch(remarksNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---- App Bar ----
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Report Remarks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
          ),

          // ---- Body ----
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section & Exam selectors
                _buildFiltersCard(theme, isDark),
                const SizedBox(height: 16),

                // Generate button
                _buildGenerateButton(),
                const SizedBox(height: 16),

                // Progress indicator
                if (_isGenerating) ...[
                  _buildProgressCard(theme),
                  const SizedBox(height: 16),
                ],

                // Remarks header with actions
                if (remarks.isNotEmpty) ...[
                  _buildRemarksHeader(theme, isDark, remarks),
                  const SizedBox(height: 12),
                ],

                // Remark cards
                ...remarks.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRemarkCard(
                          theme,
                          isDark,
                          entry.value,
                          entry.key,
                        ),
                      ),
                    ),

                // Bottom action buttons
                if (remarks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildBottomActions(),
                ],

                // Bottom safe area padding
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(ThemeData theme, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Section & Exam',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedSectionId,
            decoration: InputDecoration(
              labelText: 'Section',
              filled: true,
              fillColor: isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.class_, size: 20),
            ),
            items: _sections
                .map((s) => DropdownMenuItem(
                      value: s['id'],
                      child: Text(s['name']!),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedSectionId = val),
          ),
          const SizedBox(height: 14),

          // Exam dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedExamId,
            decoration: InputDecoration(
              labelText: 'Exam',
              filled: true,
              fillColor: isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.assignment, size: 20),
            ),
            items: _exams
                .map((e) => DropdownMenuItem(
                      value: e['id'],
                      child: Text(e['name']!),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedExamId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _isGenerating ? null : _generateRemarks,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating ? 'Generating...' : 'Generate All Remarks',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Generating AI-powered remarks...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(_generationProgress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _generationProgress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksHeader(
    ThemeData theme,
    bool isDark,
    List<ReportCommentary> remarks,
  ) {
    final approvedCount = remarks.where((r) => r.isApproved).length;
    final aiCount = remarks.where((r) => r.isLLMGenerated).length;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${remarks.length} Remarks Generated',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Summary badges
        _buildCountBadge(
          '$approvedCount approved',
          AppColors.success,
        ),
        const SizedBox(width: 8),
        _buildCountBadge(
          '$aiCount AI',
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildCountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRemarkCard(
    ThemeData theme,
    bool isDark,
    ReportCommentary remark,
    int index,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name, badges, actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student avatar with initials
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  _initials(remark.studentName),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remark.studentName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (remark.isLLMGenerated) _buildBadge('AI Generated', AppColors.info),
                        if (remark.isEdited) _buildBadge('Edited', AppColors.accent),
                        if (remark.isApproved) _buildBadge('Approved', AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions: edit, approve
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primary,
                    tooltip: 'Edit remark',
                    onPressed: () => _showEditDialog(remark),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  Checkbox(
                    value: remark.isApproved,
                    activeColor: AppColors.success,
                    onChanged: (_) {
                      ref
                          .read(remarksNotifierProvider.notifier)
                          .toggleApproval(remark.studentId);
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Remark text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.inputFillLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.borderLight,
              ),
            ),
            child: Text(
              remark.remark,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'AI Generated') ...[
            Icon(Icons.auto_awesome, color: color, size: 11),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _approveAll,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Approve All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saveAllApproved,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save Approved'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}
