import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/tenant_provider.dart';

class CreateTenantScreen extends ConsumerStatefulWidget {
  const CreateTenantScreen({super.key});

  @override
  ConsumerState<CreateTenantScreen> createState() => _CreateTenantScreenState();
}

class _CreateTenantScreenState extends ConsumerState<CreateTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form controllers
  final _schoolNameController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();

  String _selectedPlan = 'trial';
  String _selectedCountry = 'India';
  int _expectedStudents = 500;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _subdomainController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Tenant'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < 2)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Continue'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Tenant'),
                    ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('School Information'),
              subtitle: const Text('Basic details about the school'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildSchoolInfoStep(),
            ),
            Step(
              title: const Text('Admin Account'),
              subtitle: const Text('Primary administrator details'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildAdminStep(),
            ),
            Step(
              title: const Text('Subscription'),
              subtitle: const Text('Choose a plan'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildSubscriptionStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _schoolNameController,
          decoration: const InputDecoration(labelText: 'School Name *', border: OutlineInputBorder()),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          onChanged: (v) {
            // Auto-generate subdomain
            final subdomain = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').substring(0, v.length > 15 ? 15 : v.length);
            _subdomainController.text = subdomain;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _subdomainController,
          decoration: const InputDecoration(
            labelText: 'Subdomain *',
            border: OutlineInputBorder(),
            suffixText: '.schoolsaas.com',
          ),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (!RegExp(r'^[a-z0-9]+$').hasMatch(v!)) return 'Only lowercase letters and numbers';
            if (v.length < 3) return 'At least 3 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'School Email *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (!v!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'India', child: Text('India')),
            DropdownMenuItem(value: 'USA', child: Text('United States')),
            DropdownMenuItem(value: 'UK', child: Text('United Kingdom')),
            DropdownMenuItem(value: 'UAE', child: Text('UAE')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _selectedCountry = v!),
        ),
      ],
    );
  }

  Widget _buildAdminStep() {
    return Column(
      children: [
        const Text(
          'The admin account will have full access to manage this school.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _adminNameController,
          decoration: const InputDecoration(labelText: 'Admin Name *', border: OutlineInputBorder()),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _adminEmailController,
          decoration: const InputDecoration(labelText: 'Admin Email *', border: OutlineInputBorder(), helperText: 'Login credentials will be sent to this email'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (!v!.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _adminPhoneController,
          decoration: const InputDecoration(labelText: 'Admin Phone', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSubscriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expected Students', style: TextStyle(fontWeight: FontWeight.w500)),
        Slider(
          value: _expectedStudents.toDouble(),
          min: 100,
          max: 5000,
          divisions: 49,
          label: '$_expectedStudents students',
          onChanged: (v) => setState(() => _expectedStudents = v.toInt()),
        ),
        Text('$_expectedStudents students', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        const Text('Select Plan', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        _PlanCard(
          plan: 'trial',
          title: 'Free Trial',
          price: '₹0',
          duration: '14 days',
          features: const ['Up to 100 students', 'Basic features', 'Email support'],
          isSelected: _selectedPlan == 'trial',
          onTap: () => setState(() => _selectedPlan = 'trial'),
        ),
        _PlanCard(
          plan: 'basic',
          title: 'Basic',
          price: '₹5,000',
          duration: '/month',
          features: const ['Up to 500 students', 'All core features', 'Email support', 'Basic reports'],
          isSelected: _selectedPlan == 'basic',
          onTap: () => setState(() => _selectedPlan = 'basic'),
        ),
        _PlanCard(
          plan: 'pro',
          title: 'Pro',
          price: '₹15,000',
          duration: '/month',
          features: const ['Up to 2000 students', 'All features', 'Priority support', 'Advanced analytics', 'Custom branding'],
          isSelected: _selectedPlan == 'pro',
          recommended: true,
          onTap: () => setState(() => _selectedPlan = 'pro'),
        ),
        _PlanCard(
          plan: 'enterprise',
          title: 'Enterprise',
          price: 'Custom',
          duration: '',
          features: const ['Unlimited students', 'Dedicated support', 'Custom integrations', 'SLA guarantee', 'On-premise option'],
          isSelected: _selectedPlan == 'enterprise',
          onTap: () => setState(() => _selectedPlan = 'enterprise'),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _schoolNameController.text.isNotEmpty &&
            _subdomainController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      case 1:
        return _adminNameController.text.isNotEmpty &&
            _adminEmailController.text.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create tenant via repository
      final tenant = await ref.read(tenantsNotifierProvider.notifier).createTenant({
        'name': _schoolNameController.text.trim(),
        'slug': _subdomainController.text.trim().toLowerCase(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'country': _selectedCountry,
        'subscription_plan': _selectedPlan,
        'is_active': true,
      });

      // TODO: Create admin user for this tenant via Edge Function
      // await ref.read(tenantRepositoryProvider).createTenantAdmin(
      //   tenantId: tenant.id,
      //   email: _adminEmailController.text.trim(),
      //   fullName: _adminNameController.text.trim(),
      //   phone: _adminPhoneController.text.trim(),
      // );

      if (mounted) {
        setState(() => _isSubmitting = false);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 12),
                Text('Tenant Created!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('School: ${tenant.name}'),
                Text('URL: ${tenant.slug}.schoolsaas.com'),
                const SizedBox(height: 12),
                const Text('Note: Admin user creation requires Edge Function setup.', style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackBar('Error creating tenant: $e');
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String plan;
  final String title;
  final String price;
  final String duration;
  final List<String> features;
  final bool isSelected;
  final bool recommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.isSelected,
    this.recommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<String>(
                      value: plan,
                      groupValue: isSelected ? plan : '',
                      onChanged: (_) => onTap(),
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('$price$duration', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: features.take(3).map((f) => Text('• $f', style: TextStyle(fontSize: 11, color: Colors.grey[600]))).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (recommended)
                Positioned(
                  top: 0,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text('RECOMMENDED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
