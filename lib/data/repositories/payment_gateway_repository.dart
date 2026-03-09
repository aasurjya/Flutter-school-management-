import '../../data/models/payment_gateway.dart';
import 'base_repository.dart';

class PaymentGatewayRepository extends BaseRepository {
  PaymentGatewayRepository(super.client);

  Future<List<PaymentGateway>> getGateways() async {
    final response = await client
        .from('payment_gateways')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('gateway_name');

    return (response as List)
        .map((json) => PaymentGateway.fromJson(json))
        .toList();
  }

  Future<PaymentGateway> toggleGateway(String id, bool isActive) async {
    final response = await client
        .from('payment_gateways')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();

    return PaymentGateway.fromJson(response);
  }

  Future<PaymentGateway> updateGatewayConfig(
    String id,
    Map<String, dynamic> config, {
    bool? isTestMode,
  }) async {
    final updates = <String, dynamic>{
      'config': config,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (isTestMode != null) {
      updates['is_test_mode'] = isTestMode;
    }

    final response = await client
        .from('payment_gateways')
        .update(updates)
        .eq('id', id)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();

    return PaymentGateway.fromJson(response);
  }

  Future<PaymentGateway> upsertGateway({
    required String gatewayName,
    required String displayName,
    required bool isActive,
    bool isTestMode = true,
    String currencyCode = 'USD',
    Map<String, dynamic> config = const {},
  }) async {
    final tid = requireTenantId;
    final response = await client
        .from('payment_gateways')
        .upsert(
          {
            'tenant_id': tid,
            'gateway_name': gatewayName,
            'display_name': displayName,
            'is_active': isActive,
            'is_test_mode': isTestMode,
            'currency_code': currencyCode,
            'config': config,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'tenant_id,gateway_name',
        )
        .select()
        .single();

    return PaymentGateway.fromJson(response);
  }

  Future<List<PaymentTransaction>> getTransactions({
    String? studentId,
    String? invoiceId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('payment_transactions')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (invoiceId != null) {
      query = query.eq('invoice_id', invoiceId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => PaymentTransaction.fromJson(json))
        .toList();
  }

  Future<PaymentTransaction> initiatePayment({
    required String invoiceId,
    required String studentId,
    required String gateway,
    required double amount,
    String currencyCode = 'USD',
    String? paymentMethod,
  }) async {
    final response = await client
        .from('payment_transactions')
        .insert({
          'tenant_id': requireTenantId,
          'invoice_id': invoiceId,
          'student_id': studentId,
          'gateway_name': gateway,
          'amount': amount,
          'currency_code': currencyCode,
          'status': 'pending',
          'payment_method': paymentMethod,
        })
        .select()
        .single();

    return PaymentTransaction.fromJson(response);
  }

  Future<PaymentTransaction> updateTransactionStatus(
    String id,
    TransactionStatus status, {
    String? gatewayTxId,
    String? failureReason,
  }) async {
    final updates = <String, dynamic>{
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (gatewayTxId != null) {
      updates['gateway_transaction_id'] = gatewayTxId;
    }
    if (failureReason != null) {
      updates['failure_reason'] = failureReason;
    }
    if (status == TransactionStatus.success) {
      updates['paid_at'] = DateTime.now().toIso8601String();
    }

    final response = await client
        .from('payment_transactions')
        .update(updates)
        .eq('id', id)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();

    return PaymentTransaction.fromJson(response);
  }
}
