import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../services/payment_gateway_service.dart';

/// Razorpay payment gateway service — null if no key configured.
final paymentGatewayServiceProvider = Provider<PaymentGatewayService?>((ref) {
  final key = AppEnvironment.razorpayKeyId;
  if (key == null) return null;

  final service = PaymentGatewayService();
  ref.onDispose(() => service.dispose());
  return service;
});
