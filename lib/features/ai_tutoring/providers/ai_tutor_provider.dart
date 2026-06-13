import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_gateway_client.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/ai_tutor_message.dart';
import '../../../data/models/ai_tutor_session.dart';
import '../../../data/repositories/ai_tutor_repository.dart';

final aiTutorRepositoryProvider = Provider<AiTutorRepository>((ref) {
  return AiTutorRepository(ref.watch(supabaseProvider));
});

/// Past + active sessions for a student, newest first.
final tutorSessionsProvider =
    FutureProvider.autoDispose.family<List<AiTutorSession>, String>(
  (ref, studentId) =>
      ref.watch(aiTutorRepositoryProvider).getSessionsForStudent(studentId),
);

/// Immutable chat state for one session.
class TutorChatState {
  final List<AiTutorMessage> messages;
  final bool loading;
  final bool sending;
  final String? error;

  const TutorChatState({
    this.messages = const [],
    this.loading = true,
    this.sending = false,
    this.error,
  });

  TutorChatState copyWith({
    List<AiTutorMessage>? messages,
    bool? loading,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return TutorChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives one session's conversation: loads history, sends a student turn,
/// calls the gateway for the tutor's reply, and persists both.
class TutorChatNotifier extends StateNotifier<TutorChatState> {
  final AiTutorRepository _repo;
  final AiGatewayClient _gateway;
  final String _sessionId;

  // Guards against the "setState after dispose" StateNotifier class of bug —
  // async gaps can resolve after the autoDispose provider is torn down.
  bool _disposed = false;

  TutorChatNotifier(this._repo, this._gateway, this._sessionId)
      : super(const TutorChatState()) {
    _load();
  }

  static const _persona =
      'You are Campusly Tutor, a patient, encouraging tutor for a school student. '
      'Explain concepts step by step in simple language, use short examples, and '
      'end with a quick check-for-understanding question. Never do the work for '
      'the student outright — guide them. Keep replies concise.';

  Future<void> _load() async {
    try {
      final msgs = await _repo.getMessages(_sessionId);
      if (_disposed) return;
      state = state.copyWith(messages: msgs, loading: false, clearError: true);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(loading: false, error: 'Could not load this session.');
    }
  }

  Future<void> sendMessage(String text, {required String topic}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    state = state.copyWith(sending: true, clearError: true);

    try {
      final studentMsg = await _repo.addMessage(
        sessionId: _sessionId,
        role: 'student',
        content: trimmed,
      );
      if (_disposed) return;
      final withStudent = [...state.messages, studentMsg];
      state = state.copyWith(messages: withStudent);

      final result = await _gateway.complete(
        featureType: 'ai_tutoring',
        systemPrompt: _persona,
        userPrompt: _buildPrompt(withStudent, topic),
        maxTokens: 700,
        temperature: 0.6,
      );
      if (_disposed) return;

      final reply = result.text.trim().isEmpty
          ? "I'm having trouble forming an answer right now — could you rephrase that?"
          : result.text.trim();
      final tutorMsg = await _repo.addMessage(
        sessionId: _sessionId,
        role: 'tutor',
        content: reply,
        messageType: 'explanation',
      );
      if (_disposed) return;

      final updated = [...state.messages, tutorMsg];
      state = state.copyWith(messages: updated, sending: false, clearError: true);
      // Best-effort counter sync; never block the UI on it.
      _repo.setMessageCount(_sessionId, updated.length).ignore();
    } on AiGatewayQuotaException {
      if (_disposed) return;
      state = state.copyWith(
        sending: false,
        error: "Today's AI tutoring limit has been reached. Please try again tomorrow.",
      );
    } on AiGatewayExhaustedException {
      if (_disposed) return;
      state = state.copyWith(
        sending: false,
        error: 'The tutor is busy right now. Please try again in a moment.',
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        sending: false,
        error: 'Could not reach the tutor. Check your connection and try again.',
      );
    }
  }

  /// Renders the recent conversation (last 12 turns) into a single transcript
  /// the model can continue. The gateway takes system + user prompts, so we
  /// fold history into the user prompt rather than a message array.
  String _buildPrompt(List<AiTutorMessage> messages, String topic) {
    final recent =
        messages.length > 12 ? messages.sublist(messages.length - 12) : messages;
    final transcript = recent
        .map((m) => '${m.isStudent ? 'Student' : 'Tutor'}: ${m.content}')
        .join('\n');
    final subject = topic.trim().isEmpty ? 'their schoolwork' : topic.trim();
    return 'Topic: $subject\n\nConversation so far:\n$transcript\n\n'
        'Write the next Tutor reply.';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final tutorChatProvider = StateNotifierProvider.autoDispose
    .family<TutorChatNotifier, TutorChatState, String>(
  (ref, sessionId) => TutorChatNotifier(
    ref.watch(aiTutorRepositoryProvider),
    ref.watch(aiGatewayClientProvider),
    sessionId,
  ),
);
