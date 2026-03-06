import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';

class QuestionNavigator extends StatelessWidget {
  final OnlineExamSession session;
  final void Function(int sectionIndex, int questionIndex) onQuestionTap;

  const QuestionNavigator({
    super.key,
    required this.session,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title + summary
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question Navigator',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${session.answeredCount}/${session.totalQuestions} answered',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _LegendDot(
                        color: AppColors.success, label: 'Answered'),
                    const SizedBox(width: 12),
                    _LegendDot(
                        color: theme.colorScheme.primary,
                        label: 'Current'),
                    const SizedBox(width: 12),
                    _LegendDot(
                        color: AppColors.warning, label: 'Flagged'),
                    const SizedBox(width: 12),
                    _LegendDot(
                        color: Colors.grey.shade300,
                        label: 'Unanswered'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // Sections and questions
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: session.sections.length,
                  itemBuilder: (context, sectionIdx) {
                    final section = session.sections[sectionIdx];
                    final questions =
                        session.sectionQuestions[section.id] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (session.sections.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 6),
                            child: Text(
                              section.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(questions.length, (qIdx) {
                            final q = questions[qIdx];
                            final isAnswered =
                                session.isQuestionAnswered(q.id);
                            final isFlagged =
                                session.isQuestionFlagged(q.id);
                            final isCurrent =
                                sectionIdx ==
                                        session.currentSectionIndex &&
                                    qIdx == session.currentQuestionIndex;

                            Color bgColor;
                            Color textColor;

                            if (isCurrent) {
                              bgColor = theme.colorScheme.primary;
                              textColor = theme.colorScheme.onPrimary;
                            } else if (isFlagged) {
                              bgColor = AppColors.warning;
                              textColor = Colors.white;
                            } else if (isAnswered) {
                              bgColor = AppColors.success;
                              textColor = Colors.white;
                            } else {
                              bgColor = Colors.grey.shade200;
                              textColor = Colors.grey.shade700;
                            }

                            return InkWell(
                              onTap: () {
                                onQuestionTap(sectionIdx, qIdx);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isCurrent
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        '${qIdx + 1}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isFlagged && !isCurrent)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Icon(
                                          Icons.flag,
                                          size: 10,
                                          color: textColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}
