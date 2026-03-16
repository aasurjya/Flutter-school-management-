/// Adds role-specific system prompt segments and metadata.
///
/// Each role gets different default context that improves AI response quality.
class RoleContextEnricher {
  const RoleContextEnricher();

  /// Returns role-specific key-value context.
  Future<Map<String, dynamic>> enrich(String role) async {
    final data = <String, dynamic>{
      'role_description': _roleDescriptions[role] ?? 'School staff member',
      'tone_guidance': _toneGuidance[role] ?? 'Be professional and helpful.',
    };

    return data;
  }

  static const _roleDescriptions = {
    'super_admin': 'Platform administrator managing multiple school tenants',
    'tenant_admin': 'School administrator with full access to one school',
    'principal': 'School principal overseeing academics and operations',
    'teacher': 'Classroom teacher responsible for instruction and student welfare',
    'student': 'Student using the learning platform',
    'parent': 'Parent monitoring their child\'s progress',
    'accountant': 'School accountant managing fees and finances',
    'librarian': 'School librarian managing the book catalog and circulation',
    'transport_manager': 'Transport coordinator managing buses and routes',
    'hostel_warden': 'Hostel warden overseeing residential student welfare',
    'canteen_staff': 'Canteen manager handling meals and inventory',
    'receptionist': 'Front desk receptionist managing visitors and communication',
  };

  static const _toneGuidance = {
    'super_admin': 'Use technical, data-driven language. Focus on platform KPIs.',
    'tenant_admin': 'Use administrative language. Focus on school-wide metrics.',
    'principal': 'Use professional, leadership-oriented language. Highlight actionable insights.',
    'teacher': 'Use supportive, pedagogical language. Focus on student-centric insights.',
    'student': 'Use encouraging, age-appropriate language. Be a helpful tutor.',
    'parent': 'Use warm, reassuring language. Focus on their child\'s progress.',
    'accountant': 'Use precise financial language. Focus on collection rates and outstanding amounts.',
    'librarian': 'Use literary, organized language. Focus on circulation and engagement.',
    'transport_manager': 'Use operational language. Focus on routes, capacity, and safety.',
    'hostel_warden': 'Use caring, organized language. Focus on occupancy and welfare.',
    'canteen_staff': 'Use practical language. Focus on inventory and meal planning.',
    'receptionist': 'Use polite, organized language. Focus on visitor flow and scheduling.',
  };
}
