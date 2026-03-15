import '../constants/app_roles.dart';

/// Feature areas used for UI-level permission gating.
enum AppFeature {
  dashboard,
  students,
  attendance,
  fees,
  exams,
  grades,
  assignments,
  timetable,
  calendar,
  messages,
  notifications,
  library,
  transport,
  hostel,
  canteen,
  hr,
  visitors,
  reports,
  announcements,
  syllabus,
  homework,
  lms,
  aiInsights,
  gamification,
  portfolio,
  onlineExams,
  disciplineRecords,
  admissions,
  alumni,
  inventory,
  settings,
  staffManagement,
  studentManagement,
  tenantManagement,
}

/// UI-level permission matrix.
///
/// Returns `true` when [role] should see the UI for [feature].
/// This is for hiding/showing buttons and tabs — router-level guards
/// handle hard security.
class RolePermissions {
  RolePermissions._();

  static bool canAccess(String role, AppFeature feature) {
    switch (role) {
      case AppRoles.superAdmin:
        return _superAdminFeatures.contains(feature);
      case AppRoles.tenantAdmin:
      case AppRoles.principal:
        return _adminFeatures.contains(feature);
      case AppRoles.teacher:
        return _teacherFeatures.contains(feature);
      case AppRoles.student:
        return _studentFeatures.contains(feature);
      case AppRoles.parent:
        return _parentFeatures.contains(feature);
      case AppRoles.accountant:
        return _accountantFeatures.contains(feature);
      case AppRoles.librarian:
        return _librarianFeatures.contains(feature);
      case AppRoles.transportManager:
        return _transportManagerFeatures.contains(feature);
      case AppRoles.hostelWarden:
        return _hostelWardenFeatures.contains(feature);
      case AppRoles.canteenStaff:
        return _canteenStaffFeatures.contains(feature);
      case AppRoles.receptionist:
        return _receptionistFeatures.contains(feature);
      default:
        return false;
    }
  }

  // ── Role feature sets ──────────────────────────────────────────────────────

  static const _superAdminFeatures = {
    AppFeature.dashboard,
    AppFeature.tenantManagement,
    AppFeature.settings,
  };

  static const _adminFeatures = {
    AppFeature.dashboard,
    AppFeature.students,
    AppFeature.attendance,
    AppFeature.fees,
    AppFeature.exams,
    AppFeature.grades,
    AppFeature.assignments,
    AppFeature.timetable,
    AppFeature.calendar,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.library,
    AppFeature.transport,
    AppFeature.hostel,
    AppFeature.canteen,
    AppFeature.hr,
    AppFeature.reports,
    AppFeature.announcements,
    AppFeature.syllabus,
    AppFeature.homework,
    AppFeature.lms,
    AppFeature.aiInsights,
    AppFeature.disciplineRecords,
    AppFeature.admissions,
    AppFeature.inventory,
    AppFeature.settings,
    AppFeature.staffManagement,
    AppFeature.studentManagement,
  };

  static const _teacherFeatures = {
    AppFeature.dashboard,
    AppFeature.attendance,
    AppFeature.exams,
    AppFeature.grades,
    AppFeature.assignments,
    AppFeature.timetable,
    AppFeature.calendar,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.library,
    AppFeature.reports,
    AppFeature.syllabus,
    AppFeature.homework,
    AppFeature.lms,
    AppFeature.aiInsights,
    AppFeature.gamification,
    AppFeature.onlineExams,
  };

  static const _studentFeatures = {
    AppFeature.dashboard,
    AppFeature.attendance,
    AppFeature.exams,
    AppFeature.grades,
    AppFeature.assignments,
    AppFeature.timetable,
    AppFeature.calendar,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.library,
    AppFeature.transport,
    AppFeature.hostel,
    AppFeature.canteen,
    AppFeature.fees,
    AppFeature.lms,
    AppFeature.gamification,
    AppFeature.portfolio,
    AppFeature.onlineExams,
    AppFeature.homework,
  };

  static const _parentFeatures = {
    AppFeature.dashboard,
    AppFeature.attendance,
    AppFeature.fees,
    AppFeature.calendar,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.reports,
    AppFeature.homework,
    AppFeature.aiInsights,
  };

  static const _accountantFeatures = {
    AppFeature.dashboard,
    AppFeature.fees,
    AppFeature.reports,
    AppFeature.messages,
    AppFeature.notifications,
  };

  static const _librarianFeatures = {
    AppFeature.dashboard,
    AppFeature.library,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.announcements,
  };

  static const _transportManagerFeatures = {
    AppFeature.dashboard,
    AppFeature.transport,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.announcements,
  };

  static const _hostelWardenFeatures = {
    AppFeature.dashboard,
    AppFeature.hostel,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.announcements,
  };

  static const _canteenStaffFeatures = {
    AppFeature.dashboard,
    AppFeature.canteen,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.announcements,
  };

  static const _receptionistFeatures = {
    AppFeature.dashboard,
    AppFeature.visitors,
    AppFeature.calendar,
    AppFeature.messages,
    AppFeature.notifications,
    AppFeature.announcements,
  };
}
