import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/payment_gateway.dart';
import '../../../data/repositories/payment_gateway_repository.dart';

final paymentGatewayRepositoryProvider =
    Provider<PaymentGatewayRepository>((ref) {
  return PaymentGatewayRepository(ref.watch(supabaseProvider));
});

// ---------------------------------------------------------------------------
// Gateways list
// ---------------------------------------------------------------------------

class GatewaysNotifier extends AsyncNotifier<List<PaymentGateway>> {
  @override
  Future<List<PaymentGateway>> build() async {
    final repo = ref.watch(paymentGatewayRepositoryProvider);
    return repo.getGateways();
  }

  Future<void> toggle(String id, bool isActive) async {
    final repo = ref.read(paymentGatewayRepositoryProvider);
    final updated = await repo.toggleGateway(id, isActive);

    state = state.whenData((gateways) {
      return gateways.map((g) => g.id == id ? updated : g).toList();
    });
  }

  Future<void> saveConfig(
    String id,
    Map<String, dynamic> config, {
    bool? isTestMode,
  }) async {
    final repo = ref.read(paymentGatewayRepositoryProvider);
    final updated = await repo.updateGatewayConfig(
      id,
      config,
      isTestMode: isTestMode,
    );

    state = state.whenData((gateways) {
      return gateways.map((g) => g.id == id ? updated : g).toList();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(paymentGatewayRepositoryProvider);
      return repo.getGateways();
    });
  }
}

final gatewaysProvider =
    AsyncNotifierProvider<GatewaysNotifier, List<PaymentGateway>>(
  GatewaysNotifier.new,
);

// ---------------------------------------------------------------------------
// Transactions list — takes optional invoiceId param
// ---------------------------------------------------------------------------

class TransactionsFilter {
  final String? invoiceId;
  final String? studentId;
  final String? status;

  const TransactionsFilter({
    this.invoiceId,
    this.studentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionsFilter &&
          other.invoiceId == invoiceId &&
          other.studentId == studentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(invoiceId, studentId, status);
}

final transactionsProvider = FutureProvider.family<List<PaymentTransaction>,
    TransactionsFilter>((ref, filter) async {
  final repo = ref.watch(paymentGatewayRepositoryProvider);
  return repo.getTransactions(
    invoiceId: filter.invoiceId,
    studentId: filter.studentId,
    status: filter.status,
  );
});

// ---------------------------------------------------------------------------
// Initiate payment — StateNotifier for payment flow
// ---------------------------------------------------------------------------

enum PaymentFlowState { idle, processing, success, failure }

class PaymentFlowData {
  final PaymentFlowState state;
  final PaymentTransaction? transaction;
  final String? errorMessage;

  const PaymentFlowData({
    required this.state,
    this.transaction,
    this.errorMessage,
  });

  const PaymentFlowData.idle()
      : state = PaymentFlowState.idle,
        transaction = null,
        errorMessage = null;

  PaymentFlowData copyWith({
    PaymentFlowState? state,
    PaymentTransaction? transaction,
    String? errorMessage,
  }) {
    return PaymentFlowData(
      state: state ?? this.state,
      transaction: transaction ?? this.transaction,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class InitiatePaymentNotifier extends StateNotifier<PaymentFlowData> {
  final PaymentGatewayRepository _repo;

  InitiatePaymentNotifier(this._repo) : super(const PaymentFlowData.idle());

  Future<void> pay({
    required String invoiceId,
    required String studentId,
    required String gateway,
    required double amount,
    String currencyCode = 'USD',
  }) async {
    state = const PaymentFlowData(state: PaymentFlowState.processing);

    try {
      // Create a pending transaction record
      final tx = await _repo.initiatePayment(
        invoiceId: invoiceId,
        studentId: studentId,
        gateway: gateway,
        amount: amount,
        currencyCode: currencyCode,
      );

      // Simulate gateway call — in production this would launch a gateway SDK
      await Future.delayed(const Duration(seconds: 2));

      // Mark as success (real integration would do this via webhook / callback)
      final gatewayTxId =
          'TXN-${DateTime.now().millisecondsSinceEpoch}';
      final successTx = await _repo.updateTransactionStatus(
        tx.id,
        TransactionStatus.success,
        gatewayTxId: gatewayTxId,
      );

      state = PaymentFlowData(
        state: PaymentFlowState.success,
        transaction: successTx,
      );
    } catch (e) {
      state = PaymentFlowData(
        state: PaymentFlowState.failure,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const PaymentFlowData.idle();
  }
}

final initiatePaymentProvider =
    StateNotifierProvider<InitiatePaymentNotifier, PaymentFlowData>((ref) {
  final repo = ref.watch(paymentGatewayRepositoryProvider);
  return InitiatePaymentNotifier(repo);
});
