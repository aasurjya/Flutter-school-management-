import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum GatewayName { stripe, razorpay, paystack, flutterwave, mpesa, manual }

enum TransactionStatus {
  pending,
  processing,
  success,
  failed,
  refunded,
  cancelled,
}

extension GatewayNameX on GatewayName {
  String get value {
    switch (this) {
      case GatewayName.stripe:
        return 'stripe';
      case GatewayName.razorpay:
        return 'razorpay';
      case GatewayName.paystack:
        return 'paystack';
      case GatewayName.flutterwave:
        return 'flutterwave';
      case GatewayName.mpesa:
        return 'mpesa';
      case GatewayName.manual:
        return 'manual';
    }
  }

  static GatewayName fromString(String value) {
    switch (value) {
      case 'stripe':
        return GatewayName.stripe;
      case 'razorpay':
        return GatewayName.razorpay;
      case 'paystack':
        return GatewayName.paystack;
      case 'flutterwave':
        return GatewayName.flutterwave;
      case 'mpesa':
        return GatewayName.mpesa;
      default:
        return GatewayName.manual;
    }
  }

  Color get brandColor {
    switch (this) {
      case GatewayName.stripe:
        return const Color(0xFF635BFF);
      case GatewayName.razorpay:
        return const Color(0xFF3395FF);
      case GatewayName.paystack:
        return const Color(0xFF00C3F7);
      case GatewayName.flutterwave:
        return const Color(0xFFF5A623);
      case GatewayName.mpesa:
        return const Color(0xFF00A651);
      case GatewayName.manual:
        return AppColors.grey500;
    }
  }

  IconData get icon {
    switch (this) {
      case GatewayName.stripe:
        return Icons.credit_card;
      case GatewayName.razorpay:
        return Icons.payment;
      case GatewayName.paystack:
        return Icons.account_balance_wallet;
      case GatewayName.flutterwave:
        return Icons.waves;
      case GatewayName.mpesa:
        return Icons.phone_android;
      case GatewayName.manual:
        return Icons.handshake_outlined;
    }
  }
}

extension TransactionStatusX on TransactionStatus {
  String get value {
    switch (this) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.processing:
        return 'processing';
      case TransactionStatus.success:
        return 'success';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.refunded:
        return 'refunded';
      case TransactionStatus.cancelled:
        return 'cancelled';
    }
  }

  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'processing':
        return TransactionStatus.processing;
      case 'success':
        return TransactionStatus.success;
      case 'failed':
        return TransactionStatus.failed;
      case 'refunded':
        return TransactionStatus.refunded;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }
}

class PaymentGateway {
  final String id;
  final String tenantId;
  final GatewayName gatewayName;
  final bool isActive;
  final bool isTestMode;
  final String displayName;
  final String currencyCode;
  final Map<String, dynamic> config;
  final DateTime createdAt;

  const PaymentGateway({
    required this.id,
    required this.tenantId,
    required this.gatewayName,
    required this.isActive,
    required this.isTestMode,
    required this.displayName,
    required this.currencyCode,
    required this.config,
    required this.createdAt,
  });

  factory PaymentGateway.fromJson(Map<String, dynamic> json) {
    return PaymentGateway(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      gatewayName: GatewayNameX.fromString(json['gateway_name'] as String),
      isActive: (json['is_active'] as bool?) ?? false,
      isTestMode: (json['is_test_mode'] as bool?) ?? true,
      displayName: json['display_name'] as String,
      currencyCode: (json['currency_code'] as String?) ?? 'USD',
      config: (json['config'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'gateway_name': gatewayName.value,
      'is_active': isActive,
      'is_test_mode': isTestMode,
      'display_name': displayName,
      'currency_code': currencyCode,
      'config': config,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentGateway copyWith({
    bool? isActive,
    bool? isTestMode,
    Map<String, dynamic>? config,
    String? displayName,
    String? currencyCode,
  }) {
    return PaymentGateway(
      id: id,
      tenantId: tenantId,
      gatewayName: gatewayName,
      isActive: isActive ?? this.isActive,
      isTestMode: isTestMode ?? this.isTestMode,
      displayName: displayName ?? this.displayName,
      currencyCode: currencyCode ?? this.currencyCode,
      config: config ?? this.config,
      createdAt: createdAt,
    );
  }
}

class PaymentTransaction {
  final String id;
  final String tenantId;
  final String? invoiceId;
  final String? studentId;
  final String gatewayName;
  final String? gatewayTransactionId;
  final double amount;
  final String currencyCode;
  final TransactionStatus status;
  final String? paymentMethod;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.tenantId,
    this.invoiceId,
    this.studentId,
    required this.gatewayName,
    this.gatewayTransactionId,
    required this.amount,
    required this.currencyCode,
    required this.status,
    this.paymentMethod,
    this.failureReason,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      invoiceId: json['invoice_id'] as String?,
      studentId: json['student_id'] as String?,
      gatewayName: json['gateway_name'] as String,
      gatewayTransactionId: json['gateway_transaction_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: (json['currency_code'] as String?) ?? 'USD',
      status: TransactionStatusX.fromString(
          (json['status'] as String?) ?? 'pending'),
      paymentMethod: json['payment_method'] as String?,
      failureReason: json['failure_reason'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'invoice_id': invoiceId,
      'student_id': studentId,
      'gateway_name': gatewayName,
      'gateway_transaction_id': gatewayTransactionId,
      'amount': amount,
      'currency_code': currencyCode,
      'status': status.value,
      'payment_method': paymentMethod,
      'failure_reason': failureReason,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isSuccess => status == TransactionStatus.success;

  String get statusLabel =>
      status.name[0].toUpperCase() + status.name.substring(1);

  Color get statusColor {
    switch (status) {
      case TransactionStatus.success:
        return AppColors.success;
      case TransactionStatus.failed:
        return AppColors.error;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.processing:
        return AppColors.info;
      default:
        return AppColors.grey500;
    }
  }
}
