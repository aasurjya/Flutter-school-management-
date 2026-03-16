import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_context.dart';
import 'context_enrichers/role_context_enricher.dart';
import 'context_enrichers/school_context_enricher.dart';
import 'context_enrichers/student_context_enricher.dart';

/// Orchestrates context enrichers to build a complete [AIContext].
///
/// All enrichers run in parallel via `Future.wait()`. Individual enricher
/// failures are silently caught — they return empty maps rather than
/// blocking the AI call.
class AIContextBuilder {
  final RoleContextEnricher _roleEnricher;
  final SchoolContextEnricher _schoolEnricher;
  final StudentContextEnricher _studentEnricher;

  AIContextBuilder(SupabaseClient client)
      : _roleEnricher = const RoleContextEnricher(),
        _schoolEnricher = SchoolContextEnricher(client),
        _studentEnricher = StudentContextEnricher(client);

  /// Build an [AIContext] for the current user.
  ///
  /// [role] — the user's role (e.g. 'teacher', 'principal').
  /// [tenantId] — the tenant ID from JWT claims.
  /// [userId] — the authenticated user's ID.
  /// [focusStudentId] — optional student ID when viewing a specific student.
  Future<AIContext> build({
    required String role,
    String? tenantId,
    String? userId,
    String? focusStudentId,
  }) async {
    try {
      // Run all enrichers in parallel.
      final results = await Future.wait([
        _roleEnricher.enrich(role),
        _schoolEnricher.enrich(tenantId),
        if (focusStudentId != null)
          _studentEnricher.enrich(focusStudentId)
        else
          Future.value(<String, dynamic>{}),
      ]);

      final roleData = results[0];
      final schoolData = results[1];
      final studentData = results[2];

      return AIContext(
        role: role,
        tenantId: tenantId,
        userId: userId,
        roleData: roleData,
        schoolData: schoolData,
        focusEntity: studentData.isNotEmpty ? studentData : null,
      );
    } catch (e) {
      developer.log(
        'AIContextBuilder.build() failed — returning minimal context',
        name: 'AIContextBuilder',
        error: e,
      );
      return AIContext(role: role, tenantId: tenantId, userId: userId);
    }
  }
}
