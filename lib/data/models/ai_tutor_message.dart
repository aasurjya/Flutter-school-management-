/// A single message inside an AI tutoring session. Maps to `ai_tutor_messages`
/// (migration 00027). Note: this table has no `tenant_id` — RLS authorizes via
/// the parent session.
class AiTutorMessage {
  final String id;
  final String sessionId;
  final String role; // student | tutor | system
  final String content;
  final String messageType; // text | explanation | quiz | hint | solution | encouragement
  final DateTime createdAt;

  const AiTutorMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isTutor => role == 'tutor';

  factory AiTutorMessage.fromJson(Map<String, dynamic> json) {
    return AiTutorMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      role: (json['role'] as String?) ?? 'tutor',
      content: (json['content'] as String?) ?? '',
      messageType: (json['message_type'] as String?) ?? 'text',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
