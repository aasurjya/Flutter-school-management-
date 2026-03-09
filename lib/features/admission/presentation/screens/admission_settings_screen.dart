import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/admission_provider.dart';

class AdmissionSettingsScreen extends ConsumerStatefulWidget {
  const AdmissionSettingsScreen({super.key});

  @override
  ConsumerState<AdmissionSettingsScreen> createState() =>
      _AdmissionSettingsScreenState();
}

class _AdmissionSettingsScreenState
    extends ConsumerState<AdmissionSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(allAdmissionSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admission Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (settings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings,
                      size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 16),
                  Text(
                    'No admission settings configured',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add settings for each class to configure seats and dates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSettingsDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Settings'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allAdmissionSettingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: settings.length,
              itemBuilder: (context, index) {
                return _buildSettingsCard(
                    context, ref, settings[index], isDark);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSettingsDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref,
      AdmissionSettings settings, bool isDark) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final capacityPercent = settings.totalSeats > 0
        ? settings.filledSeats / settings.totalSeats
        : 0.0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.className ?? 'Class N/A',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      settings.academicYearName ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: settings.admissionOpen
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      settings.admissionOpen ? Icons.lock_open : Icons.lock,
                      size: 14,
                      color: settings.admissionOpen
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      settings.admissionOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: settings.admissionOpen
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seat capacity bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seats',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '${settings.filledSeats} / ${settings.totalSeats}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: capacityPercent,
                        minHeight: 8,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          capacityPercent >= 0.9
                              ? AppColors.error
                              : capacityPercent >= 0.7
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    '${settings.availableSeats}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'Available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _detailChip(Icons.people_outline,
                  'Waitlist: ${settings.waitlistLimit}', isDark),
              if (settings.applicationFee > 0)
                _detailChip(
                    Icons.currency_rupee,
                    'Fee: ${settings.applicationFee.toStringAsFixed(0)}',
                    isDark),
              if (settings.openDate != null)
                _detailChip(Icons.event,
                    'Opens: ${dateFormat.format(settings.openDate!)}', isDark),
              if (settings.closeDate != null)
                _detailChip(Icons.event_busy,
                    'Closes: ${dateFormat.format(settings.closeDate!)}', isDark),
            ],
          ),
          const SizedBox(height: 12),

          // Required documents
          if (settings.documentsRequired.isNotEmpty) ...[
            Text(
              'Required Documents:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: settings.documentsRequired.map((doc) {
                return Chip(
                  label: Text(
                    AdmissionDocumentType.fromString(doc).label,
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () =>
                    _showEditSettingsDialog(context, ref, settings),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _toggleAdmissionOpen(context, ref, settings),
                icon: Icon(
                  settings.admissionOpen ? Icons.lock : Icons.lock_open,
                  size: 16,
                ),
                label: Text(
                    settings.admissionOpen ? 'Close' : 'Open'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiaryLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  void _showAddSettingsDialog(BuildContext context, WidgetRef ref) {
    _showSettingsForm(context, ref, null);
  }

  void _showEditSettingsDialog(
      BuildContext context, WidgetRef ref, AdmissionSettings existing) {
    _showSettingsForm(context, ref, existing);
  }

  void _showSettingsForm(
      BuildContext context, WidgetRef ref, AdmissionSettings? existing) {
    final classIdController =
        TextEditingController(text: existing?.classId ?? '');
    final yearIdController =
        TextEditingController(text: existing?.academicYearId ?? '');
    final seatsController =
        TextEditingController(text: '${existing?.totalSeats ?? 40}');
    final waitlistController =
        TextEditingController(text: '${existing?.waitlistLimit ?? 10}');
    final feeController = TextEditingController(
        text: '${existing?.applicationFee.toStringAsFixed(0) ?? 0}');
    bool admissionOpen = existing?.admissionOpen ?? false;
    DateTime? openDate = existing?.openDate;
    DateTime? closeDate = existing?.closeDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              existing != null ? 'Edit Settings' : 'Add Admission Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing == null) ...[
                  TextField(
                    controller: classIdController,
                    decoration: const InputDecoration(
                      labelText: 'Class ID *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearIdController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year ID *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: seatsController,
                  decoration: const InputDecoration(
                    labelText: 'Total Seats',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: waitlistController,
                  decoration: const InputDecoration(
                    labelText: 'Waitlist Limit',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  decoration: const InputDecoration(
                    labelText: 'Application Fee',
                    border: OutlineInputBorder(),
                    prefixText: '\u20B9 ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Admission Open'),
                  value: admissionOpen,
                  onChanged: (v) =>
                      setDialogState(() => admissionOpen = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, size: 20),
                  title: Text(openDate != null
                      ? 'Open: ${DateFormat('dd/MM/yyyy').format(openDate!)}'
                      : 'Set open date'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: openDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setDialogState(() => openDate = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_busy, size: 20),
                  title: Text(closeDate != null
                      ? 'Close: ${DateFormat('dd/MM/yyyy').format(closeDate!)}'
                      : 'Set close date'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: closeDate ??
                          (openDate ?? DateTime.now())
                              .add(const Duration(days: 30)),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setDialogState(() => closeDate = d);
                  },
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
                  await repo.createOrUpdateSettings({
                    if (existing != null) 'id': existing.id,
                    'class_id': existing?.classId ??
                        classIdController.text.trim(),
                    'academic_year_id': existing?.academicYearId ??
                        yearIdController.text.trim(),
                    'total_seats': int.tryParse(seatsController.text) ?? 40,
                    'filled_seats': existing?.filledSeats ?? 0,
                    'waitlist_limit':
                        int.tryParse(waitlistController.text) ?? 10,
                    'application_fee':
                        double.tryParse(feeController.text) ?? 0,
                    'admission_open': admissionOpen,
                    'open_date':
                        openDate?.toIso8601String().split('T')[0],
                    'close_date':
                        closeDate?.toIso8601String().split('T')[0],
                  });
                  ref.invalidate(allAdmissionSettingsProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAdmissionOpen(
      BuildContext context, WidgetRef ref, AdmissionSettings settings) async {
    try {
      final repo = ref.read(admissionRepositoryProvider);
      await repo.createOrUpdateSettings({
        ...settings.toJson(),
        'admission_open': !settings.admissionOpen,
      });
      ref.invalidate(allAdmissionSettingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(settings.admissionOpen
                ? 'Admissions closed'
                : 'Admissions opened'),
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
  }
}
