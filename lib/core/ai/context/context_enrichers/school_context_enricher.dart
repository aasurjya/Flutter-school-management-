import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Enriches AI context with school-level data: name, academic year,
/// term, student count, teacher count.
///
/// Makes a single Supabase query. Failures return an empty map and
/// never block the AI call.
class SchoolContextEnricher {
  final SupabaseClient _client;

  const SchoolContextEnricher(this._client);

  Future<Map<String, dynamic>> enrich(String? tenantId) async {
    if (tenantId == null) return {};

    try {
      // Fetch tenant info.
      final tenantResult = await _client
          .from('tenants')
          .select('name, subscription_plan')
          .eq('id', tenantId)
          .maybeSingle();

      // Fetch current academic year.
      final yearResult = await _client
          .from('academic_years')
          .select('name, start_date, end_date')
          .eq('tenant_id', tenantId)
          .eq('is_current', true)
          .maybeSingle();

      // Fetch student count.
      final studentCount = await _client
          .from('students')
          .select('id')
          .eq('tenant_id', tenantId)
          .count(CountOption.exact);

      return {
        if (tenantResult != null)
          'school_name': tenantResult['name'] ?? 'Unknown School',
        if (yearResult != null)
          'academic_year': yearResult['name'] ?? 'Current Year',
        'total_students': studentCount.count,
      };
    } catch (e) {
      developer.log(
        'SchoolContextEnricher failed — returning empty context',
        name: 'SchoolContextEnricher',
        error: e,
      );
      return {};
    }
  }
}
