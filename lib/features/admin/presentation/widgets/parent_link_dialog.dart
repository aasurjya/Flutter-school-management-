import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/admin_user_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/credential_generator.dart';
import '../../../../data/models/student.dart';
import '../../../../data/repositories/parent_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/parent_provider.dart';
import 'credential_display_dialog.dart';

/// Full-screen bottom sheet for managing parents linked to a student.
///
/// Sections:
///  1. Currently linked parents (with unlink action).
///  2. Search existing parents and link them.
///  3. Create a new parent and link them (expandable).
class ParentLinkDialog extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;

  const ParentLinkDialog({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  /// Opens the dialog as a full-height modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String studentId,
    required String studentName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ParentLinkDialog(
        studentId: studentId,
        studentName: studentName,
      ),
    );
  }

  @override
  ConsumerState<ParentLinkDialog> createState() => _ParentLinkDialogState();
}

class _ParentLinkDialogState extends ConsumerState<ParentLinkDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(parentSearchProvider.notifier).search(query);
    });
  }

  void _invalidateLinkedParents() {
    ref.invalidate(parentsByStudentProvider(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _LinkedParentsSection(
                      studentId: widget.studentId,
                      onChanged: _invalidateLinkedParents,
                    ),
                    const SizedBox(height: 24),
                    _SearchLinkSection(
                      studentId: widget.studentId,
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onLinked: _invalidateLinkedParents,
                    ),
                    const SizedBox(height: 24),
                    _CreateLinkSection(
                      studentId: widget.studentId,
                      onCreated: _invalidateLinkedParents,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.family_restroom, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Parents',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.studentName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: Currently linked parents
// ---------------------------------------------------------------------------

class _LinkedParentsSection extends ConsumerWidget {
  final String studentId;
  final VoidCallback onChanged;

  const _LinkedParentsSection({
    required this.studentId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(parentsByStudentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Linked Parents'),
        const SizedBox(height: 8),
        linksAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text('Error loading parents: $e', style: const TextStyle(color: AppColors.error)),
          data: (links) => links.isEmpty
              ? const Text('No parents linked yet.')
              : Column(
                  children: links
                      .map((link) => _LinkedParentTile(
                            link: link,
                            onUnlink: () => _unlink(context, ref, link),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    StudentParentLink link,
  ) async {
    try {
      final repo = ref.read(parentRepositoryProvider);
      await repo.unlinkParent(link.id);
      onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlink: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _LinkedParentTile extends StatelessWidget {
  final StudentParentLink link;
  final VoidCallback onUnlink;

  const _LinkedParentTile({required this.link, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    final parent = link.parent;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            parent.firstName[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(parent.fullName),
        subtitle: Text(parent.relationDisplay),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (link.isPrimary)
              const Tooltip(
                message: 'Primary contact',
                child: Icon(Icons.star, color: Colors.amber, size: 18),
              ),
            if (link.canPickup)
              const Tooltip(
                message: 'Can pick up',
                child: Icon(Icons.directions_car, color: AppColors.primary, size: 18),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.link_off, color: AppColors.error),
              tooltip: 'Unlink',
              onPressed: () => _confirmUnlink(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnlink(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlink Parent'),
        content: Text(
          'Remove ${link.parent.fullName} from this student?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUnlink();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Search & link existing parent
// ---------------------------------------------------------------------------

class _SearchLinkSection extends ConsumerWidget {
  final String studentId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLinked;

  const _SearchLinkSection({
    required this.studentId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onLinked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(parentSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Link Existing Parent'),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search by name or phone',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 8),
        searchState.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Search error: $e',
              style: const TextStyle(color: AppColors.error)),
          data: (parents) => parents.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: parents
                      .map((p) => _ParentSearchResultTile(
                            parent: p,
                            onLink: () => _showLinkOptions(context, ref, p),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  void _showLinkOptions(
    BuildContext context,
    WidgetRef ref,
    Parent parent,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LinkOptionsSheet(
        parent: parent,
        studentId: studentId,
        onLinked: () {
          onLinked();
          ref.read(parentSearchProvider.notifier).clear();
          searchController.clear();
        },
      ),
    );
  }
}

class _ParentSearchResultTile extends StatelessWidget {
  final Parent parent;
  final VoidCallback onLink;

  const _ParentSearchResultTile({required this.parent, required this.onLink});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          parent.firstName[0].toUpperCase(),
          style: const TextStyle(color: AppColors.primary),
        ),
      ),
      title: Text(parent.fullName),
      subtitle: Text(parent.phone),
      trailing: FilledButton.tonal(
        onPressed: onLink,
        child: const Text('Link'),
      ),
    );
  }
}

class _LinkOptionsSheet extends ConsumerStatefulWidget {
  final Parent parent;
  final String studentId;
  final VoidCallback onLinked;

  const _LinkOptionsSheet({
    required this.parent,
    required this.studentId,
    required this.onLinked,
  });

  @override
  ConsumerState<_LinkOptionsSheet> createState() => _LinkOptionsSheetState();
}

class _LinkOptionsSheetState extends ConsumerState<_LinkOptionsSheet> {
  String _relation = 'Father';
  bool _isPrimary = false;
  bool _canPickup = false;
  bool _isSubmitting = false;

  Future<void> _link() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(parentRepositoryProvider);
      await repo.linkParent(
        studentId: widget.studentId,
        parentId: widget.parent.id,
        relation: _relation,
        isPrimary: _isPrimary,
        canPickup: _canPickup,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onLinked();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Link ${widget.parent.fullName}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _relation,
            decoration: const InputDecoration(
              labelText: 'Relation',
              border: OutlineInputBorder(),
            ),
            items: ['Father', 'Mother', 'Guardian', 'Other']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _relation = v);
            },
          ),
          SwitchListTile(
            title: const Text('Primary Contact'),
            value: _isPrimary,
            onChanged: (v) => setState(() => _isPrimary = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Can Pick Up'),
            value: _canPickup,
            onChanged: (v) => setState(() => _canPickup = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ? null : _link,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirm Link'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3: Create & link new parent
// ---------------------------------------------------------------------------

class _CreateLinkSection extends ConsumerStatefulWidget {
  final String studentId;
  final VoidCallback onCreated;

  const _CreateLinkSection({
    required this.studentId,
    required this.onCreated,
  });

  @override
  ConsumerState<_CreateLinkSection> createState() => _CreateLinkSectionState();
}

class _CreateLinkSectionState extends ConsumerState<_CreateLinkSection> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relation = 'Father';
  bool _isPrimary = false;
  bool _canPickup = false;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  String _tenantSlug = 'school';
  String _previewEmail = '';
  late String _generatedPassword;

  @override
  void initState() {
    super.initState();
    _generatedPassword = CredentialGenerator.generatePassword();
    _loadTenantSlug();
  }

  Future<void> _loadTenantSlug() async {
    final tenantId = ref.read(currentUserProvider)?.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;
    try {
      final data = await Supabase.instance.client
          .from('tenants')
          .select('slug')
          .eq('id', tenantId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _tenantSlug = data['slug'] as String? ?? 'school';
          _updatePreviewEmail();
        });
      }
    } catch (_) {}
  }

  void _updatePreviewEmail() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty && lastName.isEmpty) {
      setState(() => _previewEmail = '');
      return;
    }
    setState(() => _previewEmail = CredentialGenerator.generateUsername(
          firstName: firstName.isEmpty ? 'parent' : firstName,
          lastName: lastName.isEmpty ? '' : lastName,
          tenantSlug: _tenantSlug,
        ));
  }

  void _regeneratePassword() =>
      setState(() => _generatedPassword = CredentialGenerator.generatePassword());

  void _copyField(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createAndLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
    final tenantId = ref.read(currentUserProvider)?.tenantId ?? '';

    if (tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Session error: tenant not found. Please log in again.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final email = _previewEmail.isNotEmpty
        ? _previewEmail
        : CredentialGenerator.generateUsername(
            firstName: firstName,
            lastName: lastName.isEmpty ? 'parent' : lastName,
            tenantSlug: _tenantSlug,
          );
    final password = _generatedPassword;

    String? createdUserId;
    try {
      // Step 1: Create auth user via Edge Function
      final adminService = AdminUserService(Supabase.instance.client);
      final result = await adminService.createUser(
        email: email,
        password: password,
        fullName: fullName,
        tenantId: tenantId,
        role: 'parent',
        phone: phone,
      );
      createdUserId = result.userId;

      // Step 2: Create parent record with the new userId
      final repo = ref.read(parentRepositoryProvider);
      final parent = await repo.createParent(
        firstName: firstName,
        lastName: lastName,
        relation: _relation,
        phone: phone,
        userId: createdUserId,
      );

      // Step 3: Link parent to student
      await repo.linkParent(
        studentId: widget.studentId,
        parentId: parent.id,
        relation: _relation,
        isPrimary: _isPrimary,
        canPickup: _canPickup,
      );

      _clearForm();
      widget.onCreated();

      if (mounted) {
        // Show credential dialog AFTER sheet is still open (not closed first)
        await CredentialDisplayDialog.show(
          context,
          fullName: parent.fullName,
          email: email,
          password: password,
          role: 'parent',
        );
      }
    } on AdminUserCreationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      // Rollback orphaned auth user if parent DB insert failed
      if (createdUserId != null) {
        await AdminUserService(Supabase.instance.client)
            .deleteUser(createdUserId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _generatedPassword = CredentialGenerator.generatePassword();
    setState(() {
      _relation = 'Father';
      _isPrimary = false;
      _canPickup = false;
      _previewEmail = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _sectionTitle(context, 'Create & Link New Parent'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameRow(),
              const SizedBox(height: 16),
              _buildRelationDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Primary Contact'),
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Can Pick Up'),
                value: _canPickup,
                onChanged: (v) => setState(() => _canPickup = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              // ── Credentials preview ──────────────────────────────
              const Text(
                'GENERATED CREDENTIALS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.grey500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 13, color: Colors.amber),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Save these before creating — password shown here only.',
                            style:
                                TextStyle(fontSize: 11, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _CredRow(
                      label: 'Email',
                      value: _previewEmail.isNotEmpty
                          ? _previewEmail
                          : '(enter name above)',
                      onCopy: _previewEmail.isNotEmpty
                          ? () => _copyField('Email', _previewEmail)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _CredRow(
                      label: 'Password',
                      value: _passwordVisible ? _generatedPassword : '••••••••••',
                      trailingWidgets: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                          child: Icon(
                            _passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _regeneratePassword,
                          child: Icon(Icons.refresh,
                              size: 16, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _copyField('Password', _generatedPassword),
                          child: Icon(Icons.copy,
                              size: 16, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting ? null : _createAndLink,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create & Link Parent'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _updatePreviewEmail(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _updatePreviewEmail(),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _relation,
      decoration: const InputDecoration(
        labelText: 'Relation *',
        border: OutlineInputBorder(),
      ),
      items: ['Father', 'Mother', 'Guardian', 'Other']
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _relation = v);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper
// ---------------------------------------------------------------------------

Widget _sectionTitle(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold),
  );
}

// ── Credential preview row (local copy) ───────────────────────────────────
class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final List<Widget> trailingWidgets;

  const _CredRow({
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
              if (trailingWidgets.isNotEmpty)
                ...trailingWidgets
              else if (onCopy != null)
                GestureDetector(
                  onTap: onCopy,
                  child:
                      Icon(Icons.copy, size: 14, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
