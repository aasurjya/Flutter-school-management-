import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_management/core/preferences/ai_minimal_mode_provider.dart';

void main() {
  group('aiMinimalModeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to false on a fresh install', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      expect(container.read(aiMinimalModeProvider), isFalse);
    });

    test('persists the toggled value across container rebuilds', () async {
      final prefs = await SharedPreferences.getInstance();
      final first = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      await first.read(aiMinimalModeProvider.notifier).set(true);
      expect(first.read(aiMinimalModeProvider), isTrue);
      first.dispose();

      // A second container reads the same prefs.
      final second = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(second.dispose);
      expect(
        second.read(aiMinimalModeProvider),
        isTrue,
        reason: 'value must hydrate from SharedPreferences',
      );
    });

    test('toggle() flips the state', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(aiMinimalModeProvider.notifier);
      expect(container.read(aiMinimalModeProvider), isFalse);
      await notifier.toggle();
      expect(container.read(aiMinimalModeProvider), isTrue);
      await notifier.toggle();
      expect(container.read(aiMinimalModeProvider), isFalse);
    });

    test('SharedPreferences key is stable across versions', () {
      // If we ever rename this we break every existing install. The version
      // suffix is part of the public contract.
      expect(aiMinimalModePrefsKey, 'ai_minimal_mode_enabled_v1');
    });
  });
}
