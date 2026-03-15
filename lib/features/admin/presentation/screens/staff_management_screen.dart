import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/credential_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/staff_provider.dart';
import '../widgets/add_staff_sheet.dart';
import '../widgets/credential_display_dialog.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  late final List<String> _roles;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;
    final canManageAdmins =
        primaryRole == 'principal' || primaryRole == 'super_admin';
    _roles = canManageAdmins
        ? const ['teacher', 'tenant_admin', 'other']
        : const ['teacher', 'other'];
    _tabController = TabController(length: _roles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _roles.map((role) => Tab(text: _tabTitle(role))).toList(),
        ),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (query) {
              for (final role in _roles) {
                ref
                    .read(staffNotifierProvider(role).notifier)
                    .loadInitial(searchQuery: query.isEmpty ? null : query);
              }
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _roles
                  .map(
                    (role) => _StaffList(role: role),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  void _showAddStaffSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddStaffSheet(),
    );
  }

  String _tabTitle(String role) {
    switch (role) {
      case 'teacher':
        return 'Teachers';
      case 'tenant_admin':
        return 'School Admins';
      default:
        return 'Other Staff';
    }
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search staff by name or ID...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staff list — driven by StaffNotifier
// ---------------------------------------------------------------------------

class _StaffList extends ConsumerStatefulWidget {
  final String role;

  const _StaffList({required this.role});

  @override
  ConsumerState<_StaffList> createState() => _StaffListState();
}

class _StaffListState extends ConsumerState<_StaffList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(staffNotifierProvider(widget.role).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffNotifierProvider(widget.role));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.staff.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref
            .read(staffNotifierProvider(widget.role).notifier)
            .loadInitial(),
      );
    }

    if (state.staff.isEmpty) {
      return _EmptyView(role: widget.role);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.staff.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.staff.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final member = state.staff[index];
        final canManageMember = _canManageMember(member);
        return _StaffCard(
          member: member,
          onTap: () => _showStaffDetail(context, member),
          onEdit:
              canManageMember ? () => _showEditSheet(context, member) : null,
          onDeactivate: canManageMember
              ? () => _confirmDeactivate(context, member)
              : null,
        );
      },
    );
  }

  bool _canManageMember(StaffMember member) {
    final currentUser = ref.read(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;

    switch (primaryRole) {
      case 'super_admin':
        return true;
      case 'principal':
        return member.role != 'principal';
      case 'tenant_admin':
        return !const ['principal', 'tenant_admin'].contains(member.role);
      default:
        return false;
    }
  }

  void _showStaffDetail(BuildContext context, StaffMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffDetailSheet(member: member),
    );
  }

  void _showEditSheet(BuildContext context, StaffMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStaffSheet(member: member),
    );
  }

  void _confirmDeactivate(BuildContext context, StaffMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Staff'),
        content: Text(
          'Are you sure you want to deactivate ${member.fullName}? '
          'Their account will be disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deactivate(member);
            },
            child: const Text('Deactivate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivate(StaffMember member) async {
    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.deactivateStaff(member.id);
      // Refresh list to remove deactivated member.
      await ref
          .read(staffNotifierProvider(widget.role).notifier)
          .loadInitial();
      if (mounted) {
        context.showSuccessSnackBar('${member.fullName} deactivated');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to deactivate: $e');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Staff card
// ---------------------------------------------------------------------------

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;

  const _StaffCard({
    required this.member,
    required this.onTap,
    required this.onEdit,
    required this.onDeactivate,
  });

  Future<void> _viewCredentials(BuildContext context) async {
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
      final cred = await service.getCredentials(member.userId);

      if (context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;

      if (cred == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No credentials found for this user.')),
        );
        return;
      }

      await CredentialDisplayDialog.show(
        context,
        fullName: member.fullName,
        email: cred.email,
        password: cred.initialPassword,
        role: member.role,
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

  @override
  Widget build(BuildContext context) {
    final initials = _initials(member.fullName);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.employeeId} • ${member.designation ?? member.role}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (member.department != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.department!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                    if (member.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'credentials':
                        _viewCredentials(context);
                        break;
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'deactivate':
                        onDeactivate?.call();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'credentials',
                      child: Row(
                        children: [
                          Icon(Icons.key_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('View Credentials'),
                        ],
                      ),
                    ),
                    if (onEdit != null) const PopupMenuDivider(),
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onDeactivate != null) const PopupMenuDivider(),
                    if (onDeactivate != null)
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Deactivate',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Staff detail sheet (read-only)
// ---------------------------------------------------------------------------

class _StaffDetailSheet extends StatefulWidget {
  final StaffMember member;

  const _StaffDetailSheet({required this.member});

  @override
  State<_StaffDetailSheet> createState() => _StaffDetailSheetState();
}

class _StaffDetailSheetState extends State<_StaffDetailSheet> {
  UserCredential? _credential;
  bool _credentialLoading = true;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final service = CredentialService(Supabase.instance.client);
      final cred = await service.getCredentials(widget.member.userId);
      if (mounted) {
        setState(() {
          _credential = cred;
          _credentialLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _credentialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _SheetHeader(member: widget.member),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Employee ID', value: widget.member.employeeId),
                  _DetailRow(label: 'Email', value: widget.member.email),
                  if (widget.member.phone != null)
                    _DetailRow(label: 'Phone', value: widget.member.phone!),
                  if (widget.member.designation != null)
                    _DetailRow(label: 'Designation', value: widget.member.designation!),
                  if (widget.member.department != null)
                    _DetailRow(label: 'Department', value: widget.member.department!),
                  _DetailRow(label: 'Role', value: widget.member.role),
                  if (widget.member.joinDate != null)
                    _DetailRow(
                      label: 'Joined',
                      value: '${widget.member.joinDate!.day}/${widget.member.joinDate!.month}/${widget.member.joinDate!.year}',
                    ),
                  _DetailRow(
                    label: 'Status',
                    value: widget.member.isActive ? 'Active' : 'Inactive',
                    valueColor: widget.member.isActive ? AppColors.success : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  _buildCredentialsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Login Credentials',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          if (_credentialLoading)
            const Center(
              child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_credential == null)
            Text('No stored credentials',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]))
          else ...[
            _CopyableRow(label: 'Username', value: _credential!.email),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('Password',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
                Expanded(
                  child: Text(
                    _passwordVisible
                        ? _credential!.initialPassword
                        : '*' * _credential!.initialPassword.length,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(Icons.copy, color: Colors.grey[600]),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _credential!.initialPassword));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password copied'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final StaffMember member;

  const _SheetHeader({required this.member});

  @override
  Widget build(BuildContext context) {
    final initials = member.fullName.isNotEmpty
        ? member.fullName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${member.employeeId} • ${member.designation ?? member.role}',
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit staff sheet
// ---------------------------------------------------------------------------

class _EditStaffSheet extends StatefulWidget {
  final StaffMember member;

  const _EditStaffSheet({required this.member});

  @override
  State<_EditStaffSheet> createState() => _EditStaffSheetState();
}

class _EditStaffSheetState extends State<_EditStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _designationController;
  late final TextEditingController _departmentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _designationController =
        TextEditingController(text: widget.member.designation ?? '');
    _departmentController =
        TextEditingController(text: widget.member.department ?? '');
  }

  @override
  void dispose() {
    _designationController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  'Edit Staff',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _designationController,
                      decoration: const InputDecoration(
                        labelText: 'Designation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await _updateStaff();
      if (mounted) {
        Navigator.of(context).pop();
        context.showSuccessSnackBar('Staff updated successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Update failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateStaff() async {
    final supabase = Supabase.instance.client;
    await supabase.from('staff').update({
      'designation': _designationController.text.trim().isEmpty
          ? null
          : _designationController.text.trim(),
      'department': _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', widget.member.id);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyableRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            icon: Icon(Icons.copy, color: Colors.grey[600]),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String role;

  const _EmptyView({required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${_roleLabel(role)} found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Staff" to create the first record.',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'teacher':
        return 'teachers';
      case 'tenant_admin':
        return 'school admins';
      default:
        return 'staff members';
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load staff',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
