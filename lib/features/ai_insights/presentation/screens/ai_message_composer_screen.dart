import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/message_template.dart';
import '../../../../data/models/student.dart';
import '../../../../core/copy/warm_strings.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../exams/providers/exams_provider.dart';
import '../../../fees/providers/fees_provider.dart' show feeRepositoryProvider;
import '../../../messaging/providers/messages_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/message_draft_provider.dart';

class AIMessageComposerScreen extends ConsumerStatefulWidget {
  const AIMessageComposerScreen({super.key});

  @override
  ConsumerState<AIMessageComposerScreen> createState() =>
      _AIMessageComposerScreenState();
}

class _AIMessageComposerScreenState
    extends ConsumerState<AIMessageComposerScreen> {
  final _searchController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  MessageType _selectedType = MessageType.general;
  MessageDraft? _currentDraft;
  Student? _selectedStudent;
  bool _isGenerating = false;
  bool _isSending = false;
  bool _hasGenerated = false;
  bool _showSuggestions = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _generateDraft() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _hasGenerated = false;
    });

    final student = _selectedStudent!;

    // Fetch real attendance % (last 30 days).
    double? attendancePct;
    try {
      final stats = await ref
          .read(attendanceRepositoryProvider)
          .getAttendanceStats(studentId: student.id);
      attendancePct = (stats['attendance_percentage'] ?? 0).toDouble();
    } catch (_) {}

    // Fetch pending fees total.
    double? pendingFees;
    try {
      final invoices = await ref
          .read(feeRepositoryProvider)
          .getInvoices(
            studentId: student.id,
            status: 'pending',
          );
      pendingFees = invoices.fold<double>(0, (sum, inv) => sum + inv.totalAmount);
    } catch (_) {}

    // Fetch latest exam average.
    double? examAvg;
    try {
      final performances = await ref
          .read(examRepositoryProvider)
          .getStudentPerformance(studentId: student.id);
      final valid = performances.where((p) => !p.isAbsent).toList();
      if (valid.isNotEmpty) {
        examAvg =
            valid.fold<double>(0, (sum, p) => sum + p.percentage) / valid.length;
      }
    } catch (_) {}

    // Resolve primary parent name.
    final parentName = student.parents?.isNotEmpty == true
        ? student.parents!.first.firstName
        : null;

    final request = MessageDraftRequest(
      studentId: student.id,
      studentName: student.fullName,
      messageType: _selectedType,
      parentName: parentName,
      attendancePct: attendancePct,
      pendingFees: pendingFees,
      latestExamAvg: examAvg,
    );

    try {
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
            content: Text(WarmCopy.saveFailed('draft')),
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

  Future<void> _sendViaChat() async {
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

    final student = _selectedStudent;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No student selected.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Resolve the primary parent's user ID.
    final parentUserId = student.parents
        ?.where((p) => p.userId != null)
        .map((p) => p.userId!)
        .firstOrNull;

    if (parentUserId == null) {
      // TODO(scope: Phase 14.x — needs DB migration): student has no linked
      // parent user account. Cannot open a chat thread without a user_id.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No parent account linked to this student. '
            'Ask the parent to register first.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final threadsNotifier = ref.read(threadsNotifierProvider.notifier);
      final thread =
          await threadsNotifier.getOrCreatePrivateThread(parentUserId);

      if (thread == null) {
        throw Exception('Could not create or find a chat thread.');
      }

      final messagesNotifier = ref.read(messagesNotifierProvider.notifier);
      await messagesNotifier.loadMessages(threadId: thread.id);
      await messagesNotifier.sendMessage(content: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent via chat.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(WarmCopy.saveFailed('message')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
                // Student search-select
                _buildStudentSearchCard(theme, isDark),
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

  Widget _buildStudentSearchCard(ThemeData theme, bool isDark) {
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
                  Icons.person_search_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Student',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Show selected student chip or search field.
          if (_selectedStudent != null)
            _buildSelectedStudentChip(theme)
          else
            _buildStudentSearchField(theme, isDark),

          // Suggestions list.
          if (_showSuggestions && _searchQuery.length >= 2)
            _buildSuggestions(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildSelectedStudentChip(ThemeData theme) {
    final student = _selectedStudent!;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            _initials(student.fullName),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                student.admissionNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            setState(() {
              _selectedStudent = null;
              _searchController.clear();
              _searchQuery = '';
              _hasGenerated = false;
            });
          },
          color: AppColors.textSecondaryLight,
          tooltip: 'Clear selection',
        ),
      ],
    );
  }

  Widget _buildStudentSearchField(ThemeData theme, bool isDark) {
    return TextField(
      controller: _searchController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Search student by name or admission number',
        filled: true,
        fillColor: isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _showSuggestions = false;
                  });
                },
              )
            : null,
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim();
          _showSuggestions = _searchQuery.length >= 2;
        });
      },
    );
  }

  Widget _buildSuggestions(ThemeData theme, bool isDark) {
    final filter = StudentsFilter(searchQuery: _searchQuery, activeOnly: true);
    final studentsAsync = ref.watch(studentsProvider(filter));

    return studentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Could not load students. $e',
            style: const TextStyle(color: AppColors.error, fontSize: 12)),
      ),
      data: (students) {
        if (students.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No students found.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: students.length > 8 ? 8 : students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = students[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    _initials(s.fullName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(s.fullName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(s.admissionNumber,
                    style: theme.textTheme.labelSmall),
                onTap: () {
                  setState(() {
                    _selectedStudent = s;
                    _searchController.clear();
                    _searchQuery = '';
                    _showSuggestions = false;
                    _hasGenerated = false;
                  });
                },
              );
            },
          ),
        );
      },
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
            onPressed: _isSending ? null : _sendViaChat,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 18),
            label: Text(_isSending ? 'Sending...' : 'Send via Chat'),
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
