import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/notice_board.dart';

class NoticeCategoryChip extends StatelessWidget {
  final NoticeCategory category;
  final bool selected;
  final VoidCallback? onTap;

  const NoticeCategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(category),
              size: 14,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color categoryColor(NoticeCategory category) =>
      _categoryColor(category);

  static Color _categoryColor(NoticeCategory category) {
    switch (category) {
      case NoticeCategory.academic:
        return AppColors.primary;
      case NoticeCategory.sports:
        return AppColors.secondary;
      case NoticeCategory.events:
        return AppColors.accent;
      case NoticeCategory.holiday:
        return Colors.teal;
      case NoticeCategory.examination:
        return Colors.deepPurple;
      case NoticeCategory.fee:
        return Colors.orange;
      case NoticeCategory.general:
        return AppColors.info;
      case NoticeCategory.emergency:
        return AppColors.error;
    }
  }

  static IconData _categoryIcon(NoticeCategory category) {
    switch (category) {
      case NoticeCategory.academic:
        return Icons.school;
      case NoticeCategory.sports:
        return Icons.sports_soccer;
      case NoticeCategory.events:
        return Icons.event;
      case NoticeCategory.holiday:
        return Icons.beach_access;
      case NoticeCategory.examination:
        return Icons.assignment;
      case NoticeCategory.fee:
        return Icons.payment;
      case NoticeCategory.general:
        return Icons.info;
      case NoticeCategory.emergency:
        return Icons.warning_amber;
    }
  }
}
