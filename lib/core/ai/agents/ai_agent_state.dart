/// Status of the AI agent execution.
enum AgentStatus { idle, thinking, toolCall, finalAnswer, error, maxStepsReached }

/// A single step in the agent's reasoning chain.
class AgentStep {
  /// What the agent decided to do (tool call or final answer).
  final String action;

  /// Tool name if this step is a tool call, null for final answer.
  final String? toolName;

  /// Parameters passed to the tool, if applicable.
  final Map<String, dynamic>? toolParams;

  /// Result returned by the tool, if applicable.
  final Map<String, dynamic>? toolResult;

  /// Human-readable status label (e.g. "Looking up attendance...").
  final String statusLabel;

  /// Timestamp when this step started.
  final DateTime timestamp;

  const AgentStep({
    required this.action,
    this.toolName,
    this.toolParams,
    this.toolResult,
    required this.statusLabel,
    required this.timestamp,
  });
}

/// Immutable state of an AI agent execution.
class AIAgentState {
  /// All steps taken so far.
  final List<AgentStep> steps;

  /// Current step index (0-based).
  final int currentStep;

  /// Current status.
  final AgentStatus status;

  /// Final synthesized result (set when status is [AgentStatus.finalAnswer]).
  final String? finalResult;

  /// Error message if status is [AgentStatus.error].
  final String? error;

  const AIAgentState({
    this.steps = const [],
    this.currentStep = 0,
    this.status = AgentStatus.idle,
    this.finalResult,
    this.error,
  });

  AIAgentState copyWith({
    List<AgentStep>? steps,
    int? currentStep,
    AgentStatus? status,
    String? finalResult,
    String? error,
  }) =>
      AIAgentState(
        steps: steps ?? this.steps,
        currentStep: currentStep ?? this.currentStep,
        status: status ?? this.status,
        finalResult: finalResult ?? this.finalResult,
        error: error ?? this.error,
      );

  /// True when the agent has finished (final answer, error, or max steps).
  bool get isDone =>
      status == AgentStatus.finalAnswer ||
      status == AgentStatus.error ||
      status == AgentStatus.maxStepsReached;
}
