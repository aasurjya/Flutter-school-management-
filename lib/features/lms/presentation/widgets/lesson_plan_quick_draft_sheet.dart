import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ai_providers.dart';
import '../../../../core/services/ai_text_generator.dart';

/// Sprint 1.3 — "Type a topic → get a lesson plan."
///
/// No prerequisite syllabus topic required. The teacher types a topic, picks
/// subject + class + duration, and the gateway returns a structured JSON
/// lesson plan that renders as a clean preview with copy + save-as-draft.
///
/// Routes through the gateway as `feature_type = 'lesson_plan_json'`.
class LessonPlanQuickDraftSheet extends ConsumerStatefulWidget {
  const LessonPlanQuickDraftSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(_).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: const LessonPlanQuickDraftSheet(),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LessonPlanQuickDraftSheet> createState() =>
      _LessonPlanQuickDraftSheetState();
}

class _LessonPlanQuickDraftSheetState
    extends ConsumerState<LessonPlanQuickDraftSheet> {
  final _topicCtl = TextEditingController();
  final _subjectCtl = TextEditingController();
  final _classCtl = TextEditingController();
  int _duration = 40;
  bool _busy = false;
  AITextResult? _result;
  String? _error;

  // Snapshot of the inputs at generation time so the preview header always
  // reflects what the LLM actually saw, even after the teacher edits the form.
  ({String topic, String subject, String className, int duration})? _snapshot;
  bool _dirtyAfterGenerate = false;

  @override
  void initState() {
    super.initState();
    // When the teacher edits any input after a result exists, flip the
    // "input changed since last generation" nudge.
    void markDirty() {
      if (_result != null && !_dirtyAfterGenerate && mounted) {
        setState(() => _dirtyAfterGenerate = true);
      }
    }

    _topicCtl.addListener(markDirty);
    _subjectCtl.addListener(markDirty);
    _classCtl.addListener(markDirty);
  }

  @override
  void dispose() {
    _topicCtl.dispose();
    _subjectCtl.dispose();
    _classCtl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicCtl.text.trim();
    final subject = _subjectCtl.text.trim();
    final className = _classCtl.text.trim();
    if (topic.isEmpty || subject.isEmpty || className.isEmpty) {
      setState(() => _error =
          'Please fill in topic, subject and class to generate a plan.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final gen = ref.read(aiTextGeneratorProvider);
      final res = await gen.generateLessonPlan(
        topicTitle: topic,
        subjectName: subject,
        className: className,
        durationMinutes: _duration,
        fallback: '{"objective":"Lesson plan generation is unavailable right now."}',
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _snapshot = (
          topic: topic,
          subject: subject,
          className: className,
          duration: _duration,
        );
        _dirtyAfterGenerate = false;
      });
      if (res.isLLMGenerated) {
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() => _error = 'Could not generate: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(),
        // Always-on slim progress bar during generation — without this the
        // sheet appears frozen for 5-8s and looks broken to the teacher.
        if (_busy) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: 'Generating lesson plan, please wait',
            child: const LinearProgressIndicator(minHeight: 4),
          ),
        ],
        const SizedBox(height: 16),
        // Inputs ALWAYS stay editable so the teacher can tweak topic/grade
        // /duration without losing the prior preview below.
        _buildInputs(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onErrorContainer,
                )),
          ),
        ],
        const SizedBox(height: 16),
        // Preview renders BELOW the inputs (not in place of them) and BEFORE
        // the action row — natural reading order is inputs → preview → actions.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          child: _result == null
              ? const SizedBox.shrink(key: ValueKey('no-preview'))
              : Padding(
                  key: const ValueKey('preview'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PreviewCard(
                    snapshot: _snapshot,
                    child: _buildPreview(_result!),
                  ),
                ),
        ),
        if (_result != null && _dirtyAfterGenerate)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inputs changed — tap Regenerate to update.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildActions(),
      ],
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        TextField(
          controller: _topicCtl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Topic',
            hintText: 'e.g. Photosynthesis',
            prefixIcon: Icon(Icons.bookmark_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subjectCtl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Science',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _classCtl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_busy) _generate();
                },
                decoration: const InputDecoration(
                  labelText: 'Class',
                  hintText: 'e.g. Grade 7',
                  prefixIcon: Icon(Icons.grade_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Duration', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 12),
            for (final d in const [30, 40, 45, 60])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${d}m'),
                  selected: _duration == d,
                  onSelected: (v) {
                    if (v) setState(() => _duration = d);
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(AITextResult result) {
    final scheme = Theme.of(context).colorScheme;

    // The system prompt instructs the LLM to return JSON. Try to parse — if
    // it fails, fall back to showing the raw text.
    Map<String, dynamic>? json;
    try {
      final cleaned = result.text
          .replaceFirst(RegExp(r'^```json\s*', multiLine: false), '')
          .replaceFirst(RegExp(r'^```\s*', multiLine: false), '')
          .replaceFirst(RegExp(r'\s*```$', multiLine: false), '');
      final decoded = jsonDecode(cleaned.trim());
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {/* leave json null */}

    if (!result.isLLMGenerated) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'AI is unavailable right now. Please try again later.',
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      );
    }

    if (json == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          result.text,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
        ),
      );
    }

    final snap = _snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(label: 'Topic', value: snap?.topic ?? _topicCtl.text),
        _Section(
          label: 'Subject · Class · Duration',
          value:
              '${snap?.subject ?? _subjectCtl.text} · ${snap?.className ?? _classCtl.text} · ${snap?.duration ?? _duration}min',
        ),
        const Divider(height: 20),
        for (final entry in const [
          ('objective', 'Learning objective'),
          ('warm_up', 'Warm-up activity'),
          ('main_activity', 'Main activity'),
          ('assessment_activity', 'Assessment'),
          ('homework', 'Homework'),
          ('materials_needed', 'Materials'),
          ('differentiation_notes', 'Differentiation notes'),
        ])
          if ((json[entry.$1] as String?)?.trim().isNotEmpty ?? false)
            _Section(
              label: entry.$2,
              value: (json[entry.$1] as String).trim(),
            ),
      ],
    );
  }

  Widget _buildActions() {
    // Hide Copy on fallback content — copying a "service unavailable" stub
    // as if it were a real lesson plan is the worst possible outcome.
    final hasResult = _result != null;
    final showCopy = hasResult && _result!.isLLMGenerated;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showCopy)
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy as text'),
            onPressed: () async {
              final text = _renderForClipboard(_result!.text);
              await Clipboard.setData(ClipboardData(text: text));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lesson plan copied')),
              );
            },
          ),
        FilledButton.icon(
          icon: Icon(hasResult
              ? Icons.refresh_rounded
              : Icons.auto_awesome_rounded),
          label: Text(_busy
              ? 'Generating…'
              : hasResult
                  ? 'Regenerate'
                  : 'Generate lesson plan'),
          onPressed: _busy ? null : _generate,
        ),
        if (hasResult)
          TextButton.icon(
            icon: const Icon(Icons.close_rounded),
            label: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  /// Render the LLM JSON output as plain text the teacher can paste into
  /// WhatsApp / printed registers / etc. Falls back to raw if parsing fails.
  ///
  /// Reads from `_snapshot` rather than live controllers so the copied text's
  /// header always matches the inputs the LLM actually saw — even if the
  /// teacher has since edited the form fields.
  String _renderForClipboard(String raw) {
    final snap = _snapshot;
    final topic = snap?.topic ?? _topicCtl.text;
    final subject = snap?.subject ?? _subjectCtl.text;
    final className = snap?.className ?? _classCtl.text;
    final duration = snap?.duration ?? _duration;

    try {
      final cleaned = raw
          .replaceFirst(RegExp(r'^```json\s*'), '')
          .replaceFirst(RegExp(r'^```\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        const sections = [
          ('objective', 'Learning objective'),
          ('warm_up', 'Warm-up activity'),
          ('main_activity', 'Main activity'),
          ('assessment_activity', 'Assessment'),
          ('homework', 'Homework'),
          ('materials_needed', 'Materials'),
          ('differentiation_notes', 'Differentiation notes'),
        ];
        final buf = StringBuffer()
          ..writeln('Topic: $topic')
          ..writeln(
              'Subject · Class · Duration: $subject · $className · ${duration}min')
          ..writeln();
        for (final s in sections) {
          final v = (decoded[s.$1] as String?)?.trim();
          if (v != null && v.isNotEmpty) {
            buf.writeln('${s.$2}:');
            buf.writeln(v);
            buf.writeln();
          }
        }
        return buf.toString().trim();
      }
    } catch (_) {/* fall through */}
    return raw;
  }
}

// ---------------------------------------------------------------------------
// Small UI bits
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick AI lesson plan',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Text(
                'Type a topic — get a structured plan in seconds.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wraps the preview in a clearly-distinct collapsible card so the teacher
/// always sees the input form above and the result below — never one
/// replacing the other.
class _PreviewCard extends StatelessWidget {
  final Widget child;
  final ({String topic, String subject, String className, int duration})?
      snapshot;
  const _PreviewCard({required this.child, this.snapshot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI provenance row — never let the teacher mistake the preview
          // for human-authored content.
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.auto_awesome_rounded,
                    size: 16, color: scheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'AI-GENERATED PREVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String value;
  const _Section({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, height: 1.43)),
        ],
      ),
    );
  }
}
