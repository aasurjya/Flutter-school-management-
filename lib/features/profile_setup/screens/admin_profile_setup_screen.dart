import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_photo_picker.dart';

/// First-login profile setup screen for tenant_admin and principal.
class AdminProfileSetupScreen extends ConsumerStatefulWidget {
  const AdminProfileSetupScreen({super.key});

  @override
  ConsumerState<AdminProfileSetupScreen> createState() =>
      _AdminProfileSetupScreenState();
}

class _AdminProfileSetupScreenState
    extends ConsumerState<AdminProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  DateTime? _dob;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _desigCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1975),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final supabase = Supabase.instance.client;

      await supabase.from('users').update({
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
        if (_dob != null)
          'date_of_birth': _dob!.toIso8601String().split('T').first,
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Update staff row if one exists
      final staffRows = await supabase
          .from('staff')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if ((staffRows as List).isNotEmpty) {
        final staffId = staffRows.first['id'] as String;
        final staffRepo = StaffRepository(supabase);
        await staffRepo.updateStaff(staffId, {
          if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
          if (_desigCtrl.text.isNotEmpty)
            'designation': _desigCtrl.text.trim(),
          if (_dob != null)
            'date_of_birth': _dob!.toIso8601String().split('T').first,
        });
      }

      await ref.read(authNotifierProvider.notifier).markProfileComplete();
      if (mounted) context.go(AppRoutes.adminDashboard);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome, ${user?.fullName?.split(' ').first ?? 'Admin'}!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete your administrator profile.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 28),

              Center(
                child: ProfilePhotoPicker(
                  currentUrl: user?.avatarUrl,
                  storagePathPrefix: 'admins/${user?.id ?? 'unknown'}',
                  onUploaded: (url) => setState(() => _avatarUrl = url),
                ),
              ),
              const SizedBox(height: 28),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),

              // DOB
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: Text(
                  _dob == null
                      ? 'Date of Birth'
                      : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                  style:
                      TextStyle(color: _dob == null ? AppColors.grey500 : null),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Designation
              TextFormField(
                controller: _desigCtrl,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'e.g. Principal, Vice Principal',
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Short Bio (optional)',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primary,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save & Continue',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
