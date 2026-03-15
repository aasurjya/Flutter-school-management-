import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_photo_picker.dart';

/// First-login profile setup screen for teachers.
///
/// Collects: photo, DOB, gender, phone, address, qualification,
/// experience years, and subjects taught.
class TeacherProfileSetupScreen extends ConsumerStatefulWidget {
  const TeacherProfileSetupScreen({super.key});

  @override
  ConsumerState<TeacherProfileSetupScreen> createState() =>
      _TeacherProfileSetupScreenState();
}

class _TeacherProfileSetupScreenState
    extends ConsumerState<TeacherProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _qualCtrl.dispose();
    _expCtrl.dispose();
    _subjectsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
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

      // Update the users table with photo/DOB/gender
      await supabase.from('users').update({
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
        if (_dob != null)
          'date_of_birth': _dob!.toIso8601String().split('T').first,
        if (_gender != null) 'gender': _gender,
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Find the staff row for this user and update it
      final staffRows = await supabase
          .from('staff')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if ((staffRows as List).isNotEmpty) {
        final staffId = staffRows.first['id'] as String;
        final staffRepo =
            StaffRepository(supabase);
        await staffRepo.updateStaff(staffId, {
          if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
          if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
          if (_qualCtrl.text.isNotEmpty) 'qualification': _qualCtrl.text.trim(),
          if (_expCtrl.text.isNotEmpty)
            'experience_years': int.tryParse(_expCtrl.text.trim()),
        });
      }

      await ref.read(authNotifierProvider.notifier).markProfileComplete();
      if (mounted) context.go(AppRoutes.teacherDashboard);
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
              // Header
              Text(
                'Welcome, ${user?.fullName?.split(' ').first ?? 'Teacher'}!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Please fill in your details to get started.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 28),

              // Photo
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
                  style: TextStyle(
                    color: _dob == null ? AppColors.grey500 : null,
                  ),
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
                  DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _gender = v),
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
              const SizedBox(height: 16),

              // Qualification
              TextFormField(
                controller: _qualCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qualification (e.g. B.Ed, M.Sc)',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Experience
              TextFormField(
                controller: _expCtrl,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Subjects taught
              TextFormField(
                controller: _subjectsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subjects Taught (comma-separated)',
                  prefixIcon: Icon(Icons.book_outlined),
                  hintText: 'e.g. Mathematics, Physics',
                ),
              ),
              const SizedBox(height: 32),

              // Save
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
