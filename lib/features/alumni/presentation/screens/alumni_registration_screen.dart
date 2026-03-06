import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../providers/alumni_provider.dart';

class AlumniRegistrationScreen extends ConsumerStatefulWidget {
  const AlumniRegistrationScreen({super.key});

  @override
  ConsumerState<AlumniRegistrationScreen> createState() =>
      _AlumniRegistrationScreenState();
}

class _AlumniRegistrationScreenState
    extends ConsumerState<AlumniRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _classNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();
  final _industryController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillController = TextEditingController();

  AlumniVisibility _visibility = AlumniVisibility.alumniOnly;
  bool _isMentor = false;
  List<String> _skills = [];
  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _graduationYearController.dispose();
    _classNameController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    _industryController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _linkedinController.dispose();
    _bioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Registration'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < 3)
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Next'),
                    )
                  else
                    FilledButton(
                      onPressed: _isSubmitting ? null : details.onStepContinue,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Register'),
                    ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Personal Info
            Step(
              title: const Text('Personal Info'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
            ),

            // Step 2: Academic Info
            Step(
              title: const Text('Academic Info'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _graduationYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Graduation Year *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school_outlined),
                      hintText: 'e.g., 2015',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final year = int.tryParse(v);
                      if (year == null || year < 1900 || year > 2030) {
                        return 'Enter a valid year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _classNameController,
                    decoration: const InputDecoration(
                      labelText: 'Class/Section',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_outlined),
                      hintText: 'e.g., 12-A Science',
                    ),
                  ),
                ],
              ),
            ),

            // Step 3: Career Info
            Step(
              title: const Text('Career'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Current Company',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _designationController,
                    decoration: const InputDecoration(
                      labelText: 'Current Designation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _industryController,
                    decoration: const InputDecoration(
                      labelText: 'Industry',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                      hintText: 'e.g., Technology, Finance, Healthcare',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkedinController,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ],
              ),
            ),

            // Step 4: Additional
            Step(
              title: const Text('Additional'),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Short Bio',
                      border: OutlineInputBorder(),
                      hintText: 'Tell us about yourself...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skillController,
                          decoration: const InputDecoration(
                            labelText: 'Add Skills',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (_skillController.text.isNotEmpty) {
                            setState(() {
                              _skills.add(_skillController.text.trim());
                              _skillController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (_skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _skills.map((s) {
                        return Chip(
                          label: Text(s),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _skills.remove(s)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AlumniVisibility>(
                    value: _visibility,
                    decoration: const InputDecoration(
                      labelText: 'Profile Visibility',
                      border: OutlineInputBorder(),
                    ),
                    items: AlumniVisibility.values
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.label),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _visibility = val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available as Mentor'),
                    subtitle: const Text(
                        'Open to mentoring current students'),
                    value: _isMentor,
                    onChanged: (val) =>
                        setState(() => _isMentor = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final year = int.tryParse(_graduationYearController.text);
    if (year == null) return;

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(alumniProfileNotifierProvider.notifier);
      await notifier.createProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': _phoneController.text.isEmpty
            ? null
            : _phoneController.text.trim(),
        'graduation_year': year,
        'class_name': _classNameController.text.isEmpty
            ? null
            : _classNameController.text.trim(),
        'current_company': _companyController.text.isEmpty
            ? null
            : _companyController.text.trim(),
        'current_designation': _designationController.text.isEmpty
            ? null
            : _designationController.text.trim(),
        'industry': _industryController.text.isEmpty
            ? null
            : _industryController.text.trim(),
        'location_city': _cityController.text.isEmpty
            ? null
            : _cityController.text.trim(),
        'location_country': _countryController.text.isEmpty
            ? null
            : _countryController.text.trim(),
        'linkedin_url': _linkedinController.text.isEmpty
            ? null
            : _linkedinController.text.trim(),
        'bio': _bioController.text.isEmpty
            ? null
            : _bioController.text.trim(),
        'skills': _skills,
        'is_mentor': _isMentor,
        'visibility': _visibility.value,
        'user_id': ref.read(alumniRepositoryProvider).currentUserId,
      });

      ref.invalidate(alumniStatsProvider);
      ref.invalidate(myAlumniProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome to the alumni network.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
