import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/admin_user_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/credential_generator.dart';
import '../../../../data/models/academic.dart';
import '../../../../data/models/student.dart';
import '../../../../data/repositories/student_repository.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../auth/providers/auth_provider.dart';

/// Bottom-sheet form for creating a new student account and profile.
///
/// On success, calls [onSuccess] with the generated email, password, and
/// student full name so the caller can show [CredentialDisplayDialog].
class AddStudentForm extends ConsumerStatefulWidget {
  final void Function(String email, String password, String studentName)
      onSuccess;

  const AddStudentForm({super.key, required this.onSuccess});

  @override
  ConsumerState<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends ConsumerState<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _admissionNumberController = TextEditingController();

  DateTime? _dateOfBirth;
  String _gender = 'Male';
  String? _selectedClassId;
  String? _selectedSectionId;
  bool _isSubmitting = false;
  String _tenantSlug = 'school';
  bool _passwordVisible = false;
  late String _generatedPassword;
  String _previewEmail = '';

  @override
  void initState() {
    super.initState();
    _generatedPassword = CredentialGenerator.generatePassword();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTenantSlug());
  }

  Future<void> _loadTenantSlug() async {
    final tenantId = _tenantId;
    if (tenantId.isEmpty) return;
    try {
      final data = await Supabase.instance.client
          .from('tenants')
          .select('slug')
          .eq('id', tenantId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => _tenantSlug = data['slug'] as String? ?? 'school');
      }
    } catch (_) {}
  }

  void _updatePreviewEmail() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() => _previewEmail = '');
      return;
    }
    setState(() => _previewEmail = CredentialGenerator.generateUsername(
          firstName: firstName,
          lastName: lastName.isEmpty ? 'student' : lastName,
          tenantSlug: _tenantSlug,
        ));
  }

  void _regeneratePassword() =>
      setState(() => _generatedPassword = CredentialGenerator.generatePassword());

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _admissionNumberController.dispose();
    super.dispose();
  }

  String get _tenantId {
    // Prefer the DB-loaded profile (always accurate) over JWT app_metadata
    // which may be stale or missing for newly created tenant_admin accounts.
    final fromProfile = ref.read(currentUserProvider)?.tenantId;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return Supabase.instance.client.auth.currentSession?.user
            .appMetadata['tenant_id'] as String? ??
        '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      _showError('Please select a date of birth.');
      return;
    }

    setState(() => _isSubmitting = true);

    final client = Supabase.instance.client;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    final email = _emailController.text.trim().isEmpty
        ? CredentialGenerator.generateUsername(
            firstName: firstName,
            lastName: lastName,
            tenantSlug: _tenantSlug,
          )
        : _emailController.text.trim();

    final password = _generatedPassword;
    final adminService = AdminUserService(client);
    String? createdUserId;

    try {
      // Step 1: create auth user
      final result = await adminService.createUser(
        email: email,
        password: password,
        fullName: fullName,
        tenantId: _tenantId,
        role: 'student',
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      createdUserId = result.userId;

      // Step 2: create student record
      final repo = StudentRepository(client);
      final admissionNumber = _admissionNumberController.text.trim().isEmpty
          ? _generateAdmissionNumber()
          : _admissionNumberController.text.trim();

      final studentData = <String, dynamic>{
        'user_id': createdUserId,
        'first_name': firstName,
        'last_name': lastName.isEmpty ? null : lastName,
        'email': email,
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'date_of_birth':
            DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'gender': _gender,
        'admission_number': admissionNumber,
        'admission_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'is_active': true,
      };

      final student = await repo.createStudent(studentData);

      // Step 3: enroll if section was selected
      if (_selectedSectionId != null) {
        await _enrollStudent(repo, student, _selectedSectionId!);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(email, password, fullName);
      }
    } catch (e) {
      // Rollback: delete orphaned auth user if student creation failed
      if (createdUserId != null) {
        await adminService.deleteUser(createdUserId);
      }
      if (mounted) {
        _showError('Failed to create student: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _enrollStudent(
    StudentRepository repo,
    Student student,
    String sectionId,
  ) async {
    final academicYearAsync = ref.read(currentAcademicYearProvider);
    final academicYear = academicYearAsync.valueOrNull;
    if (academicYear == null) return;

    await repo.enrollStudent(
      studentId: student.id,
      sectionId: sectionId,
      academicYearId: academicYear.id,
    );
  }

  String _generateAdmissionNumber() {
    final year = DateTime.now().year;
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'ADM$year$suffix';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(context),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNameRow(),
                    const SizedBox(height: 16),
                    _buildDobAndGenderRow(context),
                    const SizedBox(height: 16),
                    _buildOptionalFields(),
                    const SizedBox(height: 16),
                    _buildClassSectionRow(classesAsync),
                    const SizedBox(height: 24),
                    // ── Credentials preview ──────────────────────────────
                    if (_previewEmail.isNotEmpty) ...[
                      const Text(
                        'GENERATED CREDENTIALS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Save before submitting — password shown here only.',
                              style: TextStyle(fontSize: 11, color: Colors.orange),
                            ),
                            const SizedBox(height: 10),
                            _buildCredRow('Email', _previewEmail, null),
                            const SizedBox(height: 6),
                            _buildCredRow(
                              'Password',
                              _passwordVisible ? _generatedPassword : '••••••••••',
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _passwordVisible = !_passwordVisible),
                                    child: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _regeneratePassword,
                                    child: Icon(Icons.refresh,
                                        size: 16, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                          ClipboardData(text: _generatedPassword));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Password copied')));
                                    },
                                    child: Icon(Icons.copy,
                                        size: 16, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Add New Student',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _updatePreviewEmail(),
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
            onChanged: (_) => _updatePreviewEmail(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDobAndGenderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDobPicker(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildGenderDropdown()),
      ],
    );
  }

  Widget _buildDobPicker(BuildContext context) {
    return InkWell(
      onTap: () => _pickDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth *',
          border: const OutlineInputBorder(),
          errorText: _dateOfBirth == null && _isSubmitting ? 'Required' : null,
        ),
        child: Text(
          _dateOfBirth != null
              ? DateFormat('MMM d, yyyy').format(_dateOfBirth!)
              : 'Select date',
          style: _dateOfBirth == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
      ),
      items: ['Male', 'Female', 'Other']
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _gender = v);
      },
    );
  }

  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone (optional)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (optional — auto-generated if blank)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            return emailRegex.hasMatch(v.trim()) ? null : 'Invalid email';
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _admissionNumberController,
          decoration: const InputDecoration(
            labelText: 'Admission Number (optional — auto-generated)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildClassSectionRow(
      AsyncValue<List<SchoolClass>> classesAsync) {
    return classesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Could not load classes: $e'),
      data: (classes) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedClassId,
            decoration: const InputDecoration(
              labelText: 'Class (optional)',
              border: OutlineInputBorder(),
            ),
            items: classes
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedClassId = v;
              _selectedSectionId = null;
            }),
          ),
          if (_selectedClassId != null) ...[
            const SizedBox(height: 16),
            _SectionDropdown(
              classId: _selectedClassId!,
              value: _selectedSectionId,
              onChanged: (v) => setState(() => _selectedSectionId = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredRow(String label, String value, Widget? trailing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(48),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Create Student'),
    );
  }
}

/// Dropdown that loads sections for a given [classId].
class _SectionDropdown extends ConsumerWidget {
  final String classId;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _SectionDropdown({
    required this.classId,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsByClassProvider(classId));

    return sectionsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Could not load sections: $e'),
      data: (sections) => DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Section (optional)',
          border: OutlineInputBorder(),
        ),
        items: sections
            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
