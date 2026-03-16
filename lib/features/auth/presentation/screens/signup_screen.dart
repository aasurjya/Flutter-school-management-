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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (kDebugMode) {
      developer.log('SignupScreen: Starting signup for email: $email',
          name: 'SignupScreen');
    }

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone.isEmpty ? null : phone,
          );

      if (kDebugMode) {
        developer.log('SignupScreen: Signup successful', name: 'SignupScreen');
      }

      if (mounted) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          _navigateToDashboard();
        } else {
          setState(() {
            _errorMessage =
                'Account created but profile could not be loaded. Please sign in.';
          });
        }
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        developer.log('SignupScreen: Auth error - ${e.message}',
            name: 'SignupScreen', level: 900);
      }
      if (mounted) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('SignupScreen: Unexpected error - $e',
            name: 'SignupScreen', level: 1000);
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
    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return 'An account with this email already exists. Please sign in.';
    } else if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (message.contains('password')) {
      return 'Password does not meet requirements. Please choose a stronger password.';
    } else if (message.contains('too many requests')) {
      return 'Too many signup attempts. Please wait and try again.';
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
    }
    return 'An unexpected error occurred. Please try again.';
  }

  void _navigateToDashboard() {
    final currentUser = ref.read(currentUserProvider);
    final primaryRole = currentUser?.primaryRole;

    if (kDebugMode) {
      developer.log(
          'SignupScreen: Navigating to dashboard for role: $primaryRole',
          name: 'SignupScreen');
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
      default:
        if (kDebugMode) {
          developer.log(
              'SignupScreen: No role yet (role=$primaryRole), showing pending message',
              name: 'SignupScreen',
              level: 800);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Account created! Please wait for an administrator to assign your role.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Decorative Elements — same as LoginScreen
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
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      if (_errorMessage != null) _buildErrorBanner(),
                      _buildSignupForm(),
                      const SizedBox(height: 24),
                      _buildSignInLink(),
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
          'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Join your school management platform',
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
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
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
            child:
                const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
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
              'Sign Up',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 24),

            // Full Name Field
            TextFormField(
              controller: _fullNameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon:
                    Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Phone Field (optional)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
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
                  tooltip: 'Toggle visibility',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Minimum 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignup(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  tooltip: 'Toggle visibility',
                  onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            LoadingButton(
              onPressed: _handleSignup,
              isLoading: _isLoading,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Text(
            'Sign In',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
}
