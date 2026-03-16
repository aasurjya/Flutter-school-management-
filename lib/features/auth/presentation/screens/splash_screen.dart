import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _authRetryCount = 0;
  static const _maxAuthRetries = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Allow splash animation to play
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (session) async {
        if (session != null) {
          developer.log('SplashScreen: Session found, loading user profile',
              name: 'SplashScreen');

          // Ensure user profile is loaded
          try {
            await ref.read(authNotifierProvider.notifier).refreshProfile();

            if (!mounted) return;

            final currentUser = ref.read(currentUserProvider);
            developer.log(
                'SplashScreen: User profile loaded - role: ${currentUser?.primaryRole}',
                name: 'SplashScreen');

            if (currentUser != null) {
              _navigateToDashboard();
            } else {
              // User profile not found, sign out and go to login
              developer.log(
                  'SplashScreen: User profile not found, redirecting to login',
                  name: 'SplashScreen',
                  level: 800);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) context.go(AppRoutes.login);
            }
          } catch (e) {
            developer.log('SplashScreen: Error loading profile - $e',
                name: 'SplashScreen', level: 900);
            if (mounted) context.go(AppRoutes.login);
          }
        } else {
          developer.log('SplashScreen: No session, redirecting to login',
              name: 'SplashScreen');
          context.go(AppRoutes.login);
        }
      },
      loading: () {
        _authRetryCount++;
        developer.log('SplashScreen: Auth state loading, retry $_authRetryCount/$_maxAuthRetries',
            name: 'SplashScreen');
        if (_authRetryCount >= _maxAuthRetries) {
          developer.log('SplashScreen: Auth timeout, redirecting to login',
              name: 'SplashScreen', level: 800);
          if (mounted) context.go(AppRoutes.login);
        } else {
          Future.delayed(const Duration(seconds: 1), _checkAuth);
        }
      },
      error: (error, _) {
        developer.log('SplashScreen: Auth error - $error',
            name: 'SplashScreen', level: 900);
        context.go(AppRoutes.login);
      },
    );
  }

  void _navigateToDashboard() {
    final currentUser = ref.read(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;
    final profileComplete = currentUser?.profileComplete ?? false;

    developer.log(
        'SplashScreen: role=$primaryRole profileComplete=$profileComplete',
        name: 'SplashScreen');

    // First-login users who have not completed their profile are redirected
    // to the appropriate setup screen (super_admin is exempt).
    if (!profileComplete && primaryRole != 'super_admin') {
      final setupRoute = _profileSetupRoute(primaryRole);
      if (setupRoute != null) {
        developer.log('SplashScreen: redirecting to profile setup $setupRoute',
            name: 'SplashScreen');
        context.go(setupRoute);
        return;
      }
    }

    switch (primaryRole) {
      case 'super_admin':
        context.go(AppRoutes.superAdminDashboard);
        break;
      case 'tenant_admin':
      case 'principal':
        context.go(AppRoutes.adminDashboard);
        break;
      case 'teacher':
        context.go(AppRoutes.teacherDashboard);
        break;
      case 'student':
        context.go(AppRoutes.studentDashboard);
        break;
      case 'parent':
        context.go(AppRoutes.parentDashboard);
        break;
      case 'accountant':
        context.go(AppRoutes.accountantDashboard);
        break;
      case 'librarian':
        context.go(AppRoutes.librarianDashboard);
        break;
      case 'transport_manager':
        context.go(AppRoutes.transportDashboard);
        break;
      case 'hostel_warden':
        context.go(AppRoutes.hostelWardenDashboard);
        break;
      case 'canteen_staff':
        context.go(AppRoutes.canteenStaffDashboard);
        break;
      case 'receptionist':
        context.go(AppRoutes.receptionistDashboard);
        break;
      default:
        developer.log('SplashScreen: Unknown role, going to login',
            name: 'SplashScreen', level: 800);
        context.go(AppRoutes.login);
    }
  }

  String? _profileSetupRoute(String? role) {
    switch (role) {
      case 'teacher':
        return AppRoutes.profileSetupTeacher;
      case 'student':
        return AppRoutes.profileSetupStudent;
      case 'parent':
        return AppRoutes.profileSetupParent;
      case 'accountant':
      case 'librarian':
      case 'transport_manager':
      case 'hostel_warden':
      case 'canteen_staff':
      case 'receptionist':
        return AppRoutes.profileSetupStaff;
      case 'tenant_admin':
      case 'principal':
        return AppRoutes.profileSetupAdmin;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo + Wordmark
                        Image.asset(
                          'assets/icons/campusly-splash.png',
                          width: 280,
                          fit: BoxFit.contain,
                          semanticLabel: 'Campusly logo',
                        ),
                        const SizedBox(height: 48),
                        // Loading indicator
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
