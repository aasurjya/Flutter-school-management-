import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_photo_picker.dart';

/// First-login profile setup screen for parents.
///
/// Collects: photo, occupation, phone, address, relationship to child.
class ParentProfileSetupScreen extends ConsumerStatefulWidget {
  const ParentProfileSetupScreen({super.key});

  @override
  ConsumerState<ParentProfileSetupScreen> createState() =>
      _ParentProfileSetupScreenState();
}

class _ParentProfileSetupScreenState
    extends ConsumerState<ParentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _relation;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _occupationCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
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
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Update parents row linked to this user
      final parentRows = await supabase
          .from('parents')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if ((parentRows as List).isNotEmpty) {
        final parentId = parentRows.first['id'] as String;
        await supabase.from('parents').update({
          if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
          if (_occupationCtrl.text.isNotEmpty)
            'occupation': _occupationCtrl.text.trim(),
          if (_addressCtrl.text.isNotEmpty)
            'address': _addressCtrl.text.trim(),
          if (_relation != null) 'relation': _relation,
          if (_avatarUrl != null) 'photo_url': _avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', parentId);
      }

      await ref.read(authNotifierProvider.notifier).markProfileComplete();
      if (mounted) context.go(AppRoutes.parentDashboard);
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
                'Welcome, ${user?.fullName?.split(' ').first ?? 'Parent'}!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'A few details to complete your profile.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 28),

              Center(
                child: ProfilePhotoPicker(
                  currentUrl: user?.avatarUrl,
                  storagePathPrefix: 'parents/${user?.id ?? 'unknown'}',
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

              // Occupation
              TextFormField(
                controller: _occupationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  prefixIcon: Icon(Icons.work_outline),
                ),
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

              // Relation
              DropdownButtonFormField<String>(
                value: _relation,
                decoration: const InputDecoration(
                  labelText: 'Relationship to Child',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'father', child: Text('Father')),
                  DropdownMenuItem(value: 'mother', child: Text('Mother')),
                  DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _relation = v),
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
