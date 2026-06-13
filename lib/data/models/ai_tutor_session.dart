/// A single AI tutoring session for a student. Maps to `ai_tutor_sessions`
/// (migration 00027). Immutable — mutations return new instances via [copyWith].
class AiTutorSession {
  final String id;
  final String tenantId;
  final String studentId;
  final String? subjectId;
  final String topic;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int messagesCount;
  final String difficultyLevel; // beginner | intermediate | advanced
  final int? satisfactionRating;
  final String status; // active | completed | abandoned
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiTutorSession({
    required this.id,
    required this.tenantId,
    required this.studentId,
    this.subjectId,
    this.topic = '',
    required this.startedAt,
    this.endedAt,
    this.messagesCount = 0,
    this.difficultyLevel = 'intermediate',
    this.satisfactionRating,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Human-friendly title for lists — falls back when the student didn't name
  /// a topic.
  String get displayTitle => topic.trim().isNotEmpty ? topic.trim() : 'General help';

  bool get isActive => status == 'active';

  factory AiTutorSession.fromJson(Map<String, dynamic> json) {
    DateTime parse(String? v, DateTime fallback) =>
        v == null ? fallback : (DateTime.tryParse(v) ?? fallback);
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return AiTutorSession(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      studentId: json['student_id'] as String,
      subjectId: json['subject_id'] as String?,
      topic: (json['topic'] as String?) ?? '',
      startedAt: parse(json['started_at'] as String?, now),
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'] as String)
          : null,
      messagesCount: (json['messages_count'] as num?)?.toInt() ?? 0,
      difficultyLevel: (json['difficulty_level'] as String?) ?? 'intermediate',
      satisfactionRating: (json['satisfaction_rating'] as num?)?.toInt(),
      status: (json['status'] as String?) ?? 'active',
      createdAt: parse(json['created_at'] as String?, now),
      updatedAt: parse(json['updated_at'] as String?, now),
    );
  }

  AiTutorSession copyWith({
    int? messagesCount,
    DateTime? endedAt,
    int? satisfactionRating,
    String? status,
    DateTime? updatedAt,
  }) {
    return AiTutorSession(
      id: id,
      tenantId: tenantId,
      studentId: studentId,
      subjectId: subjectId,
      topic: topic,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      messagesCount: messagesCount ?? this.messagesCount,
      difficultyLevel: difficultyLevel,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
