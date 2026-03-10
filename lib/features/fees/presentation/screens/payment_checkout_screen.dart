import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../data/models/payment_gateway.dart';
import '../../providers/fees_provider.dart';
import '../../providers/payment_gateway_provider.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const PaymentCheckoutScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState
    extends ConsumerState<PaymentCheckoutScreen> {
  String? _selectedGateway;

  @override
  Widget build(BuildContext context) {
    final invoiceAsync =
        ref.watch(invoiceByIdProvider(widget.invoiceId));
    final gatewaysAsync = ref.watch(gatewaysProvider);
    final paymentFlow = ref.watch(initiatePaymentProvider);

    // Show success overlay
    if (paymentFlow.state == PaymentFlowState.success) {
      return _SuccessScreen(
        transaction: paymentFlow.transaction!,
        onDone: () {
          ref.read(initiatePaymentProvider.notifier).reset();
          Navigator.of(context).pop(true);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pay Invoice'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AppErrorWidget(message: e.toString()),
        data: (invoice) {
          if (invoice == null) {
            return const AppErrorWidget(message: 'Invoice not found.');
          }
          return gatewaysAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorWidget(message: e.toString()),
            data: (gateways) {
              final activeGateways =
                  gateways.where((g) => g.isActive).toList();
              return _CheckoutBody(
                invoice: invoice,
                activeGateways: activeGateways,
                selectedGateway: _selectedGateway,
                paymentFlow: paymentFlow,
                onGatewaySelected: (g) =>
                    setState(() => _selectedGateway = g),
                onPay: () => _handlePay(invoice),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handlePay(dynamic invoice) async {
    if (_selectedGateway == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    final studentId = invoice.studentId as String? ?? '';
    final amount = (invoice.totalAmount as num?)?.toDouble() ?? 0.0;

    await ref.read(initiatePaymentProvider.notifier).pay(
          invoiceId: widget.invoiceId,
          studentId: studentId,
          gateway: _selectedGateway!,
          amount: amount,
        );
  }
}

class _CheckoutBody extends StatelessWidget {
  final dynamic invoice;
  final List<PaymentGateway> activeGateways;
  final String? selectedGateway;
  final PaymentFlowData paymentFlow;
  final ValueChanged<String?> onGatewaySelected;
  final VoidCallback onPay;

  const _CheckoutBody({
    required this.invoice,
    required this.activeGateways,
    required this.selectedGateway,
    required this.paymentFlow,
    required this.onGatewaySelected,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isProcessing = paymentFlow.state == PaymentFlowState.processing;
    final hasFailed = paymentFlow.state == PaymentFlowState.failure;
    final currFmt = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice summary card
          _InvoiceSummaryCard(invoice: invoice, currFmt: currFmt),
          const SizedBox(height: 20),

          // Error state
          if (hasFailed && paymentFlow.errorMessage != null) ...[
            _ErrorBanner(message: paymentFlow.errorMessage!),
            const SizedBox(height: 16),
          ],

          // Gateway selection
          Text(
            'Choose Payment Method',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
          ),
          const SizedBox(height: 12),

          if (activeGateways.isEmpty)
            const AppEmptyWidget(
              message: 'No payment methods available',
              subtitle:
                  'Contact your school admin to set up a payment gateway.',
              icon: Icons.payment_outlined,
            )
          else
            ...activeGateways.map((gw) => _GatewayRadioCard(
                  gateway: gw,
                  isSelected: selectedGateway == gw.gatewayName.value,
                  onTap: () => onGatewaySelected(gw.gatewayName.value),
                )),

          const SizedBox(height: 24),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed:
                  isProcessing || activeGateways.isEmpty ? null : onPay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing…',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Text(
                      'Pay ${currFmt.format((invoice.totalAmount as num?)?.toDouble() ?? 0)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final dynamic invoice;
  final NumberFormat currFmt;

  const _InvoiceSummaryCard(
      {required this.invoice, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final student = invoice.student;
    final studentName = student != null
        ? '${student.firstName} ${student.lastName}'
        : 'Student';
    final dueDate = invoice.dueDate != null
        ? DateFormat.yMMMd().format(invoice.dueDate as DateTime)
        : 'N/A';
    final amount = (invoice.totalAmount as num?)?.toDouble() ?? 0.0;
    final invoiceNumber =
        invoice.invoiceNumber as String? ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                invoiceNumber,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            studentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Due: $dueDate',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            currFmt.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayRadioCard extends StatelessWidget {
  final PaymentGateway gateway;
  final bool isSelected;
  final VoidCallback onTap;

  const _GatewayRadioCard({
    required this.gateway,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = gateway.gatewayName.brandColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? brandColor : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(gateway.gatewayName.icon, color: brandColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gateway.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (gateway.isTestMode)
                    const Text(
                      'Sandbox mode',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
            _RadioDot<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: brandColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payment failed. Please try again.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final PaymentTransaction transaction;
  final VoidCallback onDone;

  const _SuccessScreen({required this.transaction, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(symbol: '\$');
    final dateStr = transaction.paidAt != null
        ? DateFormat.yMMMd().add_jm().format(transaction.paidAt!)
        : DateFormat.yMMMd().add_jm().format(transaction.createdAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Successful',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                currFmt.format(transaction.amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
              ),
              const SizedBox(height: 32),
              // Receipt details
              _ReceiptRow(label: 'Transaction ID',
                  value: transaction.gatewayTransactionId ?? transaction.id),
              const Divider(height: 24),
              _ReceiptRow(label: 'Gateway',
                  value: transaction.gatewayName.toUpperCase()),
              const Divider(height: 24),
              _ReceiptRow(label: 'Date & Time', value: dateStr),
              const Divider(height: 24),
              _ReceiptRow(
                label: 'Status',
                value: transaction.statusLabel,
                valueColor: AppColors.success,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.grey900,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RadioDot<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final Color activeColor;

  const _RadioDot({
    super.key,
    required this.value,
    required this.groupValue,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? activeColor : const Color(0xFF9CA3AF),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            )
          : null,
    );
  }
}
