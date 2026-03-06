import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/communication.dart';
import '../../../../shared/widgets/glass_card.dart';

class TemplatePreview extends StatelessWidget {
  final CommunicationTemplate template;
  final Map<String, String>? sampleData;

  const TemplatePreview({
    super.key,
    required this.template,
    this.sampleData,
  });

  static const Map<String, String> defaultSampleData = {
    'student_name': 'Arjun Sharma',
    'parent_name': 'Rajesh Sharma',
    'class_name': 'Class 10-A',
    'teacher_name': 'Mrs. Priya Gupta',
    'school_name': 'Kendriya Vidyalaya',
    'date': '15 Mar 2026',
    'time': '10:30 AM',
    'amount': '15,000',
    'subject_name': 'Mathematics',
    'exam_name': 'Mid-Term Examination',
    'event_name': 'Annual Day',
    'attendance_date': '14 Mar 2026',
    'due_date': '31 Mar 2026',
    'grade': 'A+',
    'percentage': '92%',
    'marks': '46/50',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = {...defaultSampleData, ...?sampleData};
    final renderedBody = template.renderBody(data);
    final renderedSubject = template.renderSubject(data);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _channelIcon(template.channel),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview - ${template.channel.label}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor(template.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  template.category.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _categoryColor(template.category),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Subject
          if (renderedSubject != null && renderedSubject.isNotEmpty) ...[
            Text(
              'Subject:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              renderedSubject,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Body
          Text(
            'Message:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              renderedBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),

          // Variables list
          if (template.variables.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Variables used:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: template.variables.map((v) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '{{$v}}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _channelIcon(CommunicationChannel channel) {
    switch (channel) {
      case CommunicationChannel.sms:
        return Icons.sms_outlined;
      case CommunicationChannel.email:
        return Icons.email_outlined;
      case CommunicationChannel.push:
        return Icons.notifications_outlined;
      case CommunicationChannel.inApp:
        return Icons.phone_android_outlined;
      case CommunicationChannel.whatsapp:
        return Icons.chat_outlined;
    }
  }

  Color _categoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.feeReminder:
        return AppColors.warning;
      case TemplateCategory.attendanceAlert:
        return AppColors.error;
      case TemplateCategory.examNotice:
        return AppColors.info;
      case TemplateCategory.eventInvite:
        return AppColors.success;
      case TemplateCategory.general:
        return AppColors.textSecondaryLight;
      case TemplateCategory.emergency:
        return AppColors.error;
    }
  }
}
