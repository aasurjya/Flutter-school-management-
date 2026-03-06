import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';

class ExamSettingsScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamSettingsScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamSettingsScreen> createState() =>
      _ExamSettingsScreenState();
}

class _ExamSettingsScreenState extends ConsumerState<ExamSettingsScreen> {
  ExamSettings _settings = const ExamSettings();
  bool _loaded = false;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examAsync = ref.watch(onlineExamByIdProvider(widget.examId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Settings'),
        actions: [
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: examAsync.when(
        data: (exam) {
          if (exam == null) {
            return const Center(child: Text('Exam not found'));
          }
          if (!_loaded) {
            _settings = exam.settings;
            _startTime = exam.startTime;
            _endTime = exam.endTime;
            _loaded = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schedule section
                _SectionHeader(title: 'Schedule', icon: Icons.schedule),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DateTimePicker(
                          label: 'Start Time',
                          value: _startTime,
                          onChanged: (dt) =>
                              setState(() => _startTime = dt),
                        ),
                        const SizedBox(height: 16),
                        _DateTimePicker(
                          label: 'End Time',
                          value: _endTime,
                          onChanged: (dt) =>
                              setState(() => _endTime = dt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Question settings
                _SectionHeader(
                    title: 'Question Settings', icon: Icons.quiz_outlined),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Shuffle Questions'),
                        subtitle: const Text(
                            'Randomize question order for each student'),
                        value: _settings.shuffleQuestions,
                        onChanged: (v) => setState(() =>
                            _settings =
                                _settings.copyWith(shuffleQuestions: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Shuffle Options'),
                        subtitle: const Text(
                            'Randomize option order for MCQ questions'),
                        value: _settings.shuffleOptions,
                        onChanged: (v) => setState(() =>
                            _settings =
                                _settings.copyWith(shuffleOptions: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Result settings
                _SectionHeader(
                    title: 'Result Settings', icon: Icons.analytics_outlined),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Show Result Immediately'),
                        subtitle: const Text(
                            'Display score right after submission'),
                        value: _settings.showResultImmediately,
                        onChanged: (v) => setState(() => _settings =
                            _settings.copyWith(
                                showResultImmediately: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Allow Answer Review'),
                        subtitle: const Text(
                            'Let students review correct answers after submission'),
                        value: _settings.allowReview,
                        onChanged: (v) => setState(() =>
                            _settings =
                                _settings.copyWith(allowReview: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Attempt settings
                _SectionHeader(
                    title: 'Attempt Settings', icon: Icons.repeat),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Maximum Attempts'),
                            SizedBox(
                              width: 100,
                              child: DropdownButtonFormField<int>(
                                value: _settings.maxAttempts,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: [1, 2, 3, 5, 10]
                                    .map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Text('$v'),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() =>
                                    _settings = _settings.copyWith(
                                        maxAttempts: v ?? 1)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Negative Marking'),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: _settings
                                    .negativeMarkingValue
                                    .toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  suffixText: 'marks',
                                ),
                                onChanged: (v) => setState(() =>
                                    _settings = _settings.copyWith(
                                        negativeMarkingValue:
                                            double.tryParse(v) ?? 0)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Proctoring settings
                _SectionHeader(
                    title: 'Proctoring', icon: Icons.security_outlined),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Proctoring'),
                        subtitle: const Text(
                            'Track tab switches and flag suspicious activity'),
                        value: _settings.proctoringEnabled,
                        onChanged: (v) => setState(() => _settings =
                            _settings.copyWith(proctoringEnabled: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Fullscreen Required'),
                        subtitle: const Text(
                            'Require students to use fullscreen mode'),
                        value: _settings.fullscreenRequired,
                        onChanged: (v) => setState(() => _settings =
                            _settings.copyWith(fullscreenRequired: v)),
                      ),
                      if (_settings.proctoringEnabled) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tab Switch Limit'),
                              SizedBox(
                                width: 100,
                                child: DropdownButtonFormField<int>(
                                  value: _settings.tabSwitchLimit,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                  ),
                                  items: [0, 1, 2, 3, 5, 10]
                                      .map((v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(v == 0
                                                ? 'Unlimited'
                                                : '$v'),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() =>
                                      _settings = _settings.copyWith(
                                          tabSwitchLimit: v ?? 0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final repo = ref.read(onlineExamRepositoryProvider);
    try {
      await repo.updateExam(widget.examId, {
        'settings': _settings.toJson(),
        'start_time': _startTime?.toIso8601String(),
        'end_time': _endTime?.toIso8601String(),
      });
      ref.invalidate(onlineExamByIdProvider(widget.examId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  const _DateTimePicker({
    required this.label,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.day}/${value!.month}/${value!.year} ${value!.hour}:${value!.minute.toString().padLeft(2, '0')}'
        : 'Not set';

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: value != null
              ? TimeOfDay.fromDateTime(value!)
              : TimeOfDay.now(),
        );
        if (time == null) return;

        onChanged(DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 18),
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ),
        child: Text(display),
      ),
    );
  }
}
