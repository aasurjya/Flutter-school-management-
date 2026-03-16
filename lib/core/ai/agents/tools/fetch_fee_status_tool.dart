import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai_tool.dart';

/// Fetches fee payment status for a student.
class FetchFeeStatusTool extends AiTool {
  final SupabaseClient _client;

  FetchFeeStatusTool(this._client);

  @override
  String get name => 'fetch_fee_status';

  @override
  String get description =>
      'Get a student\'s fee status: total billed, total paid, balance due, '
      'and overdue invoice count.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'student_id': {
            'type': 'string',
            'description': 'UUID of the student',
          },
        },
        'required': ['student_id'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final studentId = params['student_id'] as String?;
    if (studentId == null || studentId.isEmpty) {
      return {'error': 'student_id is required'};
    }

    try {
      final invoices = await _client
          .from('invoices')
          .select('total_amount, paid_amount, status, due_date')
          .eq('student_id', studentId);

      final invoiceList = invoices as List;
      if (invoiceList.isEmpty) {
        return {
          'student_id': studentId,
          'message': 'No invoices found',
          'total_billed': 0,
          'total_paid': 0,
          'balance_due': 0,
        };
      }

      double totalBilled = 0;
      double totalPaid = 0;
      int overdueCount = 0;
      final now = DateTime.now();

      for (final inv in invoiceList) {
        final invoice = inv as Map<String, dynamic>;
        totalBilled += (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        totalPaid += (invoice['paid_amount'] as num?)?.toDouble() ?? 0;

        final dueDate = invoice['due_date'] as String?;
        final status = invoice['status'] as String?;
        if (status != 'paid' && dueDate != null) {
          final due = DateTime.tryParse(dueDate);
          if (due != null && due.isBefore(now)) {
            overdueCount++;
          }
        }
      }

      return {
        'student_id': studentId,
        'total_billed': totalBilled,
        'total_paid': totalPaid,
        'balance_due': totalBilled - totalPaid,
        'overdue_invoices': overdueCount,
        'total_invoices': invoices.length,
      };
    } catch (e) {
      return {'error': 'Failed to fetch fee status: $e'};
    }
  }
}
