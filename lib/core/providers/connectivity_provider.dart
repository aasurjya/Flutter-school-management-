import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/offline_sync_service.dart';
import '../services/sync_queue_service.dart';
import 'supabase_provider.dart';

/// SharedPreferences instance provider (must be overridden at app startup).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a real instance',
  );
});

/// The offline sync service — queues attendance when offline, syncs on reconnect.
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = OfflineSyncService(prefs: prefs);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of online/offline state.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return service.onlineStream;
});

/// Stream of pending sync count.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return service.pendingCountStream;
});

/// Phase 2.3 — general-purpose sync queue wired to auto-process on reconnect.
/// The queue handles insert/upsert/update/delete on any table (not just
/// attendance). On connectivity restore, pending ops are replayed
/// automatically with retry limits + dead-letter handling.
final syncQueueAutoProvider = Provider<SyncQueueService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = SyncQueueService(prefs: prefs);
  final client = ref.watch(supabaseProvider);
  final onlineStream = ref.watch(offlineSyncServiceProvider).onlineStream;

  service.attachConnectivity(
    client: client,
    onlineStream: onlineStream,
  );

  ref.onDispose(() {
    service.detachConnectivity();
  });

  return service;
});
