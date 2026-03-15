import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_photo_picker.dart';

/// First-login profile setup screen for operational staff:
/// accountant, librarian, transport_manager, hostel_warden,
/// canteen_staff, receptionist.
class StaffProfileSetupScreen extends ConsumerStatefulWidget {
  const StaffProfileSetupScreen({super.key});

  @override
  ConsumerState<StaffProfileSetupScreen> createState() =>
      _StaffProfileSetupScreenState();
}

class _StaffProfileSetupScreenState
    extends ConsumerState<StaffProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  DateTime? _dob;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _dashboardRouteForRole(String? role) {
    switch (role) {
      case 'accountant':
        return AppRoutes.accountantDashboard;
      case 'librarian':
        return AppRoutes.librarianDashboard;
      case 'transport_manager':
        return AppRoutes.transportDashboard;
      case 'hostel_warden':
        return AppRoutes.hostelWardenDashboard;
      case 'canteen_staff':
        return AppRoutes.canteenStaffDashboard;
      case 'receptionist':
        return AppRoutes.receptionistDashboard;
      default:
        return AppRoutes.adminDashboard;
    }
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
        if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

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
          if (_addressCtrl.text.isNotEmpty)
            'address': _addressCtrl.text.trim(),
          if (_deptCtrl.text.isNotEmpty)
            'department': _deptCtrl.text.trim(),
          if (_dob != null)
            'date_of_birth': _dob!.toIso8601String().split('T').first,
        });
      }

      await ref.read(authNotifierProvider.notifier).markProfileComplete();
      if (mounted) {
        context.go(_dashboardRouteForRole(user.primaryRole));
      }
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
    final roleLabel = (user?.primaryRole ?? 'staff')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

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
                'Welcome, ${user?.fullName?.split(' ').first ?? roleLabel}!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Please fill in your details as $roleLabel.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 28),

              Center(
                child: ProfilePhotoPicker(
                  currentUrl: user?.avatarUrl,
                  storagePathPrefix: 'staff/${user?.id ?? 'unknown'}',
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

              // Department
              TextFormField(
                controller: _deptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
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
