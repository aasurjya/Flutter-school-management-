import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/hr_payroll.dart';
import 'base_repository.dart';

class HRRepository extends BaseRepository {
  HRRepository(super.client);

  // ==========================================================================
  // Departments
  // ==========================================================================

  Future<List<Department>> getDepartments({bool activeOnly = true}) async {
    var query = client
        .from('departments')
        .select('*, hod:users!head_of_department_id(full_name)')
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    return (response as List).map((json) => Department.fromJson(json)).toList();
  }

  Future<Department> getDepartmentById(String id) async {
    final response = await client
        .from('departments')
        .select('*, hod:users!head_of_department_id(full_name)')
        .eq('id', id)
        .single();
    return Department.fromJson(response);
  }

  Future<Department> createDepartment(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response =
        await client.from('departments').insert(data).select().single();
    return Department.fromJson(response);
  }

  Future<Department> updateDepartment(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('departments')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Department.fromJson(response);
  }

  Future<void> deleteDepartment(String id) async {
    await client.from('departments').delete().eq('id', id);
  }

  // ==========================================================================
  // Designations
  // ==========================================================================

  Future<List<Designation>> getDesignations({
    String? departmentId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from('designations')
        .select('*, departments(name)')
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    if (departmentId != null) {
      query = query.eq('department_id', departmentId);
    }

    final response = await query.order('level').order('name');
    return (response as List)
        .map((json) => Designation.fromJson(json))
        .toList();
  }

  Future<Designation> createDesignation(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response =
        await client.from('designations').insert(data).select().single();
    return Designation.fromJson(response);
  }

  Future<Designation> updateDesignation(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('designations')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Designation.fromJson(response);
  }

  // ==========================================================================
  // Staff Contracts
  // ==========================================================================

  Future<List<StaffContract>> getStaffContracts({
    String? staffId,
    String? status,
    bool expiringOnly = false,
  }) async {
    var query = client
        .from('staff_contracts')
        .select('*, staff(employee_id, designation, first_name, last_name)')
        .eq('tenant_id', requireTenantId);

    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (expiringOnly) {
      final thirtyDaysOut =
          DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0];
      query = query
          .eq('status', 'active')
          .not('end_date', 'is', null)
          .lte('end_date', thirtyDaysOut);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => StaffContract.fromJson(json))
        .toList();
  }

