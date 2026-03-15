/// Single source of truth for all 12 role string constants.
class AppRoles {
  AppRoles._();

  // Administrative roles
  static const String superAdmin    = 'super_admin';
  static const String tenantAdmin   = 'tenant_admin';
  static const String principal     = 'principal';

  // Academic roles
  static const String teacher       = 'teacher';
  static const String student       = 'student';
  static const String parent        = 'parent';

  // Operational staff roles
  static const String accountant    = 'accountant';
  static const String librarian     = 'librarian';
  static const String transportManager = 'transport_manager';
  static const String hostelWarden  = 'hostel_warden';
  static const String canteenStaff  = 'canteen_staff';
  static const String receptionist  = 'receptionist';

  /// All 6 operational staff roles.
  static const List<String> operationalStaff = [
    accountant,
    librarian,
    transportManager,
    hostelWarden,
    canteenStaff,
    receptionist,
  ];

  /// All 12 roles.
  static const List<String> all = [
    superAdmin,
    tenantAdmin,
    principal,
    teacher,
    student,
    parent,
    ...operationalStaff,
  ];
}
