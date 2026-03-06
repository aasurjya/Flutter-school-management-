import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/admission_provider.dart';

/// Multi-step application form:
/// Step 0: Personal info
/// Step 1: Parent info
/// Step 2: Previous school
/// Step 3: Address
/// Step 4: Review & Submit
class ApplicationFormScreen extends ConsumerStatefulWidget {
  final String? inquiryId;

  const ApplicationFormScreen({super.key, this.inquiryId});

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  int _currentStep = 0;
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  bool _isSubmitting = false;

  // Step 0: Personal
  final _studentNameController = TextEditingController();
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 6));
  String _gender = 'Male';
  String? _applyingForClassId;
  String? _academicYearId;

  // Step 1: Parent
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _fatherEmailController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _motherEmailController = TextEditingController();
  final _motherOccupationController = TextEditingController();

  // Step 2: Previous school
  final _previousSchoolController = TextEditingController();
  final _previousClassController = TextEditingController();

  // Step 3: Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _fatherEmailController.dispose();
    _fatherOccupationController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _motherEmailController.dispose();
    _motherOccupationController.dispose();
    _previousSchoolController.dispose();
    _previousClassController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  static const _stepTitles = [
    'Personal Info',
    'Parent Info',
    'Previous School',
    'Address',
    'Review',
  ];

  bool _validateCurrentStep() {
    if (_currentStep < 4) {
      return _formKeys[_currentStep].currentState?.validate() ?? false;
    }
    return true;
  }

  void _nextStep() {
    if (_currentStep < 4 && _validateCurrentStep()) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit({bool asDraft = false}) async {
    if (!asDraft && _currentStep == 4) {
      // Validate all steps
      for (int i = 0; i < 4; i++) {
        if (!(_formKeys[i].currentState?.validate() ?? true)) {
          setState(() => _currentStep = i);
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'student_name': _studentNameController.text.trim(),
        'date_of_birth': _dateOfBirth.toIso8601String().split('T')[0],
        'gender': _gender,
        'applying_for_class_id': _applyingForClassId ?? '',
        'academic_year_id': _academicYearId ?? '',
        'previous_school': _previousSchoolController.text.trim().isNotEmpty
            ? _previousSchoolController.text.trim()
            : null,
        'previous_class': _previousClassController.text.trim().isNotEmpty
            ? _previousClassController.text.trim()
            : null,
        'parent_info': {
          'father_name': _fatherNameController.text.trim().isNotEmpty
              ? _fatherNameController.text.trim()
              : null,
          'father_phone': _fatherPhoneController.text.trim().isNotEmpty
              ? _fatherPhoneController.text.trim()
              : null,
          'father_email': _fatherEmailController.text.trim().isNotEmpty
              ? _fatherEmailController.text.trim()
              : null,
          'father_occupation': _fatherOccupationController.text.trim().isNotEmpty
              ? _fatherOccupationController.text.trim()
              : null,
          'mother_name': _motherNameController.text.trim().isNotEmpty
              ? _motherNameController.text.trim()
              : null,
          'mother_phone': _motherPhoneController.text.trim().isNotEmpty
              ? _motherPhoneController.text.trim()
              : null,
          'mother_email': _motherEmailController.text.trim().isNotEmpty
              ? _motherEmailController.text.trim()
              : null,
          'mother_occupation': _motherOccupationController.text.trim().isNotEmpty
              ? _motherOccupationController.text.trim()
              : null,
        },
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'city': _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        'state': _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        'pincode': _pincodeController.text.trim().isNotEmpty
            ? _pincodeController.text.trim()
            : null,
        'status': asDraft ? 'draft' : 'submitted',
      };

      if (widget.inquiryId != null) {
        data['inquiry_id'] = widget.inquiryId;
      }

      final notifier = ref.read(admissionNotifierProvider.notifier);
      await notifier.createApplication(data);
      ref.invalidate(currentAdmissionStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asDraft
                ? 'Application saved as draft'
                : 'Application submitted successfully'),
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Application'),
        actions: [
          if (_currentStep < 4)
            TextButton(
              onPressed: _isSubmitting ? null : () => _submit(asDraft: true),
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(theme),
          // Form content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildPersonalStep(),
                _buildParentStep(),
                _buildPreviousSchoolStep(),
                _buildAddressStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          // Navigation buttons
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(_stepTitles.length, (i) {
          final isActive = i == _currentStep;
          final isPast = i < _currentStep;
          final color = isActive || isPast
              ? AppColors.primary
              : AppColors.textTertiaryLight;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isPast ? AppColors.primary : AppColors.borderLight,
                        ),
                      ),
                    Container(
                      width: isActive ? 28 : 20,
                      height: isActive ? 28 : 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isPast ? color : Colors.transparent,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: isPast
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isActive ? Colors.white : color,
                                ),
                              ),
                      ),
                    ),
                    if (i < _stepTitles.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isPast ? AppColors.primary : AppColors.borderLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _stepTitles[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive || isPast
                        ? (theme.brightness == Brightness.dark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight)
                        : AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalStep() {
    return Form(
      key: _formKeys[0],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Full Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                // Date of birth
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake),
                  title: const Text('Date of Birth *'),
                  subtitle: Text(
                    '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _dateOfBirth = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _gender = v);
                  },
                ),
                const SizedBox(height: 16),
                // Class ID - In production this would use a provider to load classes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Applying for Class ID *',
                    prefixIcon: Icon(Icons.class_),
                    hintText: 'Enter class UUID',
                  ),
                  initialValue: _applyingForClassId,
                  onChanged: (v) => _applyingForClassId = v.trim(),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Academic Year ID *',
                    prefixIcon: Icon(Icons.calendar_month),
                    hintText: 'Enter academic year UUID',
                  ),
                  initialValue: _academicYearId,
                  onChanged: (v) => _academicYearId = v.trim(),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentStep() {
    return Form(
      key: _formKeys[1],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Father
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Father\'s Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fatherNameController,
                  decoration: const InputDecoration(
                    labelText: 'Father\'s Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fatherPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fatherEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fatherOccupationController,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mother
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mother\'s Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _motherNameController,
                  decoration: const InputDecoration(
                    labelText: 'Mother\'s Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motherPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motherEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motherOccupationController,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousSchoolStep() {
    return Form(
      key: _formKeys[2],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Previous School Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _previousSchoolController,
                  decoration: const InputDecoration(
                    labelText: 'Previous School Name',
                    prefixIcon: Icon(Icons.school),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _previousClassController,
                  decoration: const InputDecoration(
                    labelText: 'Previous Class / Grade',
                    prefixIcon: Icon(Icons.class_),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Leave blank if the student is applying for the first time.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return Form(
      key: _formKeys[3],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Residential Address',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: Icon(Icons.home),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    prefixIcon: Icon(Icons.pin_drop),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Application',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _reviewRow('Student Name', _studentNameController.text, isDark),
              _reviewRow('Date of Birth',
                  '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}', isDark),
              _reviewRow('Gender', _gender, isDark),
              const Divider(height: 24),
              if (_fatherNameController.text.isNotEmpty)
                _reviewRow('Father', _fatherNameController.text, isDark),
              if (_fatherPhoneController.text.isNotEmpty)
                _reviewRow('Father Phone', _fatherPhoneController.text, isDark),
              if (_motherNameController.text.isNotEmpty)
                _reviewRow('Mother', _motherNameController.text, isDark),
              if (_motherPhoneController.text.isNotEmpty)
                _reviewRow('Mother Phone', _motherPhoneController.text, isDark),
              const Divider(height: 24),
              if (_previousSchoolController.text.isNotEmpty)
                _reviewRow(
                    'Previous School', _previousSchoolController.text, isDark),
              if (_previousClassController.text.isNotEmpty)
                _reviewRow(
                    'Previous Class', _previousClassController.text, isDark),
              if (_addressController.text.isNotEmpty) ...[
                const Divider(height: 24),
                _reviewRow('Address',
                    [
                      _addressController.text,
                      _cityController.text,
                      _stateController.text,
                      _pincodeController.text,
                    ].where((s) => s.isNotEmpty).join(', '),
                    isDark),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please review all the information before submitting. You can go back to any step to make changes.',
                  style: TextStyle(fontSize: 13, color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : _currentStep < 4
                      ? _nextStep
                      : () => _submit(),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep < 4 ? 'Continue' : 'Submit Application'),
            ),
          ),
        ],
      ),
    );
  }
}
