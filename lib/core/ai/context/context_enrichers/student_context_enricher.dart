import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Enriches AI context with student-specific data when a student entity
/// is the focus of the current screen/query.
///
/// Fetches student name, class, recent attendance percentage, and parent info.
/// Failures return an empty map.
class StudentContextEnricher {
  final SupabaseClient _client;

  const StudentContextEnricher(this._client);

  /// Enrich context for a specific student.
  Future<Map<String, dynamic>> enrich(String studentId) async {
    try {
      final studentResult = await _client
          .from('students')
          .select('''
            id, first_name, last_name, admission_number, payment_status,
            student_enrollments(
              classes(name),
              sections(name)
            ),
            student_parents(
              parents(first_name, last_name)
            )
          ''')
          .eq('id', studentId)
          .maybeSingle();

      if (studentResult == null) return {};

      final firstName = studentResult['first_name'] ?? '';
      final lastName = studentResult['last_name'] ?? '';

      // Extract class/section from enrollment.
      String className = '';
      String sectionName = '';
      final enrollments = studentResult['student_enrollments'] as List?;
      if (enrollments != null && enrollments.isNotEmpty) {
        final enrollment = enrollments.first as Map<String, dynamic>;
        final classData = enrollment['classes'] as Map<String, dynamic>?;
        final sectionData = enrollment['sections'] as Map<String, dynamic>?;
        className = classData?['name'] ?? '';
        sectionName = sectionData?['name'] ?? '';
      }

      // Extract parent names.
      final parentNames = <String>[];
      final studentParents = studentResult['student_parents'] as List?;
      if (studentParents != null) {
        for (final sp in studentParents) {
          final parent = (sp as Map<String, dynamic>)['parents']
              as Map<String, dynamic>?;
          if (parent != null) {
            parentNames.add(
              '${parent['first_name'] ?? ''} ${parent['last_name'] ?? ''}'
                  .trim(),
            );
          }
        }
      }

      return {
        'student_name': '$firstName $lastName'.trim(),
        'student_class': '$className $sectionName'.trim(),
        'admission_number': studentResult['admission_number'] ?? '',
        'payment_status': studentResult['payment_status'] ?? 'unknown',
        if (parentNames.isNotEmpty) 'parent_names': parentNames,
      };
    } catch (e) {
      developer.log(
        'StudentContextEnricher failed — returning empty context',
        name: 'StudentContextEnricher',
        error: e,
      );
      return {};
    }
  }
}
