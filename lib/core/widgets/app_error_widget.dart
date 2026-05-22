import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Normalizes raw exception/error objects into user-friendly copy.
/// Catches the two most common StateErrors that leak into screens:
/// - "tenantId is null" → likely stale session / super_admin on tenant route
/// - "currentUserId is null" → mid-logout race
/// Falls back to a generic message; never surfaces stack traces.
({String title, String message, bool sessionInvalid}) describeAppError(
    Object? error) {
  final raw = error?.toString() ?? '';
  if (raw.contains('tenantId is null')) {
    return (
      title: 'Session expired',
      message: 'Please sign in again to continue.',
      sessionInvalid: true,
    );
  }
  if (raw.contains('currentUserId is null')) {
    return (
      title: 'Not signed in',
      message: 'Please sign in to continue.',
      sessionInvalid: true,
    );
  }
  return (
    title: 'Something went wrong',
    message: 'Please try again. If the problem persists, contact support.',
    sessionInvalid: false,
  );
}

/// Standard error state widget used across all screens
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry})
      : title = null;

  const AppErrorWidget._titled({
    required this.title,
    required this.message,
    this.onRetry,
  });

  /// Build from a raw exception object — normalizes Dart [StateError]s for
  /// "tenantId is null" / "currentUserId is null" into friendly copy.
  factory AppErrorWidget.fromError(Object? error, {VoidCallback? onRetry}) {
    final d = describeAppError(error);
    return AppErrorWidget._titled(
      title: d.title,
      message: d.message,
      onRetry: onRetry,
    );
  }

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard empty state widget
class AppEmptyWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmptyWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.grey400, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Get started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
