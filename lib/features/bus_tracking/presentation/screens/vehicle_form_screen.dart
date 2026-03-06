import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/bus_tracking_provider.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _helperNameController = TextEditingController();
  final _helperPhoneController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');
  final _gpsDeviceIdController = TextEditingController();

  String _vehicleType = 'bus';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleId != null) {
      _isEdit = true;
      _loadVehicle();
    }
  }

  Future<void> _loadVehicle() async {
    final repo = ref.read(busTrackingRepositoryProvider);
    final vehicle = await repo.getVehicleById(widget.vehicleId!);
    if (vehicle != null && mounted) {
      _vehicleNumberController.text = vehicle.vehicleNumber;
      _driverNameController.text = vehicle.driverName ?? '';
      _driverPhoneController.text = vehicle.driverPhone ?? '';
      _helperNameController.text = vehicle.helperName ?? '';
      _helperPhoneController.text = vehicle.helperPhone ?? '';
      _capacityController.text = vehicle.capacity.toString();
      _gpsDeviceIdController.text = vehicle.gpsDeviceId ?? '';
      setState(() {
        _vehicleType = vehicle.vehicleType;
        _isActive = vehicle.isActive;
      });
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _helperNameController.dispose();
    _helperPhoneController.dispose();
    _capacityController.dispose();
    _gpsDeviceIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(busTrackingRepositoryProvider);
      final data = {
        'vehicle_number': _vehicleNumberController.text.trim(),
        'vehicle_type': _vehicleType,
        'driver_name': _driverNameController.text.trim().isEmpty
            ? null
            : _driverNameController.text.trim(),
        'driver_phone': _driverPhoneController.text.trim().isEmpty
            ? null
            : _driverPhoneController.text.trim(),
        'helper_name': _helperNameController.text.trim().isEmpty
            ? null
            : _helperNameController.text.trim(),
        'helper_phone': _helperPhoneController.text.trim().isEmpty
            ? null
            : _helperPhoneController.text.trim(),
        'capacity': int.tryParse(_capacityController.text) ?? 40,
        'is_active': _isActive,
        'gps_device_id': _gpsDeviceIdController.text.trim().isEmpty
            ? null
            : _gpsDeviceIdController.text.trim(),
      };

      if (_isEdit) {
        await repo.updateVehicle(widget.vehicleId!, data);
      } else {
        await repo.createVehicle(data);
      }

      ref.invalidate(busVehiclesProvider(true));
      ref.invalidate(busVehiclesProvider(false));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Vehicle updated' : 'Vehicle added successfully'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Vehicle' : 'Add Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle info section
            Text(
              'VEHICLE INFORMATION',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vehicleNumberController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number *',
                hintText: 'e.g., KA-01-AB-1234',
                prefixIcon: Icon(Icons.directions_bus),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'bus', child: Text('Bus')),
                DropdownMenuItem(value: 'minibus', child: Text('Minibus')),
                DropdownMenuItem(value: 'van', child: Text('Van')),
              ],
              onChanged: (v) => setState(() => _vehicleType = v ?? 'bus'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Seating Capacity',
                prefixIcon: Icon(Icons.event_seat),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gpsDeviceIdController,
              decoration: const InputDecoration(
                labelText: 'GPS Device ID (optional)',
                hintText: 'Hardware tracker ID',
                prefixIcon: Icon(Icons.gps_fixed),
              ),
            ),

            const SizedBox(height: 24),

            // Driver section
            Text(
              'DRIVER DETAILS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverNameController,
              decoration: const InputDecoration(
                labelText: 'Driver Name',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _driverPhoneController,
              decoration: const InputDecoration(
                labelText: 'Driver Phone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // Helper section
            Text(
              'HELPER DETAILS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _helperNameController,
              decoration: const InputDecoration(
                labelText: 'Helper Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _helperPhoneController,
              decoration: const InputDecoration(
                labelText: 'Helper Phone',
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // Active toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Inactive vehicles are hidden from tracking'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),

            const SizedBox(height: 32),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Update Vehicle' : 'Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
