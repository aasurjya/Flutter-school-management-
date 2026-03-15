import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_photo_picker.dart';

/// First-login profile setup screen for students.
///
/// Collects: photo, DOB, gender, blood group, address,
/// medical conditions, emergency contact name + phone.
class StudentProfileSetupScreen extends ConsumerStatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  ConsumerState<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState
    extends ConsumerState<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _medCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;
  String? _avatarUrl;
  bool _saving = false;

  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void dispose() {
    _addressCtrl.dispose();
    _medCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2008),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
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

      // Update users table
      await supabase.from('users').update({
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
        if (_dob != null)
          'date_of_birth': _dob!.toIso8601String().split('T').first,
        if (_gender != null) 'gender': _gender,
        if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Update students table
      final studentRows = await supabase
          .from('students')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if ((studentRows as List).isNotEmpty) {
        final studentId = studentRows.first['id'] as String;
        await supabase.from('students').update({
          if (_dob != null)
            'date_of_birth': _dob!.toIso8601String().split('T').first,
          if (_gender != null) 'gender': _gender,
          if (_bloodGroup != null) 'blood_group': _bloodGroup,
          if (_addressCtrl.text.isNotEmpty)
            'address': _addressCtrl.text.trim(),
          if (_medCtrl.text.isNotEmpty)
            'medical_conditions': _medCtrl.text.trim(),
          if (_emergencyNameCtrl.text.isNotEmpty)
            'emergency_contact_name': _emergencyNameCtrl.text.trim(),
          if (_emergencyPhoneCtrl.text.isNotEmpty)
            'emergency_contact_phone': _emergencyPhoneCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', studentId);
      }

      await ref.read(authNotifierProvider.notifier).markProfileComplete();
      if (mounted) context.go(AppRoutes.studentDashboard);
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
                'Hi, ${user?.fullName?.split(' ').first ?? 'Student'}!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Tell us a bit about yourself to get started.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 28),

              Center(
                child: ProfilePhotoPicker(
                  currentUrl: user?.avatarUrl,
                  storagePathPrefix: 'students/${user?.id ?? 'unknown'}',
                  onUploaded: (url) => setState(() => _avatarUrl = url),
                ),
              ),
              const SizedBox(height: 28),

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

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 16),

              // Blood Group
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                items: _bloodGroups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodGroup = v),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Home Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Medical conditions
              TextFormField(
                controller: _medCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medical Conditions / Allergies (optional)',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              Text('Emergency Contact',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emergencyNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  prefixIcon: Icon(Icons.contact_emergency_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
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
