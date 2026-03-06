import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  final String? assetId;

  const AssetFormScreen({super.key, this.assetId});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _vendorController = TextEditingController();
  final _locationController = TextEditingController();
  final _serialNumberController = TextEditingController();

  String? _selectedCategoryId;
  AssetStatus _status = AssetStatus.available;
  AssetCondition _condition = AssetCondition.good;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.assetId != null;
    if (_isEdit) {
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    final repo = ref.read(inventoryRepositoryProvider);
    final asset = await repo.getAssetById(widget.assetId!);
    if (asset != null && mounted) {
      setState(() {
        _assetCodeController.text = asset.assetCode;
        _nameController.text = asset.name;
        _descriptionController.text = asset.description ?? '';
        _purchasePriceController.text =
            asset.purchasePrice?.toStringAsFixed(2) ?? '';
        _currentValueController.text =
            asset.currentValue?.toStringAsFixed(2) ?? '';
        _vendorController.text = asset.vendor ?? '';
        _locationController.text = asset.location ?? '';
        _serialNumberController.text = asset.serialNumber ?? '';
        _selectedCategoryId = asset.categoryId;
        _status = asset.status;
        _condition = asset.condition;
        _purchaseDate = asset.purchaseDate;
        _warrantyExpiry = asset.warrantyExpiry;
      });
    }
  }

  @override
  void dispose() {
    _assetCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _vendorController.dispose();
    _locationController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(flatCategoriesProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Asset' : 'New Asset'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _assetCodeController,
                decoration: const InputDecoration(
                  labelText: 'Asset Code *',
                  hintText: 'e.g., AST-COMP-001',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) =>
                    v?.isEmpty == true ? 'Required' : null,
                enabled: !_isEdit,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Asset Name *',
                  hintText: 'e.g., Dell Laptop Latitude 5520',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) =>
                    v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category dropdown
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Select Category')),
                    ...categories.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading categories'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the asset',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _serialNumberController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 24),

              // Status and Condition
              Text(
                'Status & Condition',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AssetStatus>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: AssetStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<AssetCondition>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                      ),
                      items: AssetCondition.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _condition = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Room 201, Lab B',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Financial Details
              Text(
                'Financial Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        prefixText: '\u20B9 ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currentValueController,
                      decoration: const InputDecoration(
                        labelText: 'Current Value',
                        prefixText: '\u20B9 ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Purchase Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  _purchaseDate != null
                      ? 'Purchase Date: ${dateFormat.format(_purchaseDate!)}'
                      : 'Select Purchase Date',
                ),
                trailing: _purchaseDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _purchaseDate = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _purchaseDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _purchaseDate = date);
                  }
                },
              ),

              // Warranty Expiry
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security_outlined),
                title: Text(
                  _warrantyExpiry != null
                      ? 'Warranty Expiry: ${dateFormat.format(_warrantyExpiry!)}'
                      : 'Select Warranty Expiry',
                ),
                trailing: _warrantyExpiry != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _warrantyExpiry = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _warrantyExpiry ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2040),
                  );
                  if (date != null) {
                    setState(() => _warrantyExpiry = date);
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Vendor',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEdit ? Icons.save : Icons.add),
                label: Text(_isEdit ? 'Update Asset' : 'Create Asset'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final data = <String, dynamic>{
        'asset_code': _assetCodeController.text.trim(),
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'purchase_date':
            _purchaseDate?.toIso8601String().split('T')[0],
        'purchase_price': _purchasePriceController.text.isNotEmpty
            ? double.tryParse(_purchasePriceController.text)
            : null,
        'current_value': _currentValueController.text.isNotEmpty
            ? double.tryParse(_currentValueController.text)
            : null,
        'vendor': _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
        'warranty_expiry':
            _warrantyExpiry?.toIso8601String().split('T')[0],
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'status': _status.value,
        'condition': _condition.value,
        'serial_number': _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(),
      };

      if (_isEdit) {
        await repo.updateAsset(widget.assetId!, data);
      } else {
        await repo.createAsset(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Asset updated' : 'Asset created'),
          ),
        );
        ref.invalidate(assetsProvider);
        if (_isEdit) {
          ref.invalidate(assetByIdProvider(widget.assetId!));
        }
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
}
