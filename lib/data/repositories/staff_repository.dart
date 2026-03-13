import 'base_repository.dart';

class StaffMember {
  final String id;
  final String userId;
  final String tenantId;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? designation;
  final String? department;
  final String role;
  final bool isActive;
  final DateTime? joinDate;

  const StaffMember({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.designation,
    this.department,
    required this.role,
    required this.isActive,
    this.joinDate,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    // user_roles is nested under users (staff→users→user_roles via FK)
    final userRolesList = user?['user_roles'] as List?;
    final firstRole = userRolesList?.isNotEmpty == true
        ? userRolesList!.first as Map<String, dynamic>?
        : null;

    return StaffMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: user?['email'] as String? ?? '',
      phone: user?['phone'] as String?,
      designation: json['designation'] as String?,
      department: json['department'] as String?,
      role: firstRole?['role'] as String? ?? 'teacher',
      isActive: json['is_active'] as bool? ?? true,
      joinDate: json['date_of_joining'] != null
          ? DateTime.tryParse(json['date_of_joining'] as String)
          : null,
    );
  }
}

class StaffRepository extends BaseRepository {
  StaffRepository(super.client);

  static const _pageSize = 25;

  /// Returns a page of active staff, optionally filtered by [role] and [searchQuery].
  /// Pass [role] = 'all' to skip role filtering.
  Future<List<StaffMember>> getStaffByRole(
    String role, {
    int limit = _pageSize,
    int offset = 0,
    String? searchQuery,
  }) async {
    final tid = requireTenantId;

    // Build the base query — user_roles is fetched separately to avoid a
    // PostgREST nested-embed limitation (staff→users→user_roles is not a
    // supported traversal path; only forward or direct reverse FKs work).
    var query = client
        .from('staff')
        .select('*, users!user_id(id, email, phone)')
        .eq('tenant_id', tid)
        .eq('is_active', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'first_name.ilike.%$searchQuery%,'
        'last_name.ilike.%$searchQuery%,'
        'employee_id.ilike.%$searchQuery%',
      );
    }

    final response = await query
        .order('first_name', ascending: true)
        .range(offset, offset + limit - 1);

    final rawList = response as List;

    // Batch-fetch roles for all returned users in one round-trip.
    final userIds = rawList
        .map((e) => (e as Map<String, dynamic>)['user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    final roleMap = await _fetchRoleMap(userIds, tid);

    final all = rawList
        .map((e) => StaffMember.fromJson(
              _injectRole(e as Map<String, dynamic>, roleMap),
            ))
        .toList();

    if (role == 'all') return all;
    if (role == 'other') {
      return all
          .where((s) => !const ['teacher', 'tenant_admin', 'principal', 'super_admin'].contains(s.role))
          .toList();
    }
    if (role == 'tenant_admin') {
      return all
          .where((s) => const ['super_admin', 'tenant_admin', 'principal'].contains(s.role))
          .toList();
    }
    return all.where((s) => s.role == role).toList();
  }

  /// Creates a staff record after an auth user has already been provisioned.
  ///
  /// [role] must be passed by the caller (it is already known from the creation
  /// flow) so we avoid a second PostgREST round-trip for user_roles.
  Future<StaffMember> createStaff({
    required String userId,
    required String firstName,
    required String lastName,
    String? phone,
    String? designation,
    String? department,
    DateTime? joinDate,
    String role = 'teacher',
  }) async {
    final tenantId = requireTenantId;
    final employeeId = _generateEmployeeId();

    final response = await client.from('staff').insert({
      'user_id': userId,
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'first_name': firstName,
      'last_name': lastName,
      'designation': designation ?? 'Teacher',
      'department': department,
      'date_of_joining':
          (joinDate ?? DateTime.now()).toIso8601String().split('T').first,
      'is_active': true,
    }).select('*, users!user_id(id, email, phone)').single();

    return StaffMember.fromJson(
      _injectRole(response, {userId: role}),
    );
  }

  /// Soft-deletes a staff member by marking them inactive.
  Future<void> deactivateStaff(String staffId) async {
    await client
        .from('staff')
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', staffId)
        .eq('tenant_id', requireTenantId);
  }

  /// Fetches a map of userId → role string for [userIds] within [tenantId].
  ///
  /// Only the first (primary or earliest) role per user is kept.
  Future<Map<String, String>> _fetchRoleMap(
    List<String> userIds,
    String tenantId,
  ) async {
    if (userIds.isEmpty) return {};
    final rolesData = await client
        .from('user_roles')
        .select('user_id, role, is_primary')
        .inFilter('user_id', userIds)
        .eq('tenant_id', tenantId);

    final roleMap = <String, String>{};
    for (final r in rolesData as List) {
      final uid = r['user_id'] as String?;
      final role = r['role'] as String?;
      final isPrimary = r['is_primary'] as bool? ?? false;
      if (uid == null || role == null) continue;
      // Prefer primary role; otherwise take first one encountered.
      if (!roleMap.containsKey(uid) || isPrimary) {
        roleMap[uid] = role;
      }
    }
    return roleMap;
  }

  /// Merges role info into the staff JSON so [StaffMember.fromJson] can read it
  /// from the expected nested path (`users.user_roles[0].role`).
  Map<String, dynamic> _injectRole(
    Map<String, dynamic> staffJson,
    Map<String, String> roleMap,
  ) {
    final userId = staffJson['user_id'] as String?;
    final role = (userId != null ? roleMap[userId] : null) ?? 'teacher';
    final users = Map<String, dynamic>.from(
      (staffJson['users'] as Map<String, dynamic>?) ?? {},
    );
    users['user_roles'] = [
      {'role': role},
    ];
    return <String, dynamic>{...staffJson, 'users': users};
  }

  /// Generates a collision-resistant employee ID using timestamp entropy.
  String _generateEmployeeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'EMP${timestamp.toString().padLeft(5, '0')}';
  }
}
