import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_management/core/ai/adapters/deepseek_adapter.dart';
import 'package:school_management/core/ai/agents/ai_agent.dart';
import 'package:school_management/core/ai/agents/ai_agent_state.dart';
import 'package:school_management/core/ai/agents/ai_tool.dart';
import 'package:school_management/core/ai/ai_router.dart';
import 'package:school_management/core/ai/models/ai_capability.dart';
import 'package:school_management/core/ai/models/ai_model_config.dart';

/// A test tool that returns hardcoded data.
class MockStudentTool extends AiTool {
  @override
  String get name => 'fetch_student';
  @override
  String get description => 'Look up a student';
  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'student_name': {'type': 'string'},
        },
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    return {
      'student_id': 'abc-123',
      'name': 'Rahul Sharma',
      'class': '5A',
      'attendance_percentage': 92.5,
    };
  }
}

void main() {
  group('AIAgent', () {
    test('returns final answer when LLM responds with plain text', () async {
      var callCount = 0;
      final mockClient = MockClient((_) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': 'Rahul is doing well. Attendance is 92.5%.',
                }
              }
            ],
          }),
          200,
        );
      });

      final adapter = DeepSeekAdapter(
        config: const AIModelConfig(
          provider: 'deepseek',
          modelId: 'deepseek-chat',
          endpoint: 'https://api.deepseek.com/chat/completions',
          apiKeyEnvVar: 'Deepseek_API',
        ),
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final router = AIRouter(
        adapters: {AICapability.textGeneration: adapter},
      );

      final agent = AIAgent(
        router: router,
        tools: [MockStudentTool()],
      );

      final state = await agent.run('How is Rahul doing?');

      expect(state.status, AgentStatus.finalAnswer);
      expect(state.finalResult, contains('Rahul'));
      expect(callCount, 1); // Only one LLM call for direct answer.

      adapter.dispose();
    });

    test('executes tool call when LLM returns tool JSON', () async {
      var callCount = 0;
      final mockClient = MockClient((_) async {
        callCount++;
        if (callCount == 1) {
          // First call: LLM wants to use a tool.
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '{"tool": "fetch_student", "params": {"student_name": "Rahul"}}',
                  }
                }
              ],
            }),
            200,
          );
        }
        // Second call: LLM gives final answer with tool result.
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content':
                      'Rahul Sharma in class 5A has 92.5% attendance. He is doing well.',
                }
              }
            ],
          }),
          200,
        );
      });

      final adapter = DeepSeekAdapter(
        config: const AIModelConfig(
          provider: 'deepseek',
          modelId: 'deepseek-chat',
          endpoint: 'https://api.deepseek.com/chat/completions',
          apiKeyEnvVar: 'Deepseek_API',
        ),
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final router = AIRouter(
        adapters: {AICapability.textGeneration: adapter},
      );

      final agent = AIAgent(
        router: router,
        tools: [MockStudentTool()],
      );

      final states = <AIAgentState>[];
      final result = await agent.run(
        'How is Rahul doing?',
        onStateChanged: (s) => states.add(s),
      );

      expect(result.status, AgentStatus.finalAnswer);
      expect(result.finalResult, contains('Rahul'));
      expect(result.steps.length, 2); // tool_call + final_answer
      expect(result.steps.first.toolName, 'fetch_student');
      expect(callCount, 2);

      // Verify state callbacks were called.
      expect(states, isNotEmpty);

      adapter.dispose();
    });

    test('respects max steps limit', () async {
      // LLM always returns tool calls — should hit max steps.
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"tool": "fetch_student", "params": {"student_name": "Rahul"}}',
                }
              }
            ],
          }),
          200,
        );
      });

      final adapter = DeepSeekAdapter(
        config: const AIModelConfig(
          provider: 'deepseek',
          modelId: 'deepseek-chat',
          endpoint: 'https://api.deepseek.com/chat/completions',
          apiKeyEnvVar: 'Deepseek_API',
        ),
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final router = AIRouter(
        adapters: {AICapability.textGeneration: adapter},
      );

      final agent = AIAgent(
        router: router,
        tools: [MockStudentTool()],
      );

      final result = await agent.run('How is Rahul doing?');

      expect(result.status, AgentStatus.maxStepsReached);
      expect(result.steps.length, AIAgent.maxSteps);
      expect(result.finalResult, isNotNull);

      adapter.dispose();
    });
  });
}
