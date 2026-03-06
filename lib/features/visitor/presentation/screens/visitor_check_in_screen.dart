import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/visitor_provider.dart';

class VisitorCheckInScreen extends ConsumerStatefulWidget {
  final String? preRegQrData;

  const VisitorCheckInScreen({super.key, this.preRegQrData});

  @override
  ConsumerState<VisitorCheckInScreen> createState() =>
      _VisitorCheckInScreenState();
}

class _VisitorCheckInScreenState
    extends ConsumerState<VisitorCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _badgeController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _itemsController = TextEditingController();
  final _departmentController = TextEditingController();
  final _notesController = TextEditingController();

  VisitorIdType? _selectedIdType;
  VisitorLogPurpose _selectedPurpose = VisitorLogPurpose.other;
  Visitor? _existingVisitor;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.preRegQrData != null) {
      _loadPreRegistration(widget.preRegQrData!);
    }
  }

  Future<void> _loadPreRegistration(String qrData) async {
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(visitorRepositoryProvider);
      final preReg = await repo.getPreRegistrationByQr(qrData);
      if (preReg != null && mounted) {
        _nameController.text = preReg.visitorName;
        _phoneController.text = preReg.visitorPhone ?? '';
        _emailController.text = preReg.visitorEmail ?? '';
        _selectedPurpose = preReg.purpose;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pre-registration: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final repo = ref.read(visitorRepositoryProvider);
      final visitor = await repo.getVisitorByPhone(phone);
      if (visitor != null && mounted) {
        setState(() {
          _existingVisitor = visitor;
          _nameController.text = visitor.fullName;
          _emailController.text = visitor.email ?? '';
          _companyController.text = visitor.company ?? '';
          _selectedIdType = visitor.idType;
          _idNumberController.text = visitor.idNumber ?? '';
        });

        if (visitor.isBlacklisted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'WARNING: This visitor is blacklisted!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // No visitor found, which is fine
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _checkIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(visitorRepositoryProvider);

      // Create or get visitor
      String visitorId;
      if (_existingVisitor != null) {
        visitorId = _existingVisitor!.id;

        if (_existingVisitor!.isBlacklisted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot check in a blacklisted visitor'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        final visitorData = {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'company': _companyController.text.trim().isEmpty
              ? null
              : _companyController.text.trim(),
          'id_type': _selectedIdType?.value,
          'id_number': _idNumberController.text.trim().isEmpty
              ? null
              : _idNumberController.text.trim(),
        };
        final visitor = await repo.createVisitor(visitorData);
        visitorId = visitor.id;
      }

      // Create visitor log
      final logData = {
        'visitor_id': visitorId,
        'purpose': _selectedPurpose.value,
        'department': _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        'badge_number': _badgeController.text.trim().isEmpty
            ? null
            : _badgeController.text.trim(),
        'vehicle_number': _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
        'items_carried': _itemsController.text.trim().isEmpty
            ? null
            : _itemsController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      await ref
          .read(visitorLogNotifierProvider.notifier)
          .checkIn(logData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor checked in successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(visitorStatsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _idNumberController.dispose();
    _badgeController.dispose();
    _vehicleController.dispose();
    _itemsController.dispose();
    _departmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In Visitor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Phone search
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Existing Visitor',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                            hintText: 'Enter phone to search',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchByPhone,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                  if (_existingVisitor != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _existingVisitor!.isBlacklisted
                            ? AppColors.errorLight
                            : AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _existingVisitor!.isBlacklisted
                                ? Icons.warning
                                : Icons.check_circle,
                            color: _existingVisitor!.isBlacklisted
                                ? AppColors.error
                                : AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _existingVisitor!.isBlacklisted
                                ? 'BLACKLISTED - ${_existingVisitor!.fullName}'
                                : 'Found: ${_existingVisitor!.fullName} (${_existingVisitor!.visitCount} visits)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Visitor details
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visitor Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Organization',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VisitorIdType>(
                    value: _selectedIdType,
                    decoration: const InputDecoration(
                      labelText: 'ID Type',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: VisitorIdType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedIdType = v),
                  ),
                  if (_selectedIdType != null) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idNumberController,
                      decoration: InputDecoration(
                        labelText: '${_selectedIdType!.label} Number',
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Visit details
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VisitorLogPurpose>(
                    value: _selectedPurpose,
                    decoration: const InputDecoration(
                      labelText: 'Purpose *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: VisitorLogPurpose.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedPurpose = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.domain),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _badgeController,
                    decoration: const InputDecoration(
                      labelText: 'Badge Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _itemsController,
                    decoration: const InputDecoration(
                      labelText: 'Items Carried',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _isLoading ? 'Checking in...' : 'Check In Visitor',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
