import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// schoolHealthNarrativeProvider's own body can't be exercised directly under
// `flutter test`: it reads `Supabase.instance.client` (a global singleton,
// not something a ProviderScope override can intercept), and this repo's
// convention — see test/screens/admin_dashboard_apple_test.dart and
// test/widgets/admin_ai_narrative_card_test.dart — is to override the whole
// provider rather than initialize a real/fake Supabase client under test.
//
// So instead of testing the real provider, this test proves the *mechanism*
// the fix relies on: an autoDispose FutureProvider without ref.keepAlive()
// re-runs its body every time it goes from zero listeners back to one
// (exactly what caused the AI-narrative card's runaway retry loop); the same
// provider WITH ref.keepAlive() does not. That mechanism, not the specific
// AI-gateway plumbing, is what was actually fixed.
void main() {
  group('autoDispose + ref.keepAlive() lifecycle', () {
    test('without keepAlive, re-listening after disposal re-runs the future', () async {
      var callCount = 0;
      final provider = FutureProvider.autoDispose<int>((ref) async {
        callCount++;
        return callCount;
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      var sub = container.listen(provider, (_, __) {});
      await container.read(provider.future);
      expect(callCount, 1);

      // Drop the only listener — autoDispose tears the provider down.
      sub.close();
      await Future<void>.delayed(Duration.zero);

      // Re-listening re-creates the provider from scratch.
      sub = container.listen(provider, (_, __) {});
      await container.read(provider.future);
      expect(callCount, 2,
          reason: 'without keepAlive, the future body reruns on every '
              'listener-drop-then-relisten cycle — this is the bug');
      sub.close();
    });

    test('with keepAlive, re-listening after disposal does NOT re-run the future', () async {
      var callCount = 0;
      final provider = FutureProvider.autoDispose<int>((ref) async {
        ref.keepAlive();
        callCount++;
        return callCount;
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      var sub = container.listen(provider, (_, __) {});
      await container.read(provider.future);
      expect(callCount, 1);

      sub.close();
      await Future<void>.delayed(Duration.zero);

      sub = container.listen(provider, (_, __) {});
      await container.read(provider.future);
      expect(callCount, 1,
          reason: 'ref.keepAlive() should prevent the body from rerunning '
              'once it has already resolved — this is the fix');
      sub.close();
    });
  });
}
