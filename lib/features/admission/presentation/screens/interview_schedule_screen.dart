import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/admission_provider.dart';
import '../widgets/application_status_badge.dart';

class InterviewScheduleScreen extends ConsumerStatefulWidget {
  final String? applicationId;

  const InterviewScheduleScreen({super.key, this.applicationId});

  @override
  ConsumerState<InterviewScheduleScreen> createState() =>
      _InterviewScheduleScreenState();
}

class _InterviewScheduleScreenState
    extends ConsumerState<InterviewScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final interviewsAsync = ref.watch(allInterviewsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Schedule'),
        actions: [
          // Status filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _statusFilter = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'scheduled', child: Text('Scheduled')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          _buildDateSelector(context, isDark),
          // Interview list
          Expanded(
            child: interviewsAsync.when(
              data: (interviews) {
                var filtered = interviews;

                if (_statusFilter != 'all') {
                  filtered = filtered
                      .where((i) => i.status.value == _statusFilter)
                      .toList();
                }

                // Filter by selected date
                filtered = filtered.where((i) {
                  final d = i.scheduledAt;
                  return d.year == _selectedDate.year &&
                      d.month == _selectedDate.month &&
                      d.day == _selectedDate.day;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available,
                            size: 64, color: AppColors.textTertiaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No interviews on ${dateFormat.format(_selectedDate)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final interview = filtered[index];
                    return _buildInterviewCard(
                        context, ref, interview, timeFormat, isDark);
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final days = List.generate(
        14, (i) => now.add(Duration(days: i - 3)));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(day),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInterviewCard(BuildContext context, WidgetRef ref,
      AdmissionInterview interview, DateFormat timeFormat, bool isDark) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeFormat.format(interview.scheduledAt),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interview.applicantName ?? 'Unknown Applicant',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (interview.interviewerName != null)
                      Text(
                        'By: ${interview.interviewerName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              InterviewStatusBadge(status: interview.status),
            ],
          ),
          if (interview.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppColors.textTertiaryLight),
                const SizedBox(width: 4),
                Text(
                  interview.location!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (interview.status == InterviewStatus.scheduled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _completeInterview(
                        context, ref, interview),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelInterview(
                        context, ref, interview.id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (interview.feedback != null &&
              interview.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (interview.score != null)
                    Text(
                      'Score: ${interview.score}/100',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    interview.feedback!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref) {
    final appIdController = TextEditingController(
      text: widget.applicationId ?? '',
    );
    final interviewerIdController = TextEditingController();
    final locationController = TextEditingController();
    DateTime scheduledDate = _selectedDate;
    TimeOfDay scheduledTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Schedule Interview'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: appIdController,
                  decoration: const InputDecoration(
                    labelText: 'Application ID *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: interviewerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Interviewer User ID *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) {
                      setDialogState(() => scheduledDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(scheduledTime.format(ctx)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: scheduledTime,
                    );
                    if (time != null) {
                      setDialogState(() => scheduledTime = time);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (appIdController.text.trim().isEmpty ||
                    interviewerIdController.text.trim().isEmpty) {
                  return;
                }

                final scheduledAt = DateTime(
                  scheduledDate.year,
                  scheduledDate.month,
                  scheduledDate.day,
                  scheduledTime.hour,
                  scheduledTime.minute,
                );

                try {
                  final repo = ref.read(admissionRepositoryProvider);
                  await repo.scheduleInterview({
                    'application_id': appIdController.text.trim(),
                    'interviewer_id': interviewerIdController.text.trim(),
                    'scheduled_at': scheduledAt.toIso8601String(),
                    'location': locationController.text.trim().isNotEmpty
                        ? locationController.text.trim()
                        : null,
                  });
                  ref.invalidate(allInterviewsProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Interview scheduled'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _completeInterview(
      BuildContext context, WidgetRef ref, AdmissionInterview interview) {
    final feedbackController = TextEditingController();
    final scoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Interview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Score (0-100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repo = ref.read(admissionRepositoryProvider);
                await repo.updateInterview(interview.id, {
                  'status': InterviewStatus.completed.value,
                  'score': int.tryParse(scoreController.text),
                  'feedback': feedbackController.text.trim().isNotEmpty
                      ? feedbackController.text.trim()
                      : null,
                });
                ref.invalidate(allInterviewsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Interview marked as completed'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelInterview(
      BuildContext context, WidgetRef ref, String interviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Interview?'),
        content: const Text(
            'Are you sure you want to cancel this interview?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel Interview'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(admissionRepositoryProvider);
        await repo.updateInterview(interviewId, {
          'status': InterviewStatus.cancelled.value,
        });
        ref.invalidate(allInterviewsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interview cancelled'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
