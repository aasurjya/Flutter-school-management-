import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// State read from the `app_killswitch` Supabase table at boot.
///
/// Always non-null — the boot check returns a "disabled" instance if the
/// network is unreachable or the table is empty, so a flaky check never
/// blocks the app from starting (the killswitch is a safety net, not a
/// hard dependency).
class KillswitchState {
  final bool maintenance;
  final String message;

  const KillswitchState({
    required this.maintenance,
    required this.message,
  });

  static const KillswitchState off = KillswitchState(
    maintenance: false,
    message: '',
  );
}

/// One-shot boot-time killswitch check. Called from `main()` between
/// Supabase init and `runApp`. Timeout is intentionally tight (2 s) so a
/// slow network can't turn this into a 10s+ blank screen.
///
/// Failure modes — all fall back to [KillswitchState.off]:
///   • Network unreachable.
///   • Table doesn't exist yet (pre-migration env).
///   • Auth/RLS denies anon read (then the maintenance row simply isn't seen
///     and we proceed; super_admin would still see the toggle in admin UI).
Future<KillswitchState> readKillswitchAtBoot(SupabaseClient client) async {
  try {
    final res = await client
        .from('app_killswitch')
        .select('enabled, message')
        .eq('key', 'maintenance')
        .maybeSingle()
        .timeout(const Duration(seconds: 2));

    if (res == null) return KillswitchState.off;
    final enabled = res['enabled'] as bool? ?? false;
    final message = (res['message'] as String?)?.trim() ?? '';
    return KillswitchState(maintenance: enabled, message: message);
  } catch (e) {
    developer.log(
      'killswitch boot check failed — proceeding (open)',
      name: 'Killswitch',
      error: e,
    );
    return KillswitchState.off;
  }
}
