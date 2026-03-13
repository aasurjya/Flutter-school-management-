import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/admin_user_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/credential_generator.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import 'credential_display_dialog.dart';

/// Bottom sheet for creating a new staff member.
///
/// Flow:
///   1. Admin fills in name, email, phone, role.
///   2. On submit: generate credentials → call Edge Function to create auth user
///      → insert staff row → show CredentialDisplayDialog → invalidate list.
///   3. On any failure: rollback orphaned auth user (best-effort) and surface error.
class AddStaffSheet extends ConsumerStatefulWidget {
  const AddStaffSheet({super.key});

  @override
  ConsumerState<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  String _selectedRole = 'teacher';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;
    final canManageSchoolAdmins =
        primaryRole == 'principal' || primaryRole == 'super_admin';
    final canManagePrincipals = primaryRole == 'super_admin';
    final availableRoles = <(String, String)>[
      if (canManagePrincipals) ('super_admin', 'Platform Admin'),
      if (canManagePrincipals) ('principal', 'Principal'),
      if (canManageSchoolAdmins) ('tenant_admin', 'School Admin'),
      ('teacher', 'Teacher'),
      ('accountant', 'Accountant'),
      ('librarian', 'Librarian'),
      ('transport_manager', 'Transport Manager'),
      ('hostel_warden', 'Hostel Warden'),
      ('canteen_staff', 'Canteen Staff'),
      ('receptionist', 'Receptionist'),
    ];
    final effectiveSelectedRole = availableRoles.any(
      (role) => role.$1 == _selectedRole,
    )
        ? _selectedRole
        : 'teacher';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        helperText: 'Leave blank to auto-generate',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // auto-gen ok
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: effectiveSelectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        border: OutlineInputBorder(),
                      ),
                      items: availableRoles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role.$1,
                              child: Text(role.$2),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _selectedRole = v ?? 'teacher',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _designationController,
                      decoration: const InputDecoration(
                        labelText: 'Designation',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Senior Teacher',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Mathematics',
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Staff Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Login credentials will be generated and shown once.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Text(
            'Add New Staff',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;
    final canManageSchoolAdmins =
        primaryRole == 'principal' || primaryRole == 'super_admin';
    final canManagePrincipals = primaryRole == 'super_admin';
    final availableRoleKeys = <String>{
      if (canManagePrincipals) 'super_admin',
      if (canManagePrincipals) 'principal',
      if (canManageSchoolAdmins) 'tenant_admin',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'hostel_warden',
      'canteen_staff',
      'receptionist',
    };
    final selectedRole =
        availableRoleKeys.contains(_selectedRole) ? _selectedRole : 'teacher';

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone =
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final designation = _designationController.text.trim().isEmpty
        ? null
        : _designationController.text.trim();
    final department = _departmentController.text.trim().isEmpty
        ? null
        : _departmentController.text.trim();

    // Derive credentials.
    final supaClient = Supabase.instance.client;
    final tenantId = ref.read(currentUserProvider)?.tenantId ?? '';
    final tenantSlug =
        (supaClient.auth.currentUser?.appMetadata['tenant_slug'] as String?)
            ?? (tenantId.isNotEmpty ? tenantId.substring(0, 8) : 'school');

    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : CredentialGenerator.generateUsername(
            firstName: firstName,
            lastName: lastName,
            tenantSlug: tenantSlug,
          );
    final password = CredentialGenerator.generatePassword();

    if (tenantId.isEmpty) {
      context.showErrorSnackBar('Session error: tenant not found. Please log out and log in again.');
      return;
    }

    setState(() => _isSubmitting = true);

    String? createdUserId;
    try {
      // Step 1: Create auth user via Edge Function.
      final adminService = AdminUserService(supaClient);
      final result = await adminService.createUser(
        email: email,
        password: password,
        fullName: '$firstName $lastName',
        tenantId: tenantId,
        role: selectedRole,
        phone: phone,
      );
      createdUserId = result.userId;

      // Step 2: Insert staff row.
      final staffRepo = ref.read(staffRepositoryProvider);
      final newMember = await staffRepo.createStaff(
        userId: createdUserId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        designation: designation,
        department: department,
        role: selectedRole,
      );

      // Step 3: Prepend to the appropriate list in-memory.
      ref
          .read(staffNotifierProvider(_staffListRoleKey(selectedRole)).notifier)
          .addStaff(newMember);

      if (mounted) {
        // Close sheet first, then show dialog so scaffold context is valid.
        Navigator.of(context).pop();
        await CredentialDisplayDialog.show(
          context,
          fullName: newMember.fullName,
          email: email,
          password: password,
          role: selectedRole,
        );
      }
    } on AdminUserCreationException catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to create account: ${e.message}');
      }
    } catch (e) {
      // Attempt to roll back orphaned auth user if staff insert failed.
      if (createdUserId != null) {
        await AdminUserService(Supabase.instance.client)
            .deleteUser(createdUserId);
      }
      if (mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _staffListRoleKey(String role) {
    if (role == 'teacher') {
      return 'teacher';
    }
    if (role == 'super_admin' || role == 'tenant_admin' || role == 'principal') {
      return 'tenant_admin';
    }
    return 'other';
  }
}
