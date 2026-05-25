import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_management/core/preferences/ai_minimal_mode_provider.dart';
import 'package:school_management/features/settings/presentation/screens/settings_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders Settings title and Preferences section', (tester) async {
      await _pump(tester);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('AI minimal mode'), findsOneWidget);
    });

    testWidgets('AI minimal mode switch starts OFF and reflects toggle', (tester) async {
      await _pump(tester);

      Switch findSwitch() => tester.widget<Switch>(find.byType(Switch));
      expect(findSwitch().value, isFalse);
      expect(find.text('Hide AI cards across the app.'), findsOneWidget);

      // Flip it on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(findSwitch().value, isTrue);
      expect(find.text('AI cards are hidden across the app.'), findsOneWidget);
    });
  });
}