  Future<StaffContract?> getActiveContract(String staffId) async {
    final response = await client
        .from('staff_contracts')
        .select('*, staff(employee_id, designation, first_name, last_name)')
        .eq('staff_id', staffId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return StaffContract.fromJson(response);
  }

  Future<StaffContract> createContract(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    // Calculate gross and net
    final basic = (data['basic_salary'] as num?)?.toDouble() ?? 0;
    final hra = (data['hra'] as num?)?.toDouble() ?? 0;
    final da = (data['da'] as num?)?.toDouble() ?? 0;
    final ta = (data['ta'] as num?)?.toDouble() ?? 0;
    final otherAllowances = data['other_allowances'] as Map<String, dynamic>? ?? {};
    final deductions = data['deductions'] as Map<String, dynamic>? ?? {};

    double otherTotal = 0;
    for (final v in otherAllowances.values) {
      otherTotal += (v is num) ? v.toDouble() : 0;
    }

    double dedTotal = 0;
    for (final v in deductions.values) {
      dedTotal += (v is num) ? v.toDouble() : 0;
    }

    data['gross_salary'] = basic + hra + da + ta + otherTotal;
    data['net_salary'] = data['gross_salary'] - dedTotal;

    final response =
        await client.from('staff_contracts').insert(data).select().single();
    return StaffContract.fromJson(response);
  }

  Future<StaffContract> updateContract(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('staff_contracts')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return StaffContract.fromJson(response);
  }

  // ==========================================================================
  // Salary Structures
  // ==========================================================================

  Future<List<SalaryStructure>> getSalaryStructures(
      {bool activeOnly = true}) async {
    var query = client
        .from('salary_structures')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    return (response as List)
        .map((json) => SalaryStructure.fromJson(json))
        .toList();
  }

  Future<SalaryStructure> createSalaryStructure(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response = await client
        .from('salary_structures')
        .insert(data)
        .select()
        .single();
    return SalaryStructure.fromJson(response);
  }

  // ==========================================================================
  // Payroll Runs
  // ==========================================================================

  Future<List<PayrollRun>> getPayrollRuns({
    int? year,
    int limit = 24,
  }) async {
    var query = client
        .from('payroll_runs')
        .select('*, approver:users!approved_by(full_name), payroll_items(*,staff(employee_id, designation, first_name, last_name))')
        .eq('tenant_id', requireTenantId);

    if (year != null) {
      query = query.eq('year', year);
    }

    final response =
        await query.order('year', ascending: false).order('month', ascending: false).limit(limit);
    return (response as List)
        .map((json) => PayrollRun.fromJson(json))
        .toList();
  }

  Future<PayrollRun?> getPayrollRunById(String id) async {
    final response = await client
        .from('payroll_runs')
        .select(
            '*, approver:users!approved_by(full_name), payroll_items(*,staff(employee_id, designation, first_name, last_name))')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return PayrollRun.fromJson(response);
  }

  Future<String> generatePayroll({
    required int month,
    required int year,
    String? notes,
  }) async {
    final response = await client.rpc('generate_payroll', params: {
      'p_tenant_id': requireTenantId,
      'p_month': month,
      'p_year': year,
      'p_notes': notes,
    });
    return response as String;
  }

  Future<PayrollRun> approvePayroll(String payrollRunId) async {
    final response = await client
        .from('payroll_runs')
        .update({
          'status': 'approved',
          'approved_by': requireUserId,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', payrollRunId)
        .select()
        .single();
    return PayrollRun.fromJson(response);
  }

  Future<void> updatePayrollItemPayment(
    String itemId, {
    required String status,
    String? method,
    String? ref,
  }) async {
    await client.from('payroll_items').update({
      'payment_status': status,
      'payment_method': method,
      'payment_ref': ref,
    }).eq('id', itemId);
  }

  // ==========================================================================
  // Salary Slips
  // ==========================================================================

  Future<List<SalarySlip>> getSalarySlips({String? staffId}) async {
    var query = client.from('salary_slips').select(
        '*, payroll_items(*, staff(employee_id, designation, first_name, last_name))');

    if (staffId != null) {
      query = query.eq('payroll_items.staff_id', staffId);
    }

    final response = await query.order('generated_at', ascending: false);
    return (response as List)
        .map((json) => SalarySlip.fromJson(json))
        .toList();
  }

  Future<SalarySlip> createSalarySlip({
    required String payrollItemId,
  }) async {
    final slipNumber =
        'SLIP-${DateTime.now().millisecondsSinceEpoch}';

    final response = await client.from('salary_slips').insert({
      'payroll_item_id': payrollItemId,
      'slip_number': slipNumber,
    }).select().single();

    return SalarySlip.fromJson(response);
  }

  /// Generate a salary slip PDF in memory. Returns raw bytes.
  Future<Uint8List> generateSalarySlipPdf({
    required PayrollItem item,
    required int month,
    required int year,
    String? schoolName,
  }) async {
    final pdf = pw.Document();

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final periodStr = '${months[month - 1]} $year';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6366F1'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      schoolName ?? 'School Management System',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Salary Slip - $periodStr',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Employee Info
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Employee: ${item.staffName ?? 'N/A'}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Employee ID: ${item.staffEmployeeId ?? 'N/A'}'),
                        pw.Text('Designation: ${item.designation ?? 'N/A'}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Days Worked: ${item.daysWorked}'),
                        pw.Text('Days Absent: ${item.daysAbsent}'),
                        pw.Text('Overtime: ${item.overtimeHours}h'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Earnings and Deductions side by side
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(8),
                          color: PdfColor.fromHex('#DCFCE7'),
                          child: pw.Text('EARNINGS',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        ...item.earnings.entries.map(
                          (e) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(_formatLabel(e.key)),
                                pw.Text(_formatCurrency(e.value)),
                              ],
                            ),
                          ),
                        ),
                        if (item.overtimeAmount > 0)
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Overtime'),
                                pw.Text(_formatCurrency(item.overtimeAmount)),
                              ],
                            ),
                          ),
                        pw.Divider(),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Gross Salary',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(_formatCurrency(item.grossSalary),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Deductions
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(8),
                          color: PdfColor.fromHex('#FEE2E2'),
                          child: pw.Text('DEDUCTIONS',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        ...item.deductions.entries.map(
                          (e) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(_formatLabel(e.key)),
                                pw.Text(_formatCurrency(e.value)),
                              ],
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Tax (TDS)'),
                              pw.Text(_formatCurrency(item.taxAmount)),
                            ],
                          ),
                        ),
                        pw.Divider(),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total Deductions',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  _formatCurrency(item.totalDeductions),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Net Pay
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EEF2FF'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColor.fromHex('#6366F1')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NET PAY',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(item.netSalary),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#6366F1'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'This is a system-generated salary slip.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==========================================================================
  // Staff Attendance Daily
  // ==========================================================================

  Future<List<StaffAttendanceDaily>> getStaffAttendance({
    required DateTime date,
    String? staffId,
  }) async {
    var query = client
        .from('staff_attendance_daily')
        .select('*, staff(employee_id, designation, first_name, last_name)')
        .eq('tenant_id', requireTenantId)
        .eq('date', date.toIso8601String().split('T')[0]);

    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }

    final response = await query.order('created_at');
    return (response as List)
        .map((json) => StaffAttendanceDaily.fromJson(json))
        .toList();
  }

  Future<List<StaffAttendanceDaily>> getStaffAttendanceRange({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client
        .from('staff_attendance_daily')
        .select('*')
        .eq('staff_id', staffId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date');

    return (response as List)
        .map((json) => StaffAttendanceDaily.fromJson(json))
        .toList();
  }

  Future<void> upsertStaffAttendance(List<Map<String, dynamic>> records) async {
    for (final record in records) {
      record['tenant_id'] = requireTenantId;
    }
    await client
        .from('staff_attendance_daily')
        .upsert(records, onConflict: 'staff_id,date');
  }

  Future<Map<String, int>> getStaffAttendanceSummary({
    required String staffId,
    required int month,
    required int year,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final records = await getStaffAttendanceRange(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );

    int present = 0, absent = 0, halfDay = 0, onLeave = 0, holiday = 0;
    for (final r in records) {
      switch (r.status) {
        case StaffAttendanceStatus.present:
          present++;
          break;
        case StaffAttendanceStatus.absent:
          absent++;
          break;
        case StaffAttendanceStatus.half_day:
          halfDay++;
          break;
        case StaffAttendanceStatus.on_leave:
          onLeave++;
          break;
        case StaffAttendanceStatus.holiday:
          holiday++;
          break;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'half_day': halfDay,
      'on_leave': onLeave,
      'holiday': holiday,
      'total_days': endDate.day,
      'working_days': present + absent + halfDay,
    };
  }

  // ==========================================================================
  // Tax Declarations
  // ==========================================================================

  Future<List<TaxDeclaration>> getTaxDeclarations({
    String? staffId,
    String? financialYear,
    String? status,
  }) async {
    var query = client
        .from('tax_declarations')
        .select('*, staff(employee_id, designation, first_name, last_name), verifier:users!verified_by(full_name)')
        .eq('tenant_id', requireTenantId);

    if (staffId != null) query = query.eq('staff_id', staffId);
    if (financialYear != null) query = query.eq('financial_year', financialYear);
    if (status != null) query = query.eq('status', status);

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => TaxDeclaration.fromJson(json))
        .toList();
  }

  Future<TaxDeclaration> createTaxDeclaration(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response = await client
        .from('tax_declarations')
        .insert(data)
        .select()
        .single();
    return TaxDeclaration.fromJson(response);
  }

  Future<TaxDeclaration> updateTaxDeclaration(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('tax_declarations')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return TaxDeclaration.fromJson(response);
  }

  Future<TaxDeclaration> verifyTaxDeclaration(String id) async {
    final response = await client.from('tax_declarations').update({
      'status': 'verified',
      'verified_by': requireUserId,
      'verified_at': DateTime.now().toIso8601String(),
    }).eq('id', id).select().single();
    return TaxDeclaration.fromJson(response);
  }

  // ==========================================================================
  // Staff Documents
  // ==========================================================================

  Future<List<StaffDocument>> getStaffDocuments(String staffId) async {
    final response = await client
        .from('staff_documents')
        .select('*')
        .eq('staff_id', staffId)
        .order('uploaded_at', ascending: false);

    return (response as List)
        .map((json) => StaffDocument.fromJson(json))
        .toList();
  }

  Future<StaffDocument> createStaffDocument(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response = await client
        .from('staff_documents')
        .insert(data)
        .select()
        .single();
    return StaffDocument.fromJson(response);
  }

  Future<void> verifyDocument(String id) async {
    await client.from('staff_documents').update({
      'verified': true,
      'verified_by': requireUserId,
    }).eq('id', id);
  }

  Future<void> deleteDocument(String id) async {
    await client.from('staff_documents').delete().eq('id', id);
  }

  // ==========================================================================
  // Dashboard Stats
  // ==========================================================================

  Future<HRDashboardStats> getHRDashboardStats() async {
    final tid = requireTenantId;

    // Try the view first
    final viewResponse = await client
        .from('v_hr_dashboard_stats')
        .select('*')
        .eq('tenant_id', tid)
        .maybeSingle();

    HRDashboardStats stats;
    if (viewResponse != null) {
      stats = HRDashboardStats.fromJson(viewResponse);
    } else {
      // Fallback: build stats from individual queries
      final staffCount = await client
          .from('staff')
          .select('id')
          .eq('tenant_id', tid)
          .eq('is_active', true);

      final deptCount = await client
          .from('departments')
          .select('id')
          .eq('tenant_id', tid)
          .eq('is_active', true);

      stats = HRDashboardStats(
        totalStaff: (staffCount as List).length,
        activeStaff: (staffCount as List).length,
        totalDepartments: (deptCount as List).length,
      );
    }

    // Get today's attendance
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayAttendance = await client
        .from('staff_attendance_daily')
        .select('status')
        .eq('tenant_id', tid)
        .eq('date', today);

    int present = 0, absent = 0, onLeave = 0;
    for (final record in (todayAttendance as List)) {
      switch (record['status']) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'on_leave':
          onLeave++;
          break;
      }
    }

    return stats.copyWith(
      presentToday: present,
      absentToday: absent,
      onLeaveToday: onLeave,
    );
  }

  // Staff by department (for directory)
  Future<List<Map<String, dynamic>>> getStaffByDepartment() async {
    // Get all departments with staff count
    final departments = await getDepartments();
    final result = <Map<String, dynamic>>[];

    for (final dept in departments) {
      // Get staff in this department through designations
      final staffResponse = await client
          .from('staff')
          .select('*, users!user_id(full_name, email)')
          .eq('tenant_id', requireTenantId)
          .eq('is_active', true);

      result.add({
        'department': dept,
        'staff_count': (staffResponse as List).length,
      });
    }

    return result;
  }

  // ==========================================================================
  // Helpers
  // ==========================================================================

  static String _formatLabel(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  static String _formatCurrency(dynamic value) {
    double amount = 0;
    if (value is num) amount = value.toDouble();
    if (value is String) amount = double.tryParse(value) ?? 0;
    return '\u20B9${amount.toStringAsFixed(2)}';
  }
}
