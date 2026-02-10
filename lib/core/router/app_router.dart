import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/parent_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/students/presentation/screens/students_list_screen.dart';
import '../../features/students/presentation/screens/student_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/attendance/presentation/screens/mark_attendance_screen.dart';
import '../../features/exams/presentation/screens/exams_screen.dart';
import '../../features/exams/presentation/screens/marks_entry_screen.dart';
import '../../features/fees/presentation/screens/fees_screen.dart';
import '../../features/messaging/presentation/screens/messages_screen.dart';
import '../../features/student/presentation/screens/student_results_screen.dart';
import '../../features/student/presentation/screens/student_assignments_screen.dart';
import '../../features/teacher/presentation/screens/class_analytics_screen.dart';
import '../../features/admin/presentation/screens/student_management_screen.dart';
import '../../features/admin/presentation/screens/staff_management_screen.dart';
import '../../features/admin/presentation/screens/academic_config_screen.dart';
import '../../features/student/presentation/screens/student_timetable_screen.dart';
import '../../features/student/presentation/screens/student_attendance_screen.dart';
import '../../features/student/presentation/screens/student_fees_screen.dart';
import '../../features/parent/presentation/screens/child_results_screen.dart';
import '../../features/teacher/presentation/screens/assignments_management_screen.dart';
import '../../features/teacher/presentation/screens/my_classes_screen.dart';
import '../../features/teacher/presentation/screens/class_students_screen.dart';
import '../../features/parent/presentation/screens/fee_payment_screen.dart';
import '../../features/admin/presentation/screens/exam_management_screen.dart';
import '../../features/admin/presentation/screens/fee_management_screen.dart';
import '../../features/admin/presentation/screens/announcements_screen.dart';
import '../../features/teacher/presentation/screens/teacher_timetable_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/presentation/screens/tenants_list_screen.dart';
import '../../features/super_admin/presentation/screens/create_tenant_screen.dart';
import '../../features/super_admin/presentation/screens/tenant_detail_screen.dart';

