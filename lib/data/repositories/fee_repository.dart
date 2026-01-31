import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
import 'base_repository.dart';

class FeeRepository extends BaseRepository {
  FeeRepository(super.client);

  Future<List<FeeHead>> getFeeHeads() async {
    final response = await client
        .from('fee_heads')
        .select('*')
        .eq('tenant_id', tenantId!)
        .order('name');

    return (response as List).map((json) => FeeHead.fromJson(json)).toList();
  }

  Future<FeeHead> createFeeHead(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('fee_heads')
        .insert(data)
        .select()
        .single();

    return FeeHead.fromJson(response);
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
        .eq('tenant_id', tenantId!)
        .eq('academic_year_id', academicYearId);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (termId != null) {
      query = query.eq('term_id', termId);
    }

    final response = await query;
    return (response as List)
        .map((json) => FeeStructure.fromJson(json))
        .toList();
  }

  Future<FeeStructure> createFeeStructure(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('fee_structures')
        .insert(data)
        .select()
        .single();

    return FeeStructure.fromJson(response);
  }

  Future<List<Invoice>> getInvoices({
    String? studentId,
    String? status,
    String? academicYearId,
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
        .eq('tenant_id', tenantId!);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Invoice.fromJson(json)).toList();
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

    return Invoice.fromJson(response);
  }

  Future<Invoice> createInvoice(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['generated_by'] = currentUserId;

    final response = await client
        .from('invoices')
        .insert(data)
        .select()
        .single();

    return Invoice.fromJson(response);
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

  Future<Payment> recordPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
    String? remarks,
  }) async {
    final invoice = await getInvoiceById(invoiceId);
    final paymentNumber = 'PAY-${DateTime.now().millisecondsSinceEpoch}';

    final response = await client.from('payments').insert({
      'tenant_id': tenantId,
      'invoice_id': invoiceId,
      'payment_number': paymentNumber,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': 'completed',
      'transaction_id': transactionId,
      'paid_at': DateTime.now().toIso8601String(),
      'received_by': currentUserId,
      'remarks': remarks,
    }).select().single();

    return Payment.fromJson(response);
  }

  Future<List<Payment>> getPayments({
    String? invoiceId,
    String? studentId,
  }) async {
    var query = client
        .from('payments')
        .select('''
          *,
          users!received_by(id, full_name),
          invoices(id, invoice_number, students(id, first_name, last_name))
        ''')
        .eq('tenant_id', tenantId!);

    if (invoiceId != null) {
      query = query.eq('invoice_id', invoiceId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<List<FeeSummary>> getFeeSummaries({
    String? sectionId,
    String? classId,
    String? academicYearId,
  }) async {
    var query = client
        .from('v_fee_summary')
        .select('*')
        .eq('tenant_id', tenantId!);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }

    final response = await query;
    return (response as List).map((json) => FeeSummary.fromJson(json)).toList();
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
    return FeeSummary.fromJson(response);
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
    
    return {
      'total_fee': totalFee,
      'total_paid': totalPaid,
      'total_pending': totalPending,
      'collection_percentage': totalFee > 0 ? (totalPaid / totalFee) * 100 : 0,
    };
  }

  Future<List<Invoice>> getOverdueInvoices() async {
    final response = await client
        .from('invoices')
        .select('''
          *,
          students(id, first_name, last_name, admission_number)
        ''')
        .eq('tenant_id', tenantId!)
        .inFilter('status', ['pending', 'partial'])
        .lt('due_date', DateTime.now().toIso8601String().split('T')[0])
        .order('due_date');

    return (response as List).map((json) => Invoice.fromJson(json)).toList();
  }
}
