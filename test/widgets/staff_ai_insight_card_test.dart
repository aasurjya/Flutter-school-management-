import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/core/theme/app_colors.dart';
import 'package:school_management/features/ai_insights/presentation/widgets/staff_ai_insight_card.dart';

void main() {
  Widget buildTestWidget({
    required ProviderListenable<AsyncValue<AITextResult>> provider,
    String title = 'Test Insight',
    IconData icon = Icons.auto_awesome,
    Color color = AppColors.accent,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProviderScope(
          child: StaffAIInsightCard(
            provider: provider,
            title: title,
            icon: icon,
            color: color,
          ),
        ),
      ),
    );
  }

  group('StaffAIInsightCard', () {
    testWidgets('shows shimmer when loading', (tester) async {
      final loadingProvider = Provider<AsyncValue<AITextResult>>(
        (ref) => const AsyncValue.loading(),
      );

      await tester.pumpWidget(buildTestWidget(provider: loadingProvider));
      await tester.pump();

      // Should show the card with loading shimmer (Container placeholders).
      expect(find.text('Test Insight'), findsOneWidget);
    });

    testWidgets('shows narrative text when data is loaded', (tester) async {
      final dataProvider = Provider<AsyncValue<AITextResult>>(
        (ref) => const AsyncValue.data(
          AITextResult(text: 'This is a test insight.', isLLMGenerated: true),
        ),
      );

      await tester.pumpWidget(buildTestWidget(provider: dataProvider));
      await tester.pump();

      expect(find.text('This is a test insight.'), findsOneWidget);
      expect(find.text('Test Insight'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget); // AI badge
    });

    testWidgets('shows auto-generated label for non-LLM results',
        (tester) async {
      final dataProvider = Provider<AsyncValue<AITextResult>>(
        (ref) => const AsyncValue.data(
          AITextResult(text: 'Fallback text.'),
        ),
      );

      await tester.pumpWidget(buildTestWidget(provider: dataProvider));
      await tester.pump();

      expect(find.text('Fallback text.'), findsOneWidget);
      expect(find.text('Auto-generated'), findsOneWidget);
      // No AI badge for non-LLM.
      expect(find.text('AI'), findsNothing);
    });

    testWidgets('hides card when result text is empty', (tester) async {
      final emptyProvider = Provider<AsyncValue<AITextResult>>(
        (ref) => const AsyncValue.data(AITextResult(text: '')),
      );

      await tester.pumpWidget(buildTestWidget(provider: emptyProvider));
      await tester.pump();

      expect(find.text('Test Insight'), findsNothing);
    });

    testWidgets('hides card on error', (tester) async {
      final errorProvider = Provider<AsyncValue<AITextResult>>(
        (ref) => AsyncValue.error('Something failed', StackTrace.current),
      );

      await tester.pumpWidget(buildTestWidget(provider: errorProvider));
      await tester.pump();

      expect(find.text('Test Insight'), findsNothing);
    });

    testWidgets('uses custom title and icon', (tester) async {
      final dataProvider = Provider<AsyncValue<AITextResult>>(
        (ref) => const AsyncValue.data(AITextResult(text: 'Custom insight.')),
      );

      await tester.pumpWidget(buildTestWidget(
        provider: dataProvider,
        title: 'Fee Insight',
        icon: Icons.account_balance_wallet,
      ));
      await tester.pump();

      expect(find.text('Fee Insight'), findsOneWidget);
      expect(find.text('Custom insight.'), findsOneWidget);
    });
  });
}
