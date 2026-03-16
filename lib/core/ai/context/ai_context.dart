/// Immutable context object assembled by [AIContextBuilder].
///
/// Contains role-appropriate data that the AI can use to produce better,
/// more contextual responses without the caller manually gathering data.
class AIContext {
  /// Current user's role (e.g. 'teacher', 'principal', 'parent').
  final String role;

  /// Tenant ID for multi-tenant isolation.
  final String? tenantId;

  /// Current user's ID.
  final String? userId;

  /// Enriched school-level data (student count, academic year, etc.).
  final Map<String, dynamic> schoolData;

  /// Optional focus entity (e.g. a specific student being viewed).
  final Map<String, dynamic>? focusEntity;

  /// Role-specific context segments added by enrichers.
  final Map<String, dynamic> roleData;

  const AIContext({
    required this.role,
    this.tenantId,
    this.userId,
    this.schoolData = const {},
    this.focusEntity,
    this.roleData = const {},
  });

  /// Merge all context data into a single map for prompt injection.
  Map<String, dynamic> toMap() => {
        'role': role,
        if (tenantId != null) 'tenant_id': tenantId,
        ...schoolData,
        ...roleData,
        if (focusEntity != null) 'focus_entity': focusEntity,
      };

  /// Build a context summary string suitable for injecting into a system prompt.
  String toPromptSegment() {
    final buf = StringBuffer()..writeln('Context:');

    for (final entry in toMap().entries) {
      if (entry.value is Map || entry.value is List) {
        buf.writeln('  ${entry.key}: ${entry.value}');
      } else {
        buf.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    return buf.toString();
  }

  AIContext copyWith({
    String? role,
    String? tenantId,
    String? userId,
    Map<String, dynamic>? schoolData,
    Map<String, dynamic>? focusEntity,
    Map<String, dynamic>? roleData,
  }) =>
      AIContext(
        role: role ?? this.role,
        tenantId: tenantId ?? this.tenantId,
        userId: userId ?? this.userId,
        schoolData: schoolData ?? this.schoolData,
        focusEntity: focusEntity ?? this.focusEntity,
        roleData: roleData ?? this.roleData,
      );
}
