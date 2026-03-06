import 'package:flutter/material.dart';
import '../../../../data/models/online_exam.dart';

/// Renders any question type with appropriate input controls
class QuestionWidget extends StatelessWidget {
  final ExamQuestion question;
  final dynamic currentResponse;
  final bool flaggedForReview;
  final bool readOnly;
  final bool showCorrectAnswer;
  final void Function(dynamic response)? onAnswer;

  const QuestionWidget({
    super.key,
    required this.question,
    this.currentResponse,
    this.flaggedForReview = false,
    this.readOnly = false,
    this.showCorrectAnswer = false,
    this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text card
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.difficulty.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: _difficultyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.questionType.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${question.marks.toStringAsFixed(question.marks == question.marks.roundToDouble() ? 0 : 1)} marks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  question.questionText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Answer input based on type
        _buildAnswerInput(context),
        // Show correct answer in review mode
        if (showCorrectAnswer && question.explanation != null) ...[
          const SizedBox(height: 16),
          _ExplanationBox(explanation: question.explanation!),
        ],
      ],
    );
  }

  Widget _buildAnswerInput(BuildContext context) {
    switch (question.questionType) {
      case ExamQuestionType.mcq:
        return _MCQInput(
          question: question,
          selectedKey: _getResponseValue(),
          readOnly: readOnly,
          showCorrectAnswer: showCorrectAnswer,
          onSelect: (key) => onAnswer?.call({'value': key}),
        );
      case ExamQuestionType.multiSelect:
        return _MultiSelectInput(
          question: question,
          selectedKeys: _getResponseValues(),
          readOnly: readOnly,
          showCorrectAnswer: showCorrectAnswer,
          onSelect: (keys) => onAnswer?.call({'values': keys}),
        );
      case ExamQuestionType.trueFalse:
        return _TrueFalseInput(
          selectedValue: _getResponseValue(),
          readOnly: readOnly,
          showCorrectAnswer: showCorrectAnswer,
          correctAnswer: _getCorrectValue(),
          onSelect: (val) => onAnswer?.call({'value': val}),
        );
      case ExamQuestionType.fillBlank:
        return _FillBlankInput(
          initialValue: _getResponseValue(),
          readOnly: readOnly,
          onChanged: (val) => onAnswer?.call({'value': val}),
        );
      case ExamQuestionType.shortAnswer:
        return _TextInput(
          initialValue: _getResponseValue(),
          maxLines: 3,
          readOnly: readOnly,
          hint: 'Enter your answer here...',
          onChanged: (val) => onAnswer?.call({'value': val}),
        );
      case ExamQuestionType.longAnswer:
        return _TextInput(
          initialValue: _getResponseValue(),
          maxLines: 10,
          readOnly: readOnly,
          hint: 'Enter your detailed answer here...',
          onChanged: (val) => onAnswer?.call({'value': val}),
        );
      case ExamQuestionType.matchPairs:
        return _MatchPairsInput(
          question: question,
          currentMatches: _getResponseMap(),
          readOnly: readOnly,
          onChanged: (matches) => onAnswer?.call({'matches': matches}),
        );
      case ExamQuestionType.ordering:
        return _OrderingInput(
          question: question,
          currentOrder: _getResponseList(),
          readOnly: readOnly,
          onChanged: (order) => onAnswer?.call({'order': order}),
        );
    }
  }

  String? _getResponseValue() {
    if (currentResponse == null) return null;
    if (currentResponse is Map) return currentResponse['value']?.toString();
    return currentResponse.toString();
  }

  List<String> _getResponseValues() {
    if (currentResponse == null) return [];
    if (currentResponse is Map && currentResponse['values'] is List) {
      return (currentResponse['values'] as List)
          .map((e) => e.toString())
          .toList();
    }
    return [];
  }

  String? _getCorrectValue() {
    final ca = question.correctAnswer;
    if (ca == null) return null;
    if (ca is Map) return ca['value']?.toString();
    return ca.toString();
  }

  Map<String, String> _getResponseMap() {
    if (currentResponse == null) return {};
    if (currentResponse is Map && currentResponse['matches'] is Map) {
      return Map<String, String>.from(currentResponse['matches']);
    }
    return {};
  }

  List<String> _getResponseList() {
    if (currentResponse == null) return [];
    if (currentResponse is Map && currentResponse['order'] is List) {
      return (currentResponse['order'] as List)
          .map((e) => e.toString())
          .toList();
    }
    return [];
  }

  Color get _difficultyColor {
    switch (question.difficulty) {
      case ExamDifficulty.easy:
        return Colors.green;
      case ExamDifficulty.medium:
        return Colors.orange;
      case ExamDifficulty.hard:
        return Colors.red;
    }
  }
}

