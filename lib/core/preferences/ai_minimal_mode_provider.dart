import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/connectivity_provider.dart' show sharedPreferencesProvider;
// Re-export so callers can import this file alone.
export '../providers/connectivity_provider.dart' show sharedPreferencesProvider;

/// Master toggle for AI-driven surfaces.
///
/// When ON, every screen renders without AI-sourced cards, narrative
/// generation, or "Generate with AI" buttons. Anomaly-source providers
/// return empty lists; on-demand AI features (lesson plan generators,
/// question paper builders) are still reachable from explicit menu
/// entries but don't proactively appear.
///
/// Default: OFF (AI surfaces visible). Teachers, parents, and admins
/// who don't trust AI yet flip this once and the app gets quieter.
///
/// Storage: persisted via SharedPreferences under the key below.
const String aiMinimalModePrefsKey = 'ai_minimal_mode_enabled_v1';

class AiMinimalModeController extends StateNotifier<bool> {
  AiMinimalModeController(this._prefs) : super(_prefs.getBool(aiMinimalModePrefsKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> set(bool enabled) async {
    state = enabled;
    await _prefs.setBool(aiMinimalModePrefsKey, enabled);
  }

  Future<void> toggle() => set(!state);
}

/// The toggle. Read from any consumer with `ref.watch(aiMinimalModeProvider)`.
///
/// Re-exports [sharedPreferencesProvider] from `connectivity_provider.dart`
/// so callers only need to import this file.
final aiMinimalModeProvider =
    StateNotifierProvider<AiMinimalModeController, bool>((ref) {
  return AiMinimalModeController(ref.watch(sharedPreferencesProvider));
});
