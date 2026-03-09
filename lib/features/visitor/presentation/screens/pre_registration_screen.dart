import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/visitor_provider.dart';

class PreRegistrationScreen extends ConsumerStatefulWidget {
  const PreRegistrationScreen({super.key});

  @override
  ConsumerState<PreRegistrationScreen> createState() =>
      _PreRegistrationScreenState();
}

class _PreRegistrationScreenState
    extends ConsumerState<PreRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Registration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'All'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Pre-Register'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayPreRegList(),
          _AllPreRegList(),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CreatePreRegForm(),
    );
  }
}

class _TodayPreRegList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preRegsAsync = ref.watch(todayPreRegistrationsProvider);
    return _PreRegListView(asyncValue: preRegsAsync);
  }
}

class _AllPreRegList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preRegsAsync = ref.watch(
        preRegistrationsProvider(const PreRegFilter(limit: 100)));
    return _PreRegListView(asyncValue: preRegsAsync);
  }
}

class _PreRegListView extends ConsumerWidget {
  final AsyncValue<List<VisitorPreRegistration>> asyncValue;

  const _PreRegListView({required this.asyncValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return asyncValue.when(
      data: (preRegs) {
        if (preRegs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No pre-registrations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: preRegs.length,
          itemBuilder: (context, index) {
            final preReg = preRegs[index];
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              onTap: () => _showQrDialog(context, preReg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        _statusColor(preReg.status).withValues(alpha: 0.1),
                    child: Icon(
                      _statusIcon(preReg.status),
                      color: _statusColor(preReg.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preReg.visitorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${preReg.purpose.label} | ${dateFormat.format(preReg.expectedDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        if (preReg.hostName != null)
                          Text(
                            'Host: ${preReg.hostName}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(preReg.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          preReg.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _statusColor(preReg.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.qr_code,
                          size: 20, color: AppColors.textTertiaryLight),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showQrDialog(
      BuildContext context, VisitorPreRegistration preReg) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Visitor QR Pass'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preReg.qrCodeData != null)
              QrImageView(
                data: preReg.qrCodeData!,
                size: 200,
              )
            else
              const Text('No QR code generated'),
            const SizedBox(height: 16),
            Text(
              preReg.visitorName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              preReg.purpose.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(VisitorPreRegStatus status) {
    switch (status) {
      case VisitorPreRegStatus.pending:
        return AppColors.warning;
      case VisitorPreRegStatus.approved:
        return AppColors.success;
      case VisitorPreRegStatus.denied:
        return AppColors.error;
      case VisitorPreRegStatus.completed:
        return AppColors.info;
    }
  }

  IconData _statusIcon(VisitorPreRegStatus status) {
    switch (status) {
      case VisitorPreRegStatus.pending:
        return Icons.schedule;
      case VisitorPreRegStatus.approved:
        return Icons.check_circle;
      case VisitorPreRegStatus.denied:
        return Icons.cancel;
      case VisitorPreRegStatus.completed:
        return Icons.done_all;
    }
  }
}

class _CreatePreRegForm extends ConsumerStatefulWidget {
  const _CreatePreRegForm();

  @override
  ConsumerState<_CreatePreRegForm> createState() =>
      _CreatePreRegFormState();
}

class _CreatePreRegFormState extends ConsumerState<_CreatePreRegForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  VisitorLogPurpose _purpose = VisitorLogPurpose.other;
  DateTime _expectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(visitorRepositoryProvider);
      await repo.createPreRegistration({
        'visitor_name': _nameController.text.trim(),
        'visitor_phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'visitor_email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'purpose': _purpose.value,
        'expected_date':
            _expectedDate.toIso8601String().split('T')[0],
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      ref.invalidate(todayPreRegistrationsProvider);
      ref.invalidate(visitorStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pre-registration created with QR pass'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pre-Register Visitor',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VisitorLogPurpose>(
                initialValue: _purpose,
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  prefixIcon: Icon(Icons.category),
                ),
                items: VisitorLogPurpose.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _purpose = v);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'Expected Date: ${dateFormat.format(_expectedDate)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expectedDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _expectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.event_available),
                  label: Text(_isLoading
                      ? 'Creating...'
                      : 'Create & Generate QR Pass'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
