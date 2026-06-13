import '../models/ai_tutor_message.dart';
import '../models/ai_tutor_session.dart';
import 'base_repository.dart';

/// Data access for the AI tutoring module (`ai_tutor_sessions`,
/// `ai_tutor_messages` — migration 00027). All reads are scoped to the
/// caller's tenant + the given student; RLS enforces tenant isolation on top.
class AiTutorRepository extends BaseRepository {
  AiTutorRepository(super.client);

  /// Sessions for one student, newest first. Guards against an empty studentId
  /// (an empty-string UUID would otherwise produce a PostgREST 400).
  Future<List<AiTutorSession>> getSessionsForStudent(String studentId) async {
    if (studentId.trim().isEmpty) return const [];
    final rows = await client
        .from('ai_tutor_sessions')
        .select()
        .eq('tenant_id', requireTenantId)
        .eq('student_id', studentId)
        .order('started_at', ascending: false);
    return (rows as List)
        .map((j) => AiTutorSession.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Create a new active session and return it.
  Future<AiTutorSession> createSession({
    required String studentId,
    required String topic,
    String difficulty = 'intermediate',
    String? subjectId,
  }) async {
    if (studentId.trim().isEmpty) {
      throw ArgumentError('studentId is required to start a tutoring session');
    }
    final row = await client
        .from('ai_tutor_sessions')
        .insert({
          'tenant_id': requireTenantId,
          'student_id': studentId,
          'topic': topic.trim(),
          'difficulty_level': difficulty,
          if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
          'status': 'active',
        })
        .select()
        .single();
    return AiTutorSession.fromJson(row);
  }

  /// All messages in a session, oldest first.
  Future<List<AiTutorMessage>> getMessages(String sessionId) async {
    if (sessionId.trim().isEmpty) return const [];
    final rows = await client
        .from('ai_tutor_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((j) => AiTutorMessage.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Append a message and return the persisted row.
  Future<AiTutorMessage> addMessage({
    required String sessionId,
    required String role,
    required String content,
    String messageType = 'text',
  }) async {
    final row = await client
        .from('ai_tutor_messages')
        .insert({
          'session_id': sessionId,
          'role': role,
          'content': content,
          'message_type': messageType,
        })
        .select()
        .single();
    return AiTutorMessage.fromJson(row);
  }

  /// Keep the session's denormalized counter + updated_at in sync.
  Future<void> setMessageCount(String sessionId, int count) async {
    await client.from('ai_tutor_sessions').update({
      'messages_count': count,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  /// Mark a session completed (e.g. when the student leaves the chat).
  Future<void> endSession(String sessionId) async {
    await client.from('ai_tutor_sessions').update({
      'status': 'completed',
      'ended_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }
}
