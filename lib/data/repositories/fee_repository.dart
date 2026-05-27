import '../../core/net/idempotency.dart';
import '../../core/net/retry.dart';
import '../models/invoice.dart';
import '../models/fee_default_prediction.dart';
import 'base_repository.dart';

class FeeRepository extends BaseRepository {
  FeeRepository(super.client);

  // ---------------------------------------------------------------------------
  // Null-safe row mappers.
  //
  // Supabase returns snake_case columns, but the Freezed models' generated
  // fromJson expects camelCase — and the joined display fields live in nested
  // objects the generated parser can't read. So map rows manually, null-safe,
  // mirroring the timetable repository's approach.
  // ---------------------------------------------------------------------------

  static String _str(Object? v) => (v as String?) ?? '';
  static double _dbl(Object? v) => (v as num?)?.toDouble() ?? 0;
  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;
  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  FeeHead _feeHeadFromRow(Map<String, dynamic> j) => FeeHead(
        id: _str(j['id']),
        tenantId: _str(j['tenant_id']),
        name: _str(j['name']),
        code: j['code'] as String?,
        description: j['description'] as String?,
        isRecurring: j['is_recurring'] as bool? ?? true,
        createdAt: _date(j['created_at']),
      );

  FeeStructure _feeStructureFromRow(Map<String, dynamic> j) {
    final feeHead = j['fee_heads'] as Map<String, dynamic>?;
    final cls = j['classes'] as Map<String, dynamic>?;
    final year = j['academic_years'] as Map<String, dynamic>?;
    final term = j['terms'] as Map<String, dynamic>?;
    return FeeStructure(
      id: _str(j['id']),
      tenantId: _str(j['tenant_id']),
      academicYearId: _str(j['academic_year_id']),
      classId: _str(j['class_id']),
      feeHeadId: _str(j['fee_head_id']),
      amount: _dbl(j['amount']),
      dueDate: _date(j['due_date']),
      termId: j['term_id'] as String?,
      isMandatory: j['is_mandatory'] as bool? ?? true,
      createdAt: _date(j['created_at']),
      feeHeadName: feeHead?['name'] as String?,
      className: cls?['name'] as String?,
      academicYearName: year?['name'] as String?,
      termName: term?['name'] as String?,
    );
  }

  InvoiceItem _invoiceItemFromRow(Map<String, dynamic> j) {
    final feeHead = j['fee_heads'] as Map<String, dynamic>?;
    return InvoiceItem(
      id: _str(j['id']),
      invoiceId: _str(j['invoice_id']),
      feeHeadId: _str(j['fee_head_id']),
      description: j['description'] as String?,
      amount: _dbl(j['amount']),
      discount: _dbl(j['discount']),
      feeHeadName: feeHead?['name'] as String?,
    );
  }

