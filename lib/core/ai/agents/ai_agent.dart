import 'dart:convert';
import 'dart:developer' as developer;

import '../ai_router.dart';
import '../models/ai_capability.dart';
import '../models/ai_completion_request.dart';
import '../models/ai_message.dart';
import 'ai_agent_state.dart';
import 'ai_tool.dart';

/// ReAct-style AI agent that can use tools to answer complex queries.
///
/// Loop:
/// 1. Send user query + tool descriptions to LLM
/// 2. LLM responds with a tool call JSON or a final text answer
/// 3. If tool call → execute → append result → go to 1
/// 4. If final answer → return to UI
/// 5. Hard limit: [maxSteps] iterations to prevent runaway loops
class AIAgent {
  /// Maximum reasoning steps before forcing a final answer.
  static const int maxSteps = 5;

  final AIRouter _router;
  final List<AiTool> _tools;

  AIAgent({
    required AIRouter router,
    required List<AiTool> tools,
  })  : _router = router,
        _tools = tools;

  /// Run the agent loop for a user [query].
  ///
  /// [onStateChanged] is called after each step, allowing the UI to show
  /// progress (e.g. "Looking up attendance...").
  Future<AIAgentState> run(
    String query, {
    String? systemContext,
    void Function(AIAgentState)? onStateChanged,
  }) async {
    var state = const AIAgentState(status: AgentStatus.thinking);
    onStateChanged?.call(state);

    // Build the system prompt with tool definitions.
    final systemPrompt = _buildSystemPrompt(systemContext);
    final conversation = <AIMessage>[
      AIMessage(role: AIMessageRole.system, content: systemPrompt),
      AIMessage(role: AIMessageRole.user, content: query),
    ];

    for (var step = 0; step < maxSteps; step++) {
      try {
        // Ask the LLM.
        final response = await _router.complete(
          AICompletionRequest(
            messages: conversation,
            temperature: 0.3,
            maxTokens: 800,
            skipCache: true, // Agent conversations should not be cached.
          ),
          capability: AICapability.textGeneration,
        );

        final llmText = response.text.trim();

        // Try to parse as a tool call.
        final toolCall = _parseToolCall(llmText);

        if (toolCall == null) {
          // LLM returned a final answer.
            final finalStep = AgentStep(
            action: 'final_answer',
            statusLabel: 'Composing answer...',
            timestamp: DateTime.now(),
          );

          state = state.copyWith(
            steps: [...state.steps, finalStep],
            currentStep: step,
            status: AgentStatus.finalAnswer,
            finalResult: llmText,
          );
          onStateChanged?.call(state);
          return state;
        }

        // Execute the tool.
        final toolName = toolCall['tool'] as String;
        final toolParams =
            (toolCall['params'] as Map<String, dynamic>?) ?? {};

        state = state.copyWith(
          status: AgentStatus.toolCall,
          currentStep: step,
          steps: [
            ...state.steps,
            AgentStep(
              action: 'tool_call',
              toolName: toolName,
              toolParams: toolParams,
              statusLabel: _humanLabel(toolName),
              timestamp: DateTime.now(),
            ),
          ],
        );
        onStateChanged?.call(state);

        final tool = _tools.where((t) => t.name == toolName).firstOrNull;
        Map<String, dynamic> result;

        if (tool == null) {
          result = {'error': 'Unknown tool: $toolName'};
        } else {
          try {
            result = await tool.execute(toolParams);
          } catch (e) {
            result = {'error': 'Tool execution failed: $e'};
          }
        }

        // Update the step with the result.
        final updatedSteps = [...state.steps];
        updatedSteps[updatedSteps.length - 1] = AgentStep(
          action: 'tool_call',
          toolName: toolName,
          toolParams: toolParams,
          toolResult: result,
          statusLabel: _humanLabel(toolName),
          timestamp: state.steps.last.timestamp,
        );
        state = state.copyWith(steps: updatedSteps);

        // Append tool result to conversation.
        conversation.add(
          AIMessage(role: AIMessageRole.assistant, content: llmText),
        );
        conversation.add(
          AIMessage(
            role: AIMessageRole.user,
            content: 'Tool result for $toolName:\n${jsonEncode(result)}',
          ),
        );

        state = state.copyWith(status: AgentStatus.thinking);
        onStateChanged?.call(state);
      } catch (e) {
        developer.log(
          'Agent step $step failed',
          name: 'AIAgent',
          error: e,
        );
        state = state.copyWith(
          status: AgentStatus.error,
          error: e.toString(),
        );
        onStateChanged?.call(state);
        return state;
      }
    }

    // Max steps reached — ask LLM for a final summary with what we have.
    try {
      conversation.add(
        const AIMessage(
          role: AIMessageRole.user,
          content:
              'You have reached the maximum number of tool calls. '
              'Please synthesize a final answer using the data collected so far.',
        ),
      );

      final finalResponse = await _router.complete(
        AICompletionRequest(
          messages: conversation,
          temperature: 0.5,
          maxTokens: 600,
          skipCache: true,
        ),
        capability: AICapability.textGeneration,
      );

      state = state.copyWith(
        status: AgentStatus.maxStepsReached,
        finalResult: finalResponse.text.trim(),
      );
    } catch (_) {
      state = state.copyWith(
        status: AgentStatus.maxStepsReached,
        finalResult: 'I gathered some information but couldn\'t complete '
            'the analysis. Please try a more specific question.',
      );
    }

    onStateChanged?.call(state);
    return state;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _buildSystemPrompt(String? extraContext) {
    final buf = StringBuffer()
      ..writeln('You are an AI agent embedded in a school management app.')
      ..writeln('You can call tools to fetch data, then synthesize a helpful answer.')
      ..writeln()
      ..writeln('Available tools:');

    for (final tool in _tools) {
      buf.writeln('- ${tool.name}: ${tool.description}');
      buf.writeln('  Parameters: ${jsonEncode(tool.parametersSchema)}');
    }

    buf
      ..writeln()
      ..writeln('INSTRUCTIONS:')
      ..writeln('- To call a tool, respond with ONLY a JSON object: '
          '{"tool": "<name>", "params": {<params>}}')
      ..writeln('- When you have enough data to answer, respond with '
          'plain text (no JSON wrapper).')
      ..writeln('- You may call up to $maxSteps tools before you must give a final answer.')
      ..writeln('- Be concise. Focus on actionable insights.');

    if (extraContext != null) {
      buf
        ..writeln()
        ..writeln(extraContext);
    }

    return buf.toString();
  }

  /// Try to parse an LLM response as a tool call JSON.
  /// Returns null if it's not a valid tool call.
  Map<String, dynamic>? _parseToolCall(String text) {
    try {
      // Strip markdown code fences if present.
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '')
            .trim();
      }

      if (!cleaned.startsWith('{')) return null;

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      if (json.containsKey('tool')) return json;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _humanLabel(String toolName) {
    const labels = {
      'fetch_student': 'Looking up student info...',
      'fetch_attendance': 'Checking attendance records...',
      'fetch_marks': 'Reviewing academic performance...',
      'fetch_risk_score': 'Analyzing risk factors...',
      'fetch_fee_status': 'Checking fee status...',
      'compose_message': 'Drafting message...',
    };
    return labels[toolName] ?? 'Processing...';
  }
}