// ==================== MCQ INPUT ====================

class _MCQInput extends StatelessWidget {
  final ExamQuestion question;
  final String? selectedKey;
  final bool readOnly;
  final bool showCorrectAnswer;
  final void Function(String) onSelect;

  const _MCQInput({
    required this.question,
    this.selectedKey,
    this.readOnly = false,
    this.showCorrectAnswer = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = question.optionEntries;

    // Fallback if optionEntries is empty
    List<MapEntry<String, String>> displayOptions = options;
    if (displayOptions.isEmpty) {
      // Try raw options
      for (int i = 0; i < question.options.length; i++) {
        final opt = question.options[i];
        if (opt is String) {
          displayOptions.add(MapEntry(String.fromCharCode(65 + i), opt));
        } else if (opt is Map) {
          displayOptions.add(MapEntry(
            opt['key']?.toString() ?? String.fromCharCode(65 + i),
            opt['text']?.toString() ?? opt['value']?.toString() ?? '',
          ));
        }
      }
    }

    final correctKey = showCorrectAnswer
        ? (question.correctAnswer is Map
            ? question.correctAnswer['value']?.toString()
            : question.correctAnswer?.toString())
        : null;

    return Column(
      children: displayOptions.map((entry) {
        final isSelected = selectedKey == entry.key;
        final isCorrect = showCorrectAnswer && correctKey == entry.key;
        final isWrong =
            showCorrectAnswer && isSelected && correctKey != entry.key;

        Color? cardColor;
        Color? borderColor;
        if (isCorrect) {
          cardColor = Colors.green.withAlpha(20);
          borderColor = Colors.green;
        } else if (isWrong) {
          cardColor = Colors.red.withAlpha(20);
          borderColor = Colors.red;
        } else if (isSelected) {
          cardColor = theme.colorScheme.primaryContainer;
          borderColor = theme.colorScheme.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: readOnly ? null : () => onSelect(entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor ??
                      theme.colorScheme.outlineVariant.withAlpha(100),
                  width: isSelected || isCorrect || isWrong ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isCorrect
                              ? Colors.green
                              : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: (isSelected || isCorrect)
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(Icons.check_circle, color: Colors.green),
                  if (isWrong) const Icon(Icons.cancel, color: Colors.red),
                  if (isSelected && !showCorrectAnswer)
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ==================== MULTI SELECT INPUT ====================

class _MultiSelectInput extends StatelessWidget {
  final ExamQuestion question;
  final List<String> selectedKeys;
  final bool readOnly;
  final bool showCorrectAnswer;
  final void Function(List<String>) onSelect;

  const _MultiSelectInput({
    required this.question,
    required this.selectedKeys,
    this.readOnly = false,
    this.showCorrectAnswer = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = question.optionEntries.isEmpty
        ? question.options
            .asMap()
            .entries
            .map((e) {
              final opt = e.value;
              if (opt is Map) {
                return MapEntry(
                  opt['key']?.toString() ?? String.fromCharCode(65 + e.key),
                  opt['text']?.toString() ?? '',
                );
              }
              return MapEntry(String.fromCharCode(65 + e.key), opt.toString());
            })
            .toList()
        : question.optionEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select all that apply:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map((entry) {
          final isSelected = selectedKeys.contains(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: readOnly
                  ? null
                  : () {
                      final newKeys = List<String>.from(selectedKeys);
                      if (isSelected) {
                        newKeys.remove(entry.key);
                      } else {
                        newKeys.add(entry.key);
                      }
                      onSelect(newKeys);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withAlpha(100),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ==================== TRUE/FALSE INPUT ====================

class _TrueFalseInput extends StatelessWidget {
  final String? selectedValue;
  final bool readOnly;
  final bool showCorrectAnswer;
  final String? correctAnswer;
  final void Function(String) onSelect;

  const _TrueFalseInput({
    this.selectedValue,
    this.readOnly = false,
    this.showCorrectAnswer = false,
    this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _TFButton(
            label: 'True',
            icon: Icons.check_circle_outline,
            isSelected: selectedValue == 'true',
            isCorrect: showCorrectAnswer && correctAnswer == 'true',
            isWrong: showCorrectAnswer &&
                selectedValue == 'true' &&
                correctAnswer != 'true',
            onTap: readOnly ? null : () => onSelect('true'),
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TFButton(
            label: 'False',
            icon: Icons.cancel_outlined,
            isSelected: selectedValue == 'false',
            isCorrect: showCorrectAnswer && correctAnswer == 'false',
            isWrong: showCorrectAnswer &&
                selectedValue == 'false' &&
                correctAnswer != 'false',
            onTap: readOnly ? null : () => onSelect('false'),
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _TFButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.isCorrect = false,
    this.isWrong = false,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? borderColor;
    Color iconColor = theme.colorScheme.onSurfaceVariant;

    if (isCorrect) {
      bgColor = Colors.green.withAlpha(20);
      borderColor = Colors.green;
      iconColor = Colors.green;
    } else if (isWrong) {
      bgColor = Colors.red.withAlpha(20);
      borderColor = Colors.red;
      iconColor = Colors.red;
    } else if (isSelected) {
      bgColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.primary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? theme.colorScheme.outlineVariant,
            width: (isSelected || isCorrect || isWrong) ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : null,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FILL BLANK INPUT ====================

class _FillBlankInput extends StatefulWidget {
  final String? initialValue;
  final bool readOnly;
  final void Function(String) onChanged;

  const _FillBlankInput({
    this.initialValue,
    this.readOnly = false,
    required this.onChanged,
  });

  @override
  State<_FillBlankInput> createState() => _FillBlankInputState();
}

class _FillBlankInputState extends State<_FillBlankInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.edit_note),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ==================== TEXT INPUT ====================

class _TextInput extends StatefulWidget {
  final String? initialValue;
  final int maxLines;
  final bool readOnly;
  final String hint;
  final void Function(String) onChanged;

  const _TextInput({
    this.initialValue,
    this.maxLines = 3,
    this.readOnly = false,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ==================== MATCH PAIRS INPUT ====================

class _MatchPairsInput extends StatelessWidget {
  final ExamQuestion question;
  final Map<String, String> currentMatches;
  final bool readOnly;
  final void Function(Map<String, String>) onChanged;

  const _MatchPairsInput({
    required this.question,
    required this.currentMatches,
    this.readOnly = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Options format: [{left: "A", right: "1"}, ...]
    final leftItems = <String>[];
    final rightItems = <String>[];
    for (final opt in question.options) {
      if (opt is Map) {
        leftItems.add(opt['left']?.toString() ?? '');
        rightItems.add(opt['right']?.toString() ?? '');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match items from the left column with the right column:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...leftItems.asMap().entries.map((entry) {
          final leftItem = entry.value;
          final matched = currentMatches[leftItem];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(leftItem,
                        style: theme.textTheme.bodyMedium),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 20),
                ),
                Expanded(
                  child: readOnly
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: matched != null
                                ? theme.colorScheme.primaryContainer
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(matched ?? 'Not matched'),
                        )
                      : DropdownButtonFormField<String>(
                          value: matched,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                          hint: const Text('Select'),
                          items: rightItems
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final newMatches =
                                Map<String, String>.from(currentMatches);
                            newMatches[leftItem] = val;
                            onChanged(newMatches);
                          },
                        ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ==================== ORDERING INPUT ====================

class _OrderingInput extends StatelessWidget {
  final ExamQuestion question;
  final List<String> currentOrder;
  final bool readOnly;
  final void Function(List<String>) onChanged;

  const _OrderingInput({
    required this.question,
    required this.currentOrder,
    this.readOnly = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get items to order
    List<String> items;
    if (currentOrder.isNotEmpty) {
      items = currentOrder;
    } else {
      items = question.options.map((o) {
        if (o is Map) return o['text']?.toString() ?? o.toString();
        return o.toString();
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arrange in the correct order (drag to reorder):',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (readOnly)
          ...items.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              ))
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              final newItems = List<String>.from(items);
              if (newIndex > oldIndex) newIndex--;
              final item = newItems.removeAt(oldIndex);
              newItems.insert(newIndex, item);
              onChanged(newItems);
            },
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey('$index-${items[index]}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          theme.colorScheme.outlineVariant.withAlpha(100),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(items[index])),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ==================== EXPLANATION BOX ====================

class _ExplanationBox extends StatelessWidget {
  final String explanation;

  const _ExplanationBox({required this.explanation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explanation',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
