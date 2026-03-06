import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/services/claude_vision_service.dart';
import '../../../core/services/screen_capture_service.dart';

/// A single chat message in the AI tutor session.
class TutorMessage {
  final String text;
  final bool isUser;
  final bool hasScreenshot;
  final DateTime timestamp;

  const TutorMessage({
    required this.text,
    required this.isUser,
    this.hasScreenshot = false,
    required this.timestamp,
  });
}

class AiTutorState {
  final List<TutorMessage> messages;
  final bool isLoading;
  final String? error;

  const AiTutorState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiTutorState copyWith({
    List<TutorMessage>? messages,
    bool? isLoading,
    String? error,
  }) =>
      AiTutorState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AiTutorNotifier extends StateNotifier<AiTutorState> {
  AiTutorNotifier() : super(const AiTutorState());

  ClaudeVisionService? _service;

  ClaudeVisionService? _getService() {
    final key = AppEnvironment.claudeApiKey;
    if (key == null) return null;
    return _service ??= ClaudeVisionService(apiKey: key);
  }

  /// Sends a user question, captures the current screen, and gets an AI response.
  Future<void> ask(String question) async {
    if (question.trim().isEmpty) return;

    // Capture the screen immediately before updating state
    final screenshot = await ScreenCaptureService.captureBase64();

    // Add user message
    state = state.copyWith(
      messages: [
        ...state.messages,
        TutorMessage(
          text: question.trim(),
          isUser: true,
          hasScreenshot: screenshot != null,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: true,
      error: null,
    );

    final service = _getService();
    if (service == null) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          TutorMessage(
            text:
                'AI Tutor is not configured. Please add CLAUDE_API_KEY to your .env file.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
      return;
    }

    try {
      // Build conversation history (text-only for history, image only on current message)
      final history = _buildHistory();

      final response = await service.ask(
        question: question.trim(),
        screenshotBase64: screenshot,
        history: history,
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          TutorMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          TutorMessage(
            text: 'Sorry, I had trouble responding. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clears the conversation history.
  void clearHistory() {
    state = const AiTutorState();
  }

  /// Builds the conversation history in Claude's message format (text-only for past messages).
  List<Map<String, dynamic>> _buildHistory() {
    final history = <Map<String, dynamic>>[];
    // Exclude the last user message we just added (we'll send it as the current message)
    final pastMessages = state.messages.length > 1
        ? state.messages.sublist(0, state.messages.length - 1)
        : <TutorMessage>[];

    for (final msg in pastMessages) {
      history.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    return history;
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}

final aiTutorProvider =
    StateNotifierProvider<AiTutorNotifier, AiTutorState>((ref) {
  return AiTutorNotifier();
});
