import 'package:flutter/material.dart';

/// A "no data" placeholder widget with an icon, message, and optional
/// action button.
///
/// Use this for empty list states, search-no-results, error fallbacks, etc.
class EmptyState extends StatelessWidget {
  /// The icon displayed above the message.
  final IconData icon;

  /// Primary message (e.g., "No students found").
  final String message;

  /// Optional secondary/description text.
  final String? description;

  /// Optional action button label. When set, [onAction] must also be provided.
  final String? actionLabel;

  /// Callback for the action button.
  final VoidCallback? onAction;

  /// Icon size. Defaults to 64.
  final double iconSize;

  /// Icon color. Defaults to grey[400].
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
