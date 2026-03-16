import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/constants/app_roles.dart';
import 'package:school_management/core/utils/role_permissions.dart';

void main() {
  group('RolePermissions — aiInsights access', () {
    test('all 12 roles can access aiInsights', () {
      final allRoles = [
        AppRoles.superAdmin,
        AppRoles.tenantAdmin,
        AppRoles.principal,
        AppRoles.teacher,
        AppRoles.student,
        AppRoles.parent,
        AppRoles.accountant,
        AppRoles.librarian,
        AppRoles.transportManager,
        AppRoles.hostelWarden,
        AppRoles.canteenStaff,
        AppRoles.receptionist,
      ];

      for (final role in allRoles) {
        expect(
          RolePermissions.canAccess(role, AppFeature.aiInsights),
          isTrue,
          reason: '$role should have access to aiInsights',
        );
      }
    });

    test('unknown role cannot access any feature', () {
      expect(
        RolePermissions.canAccess('unknown_role', AppFeature.aiInsights),
        isFalse,
      );
      expect(
        RolePermissions.canAccess('unknown_role', AppFeature.dashboard),
        isFalse,
      );
    });
  });

  group('RolePermissions — dashboard access', () {
    test('all roles have dashboard access', () {
      final allRoles = [
        AppRoles.superAdmin,
        AppRoles.tenantAdmin,
        AppRoles.principal,
        AppRoles.teacher,
        AppRoles.student,
        AppRoles.parent,
        AppRoles.accountant,
        AppRoles.librarian,
        AppRoles.transportManager,
        AppRoles.hostelWarden,
        AppRoles.canteenStaff,
        AppRoles.receptionist,
      ];

      for (final role in allRoles) {
        expect(
          RolePermissions.canAccess(role, AppFeature.dashboard),
          isTrue,
          reason: '$role should have dashboard access',
        );
      }
    });
  });

  group('RolePermissions — role-specific features', () {
    test('only admin and teacher have exams access', () {
      expect(
        RolePermissions.canAccess(AppRoles.tenantAdmin, AppFeature.exams),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(AppRoles.teacher, AppFeature.exams),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(AppRoles.student, AppFeature.exams),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(AppRoles.accountant, AppFeature.exams),
        isFalse,
      );
    });

    test('accountant has fees access but not library', () {
      expect(
        RolePermissions.canAccess(AppRoles.accountant, AppFeature.fees),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(AppRoles.accountant, AppFeature.library),
        isFalse,
      );
    });

    test('librarian has library access but not fees', () {
      expect(
        RolePermissions.canAccess(AppRoles.librarian, AppFeature.library),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(AppRoles.librarian, AppFeature.fees),
        isFalse,
      );
    });

    test('transport manager has transport but not hostel', () {
      expect(
        RolePermissions.canAccess(
            AppRoles.transportManager, AppFeature.transport),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(
            AppRoles.transportManager, AppFeature.hostel),
        isFalse,
      );
    });

    test('super admin has tenantManagement but not students', () {
      expect(
        RolePermissions.canAccess(
            AppRoles.superAdmin, AppFeature.tenantManagement),
        isTrue,
      );
      expect(
        RolePermissions.canAccess(AppRoles.superAdmin, AppFeature.students),
        isFalse,
      );
    });

    test('receptionist has visitors access', () {
      expect(
        RolePermissions.canAccess(AppRoles.receptionist, AppFeature.visitors),
        isTrue,
      );
    });
  });
}
