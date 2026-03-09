import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';

/// A slim banner rendered at the top of the app shell whenever the device is
/// offline.  Uses [AnimatedContainer] to slide in/out smoothly.
///
/// Place it directly above the main content child in the scaffold body:
/// ```dart
/// Column(
///   children: [
///     const OfflineBanner(),
///     Expanded(child: child),
///   ],
/// )
/// ```
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.when(
      data: (v) => v,
      loading: () => true,
      error: (_, __) => true,
    );

    // Collapsed height when online, expanded when offline
    const expandedHeight = 40.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOnline ? 0.0 : expandedHeight,
      color: AppColors.warning,
      child: isOnline
          ? const SizedBox.shrink()
          : const _BannerContent(),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              "You're offline \u2022 Changes will sync when connected",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
