import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (kDebugMode) {
      developer.log('LoginScreen: Starting login for email: $email',
          name: 'LoginScreen');
    }

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: email,
            password: password,
          );

      if (kDebugMode) {
        developer.log('LoginScreen: Login successful', name: 'LoginScreen');
      }

      if (mounted) {
        final currentUser = ref.read(currentUserProvider);
        if (kDebugMode) {
          developer.log(
              'LoginScreen: User loaded - role: ${currentUser?.primaryRole}',
              name: 'LoginScreen');
        }

        if (currentUser != null) {
          _navigateToDashboard();
        } else {
          setState(() {
            _errorMessage = 'User profile not found. Please contact support.';
          });
        }
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        developer.log('LoginScreen: Auth error - ${e.message}',
            name: 'LoginScreen', level: 900);
      }
      if (mounted) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('LoginScreen: Unexpected error - $e',
            name: 'LoginScreen', level: 1000);
      }
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (message.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    } else if (message.contains('user not found')) {
      return 'No account found with this email address.';
    } else if (message.contains('too many requests')) {
      return 'Too many login attempts. Please wait and try again.';
    }
    return error.message;
  }

  String _getErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (message.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    } else if (message.contains('profile not found')) {
      return 'User profile not found. Please contact administrator.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  void _navigateToDashboard() {
    final currentUser = ref.read(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;
    final profileComplete = currentUser?.profileComplete ?? false;

    if (kDebugMode) {
      developer.log('Navigating to dashboard for role: $primaryRole, profileComplete: $profileComplete',
          name: 'LoginScreen');
    }

    // First-login: redirect to profile setup (super_admin is exempt)
    if (!profileComplete && primaryRole != 'super_admin') {
      final setupRoute = _getProfileSetupRoute(primaryRole);
      if (setupRoute != null) {
        if (kDebugMode) {
          developer.log('LoginScreen: redirecting to profile setup $setupRoute',
              name: 'LoginScreen');
        }
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
        // Unknown role — redirect to login for safety
        if (kDebugMode) {
          developer.log('Unknown role: $primaryRole, redirecting to login',
              name: 'LoginScreen', level: 800);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unknown role. Please contact administrator.'),
            ),
          );
        }
        context.go(AppRoutes.login);
    }
  }

  String? _getProfileSetupRoute(String? role) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.info.withValues(alpha: 0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      if (_errorMessage != null) _buildErrorBanner(),
                      _buildLoginForm(),
                      if (!AppEnvironment.isProduction) ...[
                        const SizedBox(height: 24),
                        _buildEnvironmentBadge(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'EduSaaS Enterprise',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The complete operating system for modern education.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.grey500,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Work Email',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Enter a valid work email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                if (value.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _handleLogin,
              isLoading: _isLoading,
              child: const Text('Access Dashboard'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                minimumSize: const Size(double.infinity, 36),
              ),
              child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bug_report, size: 16, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            AppEnvironment.environmentName,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => _ForgotPasswordDialog(),
    );
  }
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _message = 'Please enter a valid email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(email);
      setState(() {
        _message = 'Password reset email sent. Please check your inbox.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to send reset email. Please try again.';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(
                color: _isSuccess ? AppColors.success : AppColors.error,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}
