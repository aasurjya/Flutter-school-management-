import '../../ai_router.dart';
import '../../models/ai_capability.dart';
import '../../models/ai_completion_request.dart';
import '../../models/ai_message.dart';
import '../ai_tool.dart';

/// Drafts a parent message using collected context data and the AI router.
class ComposeMessageTool extends AiTool {
  final AIRouter _router;

  ComposeMessageTool(this._router);

  @override
  String get name => 'compose_message';

  @override
  String get description =>
      'Draft a professional message to a student\'s parents. '
      'Provide the message_type (e.g. "attendance_concern", "appreciation"), '
      'student_name, parent_name, and any relevant context data.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'message_type': {
            'type': 'string',
            'description':
                'Type of message: attendance_concern, appreciation, '
                    'fee_reminder, academic_update, general',
          },
          'student_name': {
            'type': 'string',
            'description': 'Student\'s full name',
          },
          'parent_name': {
            'type': 'string',
            'description': 'Parent\'s name (use "Parent" if unknown)',
          },
          'context_data': {
            'type': 'string',
            'description': 'Relevant data/facts to include in the message',
          },
        },
        'required': ['message_type', 'student_name'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final messageType = params['message_type'] as String? ?? 'general';
    final studentName = params['student_name'] as String? ?? 'the student';
    final parentName = params['parent_name'] as String? ?? 'Parent';
    final contextData = params['context_data'] as String? ?? '';

    const systemPrompt =
        'You are a professional school communication assistant for an Indian school. '
        'Write a polite, warm, professional message in letter format. '
        'Include a greeting, 2-3 paragraphs, and a closing. '
        'Be respectful of Indian cultural norms. Do not use markdown. '
        'Keep it under 150 words.';

    final userPrompt = 'Write a $messageType message to $parentName about '
        'their child $studentName.\n'
        '${contextData.isNotEmpty ? 'Context: $contextData' : ''}';

    try {
      final response = await _router.complete(
        AICompletionRequest(
          messages: [
            const AIMessage(role: AIMessageRole.system, content: systemPrompt),
            AIMessage(role: AIMessageRole.user, content: userPrompt),
          ],
          temperature: 0.6,
          maxTokens: 400,
          skipCache: true,
        ),
        capability: AICapability.textGeneration,
      );

      return {
        'message_type': messageType,
        'recipient': parentName,
        'student': studentName,
        'draft_message': response.text,
      };
    } catch (e) {
      return {'error': 'Failed to compose message: $e'};
    }
  }
}
