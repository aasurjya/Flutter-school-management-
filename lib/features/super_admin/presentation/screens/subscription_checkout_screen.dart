import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/services/payment_gateway_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/subscription_plan.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/tenant_provider.dart';

/// Super-admin screen: pick a plan → pay via Razorpay → webhook bumps tenant.
///
/// Shows the plan catalog from `subscription_plans`, lets the super-admin
/// select one, then opens Razorpay checkout via `openSubscriptionCheckout`.
/// On success the client inserts a `subscription_invoices` row (status=paid)
/// as a fallback in case the webhook is delayed; the webhook is the source
/// of truth and will upsert on `razorpay_payment_id`.
class SubscriptionCheckoutScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const SubscriptionCheckoutScreen({super.key, required this.tenantId});

  @override
  ConsumerState<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState
    extends ConsumerState<SubscriptionCheckoutScreen> {
  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  String? _error;
  int? _selectedIndex;
  bool _paying = false;
  final _paymentService = PaymentGatewayService();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans =
          await ref.read(subscriptionServiceProvider).listPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_selectedIndex == null) return;
    final plan = _plans[_selectedIndex!];
    setState(() => _paying = true);
    try {
      final result = await _paymentService.openSubscriptionCheckout(
        amountInPaise: plan.priceInrPaise,
        tenantId: widget.tenantId,
        planId: plan.id,
        planDisplayName: plan.displayName,
      );
      if (!mounted) return;
      if (result.success) {
        // Optimistically refresh tenant data; webhook will reconcile.
        ref.invalidate(tenantByIdProvider(widget.tenantId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment received. Plan will update to ${plan.displayName} shortly.',
            ),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Payment failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't start the payment. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(WarmCopy.loadFailed('plans')),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plans.length,
                  itemBuilder: (context, i) {
                    final plan = _plans[i];
                    final selected = _selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selectedIndex = i),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected
                                      ? const Color(0xFF1565C0)
                                      : AppColors.separator,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${plan.maxStudents == 100000 ? 'Unlimited' : plan.maxStudents} students · '
                                        '₹${plan.priceInr}/year · '
                                        '\$${plan.aiCreditsUsd.toStringAsFixed(2)} AI/day',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        children: plan.featureFlags.entries
                                            .where((e) => e.value)
                                            .map((e) => Chip(
                                                  label: Text(e.key),
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  labelStyle:
                                                      const TextStyle(
                                                          fontSize: 10),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _loading || _plans.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed:
                      _selectedIndex == null || _paying ? null : _pay,
                  child: _paying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selectedIndex == null
                              ? 'Select a plan'
                              : 'Pay ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_plans[_selectedIndex!].priceInr)}',
                        ),
                ),
              ),
            ),
    );
  }
}
