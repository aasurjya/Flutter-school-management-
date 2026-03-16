import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/providers/ai_providers.dart';
import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/features/ai_insights/presentation/widgets/admin_ai_narrative_card.dart';
import 'package:school_management/features/ai_insights/providers/school_health_provider.dart';

void main() {
  group('AdminAINarrativeCard', () {
    testWidgets('shows fallback narrative when no API key', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiTextGeneratorProvider
                .overrideWithValue(const AITextGenerator()),
            schoolHealthNarrativeProvider.overrideWith(
              (ref) async => const AITextResult(
                text: 'Attendance is 85% today. Monitor fee collections.',
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminAINarrativeCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('School Health Summary'), findsOneWidget);
      expect(find.text('Daily overview'), findsOneWidget);
      expect(find.textContaining('85%'), findsOneWidget);
    });

    testWidgets('shows AI badge when LLM generated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolHealthNarrativeProvider.overrideWith(
              (ref) async => const AITextResult(
                text: 'LLM generated narrative.',
                isLLMGenerated: true,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminAINarrativeCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI-generated insight'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('LLM generated narrative.'), findsOneWidget);
    });
  });
}
