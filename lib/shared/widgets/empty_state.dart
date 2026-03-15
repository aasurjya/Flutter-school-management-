import 'package:flutter/material.dart';

/// A "no data" placeholder widget with an icon, message, and optional
/// action button.
///
/// Use this for empty list states, search-no-results, error fallbacks, etc.
class EmptyState extends StatelessWidget {
  /// Optional image path or URL. If provided, replaces the icon.
  final String? imagePath;

  /// The icon displayed above the message (if imagePath is null).
  final IconData? icon;

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

  /// Height for the image. Defaults to 200.
  final double imageHeight;

  const EmptyState({
    super.key,
    this.imagePath,
    this.icon,
    required this.message,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
    this.imageHeight = 180,
  }) : assert(imagePath != null || icon != null, 'Either imagePath or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              imagePath!.startsWith('http')
                  ? Image.network(imagePath!, height: imageHeight, fit: BoxFit.contain)
                  : Image.asset(imagePath!, height: imageHeight, fit: BoxFit.contain)
            else if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
