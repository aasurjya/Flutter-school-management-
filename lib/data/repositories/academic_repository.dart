import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academic.dart';
import 'base_repository.dart';

class AcademicRepository extends BaseRepository {
  AcademicRepository(SupabaseClient client) : super(client);

  Future<List<SchoolClass>> getClasses() async {
    final response = await client
        .from('classes')
        .select('*')
        .eq('tenant_id', tenantId!)
        .order('sequence_order');

    return (response as List)
        .map((json) => SchoolClass.fromJson(json))
        .toList();
  }

  Future<List<Section>> getSections({String? classId}) async {
    var query = client
        .from('sections')
        .select('''
          *,
          classes!inner(id, name)
        ''')
        .eq('tenant_id', tenantId!);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }

    final response = await query.order('name');

    return (response as List).map((json) {
      if (json['classes'] != null) {
        json['class'] = json['classes'];
      }
      return Section.fromJson(json);
    }).toList();
  }

  Future<AcademicYear?> getCurrentAcademicYear() async {
    final current = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', tenantId!)
        .eq('is_current', true)
        .maybeSingle();

    if (current != null) {
      return AcademicYear.fromJson(current);
    }

    final latest = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', tenantId!)
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latest != null) {
      return AcademicYear.fromJson(latest);
    }

    return null;
  }

  Future<List<AcademicYear>> getAcademicYears() async {
    final response = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', tenantId!)
        .order('start_date', ascending: false);

    return (response as List)
        .map((json) => AcademicYear.fromJson(json))
        .toList();
  }
}
