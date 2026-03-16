import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../providers/certificate_provider.dart';
import '../widgets/certificate_card.dart';

class CertificateListScreen extends ConsumerStatefulWidget {
  const CertificateListScreen({super.key});

  @override
  ConsumerState<CertificateListScreen> createState() =>
      _CertificateListScreenState();
}

class _CertificateListScreenState
    extends ConsumerState<CertificateListScreen> {
  final _searchController = TextEditingController();
  CertificateStatus? _statusFilter;
  CertificateType? _typeFilter;

  CertificateFilter get _currentFilter => CertificateFilter(
        status: _statusFilter,
        type: _typeFilter,
        search: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        limit: 100,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final certsAsync =
        ref.watch(issuedCertificatesProvider(_currentFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Certificates'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.issueCertificate),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search & filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by number or purpose...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _statusFilter == null,
                        onTap: () =>
                            setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Draft',
                        selected:
                            _statusFilter == CertificateStatus.draft,
                        color: AppColors.warning,
                        onTap: () => setState(() =>
                            _statusFilter = CertificateStatus.draft),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Issued',
                        selected:
                            _statusFilter == CertificateStatus.issued,
                        color: AppColors.success,
                        onTap: () => setState(() =>
                            _statusFilter = CertificateStatus.issued),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Revoked',
                        selected:
                            _statusFilter == CertificateStatus.revoked,
                        color: AppColors.error,
                        onTap: () => setState(() =>
                            _statusFilter = CertificateStatus.revoked),
                      ),
                      const SizedBox(width: 16),
                      // Type filters
                      PopupMenuButton<CertificateType?>(
                        onSelected: (v) =>
                            setState(() => _typeFilter = v),
                        child: Chip(
                          label: Text(
                            _typeFilter?.label ?? 'All Types',
                            style: theme.textTheme.labelSmall,
                          ),
                          avatar: const Icon(Icons.filter_list, size: 16),
                          deleteIcon: _typeFilter != null
                              ? const Icon(Icons.close, size: 14)
                              : null,
                          onDeleted: _typeFilter != null
                              ? () =>
                                  setState(() => _typeFilter = null)
                              : null,
                        ),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...CertificateType.values.map(
                            (t) => PopupMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: certsAsync.when(
              data: (certs) {
                if (certs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 64,
                            color: AppColors.textTertiaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No certificates found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: certs.length,
                  itemBuilder: (context, index) {
                    final cert = certs[index];
                    return CertificateCard(
                      certificate: cert,
                      onTap: () => context.push(
                        AppRoutes.certificatePreview
                            .replaceFirst(':certId', cert.id),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
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
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: selected ? chipColor : AppColors.textSecondaryLight,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
