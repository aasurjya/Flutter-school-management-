import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/providers/ai_providers.dart';
import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/features/ai_insights/presentation/widgets/platform_ai_health_card.dart';

void main() {
  group('PlatformAIHealthCard', () {
    testWidgets('shows fallback with tenant and user counts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiTextGeneratorProvider
                .overrideWithValue(const AITextGenerator()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformAIHealthCard(
                tenantCount: 5,
                totalUsers: 2000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Platform AI Health'), findsOneWidget);
      expect(find.textContaining('5'), findsWidgets);
      expect(find.textContaining('2000'), findsWidgets);
    });

    testWidgets('shows placeholder when tenant count is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiTextGeneratorProvider
                .overrideWithValue(const AITextGenerator()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformAIHealthCard(
                tenantCount: 0,
                totalUsers: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Platform AI Health'), findsOneWidget);
    });
  });
}