// New feature imports
import '../../features/canteen/presentation/screens/canteen_menu_screen.dart';
import '../../features/canteen/presentation/screens/cart_screen.dart';
import '../../features/canteen/presentation/screens/wallet_screen.dart';
import '../../features/canteen/presentation/screens/order_history_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/library/presentation/screens/my_books_screen.dart';
import '../../features/transport/presentation/screens/transport_screen.dart';
import '../../features/transport/presentation/screens/route_detail_screen.dart';
import '../../features/transport/presentation/screens/my_transport_screen.dart';
import '../../features/hostel/presentation/screens/hostel_screen.dart';
import '../../features/hostel/presentation/screens/hostel_detail_screen.dart';
import '../../features/hostel/presentation/screens/my_hostel_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/health/presentation/screens/student_health_profile_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/gamification/presentation/screens/leaderboard_screen.dart';
import '../../features/insights/presentation/screens/child_insights_screen.dart';
import '../../features/assessments/presentation/screens/quizzes_screen.dart';
import '../../features/assessments/presentation/screens/take_quiz_screen.dart';
import '../../features/assessments/presentation/screens/quiz_result_screen.dart';
import '../../features/ptm/presentation/screens/ptm_scheduler_screen.dart';
import '../../features/ptm/presentation/screens/book_appointment_screen.dart';
import '../../features/emergency/presentation/screens/emergency_dashboard_screen.dart';
import '../../features/leave/presentation/screens/leave_management_screen.dart';
import '../../features/resources/presentation/screens/resource_library_screen.dart';
import '../../features/reports/presentation/screens/report_cards_screen.dart';
import '../../features/reports/presentation/screens/report_card_view_screen.dart';
import '../shell/main_shell.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String selectTenant = '/select-tenant';

  // Dashboard routes by role
  static const String adminDashboard = '/admin';
  static const String teacherDashboard = '/teacher';
  static const String studentDashboard = '/student';
  static const String parentDashboard = '/parent';

  // Feature routes
  static const String students = '/students';
  static const String studentDetail = '/students/:id';
  static const String attendance = '/attendance';
  static const String markAttendance = '/attendance/mark/:sectionId';
  static const String exams = '/exams';
  static const String marksEntry = '/exams/:examId/marks';
  static const String fees = '/fees';
  static const String messages = '/messages';
  static const String assignments = '/assignments';
  static const String timetable = '/timetable';
  static const String calendar = '/calendar';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Canteen routes
  static const String canteen = '/canteen';
  static const String canteenCart = '/canteen/cart';
  static const String canteenWallet = '/canteen/wallet';
  static const String canteenOrders = '/canteen/orders';

  // Library routes
  static const String library = '/library';
  static const String libraryBookDetail = '/library/book/:bookId';
  static const String libraryMyBooks = '/library/my-books';

  // Transport routes
  static const String transport = '/transport';
  static const String transportRouteDetail = '/transport/route/:routeId';
  static const String transportMyRoute = '/transport/my-route';

  // Hostel routes
  static const String hostel = '/hostel';
  static const String hostelDetail = '/hostel/:hostelId';
  static const String hostelMyRoom = '/hostel/my-room';

  // Notifications
  static const String notifications = '/notifications';

  // Health routes
  static const String healthProfile = '/health/:studentId';
  static const String healthEdit = '/health/edit/:studentId';
  static const String healthIncidents = '/health/incidents/:studentId';

  // Gamification routes
  static const String achievements = '/gamification/achievements/:studentId';
  static const String leaderboard = '/gamification/leaderboard';

  // Insights routes
  static const String childInsights = '/insights/:studentId';

  // Assessment routes
  static const String assessments = '/assessments';
  static const String assessmentDetail = '/assessments/:quizId';
  static const String createAssessment = '/assessments/create';
  static const String takeQuiz = '/assessments/take/:quizId';
  static const String quizResult = '/assessments/result/:attemptId';
  static const String quizReview = '/assessments/review/:attemptId';

  // PTM routes
  static const String ptm = '/ptm';
  static const String ptmDetail = '/ptm/:scheduleId';
  static const String ptmBook = '/ptm/:scheduleId/book';

  // Emergency routes
  static const String emergency = '/emergency';

  // Leave routes
  static const String leave = '/leave';

  // Resource Library routes
  static const String resources = '/resources';
  static const String resourceDetail = '/resources/:resourceId';

  // Report Card routes
  static const String reports = '/reports';
  static const String reportDetail = '/reports/:reportId';

  // Student portal routes
  static const String studentResults = '/student/results';
  static const String studentAssignments = '/student/assignments';

  // Teacher portal routes
  static const String classAnalytics = '/teacher/class-analytics/:sectionId';

  // Admin routes
  static const String studentManagement = '/admin/students';
  static const String staffManagement = '/admin/staff';
  static const String academicConfig = '/admin/academic-config';

  // Student portal routes (additional)
  static const String studentTimetable = '/student/timetable';
  static const String studentAttendance = '/student/attendance';
  static const String studentFees = '/student/fees';

  // Parent portal routes
  static const String childResults = '/parent/child/:childId/results';

  // Teacher portal routes (additional)
  static const String teacherAssignments = '/teacher/assignments';
  static const String teacherClasses = '/teacher/classes';
  static const String classStudents = '/teacher/class/:sectionId/students';

  // Parent portal routes (additional)
  static const String feePayment = '/parent/child/:childId/fees';

  // Admin routes (additional)
  static const String examManagement = '/admin/exams';
  static const String feeManagement = '/admin/fees';
  static const String announcements = '/admin/announcements';

  // Teacher routes (additional)
  static const String teacherTimetable = '/teacher/timetable';

  // Super Admin routes
  static const String superAdminDashboard = '/super-admin';
  static const String tenantsList = '/super-admin/tenants';
  static const String createTenant = '/super-admin/tenants/create';
  static const String tenantDetail = '/super-admin/tenants/:tenantId';
}

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final supabase = ref.read(supabaseProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      supabase.auth.onAuthStateChange.map((event) => event.session),
    ),
    redirect: (context, state) {
      // Read current session and user synchronously on every redirect
      final session = supabase.auth.currentSession;
      final currentUser = ref.read(currentUserProvider);
      final isLoggedIn = session != null || currentUser != null;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      developer.log(
        'Router redirect: location=${state.matchedLocation}, '
        'session=${session != null}, currentUser=${currentUser != null}, '
        'isLoggedIn=$isLoggedIn',
        name: 'AppRouter',
      );

      // If on splash, don't redirect
      if (isSplash) return null;

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return _getDashboardRoute(ref);
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Dashboard Routes
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeacherDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.studentDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StudentDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.parentDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ParentDashboardScreen(),
            ),
          ),

          // Students
          GoRoute(
            path: AppRoutes.students,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StudentsListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => StudentDetailScreen(
                  studentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Attendance
          GoRoute(
            path: AppRoutes.attendance,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendanceScreen(),
            ),
            routes: [
              GoRoute(
                path: 'mark/:sectionId',
                builder: (context, state) => MarkAttendanceScreen(
                  sectionId: state.pathParameters['sectionId']!,
                  date: state.uri.queryParameters['date'],
                ),
              ),
            ],
          ),

          // Exams
          GoRoute(
            path: AppRoutes.exams,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExamsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':examId/marks',
                builder: (context, state) => MarksEntryScreen(
                  examId: state.pathParameters['examId']!,
                ),
              ),
            ],
          ),

          // Fees
          GoRoute(
            path: AppRoutes.fees,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeesScreen(),
            ),
          ),

          // Messages
          GoRoute(
            path: AppRoutes.messages,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesScreen(),
            ),
          ),

          // ==================== CANTEEN ====================
          GoRoute(
            path: AppRoutes.canteen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CanteenMenuScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.canteenCart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.canteenWallet,
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: AppRoutes.canteenOrders,
            builder: (context, state) => const OrderHistoryScreen(),
          ),

          // ==================== LIBRARY ====================
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/library/book/:bookId',
            builder: (context, state) => BookDetailScreen(
              bookId: state.pathParameters['bookId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.libraryMyBooks,
            builder: (context, state) => const MyBooksScreen(),
          ),

          // ==================== TRANSPORT ====================
          GoRoute(
            path: AppRoutes.transport,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransportScreen(),
            ),
          ),
          GoRoute(
            path: '/transport/route/:routeId',
            builder: (context, state) => RouteDetailScreen(
              routeId: state.pathParameters['routeId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.transportMyRoute,
            builder: (context, state) => const MyTransportScreen(),
          ),

          // ==================== HOSTEL ====================
          GoRoute(
            path: AppRoutes.hostel,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HostelScreen(),
            ),
          ),
          GoRoute(
            path: '/hostel/my-room',
            builder: (context, state) => const MyHostelScreen(),
          ),
          GoRoute(
            path: '/hostel/:hostelId',
            builder: (context, state) => HostelDetailScreen(
              hostelId: state.pathParameters['hostelId']!,
            ),
          ),

          // ==================== NOTIFICATIONS ====================
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationCenterScreen(),
          ),

          // ==================== HEALTH ====================
          GoRoute(
            path: '/health/:studentId',
            builder: (context, state) => StudentHealthProfileScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),

          // ==================== GAMIFICATION ====================
          GoRoute(
            path: '/gamification/achievements/:studentId',
            builder: (context, state) => AchievementsScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            builder: (context, state) => const LeaderboardScreen(),
          ),

          // ==================== INSIGHTS ====================
          GoRoute(
            path: '/insights/:studentId',
            builder: (context, state) => ChildInsightsScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),

          // ==================== ASSESSMENTS ====================
          GoRoute(
            path: AppRoutes.assessments,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuizzesScreen(),
            ),
          ),
          GoRoute(
            path: '/assessments/take/:quizId',
            builder: (context, state) => TakeQuizScreen(
              quizId: state.pathParameters['quizId']!,
              studentId: state.uri.queryParameters['studentId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/assessments/result/:attemptId',
            builder: (context, state) => QuizResultScreen(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),

          // ==================== PTM ====================
          GoRoute(
            path: AppRoutes.ptm,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PTMSchedulerScreen(),
            ),
          ),
          GoRoute(
            path: '/ptm/:scheduleId/book',
            builder: (context, state) => BookAppointmentScreen(
              scheduleId: state.pathParameters['scheduleId']!,
            ),
          ),

          // ==================== EMERGENCY ====================
          GoRoute(
            path: AppRoutes.emergency,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EmergencyDashboardScreen(),
            ),
          ),

          // ==================== LEAVE ====================
          GoRoute(
            path: AppRoutes.leave,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaveManagementScreen(),
            ),
          ),

          // ==================== RESOURCES ====================
          GoRoute(
            path: AppRoutes.resources,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ResourceLibraryScreen(),
            ),
          ),

          // ==================== REPORT CARDS ====================
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportCardsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports/:reportId',
            builder: (context, state) => ReportCardViewScreen(
              reportId: state.pathParameters['reportId']!,
            ),
          ),

          // Student Results
          GoRoute(
            path: AppRoutes.studentResults,
            builder: (context, state) => StudentResultsScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),

          // Student Assignments
          GoRoute(
            path: AppRoutes.studentAssignments,
            builder: (context, state) => const StudentAssignmentsScreen(),
          ),

          // Class Analytics
          GoRoute(
            path: '/teacher/class-analytics/:sectionId',
            builder: (context, state) => ClassAnalyticsScreen(
              sectionId: state.pathParameters['sectionId']!,
              sectionName: state.uri.queryParameters['name'],
            ),
          ),

          // Admin Student Management
          GoRoute(
            path: AppRoutes.studentManagement,
            builder: (context, state) => const StudentManagementScreen(),
          ),

          // Admin Staff Management
          GoRoute(
            path: AppRoutes.staffManagement,
            builder: (context, state) => const StaffManagementScreen(),
          ),

          // Admin Academic Config
          GoRoute(
            path: AppRoutes.academicConfig,
            builder: (context, state) => const AcademicConfigScreen(),
          ),

          // Student Timetable
          GoRoute(
            path: AppRoutes.studentTimetable,
            builder: (context, state) => const StudentTimetableScreen(),
          ),

          // Student Attendance
          GoRoute(
            path: AppRoutes.studentAttendance,
            builder: (context, state) => StudentAttendanceScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),

          // Student Fees
          GoRoute(
            path: AppRoutes.studentFees,
            builder: (context, state) => StudentFeesScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),

          // Parent Child Results
          GoRoute(
            path: '/parent/child/:childId/results',
            builder: (context, state) => ChildResultsScreen(
              childId: state.pathParameters['childId']!,
              childName: state.uri.queryParameters['name'],
            ),
          ),

          // Teacher Assignments Management
          GoRoute(
            path: AppRoutes.teacherAssignments,
            builder: (context, state) => const AssignmentsManagementScreen(),
          ),

          // Teacher My Classes
          GoRoute(
            path: AppRoutes.teacherClasses,
            builder: (context, state) => const MyClassesScreen(),
          ),

          // Teacher Class Students
          GoRoute(
            path: '/teacher/class/:sectionId/students',
            builder: (context, state) => ClassStudentsScreen(
              sectionId: state.pathParameters['sectionId']!,
              className: state.uri.queryParameters['name'],
            ),
          ),

          // Parent Fee Payment
          GoRoute(
            path: '/parent/child/:childId/fees',
            builder: (context, state) => FeePaymentScreen(
              childId: state.pathParameters['childId']!,
              childName: state.uri.queryParameters['name'],
            ),
          ),

          // Admin Exam Management
          GoRoute(
            path: AppRoutes.examManagement,
            builder: (context, state) => const ExamManagementScreen(),
          ),

          // Admin Fee Management
          GoRoute(
            path: AppRoutes.feeManagement,
            builder: (context, state) => const FeeManagementScreen(),
          ),

          // Admin Announcements
          GoRoute(
            path: AppRoutes.announcements,
            builder: (context, state) => const AnnouncementsScreen(),
          ),

          // Teacher Timetable
          GoRoute(
            path: AppRoutes.teacherTimetable,
            builder: (context, state) => const TeacherTimetableScreen(),
          ),

          // Super Admin Dashboard
          GoRoute(
            path: AppRoutes.superAdminDashboard,
            builder: (context, state) => const SuperAdminDashboardScreen(),
          ),

          // Tenants List
          GoRoute(
            path: AppRoutes.tenantsList,
            builder: (context, state) => const TenantsListScreen(),
          ),

          // Create Tenant
          GoRoute(
            path: AppRoutes.createTenant,
            builder: (context, state) => const CreateTenantScreen(),
          ),

          // Tenant Detail
          GoRoute(
            path: '/super-admin/tenants/:tenantId',
            builder: (context, state) => TenantDetailScreen(
              tenantId: state.pathParameters['tenantId']!,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Get dashboard route based on user role
String _getDashboardRoute(Ref ref) {
  final currentUser = ref.read(currentUserProvider);
  final primaryRole = currentUser?.primaryRole;

  developer.log('Getting dashboard route for role: $primaryRole',
      name: 'AppRouter');

  switch (primaryRole) {
    case 'super_admin':
      return AppRoutes.superAdminDashboard;
    case 'tenant_admin':
    case 'principal':
      return AppRoutes.adminDashboard;
    case 'teacher':
      return AppRoutes.teacherDashboard;
    case 'student':
      return AppRoutes.studentDashboard;
    case 'parent':
      return AppRoutes.parentDashboard;
    default:
      developer.log('No valid role found, redirecting to login',
          name: 'AppRouter', level: 800);
      return AppRoutes.login;
  }
}

/// Converts a [Stream] into a [ChangeNotifier] for GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
