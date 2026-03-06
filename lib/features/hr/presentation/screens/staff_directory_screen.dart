import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/hr_provider.dart';
import '../widgets/staff_card.dart';

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  ConsumerState<StaffDirectoryScreen> createState() =>
      _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  String _searchQuery = '';
  String? _selectedDepartment;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(
      staffContractsProvider(
          const StaffContractFilter(status: 'active')),
    );
    final departmentsAsync = ref.watch(departmentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search staff...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 12),
                // Department filter
                departmentsAsync.when(
                  data: (departments) => SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedDepartment == null,
                          onTap: () =>
                              setState(() => _selectedDepartment = null),
                        ),
                        ...departments.map((dept) => _FilterChip(
                              label: dept.name,
                              selected:
                                  _selectedDepartment == dept.id,
                              onTap: () => setState(
                                  () => _selectedDepartment = dept.id),
                            )),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: contractsAsync.when(
              data: (contracts) {
                var filtered = contracts;

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((c) {
                    final name =
                        (c.staffName ?? '').toLowerCase();
                    final empId =
                        (c.staffEmployeeId ?? '').toLowerCase();
                    return name.contains(_searchQuery) ||
                        empId.contains(_searchQuery);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No staff match your search'
                              : 'No staff found',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    staffContractsProvider(
                        const StaffContractFilter(status: 'active')),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contract = filtered[index];
                      return StaffCard(
                        name: contract.staffName ?? 'Unknown',
                        employeeId: contract.staffEmployeeId,
                        designation: contract.contractTypeDisplay,
                        onTap: () => context.push(
                            '/hr/staff-profile/${contract.staffId}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\u20B9${contract.netSalary.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              '/month',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withAlpha(30),
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}
