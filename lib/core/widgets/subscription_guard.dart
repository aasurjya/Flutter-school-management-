import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/subscription_plan.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';

/// Wraps a feature screen and gates it behind a subscription feature flag.
///
/// On first build it calls `enforce-subscription?feature=<featureKey>`.
/// While loading, shows a centered spinner.
/// If allowed → renders [child].
/// If blocked → renders an upgrade prompt with [onUpgrade] (defaults to
/// pushing the super-admin subscription checkout screen).
///
/// Usage:
///   SubscriptionGuard(
///     featureKey: 'whatsapp',
///     child: WhatsAppSettingsScreen(),
///   )
class SubscriptionGuard extends ConsumerStatefulWidget {
  final String featureKey;
  final Widget child;
  final VoidCallback? onUpgrade;
  final String? blockedMessage;

  const SubscriptionGuard({
    super.key,
    required this.featureKey,
    required this.child,
    this.onUpgrade,
    this.blockedMessage,
  });

  @override
  ConsumerState<SubscriptionGuard> createState() => _SubscriptionGuardState();
}

class _SubscriptionGuardState extends ConsumerState<SubscriptionGuard> {
  SubscriptionVerdict? _verdict;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    try {
      final v = await ref
          .read(subscriptionServiceProvider)
          .checkFeature(widget.featureKey);
      if (!mounted) return;
      setState(() {
        _verdict = v;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fail-open: if the gate is unreachable, show the feature rather than
      // locking a paid tenant out due to a transient edge-function error.
      setState(() {
        _loading = false;
        _verdict = const SubscriptionVerdict(
          allowed: true,
          reason: 'gate_unreachable_fail_open',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final v = _verdict;
    if (v == null || v.allowed) {
      return widget.child;
    }
    return _UpgradePrompt(
      featureKey: widget.featureKey,
      planId: v.planId,
      message:
          widget.blockedMessage ?? 'This feature is not available on your plan.',
      onUpgrade: widget.onUpgrade,
    );
  }
}

class _UpgradePrompt extends StatelessWidget {
  final String featureKey;
  final String? planId;
  final String message;
  final VoidCallback? onUpgrade;

  const _UpgradePrompt({
    required this.featureKey,
    required this.message,
    this.planId,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 56,
              color: AppColors.separator,
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUpgrade ??
                  () => Navigator.of(context).pushNamed('/super-admin/billing'),
              icon: const Icon(Icons.upgrade),
              label: const Text('View plans'),
            ),
          ],
        ),
      ),
    );
  }
}
