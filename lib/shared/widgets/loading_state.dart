import 'package:flutter/material.dart';

/// A centered loading indicator with an optional message.
///
/// Use this instead of manually wrapping [CircularProgressIndicator]
/// in a [Center] widget throughout the app.
class LoadingState extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  /// Size of the progress indicator. Defaults to 36.
  final double size;

  /// Color of the progress indicator. Defaults to the theme's primary color.
  final Color? color;

  const LoadingState({
    super.key,
    this.message,
    this.size = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
