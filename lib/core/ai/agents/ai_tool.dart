/// Abstract definition of a tool the AI agent can invoke.
///
/// Each tool has a [name] and [description] (sent to the LLM as JSON schema),
/// a [parametersSchema] describing expected params, and an [execute] method
/// that runs the tool and returns structured data.
abstract class AiTool {
  /// Tool name sent to the LLM (e.g. 'fetch_attendance').
  String get name;

  /// Human-readable description sent to the LLM.
  String get description;

  /// JSON Schema describing the parameters this tool accepts.
  Map<String, dynamic> get parametersSchema;

  /// Execute the tool with the given [params] and return structured data.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params);

  /// Produce the tool definition for the LLM system prompt.
  Map<String, dynamic> toToolDefinition() => {
        'name': name,
        'description': description,
        'parameters': parametersSchema,
      };
}
