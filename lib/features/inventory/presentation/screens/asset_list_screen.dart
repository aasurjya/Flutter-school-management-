import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/inventory_register_pdf_builder.dart';
import '../widgets/asset_card.dart';
import '../../../../core/copy/warm_strings.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  String? _selectedCategory;
  String? _selectedStatus;
  String? _selectedLocation;
  String _searchQuery = '';
  bool _isGridView = true;
  bool _isExporting = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportRegisterPdf(List<Asset> assets) async {
    if (assets.isEmpty) {
      context.showErrorSnackBar('No assets match the current filters');
      return;
    }
    setState(() => _isExporting = true);
    try {
      final bytes = await InventoryRegisterPdfBuilder.build(
        assets: assets,
      );
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name:
            'asset-register-${DateTime.now().toIso8601String().split('T')[0]}.pdf',
      );
      if (mounted) {
        context.showSuccessSnackBar(
            'Exported ${assets.length} assets to PDF');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(WarmCopy.genericError);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  AssetFilter get _currentFilter => AssetFilter(
        categoryId: _selectedCategory,
        status: _selectedStatus,
        location: _selectedLocation,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider(_currentFilter));
    final categoriesAsync = ref.watch(flatCategoriesProvider);
    final locationsAsync = ref.watch(assetLocationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Asset',
            onPressed: () => context.push('/inventory/scan'),
          ),
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export Asset Register (PDF)',
                  onPressed: () {
                    final currentAssets =
                        assetsAsync.asData?.value ?? const <Asset>[];
                    _exportRegisterPdf(currentAssets);
                  },
                ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or serial...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.inputFillLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Status filter
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedStatus != null
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                        color: _selectedStatus != null
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : null,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        hint: const Text('Status'),
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Status')),
                          ...AssetStatus.values.map(
                            (s) => DropdownMenuItem(
                              value: s.value,
                              child: Text(s.label),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value),
                      ),
                    ),
                  ),
                ),

                // Category filter
                categoriesAsync.when(
                  data: (categories) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButtonHideUnderline(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedCategory != null
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                          color: _selectedCategory != null
                              ? AppColors.primary
                                  .withValues(alpha: 0.08)
                              : null,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Category'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All Categories')),
                            ...categories.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedCategory = value),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Location filter
                locationsAsync.when(
                  data: (locations) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButtonHideUnderline(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedLocation != null
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                          color: _selectedLocation != null
                              ? AppColors.primary
                                  .withValues(alpha: 0.08)
                              : null,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedLocation,
                          hint: const Text('Location'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All Locations')),
                            ...locations.map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(l),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedLocation = value),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Clear all filters
                if (_selectedStatus != null ||
                    _selectedCategory != null ||
                    _selectedLocation != null)
                  ActionChip(
                    label: const Text('Clear All'),
                    avatar: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() {
                      _selectedStatus = null;
                      _selectedCategory = null;
                      _selectedLocation = null;
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Asset list/grid
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No assets found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first asset or adjust filters',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      return AssetCard(
                        asset: assets[index],
                        onTap: () => context
                            .push('/inventory/assets/${assets[index].id}'),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    return AssetListTile(
                      asset: assets[index],
                      onTap: () => context
                          .push('/inventory/assets/${assets[index].id}'),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(WarmCopy.genericError)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/assets/form'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
