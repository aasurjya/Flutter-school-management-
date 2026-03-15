import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../data/models/payment_gateway.dart';
import '../../providers/payment_gateway_provider.dart';

class PaymentGatewayScreen extends ConsumerWidget {
  const PaymentGatewayScreen({super.key});

  static const _allGateways = [
    GatewayName.stripe,
    GatewayName.razorpay,
    GatewayName.paystack,
    GatewayName.flutterwave,
    GatewayName.mpesa,
    GatewayName.manual,
  ];

  static const _defaultDisplayNames = {
    GatewayName.stripe: 'Stripe',
    GatewayName.razorpay: 'Razorpay',
    GatewayName.paystack: 'Paystack',
    GatewayName.flutterwave: 'Flutterwave',
    GatewayName.mpesa: 'M-Pesa',
    GatewayName.manual: 'Manual Payment',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatewaysAsync = ref.watch(gatewaysProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Payment Gateways'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: gatewaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(gatewaysProvider),
        ),
        data: (gateways) => _GatewayList(
          gateways: gateways,
          allGateways: _allGateways,
          defaultDisplayNames: _defaultDisplayNames,
        ),
      ),
    );
  }
}

class _GatewayList extends ConsumerWidget {
  final List<PaymentGateway> gateways;
  final List<GatewayName> allGateways;
  final Map<GatewayName, String> defaultDisplayNames;

  const _GatewayList({
    required this.gateways,
    required this.allGateways,
    required this.defaultDisplayNames,
  });

  PaymentGateway? _findGateway(GatewayName name) {
    try {
      return gateways.firstWhere((g) => g.gatewayName == name);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.read(gatewaysProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Configure payment gateways for your school. Enable the ones '
              'you want to offer to parents and students.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ),
          ...allGateways.map((gatewayName) {
            final existing = _findGateway(gatewayName);
            return _GatewayCard(
              gatewayName: gatewayName,
              existing: existing,
              displayName: existing?.displayName ??
                  defaultDisplayNames[gatewayName] ??
                  gatewayName.name,
            );
          }),
        ],
      ),
    );
  }
}

class _GatewayCard extends ConsumerWidget {
  final GatewayName gatewayName;
  final PaymentGateway? existing;
  final String displayName;

  const _GatewayCard({
    required this.gatewayName,
    required this.existing,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = existing?.isActive ?? false;
    final isTestMode = existing?.isTestMode ?? true;
    final brandColor = gatewayName.brandColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? brandColor.withValues(alpha: 0.4) : AppColors.borderLight,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gateway icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                gatewayName.icon,
                color: brandColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Name & badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey900,
                                ),
                      ),
                      if (isTestMode && isActive) ...[
                        const SizedBox(width: 8),
                        const _Badge(label: 'Test', color: AppColors.warning),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? 'Active' : 'Disabled',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive ? AppColors.success : AppColors.grey400,
                        ),
                  ),
                ],
              ),
            ),
            // Configure button
            if (existing != null)
              TextButton(
                onPressed: () => _showConfigSheet(context, ref, existing!),
                style: TextButton.styleFrom(
                  foregroundColor: brandColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Configure'),
              ),
            const SizedBox(width: 8),
            // Toggle switch
            Switch(
              value: isActive,
              activeThumbColor: brandColor,
              onChanged: (val) => _handleToggle(context, ref, val),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggle(
      BuildContext context, WidgetRef ref, bool value) async {
    if (existing == null) {
      // Gateway not configured yet — prompt configuration first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please configure the gateway before enabling it.'),
        ),
      );
      return;
    }
    try {
      await ref.read(gatewaysProvider.notifier).toggle(existing!.id, value);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showConfigSheet(
      BuildContext context, WidgetRef ref, PaymentGateway gateway) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GatewayConfigSheet(gateway: gateway),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GatewayConfigSheet extends ConsumerStatefulWidget {
  final PaymentGateway gateway;

  const _GatewayConfigSheet({required this.gateway});

  @override
  ConsumerState<_GatewayConfigSheet> createState() =>
      _GatewayConfigSheetState();
}

class _GatewayConfigSheetState extends ConsumerState<_GatewayConfigSheet> {
  late final TextEditingController _publicKeyCtrl;
  late final TextEditingController _secretKeyCtrl;
  late final TextEditingController _webhookCtrl;
  late bool _isTestMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.gateway.config;
    _publicKeyCtrl =
        TextEditingController(text: cfg['public_key'] as String? ?? '');
    _secretKeyCtrl =
        TextEditingController(text: cfg['secret_key'] as String? ?? '');
    _webhookCtrl =
        TextEditingController(text: cfg['webhook_secret'] as String? ?? '');
    _isTestMode = widget.gateway.isTestMode;
  }

  @override
  void dispose() {
    _publicKeyCtrl.dispose();
    _secretKeyCtrl.dispose();
    _webhookCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final config = <String, dynamic>{
        if (_publicKeyCtrl.text.isNotEmpty)
          'public_key': _publicKeyCtrl.text.trim(),
        if (_secretKeyCtrl.text.isNotEmpty)
          'secret_key': _secretKeyCtrl.text.trim(),
        if (_webhookCtrl.text.isNotEmpty)
          'webhook_secret': _webhookCtrl.text.trim(),
      };
      await ref.read(gatewaysProvider.notifier).saveConfig(
            widget.gateway.id,
            config,
            isTestMode: _isTestMode,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = widget.gateway.gatewayName.brandColor;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.gateway.gatewayName.icon,
                    color: brandColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Configure ${widget.gateway.displayName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ConfigField(
            controller: _publicKeyCtrl,
            label: 'Public / Publishable Key',
            hint: 'pk_test_...',
          ),
          const SizedBox(height: 12),
          _ConfigField(
            controller: _secretKeyCtrl,
            label: 'Secret Key',
            hint: 'sk_test_...',
            obscure: true,
          ),
          const SizedBox(height: 12),
          _ConfigField(
            controller: _webhookCtrl,
            label: 'Webhook Secret (optional)',
            hint: 'whsec_...',
            obscure: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _isTestMode,
                activeThumbColor: AppColors.warning,
                onChanged: (val) => setState(() => _isTestMode = val),
              ),
              const SizedBox(width: 8),
              Text(
                'Test / Sandbox mode',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: brandColor),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;

  const _ConfigField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}
