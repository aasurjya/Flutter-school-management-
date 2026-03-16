import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/agents/ai_agent.dart';
import '../../../core/ai/agents/ai_agent_state.dart';
import '../../../core/ai/models/ai_capability.dart';
import '../../../core/ai/models/ai_completion_request.dart';
import '../../../core/ai/models/ai_message.dart';
import '../../../core/ai/ai_router.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../core/services/claude_vision_service.dart';
import '../../../core/services/screen_capture_service.dart';

/// A single chat message in the AI tutor session.
class TutorMessage {
  final String text;
  final bool isUser;
  final bool hasScreenshot;
  final DateTime timestamp;

  /// For agentic queries, tracks intermediate steps.
  final List<AgentStep>? agentSteps;

  const TutorMessage({
    required this.text,
    required this.isUser,
    this.hasScreenshot = false,
    required this.timestamp,
    this.agentSteps,
  });
}

class AiTutorState {
  final List<TutorMessage> messages;
  final bool isLoading;
  final String? error;

  /// Current agent status label (e.g. "Looking up attendance...").
  final String? agentStatusLabel;

  const AiTutorState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.agentStatusLabel,
  });

  AiTutorState copyWith({
    List<TutorMessage>? messages,
    bool? isLoading,
    String? error,
    String? agentStatusLabel,
  }) =>
      AiTutorState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        agentStatusLabel: agentStatusLabel,
      );
}

class AiTutorNotifier extends StateNotifier<AiTutorState> {
  final AIRouter? _router;
  final AIAgent? _agent;

  AiTutorNotifier({AIRouter? router, AIAgent? agent})
      : _router = router,
        _agent = agent,
        super(const AiTutorState());

  ClaudeVisionService? _legacyService;

  ClaudeVisionService? _getLegacyService() {
    final key = AppEnvironment.claudeApiKey;
    if (key == null) return null;
    return _legacyService ??= ClaudeVisionService(apiKey: key);
  }

  /// Sends a user question, captures the current screen, and gets an AI response.
  Future<void> ask(String question) async {
    if (question.trim().isEmpty) return;

    // Capture the screen immediately before updating state.
    final screenshot = await ScreenCaptureService.captureBase64();

    // Add user message.
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
      agentStatusLabel: null,
    );

    // Detect if this is an agentic query.
    if (_agent != null && _detectAgenticQuery(question)) {
      await _handleAgenticQuery(question);
      return;
    }

    // Try the new AIRouter with vision capability first.
    if (_router != null && _router.supports(AICapability.vision)) {
      try {
        final history = _buildRouterHistory();
        final messages = [
          AIMessage(
            role: AIMessageRole.system,
            content: ClaudeVisionService.systemPromptText,
          ),
          ...history,
          AIMessage(
            role: AIMessageRole.user,
            content: question.trim(),
            imageBase64: screenshot,
          ),
        ];

        final response = await _router.complete(
          AICompletionRequest(
            messages: messages,
            maxTokens: 1024,
            skipCache: true, // Conversational — don't cache.
          ),
          capability: AICapability.vision,
        );

        state = state.copyWith(
          messages: [
            ...state.messages,
            TutorMessage(
              text: response.text,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
          isLoading: false,
        );
        return;
      } catch (_) {
        // Fall through to legacy service.
      }
    }

    // Legacy path: direct ClaudeVisionService.
    final service = _getLegacyService();
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
      final history = _buildLegacyHistory();
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

  // ---------------------------------------------------------------------------
  // Agentic query handling
  // ---------------------------------------------------------------------------

  /// Heuristic: detect queries that would benefit from tool-based data gathering.
  bool _detectAgenticQuery(String query) {
    final lower = query.toLowerCase();
    final agenticPatterns = [
      'how is',
      'how are',
      'tell me about',
      'what is the status of',
      'give me a summary',
      'compare',
      'draft a message',
      'write a message',
      'compose a',
      'student report',
      'doing in',
    ];
    return agenticPatterns.any((p) => lower.contains(p));
  }

  Future<void> _handleAgenticQuery(String question) async {
    try {
      final agentState = await _agent!.run(
        question,
        onStateChanged: (s) {
          if (!mounted) return;
          // Update the status label in real-time.
          final latestStep = s.steps.isNotEmpty ? s.steps.last : null;
          state = state.copyWith(
            agentStatusLabel: latestStep?.statusLabel,
          );
        },
      );

      final responseText = agentState.finalResult ??
          'I wasn\'t able to complete the analysis. Please try a more specific question.';

      state = state.copyWith(
        messages: [
          ...state.messages,
          TutorMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
            agentSteps: agentState.steps,
          ),
        ],
        isLoading: false,
        agentStatusLabel: null,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          TutorMessage(
            text: 'Sorry, I had trouble gathering the information. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
        error: e.toString(),
        agentStatusLabel: null,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // History builders
  // ---------------------------------------------------------------------------

  List<AIMessage> _buildRouterHistory() {
    final pastMessages = state.messages.length > 1
        ? state.messages.sublist(0, state.messages.length - 1)
        : <TutorMessage>[];

    return pastMessages
        .map((msg) => AIMessage(
              role: msg.isUser ? AIMessageRole.user : AIMessageRole.assistant,
              content: msg.text,
            ))
        .toList();
  }

  List<Map<String, dynamic>> _buildLegacyHistory() {
    final pastMessages = state.messages.length > 1
        ? state.messages.sublist(0, state.messages.length - 1)
        : <TutorMessage>[];

    return pastMessages
        .map((msg) => {
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.text,
            })
        .toList();
  }

  @override
  void dispose() {
    _legacyService?.dispose();
    super.dispose();
  }
}

final aiTutorProvider =
    StateNotifierProvider<AiTutorNotifier, AiTutorState>((ref) {
  final router = ref.watch(aiRouterProvider);
  final agent = ref.watch(aiAgentProvider);
  return AiTutorNotifier(router: router, agent: agent);
});
