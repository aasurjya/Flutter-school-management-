import 'package:flutter/material.dart';

import '../../../../data/models/syllabus_topic.dart';

/// 4-button segmented toggle for setting topic coverage status.
///
/// Follows the attendance mark button pattern from [MarkAttendanceScreen]:
/// selected buttons have a filled background with the status colour, while
/// unselected buttons show a border outline only.
class TopicStatusToggle extends StatelessWidget {
  final TopicStatus currentStatus;
  final ValueChanged<TopicStatus> onStatusChanged;

  const TopicStatusToggle({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TopicStatus.values.map((status) {
        final isSelected = status == currentStatus;
        final index = TopicStatus.values.indexOf(status);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < TopicStatus.values.length - 1 ? 6 : 0,
            ),
            child: _StatusButton(
              label: _shortLabel(status),
              icon: status.icon,
              color: status.color,
              isSelected: isSelected,
              onTap: () => onStatusChanged(status),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Abbreviated labels to prevent overflow in tight layouts.
  String _shortLabel(TopicStatus status) {
    switch (status) {
      case TopicStatus.notStarted:
        return 'Not Started';
      case TopicStatus.inProgress:
        return 'In Progress';
      case TopicStatus.completed:
        return 'Done';
      case TopicStatus.skipped:
        return 'Skipped';
    }
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