  Invoice _invoiceFromRow(Map<String, dynamic> j) {
    final student = j['students'] as Map<String, dynamic>?;
    final year = j['academic_years'] as Map<String, dynamic>?;
    final term = j['terms'] as Map<String, dynamic>?;
    // section/class come via student_enrollments (only on getInvoiceById).
    final enrollments = student?['student_enrollments'] as List?;
    final firstEnroll = (enrollments != null && enrollments.isNotEmpty)
        ? enrollments.first as Map<String, dynamic>?
        : null;
    final section = firstEnroll?['sections'] as Map<String, dynamic>?;
    final cls = section?['classes'] as Map<String, dynamic>?;

    String? studentName;
    if (student != null) {
      final full =
          '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
      studentName = full.isEmpty ? null : full;
    }

    final itemsRaw = j['invoice_items'] as List?;
    final paymentsRaw = j['payments'] as List?;

    return Invoice(
      id: _str(j['id']),
      tenantId: _str(j['tenant_id']),
      invoiceNumber: _str(j['invoice_number']),
      studentId: _str(j['student_id']),
      academicYearId: _str(j['academic_year_id']),
      termId: j['term_id'] as String?,
      totalAmount: _dbl(j['total_amount']),
      discountAmount: _dbl(j['discount_amount']),
      paidAmount: _dbl(j['paid_amount']),
      dueDate: _date(j['due_date']) ?? DateTime.now(),
      status: (j['status'] as String?) ?? 'pending',
      notes: j['notes'] as String?,
      generatedBy: j['generated_by'] as String?,
      createdAt: _date(j['created_at']),
      updatedAt: _date(j['updated_at']),
      studentName: studentName,
      admissionNumber: student?['admission_number'] as String?,
      sectionName: section?['name'] as String?,
      className: cls?['name'] as String?,
      academicYearName: year?['name'] as String?,
      termName: term?['name'] as String?,
      items: itemsRaw
          ?.map((e) => _invoiceItemFromRow(e as Map<String, dynamic>))
          .toList(),
      payments: paymentsRaw
          ?.map((e) => _paymentFromRow(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Payment _paymentFromRow(Map<String, dynamic> j) {
    final receivedByUser = j['users'] as Map<String, dynamic>?;
    final invoice = j['invoices'] as Map<String, dynamic>?;
    final invoiceStudent = invoice?['students'] as Map<String, dynamic>?;
    String? studentName;
    if (invoiceStudent != null) {
      final full =
          '${invoiceStudent['first_name'] ?? ''} ${invoiceStudent['last_name'] ?? ''}'
              .trim();
      studentName = full.isEmpty ? null : full;
    }
    return Payment(
      id: _str(j['id']),
      tenantId: _str(j['tenant_id']),
      invoiceId: _str(j['invoice_id']),
      paymentNumber: _str(j['payment_number']),
      amount: _dbl(j['amount']),
      paymentMethod: _str(j['payment_method']),
      status: (j['status'] as String?) ?? 'pending',
      transactionId: j['transaction_id'] as String?,
      gatewayResponse: j['gateway_response'] as Map<String, dynamic>?,
      paidAt: _date(j['paid_at']),
      receivedBy: j['received_by'] as String?,
      remarks: j['remarks'] as String?,
      createdAt: _date(j['created_at']),
      receivedByName: receivedByUser?['full_name'] as String?,
      invoiceNumber: invoice?['invoice_number'] as String?,
      studentName: studentName,
    );
  }

  FeeSummary _feeSummaryFromRow(Map<String, dynamic> j) => FeeSummary(
        tenantId: _str(j['tenant_id']),
        studentId: _str(j['student_id']),
        studentName: _str(j['student_name']),
        admissionNumber: _str(j['admission_number']),
        sectionId: _str(j['section_id']),
        sectionName: _str(j['section_name']),
        className: _str(j['class_name']),
        academicYearId: _str(j['academic_year_id']),
        academicYearName: _str(j['academic_year_name']),
        totalFee: _dbl(j['total_fee']),
        totalDiscount: _dbl(j['total_discount']),
        totalPaid: _dbl(j['total_paid']),
        totalPending: _dbl(j['total_pending']),
        totalInvoices: _int(j['total_invoices']),
        paidInvoices: _int(j['paid_invoices']),
        pendingInvoices: _int(j['pending_invoices']),
        overdueInvoices: _int(j['overdue_invoices']),
      );

  Future<List<FeeHead>> getFeeHeads() async {
    final response = await client
        .from('fee_heads')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('name');

    return (response as List)
        .map((json) => _feeHeadFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<FeeHead> createFeeHead(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('fee_heads')
        .insert(data)
        .select()
        .single();

    return _feeHeadFromRow(response);
  }

  Future<FeeHead> updateFeeHead(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('fee_heads')
        .update(data)
        .eq('id', id)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();
    return _feeHeadFromRow(response);
  }

  /// Apply a discount/concession to a specific invoice.
  /// Writes `discount_amount` and an optional `notes` line; trigger on the
  /// invoices table recomputes balance and status.
  Future<Invoice> applyInvoiceDiscount({
    required String invoiceId,
    required double discountAmount,
    String? reason,
  }) async {
    final response = await client
        .from('invoices')
        .update({
          'discount_amount': discountAmount,
          if (reason != null) 'notes': reason,
        })
        .eq('id', invoiceId)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();
    return _invoiceFromRow(response);
  }

  Future<List<FeeStructure>> getFeeStructures({
    required String academicYearId,
    String? classId,
    String? termId,
  }) async {
    var query = client
        .from('fee_structures')
        .select('''
          *,
          fee_heads(id, name, code),
          classes(id, name),
          academic_years(id, name),
          terms(id, name)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('academic_year_id', academicYearId);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (termId != null) {
      query = query.eq('term_id', termId);
    }

    final response = await query;
    return (response as List)
        .map((json) => _feeStructureFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<FeeStructure> createFeeStructure(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('fee_structures')
        .insert(data)
        .select()
        .single();

    return _feeStructureFromRow(response);
  }

  Future<List<Invoice>> getInvoices({
    String? studentId,
    String? status,
    String? academicYearId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('invoices')
        .select('''
          *,
          students(id, first_name, last_name, admission_number),
          academic_years(id, name),
          terms(id, name),
          invoice_items(*, fee_heads(id, name)),
          payments(*)
        ''')
        .eq('tenant_id', requireTenantId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }

    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _invoiceFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice?> getInvoiceById(String invoiceId) async {
    final response = await client
        .from('invoices')
        .select('''
          *,
          students(
            id, first_name, last_name, admission_number,
            student_enrollments!inner(
              sections(id, name, classes(id, name)),
              academic_years!inner(is_current)
            )
          ),
          academic_years(id, name),
          terms(id, name),
          invoice_items(*, fee_heads(id, name)),
          payments(*, users!received_by(id, full_name))
        ''')
        .eq('id', invoiceId)
        .single();

    return _invoiceFromRow(response);
  }

  Future<Invoice> createInvoice(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['generated_by'] = currentUserId;

    final response = await client
        .from('invoices')
        .insert(data)
        .select()
        .single();

    return _invoiceFromRow(response);
  }

  Future<void> addInvoiceItems(
    String invoiceId,
    List<Map<String, dynamic>> items,
  ) async {
    final records = items.map((item) => {
      ...item,
      'invoice_id': invoiceId,
    }).toList();

    await client.from('invoice_items').insert(records);
  }

  Future<int> generateClassInvoices({
    required String classId,
    required String academicYearId,
    String? termId,
    DateTime? dueDate,
  }) async {
    final response = await client.rpc('generate_class_invoices', params: {
      'p_tenant_id': tenantId,
      'p_class_id': classId,
      'p_academic_year_id': academicYearId,
      'p_term_id': termId,
      'p_due_date': dueDate?.toIso8601String().split('T')[0],
    });

    return response as int;
  }

  /// Records a payment. **The single most safety-critical write in the app.**
  ///
  /// Stage 1 / S1.8 + Stage 2 / S2.17 — every call carries a
  /// `client_request_id` that the UNIQUE(tenant_id, client_request_id) index
  /// (migration `00063`) uses to dedupe. If the gateway already returned a
  /// `gatewayPaymentId`, prefer that as the idempotency key — it's the
  /// strongest guarantee against double-charge (Razorpay returns the same
  /// payment_id on retry of the same client-side capture call).
  ///
  /// The whole insert is wrapped in [retryNetwork] which retries transient
  /// 5xx/timeout failures with jitter — exactly the failure mode that used
  /// to cause double-charges before this PR.
  Future<Payment> recordPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
    String? remarks,
    String? gatewayPaymentId,
    String? gatewayOrderId,
    String? gatewaySignature,
    String? clientRequestId,
  }) async {
    final paymentNumber = 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    // Prefer gateway-provided id as the dedup key when available — Razorpay
    // returns the same payment_id on retry of the same capture, so this is
    // a stronger guarantee than a freshly-generated UUID.
    final key = clientRequestId ?? gatewayPaymentId ?? IdempotencyKey.generate();

    final data = <String, dynamic>{
      'tenant_id': tenantId,
      'invoice_id': invoiceId,
      'payment_number': paymentNumber,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': 'completed',
      'transaction_id': transactionId ?? gatewayPaymentId,
      'paid_at': DateTime.now().toIso8601String(),
      'received_by': currentUserId,
      'remarks': remarks,
      'client_request_id': key,
    };

    if (gatewayPaymentId != null || gatewayOrderId != null) {
      data['gateway_response'] = {
        if (gatewayPaymentId != null) 'payment_id': gatewayPaymentId,
        if (gatewayOrderId != null) 'order_id': gatewayOrderId,
        if (gatewaySignature != null) 'signature': gatewaySignature,
      };
    }

    final response = await retryNetwork(
      () => client.from('payments').insert(data).select().single(),
      label: 'payments.record',
    );
    return _paymentFromRow(response);
  }

  Future<List<Payment>> getPayments({
    String? invoiceId,
    String? studentId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('payments')
        .select('''
          *,
          users!received_by(id, full_name),
          invoices(id, invoice_number, students(id, first_name, last_name))
        ''')
        .eq('tenant_id', requireTenantId);

    if (invoiceId != null) {
      query = query.eq('invoice_id', invoiceId);
    }

    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _paymentFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeeSummary>> getFeeSummaries({
    String? sectionId,
    String? classId,
    String? academicYearId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('v_fee_summary')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }

    final response = await query.range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _feeSummaryFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<FeeSummary?> getStudentFeeSummary({
    required String studentId,
    String? academicYearId,
  }) async {
    var query = client
        .from('v_fee_summary')
        .select('*')
        .eq('student_id', studentId);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }

    final response = await query.maybeSingle();
    if (response == null) return null;
    return _feeSummaryFromRow(response);
  }

  Future<Map<String, double>> getFeeCollectionStats({
    String? academicYearId,
  }) async {
    final summaries = await getFeeSummaries(academicYearId: academicYearId);
    
    double totalFee = 0;
    double totalPaid = 0;
    double totalPending = 0;
    
    for (final summary in summaries) {
      totalFee += summary.totalFee;
      totalPaid += summary.totalPaid;
      totalPending += summary.totalPending;
    }

    // Overdue: outstanding balance on past-due unpaid invoices. Defensive —
    // never let a stats sub-query break the whole screen.
    double totalOverdue = 0;
    try {
      final overdue = await getOverdueInvoices(limit: 1000);
      for (final inv in overdue) {
        totalOverdue += (inv.totalAmount - inv.discountAmount - inv.paidAmount);
      }
    } catch (_) {}

    // Today's collections: completed payments dated today.
    double todayCollected = 0;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final pays = await client
          .from('payments')
          .select('amount, paid_at, status')
          .eq('tenant_id', requireTenantId)
          .eq('status', 'completed')
          .gte('paid_at', startOfDay);
      for (final p in pays as List) {
        todayCollected += ((p as Map)['amount'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}

    return {
      // Canonical keys the screen reads.
      'total_collected': totalPaid,
      'total_pending': totalPending,
      'total_overdue': totalOverdue < 0 ? 0 : totalOverdue,
      'today_collected': todayCollected,
      // Retained for any other consumers.
      'total_fee': totalFee,
      'total_paid': totalPaid,
      'collection_percentage': totalFee > 0 ? (totalPaid / totalFee) * 100 : 0,
    };
  }

  Future<List<Invoice>> getOverdueInvoices({int limit = 50, int offset = 0}) async {
    final response = await client
        .from('invoices')
        .select('''
          *,
          students(id, first_name, last_name, admission_number)
        ''')
        .eq('tenant_id', requireTenantId)
        .inFilter('status', ['pending', 'partial'])
        .lt('due_date', DateTime.now().toIso8601String().split('T')[0])
        .order('due_date')
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => _invoiceFromRow(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== PREDICTIVE FEE COLLECTION ====================

  /// Calls the predict_fee_defaults() RPC and returns ranked risk predictions.
  Future<List<FeeDefaultPrediction>> getFeeDefaultPredictions() async {
    final tid = requireTenantId;
    final response =
        await client.rpc('predict_fee_defaults', params: {'p_tenant_id': tid});

    return (response as List)
        .map((json) => FeeDefaultPrediction.fromJson(json))
        .toList();
  }

  /// Logs that a reminder was sent for an invoice.
  Future<void> logReminderSent({
    required String invoiceId,
    required String studentId,
    required String messageText,
    required int riskScore,
    String channel = 'app',
  }) async {
    await client.from('fee_reminder_log').insert({
      'tenant_id': requireTenantId,
      'invoice_id': invoiceId,
      'student_id': studentId,
      'sent_by': client.auth.currentUser?.id,
      'channel': channel,
      'message_text': messageText,
      'risk_score': riskScore,
    });
  }
}
