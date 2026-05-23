import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/features/dashboard/providers/dashboard_kpis_provider.dart';

void main() {
  group('AdminKpis.fromJson', () {
    test('parses a full row', () {
      final k = AdminKpis.fromJson({
        'tenant_id': 't1',
        'active_students': 1243,
        'today_attendance_pct': 92.5,
        'fees_collected_mtd': 845000.0,
        'overdue_invoices': 17,
        'at_risk_students': 4,
        'refreshed_at': '2026-05-23T12:00:00Z',
      });
      expect(k.tenantId, 't1');
      expect(k.activeStudents, 1243);
      expect(k.todayAttendancePct, 92.5);
      expect(k.feesCollectedMtd, 845000.0);
      expect(k.overdueInvoices, 17);
      expect(k.atRiskStudents, 4);
      expect(k.refreshedAt.toIso8601String(), '2026-05-23T12:00:00.000Z');
    });

    test('null today_attendance_pct is preserved (zero rows in attendance)',
        () {
      final k = AdminKpis.fromJson({
        'tenant_id': 't1',
        'active_students': 100,
        'today_attendance_pct': null,
        'fees_collected_mtd': 0,
        'overdue_invoices': 0,
        'at_risk_students': 0,
        'refreshed_at': '2026-05-23T12:00:00Z',
      });
      expect(k.todayAttendancePct, isNull);
    });

    test('tolerates missing optional numeric fields with 0 default', () {
      final k = AdminKpis.fromJson({
        'tenant_id': 't1',
        'refreshed_at': '2026-05-23T12:00:00Z',
      });
      expect(k.activeStudents, 0);
      expect(k.feesCollectedMtd, 0);
      expect(k.overdueInvoices, 0);
      expect(k.atRiskStudents, 0);
    });
  });

  group('TeacherClassSummary.fromJson', () {
    test('parses a full row', () {
      final s = TeacherClassSummary.fromJson({
        'tenant_id': 't1',
        'section_id': 's1',
        'section_name': '10-A',
        'class_id': 'c1',
        'class_name': 'Grade 10',
        'active_students': 32,
        'today_attendance_pct': 89.1,
        'at_risk_students': 2,
        'refreshed_at': '2026-05-23T12:00:00Z',
      });
      expect(s.sectionName, '10-A');
      expect(s.className, 'Grade 10');
      expect(s.activeStudents, 32);
      expect(s.atRiskStudents, 2);
    });
  });

  group('ParentChildOverview.fromJson', () {
    test('parses a full row', () {
      final c = ParentChildOverview.fromJson({
        'tenant_id': 't1',
        'student_id': 'st1',
        'student_name': 'Aarav Sharma',
        'week_attendance_pct': 95.0,
        'outstanding_amount': 12500.0,
        'risk_level': 'low',
        'refreshed_at': '2026-05-23T12:00:00Z',
      });
      expect(c.studentName, 'Aarav Sharma');
      expect(c.weekAttendancePct, 95.0);
      expect(c.outstandingAmount, 12500.0);
      expect(c.riskLevel, 'low');
    });

    test('null risk_level is preserved (no recent score)', () {
      final c = ParentChildOverview.fromJson({
        'tenant_id': 't1',
        'student_id': 'st1',
        'student_name': 'Aarav',
        'outstanding_amount': 0,
        'refreshed_at': '2026-05-23T12:00:00Z',
      });
      expect(c.riskLevel, isNull);
      expect(c.weekAttendancePct, isNull);
    });
  });
}
