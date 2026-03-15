import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/admin_user_service.dart';
import '../../../../core/services/credential_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/credential_generator.dart';
import '../../../../data/repositories/staff_repository.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../admin/presentation/widgets/credential_display_dialog.dart';
import '../../providers/tenant_provider.dart';
import '../widgets/user_profile_detail_sheet.dart' as profile_sheet;

// ─── Role meta ────────────────────────────────────────────────────────────────

class _RoleMeta {
  final String role;
  final String label;
  final IconData icon;
  final Color color;
  const _RoleMeta(this.role, this.label, this.icon, this.color);
}

const _creatableRoles = [
  _RoleMeta('teacher', 'Teacher', Icons.school_outlined, Color(0xFF6366F1)),
  _RoleMeta('student', 'Student', Icons.person_outlined, Color(0xFF3B82F6)),
  _RoleMeta('parent', 'Parent', Icons.family_restroom_outlined, Color(0xFFF59E0B)),
  _RoleMeta('tenant_admin', 'Admin', Icons.admin_panel_settings_outlined, Color(0xFFEF4444)),
  _RoleMeta('accountant', 'Accountant', Icons.account_balance_outlined, Color(0xFF10B981)),
  _RoleMeta('librarian', 'Librarian', Icons.menu_book_outlined, Color(0xFF8B5CF6)),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TenantDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantByIdProvider(widget.tenantId));

    return tenantAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Tenant Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tenantByIdProvider(widget.tenantId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (tenant) {
        if (tenant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tenant')),
            body: const Center(child: Text('School not found')),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (a) => _handleAction(a, tenant.isActive),
                    itemBuilder: (_) => [
                      if (tenant.isActive)
                        const PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.block, size: 18, color: AppColors.warning), SizedBox(width: 8), Text('Suspend')]))
                      else
                        const PopupMenuItem(value: 'activate', child: Row(children: [Icon(Icons.check_circle, size: 18, color: AppColors.success), SizedBox(width: 8), Text('Activate')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.grey800],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 80, 56),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  tenant.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tenant.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tenant.slug}.schoolsaas.com',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  _StatusBadge(isActive: tenant.isActive),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Users'),
                    Tab(text: 'Billing'),
                    Tab(text: 'Settings'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(tenantId: widget.tenantId, tenant: tenant),
                _UsersTab(tenantId: widget.tenantId, tenantSlug: tenant.slug),
                _BillingTab(tenant: tenant),
                _SettingsTab(onDelete: () => _handleAction('delete', true)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAction(String action, bool isActive) {
    switch (action) {
      case 'suspend':
        _confirm('Suspend Tenant', 'Users will not be able to log in.', AppColors.warning, () async {
          await ref.read(tenantsNotifierProvider.notifier).suspendTenant(widget.tenantId);
          ref.invalidate(tenantByIdProvider(widget.tenantId));
          if (mounted) _snack('Tenant suspended');
        });
      case 'activate':
        _confirm('Activate Tenant', 'Restore access for all users?', AppColors.success, () async {
          await ref.read(tenantsNotifierProvider.notifier).activateTenant(widget.tenantId);
          ref.invalidate(tenantByIdProvider(widget.tenantId));
          if (mounted) _snack('Tenant activated');
        });
      case 'delete':
        _confirm('Delete Tenant', 'This permanently deletes all data. Cannot be undone.', AppColors.error, () async {
          await ref.read(tenantsNotifierProvider.notifier).deleteTenant(widget.tenantId);
          if (mounted) {
            context.pop();
            _snack('Tenant deleted');
          }
        });
    }
  }

  void _confirm(String title, String msg, Color color, Future<void> Function() onOk) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(ctx); onOk(); },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF10B981) : AppColors.error, width: 1),
      ),
      child: Text(
        isActive ? 'Active' : 'Suspended',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? const Color(0xFF10B981) : AppColors.error,
        ),
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final String tenantId;
  final dynamic tenant;
  const _OverviewTab({required this.tenantId, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(tenantStatsProvider(tenantId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsAsync.when(
            loading: () => const _StatsRowLoading(),
            error: (e, _) => _ErrorCard(message: 'Stats: $e', onRetry: () => ref.invalidate(tenantStatsProvider(tenantId))),
            data: (stats) => Row(
              children: [
                Expanded(child: _StatCard(label: 'Students', value: '${stats['students'] ?? 0}', icon: Icons.person_outlined, color: const Color(0xFF3B82F6))),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Teachers', value: '${stats['teachers'] ?? 0}', icon: Icons.school_outlined, color: const Color(0xFF6366F1))),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Parents', value: '${stats['parents'] ?? 0}', icon: Icons.family_restroom_outlined, color: const Color(0xFFF59E0B))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: tenant.email ?? 'Not set'),
                _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: tenant.phone ?? 'Not set'),
                _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: tenant.fullAddress.isNotEmpty ? tenant.fullAddress : 'Not set'),
                _InfoRow(icon: Icons.calendar_today_outlined, label: 'Created', value: DateFormat('MMM d, yyyy').format(tenant.createdAt)),
                _InfoRow(icon: Icons.language_outlined, label: 'Timezone', value: tenant.timezone, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Subscription', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.card_membership_outlined, label: 'Plan', value: tenant.subscriptionPlan.toUpperCase()),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Expires',
                  value: tenant.subscriptionExpiresAt != null
                      ? DateFormat('MMM d, yyyy').format(tenant.subscriptionExpiresAt!)
                      : 'No expiry',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Users tab ────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerStatefulWidget {
  final String tenantId;
  final String tenantSlug;
  const _UsersTab({required this.tenantId, required this.tenantSlug});

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(tenantStatsProvider(widget.tenantId));
    final usersAsync = ref.watch(tenantUsersProvider(widget.tenantId));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            // Role summary cards
            statsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => _ErrorCard(message: 'Stats: $e', onRetry: () => ref.invalidate(tenantStatsProvider(widget.tenantId))),
              data: (stats) => Column(
                children: [
                  _RoleCard(
                    meta: const _RoleMeta('tenant_admin', 'Administrators', Icons.admin_panel_settings_outlined, Color(0xFFEF4444)),
                    count: stats['admins'] ?? 0,
                    onAdd: () => _showCreateUserSheet(const _RoleMeta('tenant_admin', 'Admin', Icons.admin_panel_settings_outlined, Color(0xFFEF4444))),
                  ),
                  _RoleCard(
                    meta: const _RoleMeta('teacher', 'Teachers', Icons.school_outlined, Color(0xFF6366F1)),
                    count: stats['teachers'] ?? 0,
                    onAdd: () => _showCreateUserSheet(const _RoleMeta('teacher', 'Teacher', Icons.school_outlined, Color(0xFF6366F1))),
                  ),
                  _RoleCard(
                    meta: const _RoleMeta('student', 'Students', Icons.person_outlined, Color(0xFF3B82F6)),
                    count: stats['students'] ?? 0,
                    onAdd: () => _showCreateUserSheet(const _RoleMeta('student', 'Student', Icons.person_outlined, Color(0xFF3B82F6))),
                  ),
                  _RoleCard(
                    meta: const _RoleMeta('parent', 'Parents', Icons.family_restroom_outlined, Color(0xFFF59E0B)),
                    count: stats['parents'] ?? 0,
                    onAdd: () => _showCreateUserSheet(const _RoleMeta('parent', 'Parent', Icons.family_restroom_outlined, Color(0xFFF59E0B))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recent users list
            const Text('Recent Users', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            usersAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => _ErrorCard(message: 'Users: $e', onRetry: () => ref.invalidate(tenantUsersProvider(widget.tenantId))),
              data: (users) {
                if (users.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No users yet', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Tap + to add your first user', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: users.map((u) => _UserListItem(user: u)).toList(),
                );
              },
            ),
          ],
        ),

        // FAB - Add user
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _isCreating ? null : _showRolePickerSheet,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: _isCreating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add_outlined),
            label: Text(_isCreating ? 'Creating...' : 'Add User'),
          ),
        ),
      ],
    );
  }

  void _showRolePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Select Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _creatableRoles.map((meta) => _RoleChip(
                meta: meta,
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateUserSheet(meta);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserSheet(_RoleMeta meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CreateUserSheet(
        meta: meta,
        tenantId: widget.tenantId,
        tenantSlug: widget.tenantSlug,
        onCreated: () {
          ref.invalidate(tenantUsersProvider(widget.tenantId));
          ref.invalidate(tenantStatsProvider(widget.tenantId));
        },
      ),
    );
  }
}

// ─── Role card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final _RoleMeta meta;
  final int count;
  final VoidCallback onAdd;
  const _RoleCard({required this.meta, required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(meta.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: meta.color),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: meta.color, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role chip ────────────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final _RoleMeta meta;
  final VoidCallback onTap;
  const _RoleChip({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: meta.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meta.icon, color: meta.color, size: 18),
            const SizedBox(width: 8),
            Text(meta.label, style: TextStyle(color: meta.color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Create User bottom sheet ─────────────────────────────────────────────────

class _CreateUserSheet extends StatefulWidget {
  final _RoleMeta meta;
  final String tenantId;
  final String tenantSlug;
  final VoidCallback onCreated;
  const _CreateUserSheet({required this.meta, required this.tenantId, required this.tenantSlug, required this.onCreated});

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _autoEmail = true;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  String? _error;
  late String _generatedPassword;

  @override
  void initState() {
    super.initState();
    _generatedPassword = CredentialGenerator.generatePassword();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _regeneratePassword() {
    setState(() => _generatedPassword = CredentialGenerator.generatePassword());
  }

  void _copyField(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  void _onNameChanged(String value) {
    if (!_autoEmail) return;
    final parts = value.trim().split(' ');
    if (parts.length >= 2) {
      final suggested = CredentialGenerator.generateUsername(
        firstName: parts.first,
        lastName: parts.last,
        tenantSlug: widget.tenantSlug,
      );
      setState(() => _emailCtrl.text = suggested);
    }
  }

  // Roles that require a corresponding row in the `staff` table.
  static const _staffRoles = {
    'teacher', 'tenant_admin', 'principal', 'accountant',
    'librarian', 'transport_manager', 'hostel_warden',
    'canteen_staff', 'receptionist',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      final password = _generatedPassword;
      final fullName = _nameCtrl.text.trim();
      final service = AdminUserService(Supabase.instance.client);
      final result = await service.createUser(
        email: _emailCtrl.text.trim(),
        password: password,
        fullName: fullName,
        tenantId: widget.tenantId,
        role: widget.meta.role,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      // For staff roles, also insert a `staff` table row so the tenant admin
      // can see this person in Staff Management. The super_admin JWT has no
      // tenant_id claim, so we pass tenantIdOverride explicitly.
      if (_staffRoles.contains(widget.meta.role)) {
        final staffRepo = StaffRepository(Supabase.instance.client);
        final parts = fullName.split(' ');
        await staffRepo.createStaff(
          userId: result.userId,
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          tenantIdOverride: widget.tenantId,
          role: widget.meta.role,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        await CredentialDisplayDialog.show(
          context,
          fullName: fullName,
          email: result.email,
          password: result.password,
          role: widget.meta.role,
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('AdminUserCreationException: ', ''); });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: widget.meta.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.meta.icon, color: widget.meta.color),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add ${widget.meta.label}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Generate credentials automatically', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Full name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline, size: 20)),
              onChanged: _onNameChanged,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              onTap: () => setState(() => _autoEmail = false),
              decoration: InputDecoration(
                labelText: 'Email / Username *',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                suffixIcon: _autoEmail
                    ? Tooltip(message: 'Auto-generated from name', child: Icon(Icons.auto_awesome, size: 16, color: widget.meta.color))
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
            ),
            const SizedBox(height: 20),

            // ── Credentials Preview ─────────────────────────────────────
            const SizedBox(height: 4),
            const Text(
              'GENERATED CREDENTIALS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.grey500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Save these before creating — password shown here only.',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Username row
                  _CredPreviewRow(
                    label: 'Username',
                    value: _emailCtrl.text.isNotEmpty
                        ? _emailCtrl.text.split('@').first
                        : '(enter name above)',
                    onCopy: _emailCtrl.text.isNotEmpty
                        ? () => _copyField(context, 'Username', _emailCtrl.text.split('@').first)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  // Email row
                  _CredPreviewRow(
                    label: 'Email',
                    value: _emailCtrl.text.isNotEmpty
                        ? _emailCtrl.text
                        : '(enter name above)',
                    onCopy: _emailCtrl.text.isNotEmpty
                        ? () => _copyField(context, 'Email', _emailCtrl.text)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  // Password row
                  _CredPreviewRow(
                    label: 'Password',
                    value: _passwordVisible ? _generatedPassword : '••••••••••',
                    trailingWidgets: [
                      GestureDetector(
                        onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                        child: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _regeneratePassword,
                        child: const Icon(Icons.refresh, size: 16, color: AppColors.grey500),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _copyField(context, 'Password', _generatedPassword),
                        child: const Icon(Icons.copy, size: 16, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.meta.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_outlined, size: 18),
                label: Text(_isSubmitting ? 'Creating...' : 'Create ${widget.meta.label}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User list item ───────────────────────────────────────────────────────────

// Thin wrapper so _UserListItem can call the profile detail sheet without
// importing the sheet package directly in the widget itself.
abstract class _UserProfileDetailSheet {
  static void show(BuildContext context, Map<String, dynamic> user) =>
      profile_sheet.UserProfileDetailSheet.show(context, user);
}

class _UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final roles = user['user_roles'] as List? ?? [];
    final primaryRole = roles.isNotEmpty
        ? (roles.first as Map<String, dynamic>)['role']?.toString() ?? 'user'
        : 'user';
    final isActive = user['is_active'] == true;
    final name = user['full_name']?.toString() ?? user['email']?.toString() ?? 'Unknown';
    final userId = user['id']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _UserProfileDetailSheet.show(context, user),
        onLongPress: () => _showCredentials(context, userId, name, email, primaryRole),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(primaryRole.replaceAll('_', ' '), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isActive ? const Color(0xFF10B981) : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF10B981) : AppColors.error),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _showCredentials(
    BuildContext context,
    String userId,
    String name,
    String email,
    String role,
  ) async {
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading credentials...'),
          ],
        ),
      ),
    );

    try {
      final service = CredentialService(Supabase.instance.client);
      final cred = await service.getCredentials(userId);

      if (context.mounted) Navigator.of(context).pop(); // close loading

      if (!context.mounted) return;

      if (cred == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No credentials found for this user.')),
        );
        return;
      }

      await CredentialDisplayDialog.show(
        context,
        fullName: name,
        email: cred.email,
        password: cred.initialPassword,
        role: role,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load credentials: $e')),
        );
      }
    }
  }
}

// ─── Billing tab ──────────────────────────────────────────────────────────────

class _BillingTab extends StatelessWidget {
  final dynamic tenant;
  const _BillingTab({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Current Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text(tenant.subscriptionPlan.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.calendar_today_outlined, label: 'Created', value: DateFormat('MMM d, yyyy').format(tenant.createdAt)),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Expires',
                  value: tenant.subscriptionExpiresAt != null
                      ? DateFormat('MMM d, yyyy').format(tenant.subscriptionExpiresAt!)
                      : 'No expiry',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Payment history coming soon', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings tab ─────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final VoidCallback onDelete;
  const _SettingsTab({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.settings_outlined, size: 36, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Tenant settings coming soon', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: AppColors.error.withValues(alpha: 0.06),
          leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
          title: const Text('Delete Tenant', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          subtitle: const Text('Permanently delete all data'),
          onTap: onDelete,
        ),
      ],
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _StatsRowLoading extends StatelessWidget {
  const _StatsRowLoading();
  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(child: SizedBox(height: 90)),
          SizedBox(width: 8),
          Expanded(child: SizedBox(height: 90)),
          SizedBox(width: 8),
          Expanded(child: SizedBox(height: 90)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(width: 72, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ─── Credential preview row (used in _CreateUserSheet) ────────────────────────

class _CredPreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final List<Widget> trailingWidgets;

  const _CredPreviewRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.trailingWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.3)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingWidgets.isNotEmpty) ...trailingWidgets
              else if (onCopy != null)
                GestureDetector(
                  onTap: onCopy,
                  child: Icon(Icons.copy, size: 14, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
