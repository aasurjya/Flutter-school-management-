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
        developer.log('SplashScreen: Auth state loading, waiting...',
            name: 'SplashScreen');
        Future.delayed(const Duration(seconds: 1), _checkAuth);
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

    developer.log('SplashScreen: Navigating to dashboard for role: $primaryRole',
        name: 'SplashScreen');

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
      default:
        developer.log('SplashScreen: Unknown role, going to login',
            name: 'SplashScreen', level: 800);
        context.go(AppRoutes.login);
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
                        // Logo Container
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // App Name
                        const Text(
                          'EduSaaS',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'School Management System',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 1,
                          ),
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
