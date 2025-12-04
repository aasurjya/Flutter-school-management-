import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  static const String canteen = '/canteen';
  static const String library = '/library';
  static const String transport = '/transport';
  static const String hostel = '/hostel';
  static const String settings = '/settings';
  static const String profile = '/profile';
}

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      
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

  print('_getDashboardRoute: currentUser = $currentUser');
  print('_getDashboardRoute: primaryRole = $primaryRole');
  print('_getDashboardRoute: user roles = ${currentUser?.roles}');

  switch (primaryRole) {
    case 'super_admin':
    case 'tenant_admin':
    case 'principal':
      print('_getDashboardRoute: returning /admin');
      return AppRoutes.adminDashboard;
    case 'teacher':
      print('_getDashboardRoute: returning /teacher');
      return AppRoutes.teacherDashboard;
    case 'student':
      print('_getDashboardRoute: returning /student');
      return AppRoutes.studentDashboard;
    case 'parent':
      print('_getDashboardRoute: returning /parent');
      return AppRoutes.parentDashboard;
    default:
      print('_getDashboardRoute: ERROR - no valid role found, returning /login');
      return AppRoutes.login;
  }
}
