/// User model
class AppUser {
  final String id;
  final String? tenantId;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final bool isActive;
  final List<String> roles;
  final String? primaryRole;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    this.tenantId,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.isActive = true,
    this.roles = const [],
    this.primaryRole,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Extract roles from user_roles if present
    List<String> extractedRoles = [];
    if (json['user_roles'] != null) {
      extractedRoles = (json['user_roles'] as List)
          .map((r) => r['role'] as String)
          .toList();
    } else if (json['roles'] != null) {
      extractedRoles = List<String>.from(json['roles']);
    }

    // Find primary role
    String? primaryRole;
    if (json['user_roles'] != null) {
      final primary = (json['user_roles'] as List)
          .firstWhere((r) => r['is_primary'] == true, orElse: () => null);
      primaryRole = primary?['role'];
    }
    primaryRole ??= extractedRoles.isNotEmpty ? extractedRoles.first : null;

    return AppUser(
      id: json['id'],
      tenantId: json['tenant_id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      roles: extractedRoles,
      primaryRole: primaryRole,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'address': address,
      'is_active': isActive,
    };
  }

  AppUser copyWith({
    String? id,
    String? tenantId,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    bool? isActive,
    List<String>? roles,
    String? primaryRole,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      primaryRole: primaryRole ?? this.primaryRole,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has a specific role
  bool hasRole(String role) => roles.contains(role);

  /// Check if user is admin
  bool get isAdmin =>
      hasRole('super_admin') || hasRole('tenant_admin') || hasRole('principal');

  /// Check if user is teacher
  bool get isTeacher => hasRole('teacher');

  /// Check if user is student
  bool get isStudent => hasRole('student');

  /// Check if user is parent
  bool get isParent => hasRole('parent');

  /// Get user initials
  String get initials {
    if (fullName == null || fullName!.isEmpty) {
      return email[0].toUpperCase();
    }
    final parts = fullName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName![0].toUpperCase();
  }
}
