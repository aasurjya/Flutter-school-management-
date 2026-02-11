import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/tenant.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/tenant_provider.dart';

class TenantsListScreen extends ConsumerStatefulWidget {
  const TenantsListScreen({super.key});

  @override
  ConsumerState<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends ConsumerState<TenantsListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _planFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Load tenants on init
    Future.microtask(() => ref.read(tenantsNotifierProvider.notifier).loadTenants());
  }

  List<Tenant> _filterTenants(List<Tenant> tenants) {
    return tenants.where((t) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!t.name.toLowerCase().contains(query) &&
            !t.slug.toLowerCase().contains(query) &&
            !(t.email?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      if (_statusFilter != 'all') {
        if (_statusFilter == 'active' && !t.isActive) return false;
        if (_statusFilter == 'suspended' && t.isActive) return false;
      }
      if (_planFilter != 'all' && t.subscriptionPlan != _planFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tenantsNotifierProvider.notifier).loadTenants(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTenants,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: tenantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(tenantsNotifierProvider.notifier).loadTenants(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (tenants) {
                final filteredTenants = _filterTenants(tenants);
                if (filteredTenants.isEmpty) {
                  return const Center(child: Text('No tenants found'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(tenantsNotifierProvider.notifier).loadTenants(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTenants.length,
                    itemBuilder: (context, index) {
                      final tenant = filteredTenants[index];
                      return _TenantCard(
                        tenant: tenant,
                        onTap: () => context.push('/super-admin/tenants/${tenant.id}'),
                        onAction: (action) => _handleAction(action, tenant),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/super-admin/tenants/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Tenant'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tenants...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'trial', child: Text('Trial')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _planFilter,
                  decoration: InputDecoration(
                    labelText: 'Plan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Plans')),
                    DropdownMenuItem(value: 'trial', child: Text('Trial')),
                    DropdownMenuItem(value: 'basic', child: Text('Basic')),
                    DropdownMenuItem(value: 'pro', child: Text('Pro')),
                    DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
                  ],
                  onChanged: (v) => setState(() => _planFilter = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Tenant tenant) {
    switch (action) {
      case 'suspend':
        _showSuspendDialog(tenant);
        break;
      case 'activate':
        _activateTenant(tenant);
        break;
      case 'delete':
        _showDeleteDialog(tenant);
        break;
    }
  }

  void _showSuspendDialog(Tenant tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Tenant'),
        content: Text('Are you sure you want to suspend "${tenant.name}"? All users will lose access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(tenantsNotifierProvider.notifier).suspendTenant(tenant.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tenant suspended'), backgroundColor: AppColors.warning),
                  );
                }
              } catch (e) {
                if (mounted) {
                  context.showErrorSnackBar('Error: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateTenant(Tenant tenant) async {
    try {
      await ref.read(tenantsNotifierProvider.notifier).activateTenant(tenant.id);
      if (mounted) {
        context.showSuccessSnackBar('Tenant activated');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    }
  }

  void _showDeleteDialog(Tenant tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Text('Are you sure you want to permanently delete "${tenant.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(tenantsNotifierProvider.notifier).deleteTenant(tenant.id);
                if (mounted) {
                  context.showErrorSnackBar('Tenant deleted');
                }
              } catch (e) {
                if (mounted) {
                  context.showErrorSnackBar('Error: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportTenants() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting tenants...')));
  }
}

class _TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onTap;
  final Function(String) onAction;

  const _TenantCard({required this.tenant, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isActive = tenant.isActive;
    final isSuspended = !tenant.isActive;
    final status = isActive ? 'active' : 'suspended';
    final subscriptionEnd = tenant.subscriptionExpiresAt ?? DateTime.now().add(const Duration(days: 365));
    final isExpiringSoon = subscriptionEnd.difference(DateTime.now()).inDays <= 30;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                    child: Text(
                      tenant.name.substring(0, 1),
                      style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tenant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${tenant.slug}.schoolsaas.com', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      if (isSuspended)
                        const PopupMenuItem(value: 'activate', child: Row(children: [Icon(Icons.check_circle, size: 18, color: AppColors.success), SizedBox(width: 8), Text('Activate')]))
                      else
                        const PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.block, size: 18, color: AppColors.warning), SizedBox(width: 8), Text('Suspend')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(Icons.email, tenant.email ?? 'No email'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Plan: ${tenant.subscriptionPlan.toUpperCase()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 12, color: isExpiringSoon ? AppColors.warning : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${DateFormat('MMM d, yyyy').format(subscriptionEnd)}',
                    style: TextStyle(fontSize: 12, color: isExpiringSoon ? AppColors.warning : Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return AppColors.success;
      case 'trial': return AppColors.warning;
      case 'suspended': return AppColors.error;
      default: return Colors.grey;
    }
  }
}
