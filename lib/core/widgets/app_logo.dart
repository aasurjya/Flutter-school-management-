import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Campusly logo — cursive "C" monogram icon with optional wordmark
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            size > 128
                ? 'assets/icons/logo-512.png'
                : 'assets/icons/logo-192.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'Campusly',
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
