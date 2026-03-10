import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/message_template.dart';
import '../../providers/message_draft_provider.dart';

class AIMessageComposerScreen extends ConsumerStatefulWidget {
  const AIMessageComposerScreen({super.key});

  @override
  ConsumerState<AIMessageComposerScreen> createState() =>
      _AIMessageComposerScreenState();
}

class _AIMessageComposerScreenState
    extends ConsumerState<AIMessageComposerScreen> {
  final _studentNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  MessageType _selectedType = MessageType.general;
  MessageDraft? _currentDraft;
  bool _isGenerating = false;
  bool _hasGenerated = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _generateDraft() async {
    final studentName = _studentNameController.text.trim();
    if (studentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the student name.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _hasGenerated = false;
    });

    final request = MessageDraftRequest(
      studentId: studentName.toLowerCase().replaceAll(' ', '-'),
      studentName: studentName,
      messageType: _selectedType,
    );

    try {
      // Invalidate any cached result for this request before fetching
      ref.invalidate(messageDraftProvider(request));
      final draft = await ref.read(messageDraftProvider(request).future);

      if (mounted) {
        setState(() {
          _currentDraft = draft;
          _subjectController.text = draft.subject;
          _bodyController.text = draft.body;
          _isGenerating = false;
          _hasGenerated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate draft: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (subject.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to copy. Generate a draft first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final text = 'Subject: $subject\n\n$body';
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _sendViaChat() {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate or write a message first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message ready to send.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Message Composer',
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
                // Student name input
                _buildStudentNameCard(theme, isDark),
                const SizedBox(height: 16),

                // Message type selector
                _buildMessageTypeCard(theme, isDark),
                const SizedBox(height: 16),

                // Generate button
                _buildGenerateButton(),
                const SizedBox(height: 16),

                // Loading state
                if (_isGenerating) ...[
                  _buildLoadingCard(theme),
                  const SizedBox(height: 16),
                ],

                // Editable message area
                if (_hasGenerated && !_isGenerating) ...[
                  _buildMessageEditorCard(theme, isDark),
                  const SizedBox(height: 16),

                  // Bottom action buttons
                  _buildActionButtons(),
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

  Widget _buildStudentNameCard(ThemeData theme, bool isDark) {
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
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Student Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _studentNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Student Name',
              hintText: 'Enter student name',
              filled: true,
              fillColor:
                  isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.school_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTypeCard(ThemeData theme, bool isDark) {
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
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Message Type',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MessageType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected ? Colors.white : type.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: type.color,
                backgroundColor: isDark
                    ? type.color.withValues(alpha: 0.15)
                    : type.color.withValues(alpha: 0.08),
                side: BorderSide(
                  color: isSelected
                      ? type.color
                      : type.color.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                showCheckmark: false,
                onSelected: (_) {
                  setState(() => _selectedType = type);
                },
              );
            }).toList(),
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
        onPressed: _isGenerating ? null : _generateDraft,
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
          _isGenerating ? 'Generating...' : 'Generate Draft',
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

  Widget _buildLoadingCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Composing your message...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI is drafting a personalized ${_selectedType.label.toLowerCase()} message.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageEditorCard(ThemeData theme, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and AI badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Message Draft',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_currentDraft?.isLLMGenerated == true) _buildAIBadge(),
            ],
          ),
          const SizedBox(height: 20),

          // Subject line
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              filled: true,
              fillColor:
                  isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.subject, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Body text area
          TextField(
            controller: _bodyController,
            maxLines: 12,
            minLines: 6,
            decoration: InputDecoration(
              labelText: 'Message Body',
              alignLabelWithHint: true,
              filled: true,
              fillColor:
                  isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: AppColors.info, size: 13),
          SizedBox(width: 4),
          Text(
            'AI Generated',
            style: TextStyle(
              color: AppColors.info,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Copy to Clipboard
        IconButton(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy),
          tooltip: 'Copy to Clipboard',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Regenerate
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _generateDraft,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Regenerate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Send via Chat
        Expanded(
          child: FilledButton.icon(
            onPressed: _sendViaChat,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send via Chat'),
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
}
