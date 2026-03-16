import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/credential_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet that displays a user's full profile details,
/// fetched from the [user] map returned by [tenantUsersProvider].
///
/// Shows role-specific information:
/// - teacher  → subjects taught, qualification, experience
/// - student  → class/section, DOB, blood group
/// - parent   → occupation, linked children (if present in data)
/// - staff    → department, employee ID, designation
///
/// Also shows stored login credentials (initial password) for super admin.
class UserProfileDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfileDetailSheet({super.key, required this.user});

  static void show(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => UserProfileDetailSheet(user: user),
    );
  }

  @override
  State<UserProfileDetailSheet> createState() =>
      _UserProfileDetailSheetState();
}

class _UserProfileDetailSheetState extends State<UserProfileDetailSheet> {
  UserCredential? _credential;
  bool _credentialLoading = true;
  bool _passwordVisible = false;

  Map<String, dynamic> get user => widget.user;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final userId = user['id']?.toString();
    if (userId == null) {
      setState(() => _credentialLoading = false);
      return;
    }
    final service = CredentialService(Supabase.instance.client);
    final cred = await service.getCredentials(userId);
    if (mounted) {
      setState(() {
        _credential = cred;
        _credentialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = user['user_roles'] as List? ?? [];
    final primaryRole = roles.isNotEmpty
        ? (roles.first as Map<String, dynamic>)['role']?.toString() ?? 'user'
        : 'user';
    final name =
        user['full_name']?.toString() ?? user['email']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString();
    final avatar = user['avatar_url']?.toString();
    final isActive = user['is_active'] == true;
    final profileComplete = user['profile_complete'] == true;
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Avatar + name row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        const Color(0xFF6366F1).withValues(alpha: 0.12),
                    backgroundImage:
                        avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(initials,
                            style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w700,
                                fontSize: 20))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _RoleBadge(role: primaryRole),
                            const SizedBox(width: 8),
                            _StatusDot(isActive: isActive),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Profile incomplete warning
              if (!profileComplete)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profile not yet completed by the user.',
                          style:
                              TextStyle(fontSize: 13, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contact section
              _SectionTitle('Contact'),
              _InfoRow(Icons.email_outlined, 'Email', email),
              if (phone != null)
                _InfoRow(Icons.phone_outlined, 'Phone', phone),

              // Credentials section
              const SizedBox(height: 16),
              _buildCredentialsSection(),

              // Role-specific section
              _roleSection(primaryRole),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    if (_credentialLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Login Credentials'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    if (_credential == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Login Credentials'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No stored credentials',
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
        ],
      );
    }

    final cred = _credential!;
    final maskedPassword = '*' * cred.initialPassword.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Login Credentials'),
        _CopyableInfoRow(
          icon: Icons.person_outline,
          label: 'Username',
          value: cred.email,
        ),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 10),
            Text('Password: ',
                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
            Expanded(
              child: Text(
                _passwordVisible ? cred.initialPassword : maskedPassword,
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
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                tooltip: 'Toggle visibility',
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
                icon: Icon(Icons.copy, color: Theme.of(context).textTheme.bodySmall?.color),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: cred.initialPassword));
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
    );
  }

  Widget _roleSection(String role) {
    switch (role) {
      case 'teacher':
        return _teacherSection();
      case 'student':
        return _studentSection();
      case 'parent':
        return _parentSection();
      default:
        return _staffSection();
    }
  }

  Widget _teacherSection() {
    final staffRaw = user['staff'];
    final staff = staffRaw is List
        ? (staffRaw.isNotEmpty ? staffRaw.first as Map<String, dynamic> : null)
        : staffRaw as Map<String, dynamic>?;
    if (staff == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionTitle('Professional Details'),
        if (staff['designation'] != null)
          _InfoRow(Icons.badge_outlined, 'Designation',
              staff['designation'].toString()),
        if (staff['department'] != null)
          _InfoRow(Icons.business_outlined, 'Department',
              staff['department'].toString()),
        if (staff['qualification'] != null)
          _InfoRow(Icons.school_outlined, 'Qualification',
              staff['qualification'].toString()),
        if (staff['experience_years'] != null)
          _InfoRow(Icons.work_outline, 'Experience',
              '${staff['experience_years']} years'),
        if (staff['employee_id'] != null)
          _InfoRow(Icons.numbers_outlined, 'Employee ID',
              staff['employee_id'].toString()),
        if (staff['phone'] != null)
          _InfoRow(Icons.phone_outlined, 'Staff Phone',
              staff['phone'].toString()),
      ],
    );
  }

  Widget _studentSection() {
    final dob = user['date_of_birth']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionTitle('Student Details'),
        if (user['gender'] != null)
          _InfoRow(Icons.person_outline, 'Gender', user['gender'].toString()),
        if (dob != null) _InfoRow(Icons.cake_outlined, 'Date of Birth', dob),
        if (user['address'] != null)
          _InfoRow(Icons.home_outlined, 'Address', user['address'].toString()),
      ],
    );
  }

  Widget _parentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionTitle('Parent Details'),
        if (user['address'] != null)
          _InfoRow(
              Icons.home_outlined, 'Address', user['address'].toString()),
      ],
    );
  }

  Widget _staffSection() {
    final staffRaw = user['staff'];
    final staff = staffRaw is List
        ? (staffRaw.isNotEmpty ? staffRaw.first as Map<String, dynamic> : null)
        : staffRaw as Map<String, dynamic>?;
    if (staff == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionTitle('Staff Details'),
        if (staff['designation'] != null)
          _InfoRow(Icons.badge_outlined, 'Designation',
              staff['designation'].toString()),
        if (staff['department'] != null)
          _InfoRow(Icons.business_outlined, 'Department',
              staff['department'].toString()),
        if (staff['employee_id'] != null)
          _InfoRow(Icons.numbers_outlined, 'Employee ID',
              staff['employee_id'].toString()),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodySmall?.color,
                letterSpacing: 0.5)),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: secondaryColor),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(fontSize: 13, color: secondaryColor)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CopyableInfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: secondaryColor),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(fontSize: 13, color: secondaryColor)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              icon: Icon(Icons.copy, color: secondaryColor),
              tooltip: 'Copy',
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
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    const colors = {
      'teacher': Color(0xFF6366F1),
      'student': Color(0xFF3B82F6),
      'parent': Color(0xFFF59E0B),
      'tenant_admin': Color(0xFFEF4444),
      'principal': Color(0xFFEF4444),
      'accountant': Color(0xFF10B981),
      'librarian': Color(0xFF8B5CF6),
    };
    final color = colors[role] ?? AppColors.grey500;
    final label = role.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF10B981) : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(isActive ? 'Active' : 'Inactive',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
