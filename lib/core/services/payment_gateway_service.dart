import 'dart:async';
import 'dart:developer' as developer;

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../config/app_environment.dart';

/// Result of a Razorpay checkout attempt.
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
  });
}

/// Wraps the Razorpay SDK with a Completer-based async flow.
class PaymentGatewayService {
  final Razorpay _razorpay;
  Completer<PaymentResult>? _completer;

  PaymentGatewayService() : _razorpay = Razorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Opens Razorpay checkout and waits for a result.
  ///
  /// [amountInPaise] — amount in smallest currency unit (100 paise = ₹1).
  Future<PaymentResult> openCheckout({
    required int amountInPaise,
    required String invoiceId,
    required String studentName,
    String? email,
    String? phone,
    String? description,
  }) {
    _completer = Completer<PaymentResult>();

    final options = <String, dynamic>{
      'key': AppEnvironment.razorpayKeyId,
      'amount': amountInPaise,
      'name': 'School Fees',
      'description': description ?? 'Invoice: $invoiceId',
      'prefill': <String, String>{
        if (email != null) 'email': email,
        if (phone != null) 'contact': phone,
      },
      'notes': <String, String>{
        'invoice_id': invoiceId,
        'student_name': studentName,
      },
      'theme': <String, String>{
        'color': '#1565C0',
      },
    };

    developer.log(
      'Opening Razorpay checkout for ₹${amountInPaise / 100}',
      name: 'PaymentGatewayService',
    );

    _razorpay.open(options);
    return _completer!.future;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    developer.log(
      'Payment success: ${response.paymentId}',
      name: 'PaymentGatewayService',
    );
    _completer?.complete(PaymentResult(
      success: true,
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    developer.log(
      'Payment failed: ${response.code} — ${response.message}',
      name: 'PaymentGatewayService',
    );
    _completer?.complete(PaymentResult(
      success: false,
      errorMessage: response.message ?? 'Payment failed (code: ${response.code})',
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log(
      'External wallet selected: ${response.walletName}',
      name: 'PaymentGatewayService',
    );
    // Treat as a cancellation — user switched to external wallet flow
    _completer?.complete(PaymentResult(
      success: false,
      errorMessage: 'Redirected to ${response.walletName}. Please check payment status.',
    ));
  }

  void dispose() {
    _razorpay.clear();
  }
}
