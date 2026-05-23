import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Read-side bindings for the 3 dashboard materialized views shipped in
/// PR #8 (`migration 00064_dashboard_materialized_views.sql`):
///   • [adminKpisProvider]            ← `v_my_admin_kpis`
///   • [teacherClassSummaryProvider]  ← `v_my_teacher_class_summary`
///   • [parentChildOverviewProvider]  ← `v_my_parent_child_overview`
///
/// Each MV is refreshed every 5 minutes by pg_cron. The Flutter side caches
/// for 60 s on top of that so tabbing between dashboard tabs is free.
///
/// The MVs are NOT covered by RLS (mvs don't support it). Reads go through
/// the `v_my_*` views which have SECURITY INVOKER + a JWT tenant_id WHERE
/// clause — see the migration for the exact policy. A tenant_id rotation
/// invalidates the read immediately because the request cache key includes
/// it.

class AdminKpis {
  final String tenantId;
  final int activeStudents;
  final double? todayAttendancePct;
  final double feesCollectedMtd;
  final int overdueInvoices;
  final int atRiskStudents;
  final DateTime refreshedAt;

  const AdminKpis({
    required this.tenantId,
    required this.activeStudents,
    required this.todayAttendancePct,
    required this.feesCollectedMtd,
    required this.overdueInvoices,
    required this.atRiskStudents,
    required this.refreshedAt,
  });

  factory AdminKpis.fromJson(Map<String, dynamic> j) {
    return AdminKpis(
      tenantId: j['tenant_id'] as String,
      activeStudents: (j['active_students'] as num?)?.toInt() ?? 0,
      todayAttendancePct:
          (j['today_attendance_pct'] as num?)?.toDouble(),
      feesCollectedMtd: (j['fees_collected_mtd'] as num?)?.toDouble() ?? 0,
      overdueInvoices: (j['overdue_invoices'] as num?)?.toInt() ?? 0,
      atRiskStudents: (j['at_risk_students'] as num?)?.toInt() ?? 0,
      refreshedAt:
          DateTime.tryParse(j['refreshed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TeacherClassSummary {
  final String tenantId;
  final String sectionId;
  final String sectionName;
  final String classId;
  final String className;
  final int activeStudents;
  final double? todayAttendancePct;
  final int atRiskStudents;
  final DateTime refreshedAt;

  const TeacherClassSummary({
    required this.tenantId,
    required this.sectionId,
    required this.sectionName,
    required this.classId,
    required this.className,
    required this.activeStudents,
    required this.todayAttendancePct,
    required this.atRiskStudents,
    required this.refreshedAt,
  });

  factory TeacherClassSummary.fromJson(Map<String, dynamic> j) {
    return TeacherClassSummary(
      tenantId: j['tenant_id'] as String,
      sectionId: j['section_id'] as String,
      sectionName: j['section_name'] as String? ?? '',
      classId: j['class_id'] as String? ?? '',
      className: j['class_name'] as String? ?? '',
      activeStudents: (j['active_students'] as num?)?.toInt() ?? 0,
      todayAttendancePct: (j['today_attendance_pct'] as num?)?.toDouble(),
      atRiskStudents: (j['at_risk_students'] as num?)?.toInt() ?? 0,
      refreshedAt:
          DateTime.tryParse(j['refreshed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ParentChildOverview {
  final String tenantId;
  final String studentId;
  final String studentName;
  final double? weekAttendancePct;
  final double outstandingAmount;
  final String? riskLevel;
  final DateTime refreshedAt;

  const ParentChildOverview({
    required this.tenantId,
    required this.studentId,
    required this.studentName,
    required this.weekAttendancePct,
    required this.outstandingAmount,
    required this.riskLevel,
    required this.refreshedAt,
  });

  factory ParentChildOverview.fromJson(Map<String, dynamic> j) {
    return ParentChildOverview(
      tenantId: j['tenant_id'] as String,
      studentId: j['student_id'] as String,
      studentName: j['student_name'] as String? ?? '',
      weekAttendancePct: (j['week_attendance_pct'] as num?)?.toDouble(),
      outstandingAmount:
          (j['outstanding_amount'] as num?)?.toDouble() ?? 0,
      riskLevel: j['risk_level'] as String?,
      refreshedAt:
          DateTime.tryParse(j['refreshed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Single-row admin KPI summary — reads from `v_my_admin_kpis`. Replaces
/// 5+ ad-hoc aggregation queries on the admin dashboard with one
/// pre-aggregated read.
///
/// Returns null when the caller has no tenant context (super_admin) or
/// the MV isn't deployed yet (graceful migration window).
final adminKpisProvider = FutureProvider.autoDispose<AdminKpis?>((ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId;
  if (tenantId == null) return null;
  return cachedLoad<AdminKpis?>(
    ref,
    namespace: 'dashboard.admin_kpis',
    tenantId: tenantId,
    ttl: const Duration(seconds: 60),
    load: () async {
      try {
        final row = await client
            .from('v_my_admin_kpis')
            .select()
            .maybeSingle();
        if (row == null) return null;
        return AdminKpis.fromJson(row);
      } on PostgrestException catch (e) {
        // Function/view missing on this DB — pre-MV-migration env. Caller
        // should fall back to the legacy per-stat providers.
        if (e.code == '42P01' || e.code == 'PGRST205') return null;
        rethrow;
      }
    },
  );
});

/// Per-section snapshot rows for the teacher dashboard. Reads from
/// `v_my_teacher_class_summary` (one row per section the caller has
/// access to under RLS).
final teacherClassSummaryProvider =
    FutureProvider.autoDispose<List<TeacherClassSummary>>((ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId;
  if (tenantId == null) return const [];
  return cachedLoad<List<TeacherClassSummary>>(
    ref,
    namespace: 'dashboard.teacher_class_summary',
    tenantId: tenantId,
    ttl: const Duration(seconds: 60),
    load: () async {
      try {
        final rows = await client
            .from('v_my_teacher_class_summary')
            .select()
            .order('class_name');
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map(TeacherClassSummary.fromJson)
            .toList(growable: false);
      } on PostgrestException catch (e) {
        if (e.code == '42P01' || e.code == 'PGRST205') return const [];
        rethrow;
      }
    },
  );
});

/// Per-student rows for the parent dashboard. Reads from
/// `v_my_parent_child_overview` — one row per active student the parent
/// is linked to under RLS.
final parentChildOverviewProvider =
    FutureProvider.autoDispose<List<ParentChildOverview>>((ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  final tenantId = user?.tenantId;
  if (tenantId == null) return const [];
  return cachedLoad<List<ParentChildOverview>>(
    ref,
    namespace: 'dashboard.parent_child_overview',
    tenantId: tenantId,
    ttl: const Duration(seconds: 60),
    load: () async {
      try {
        final rows = await client
            .from('v_my_parent_child_overview')
            .select()
            .order('student_name');
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map(ParentChildOverview.fromJson)
            .toList(growable: false);
      } on PostgrestException catch (e) {
        if (e.code == '42P01' || e.code == 'PGRST205') return const [];
        rethrow;
      }
    },
  );
});
