import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

/// Tracks all active realtime channels across the app and provides a
/// single `cleanupAll()` entry point for logout / forced cleanup.
///
/// Phase 2.2 — safety net for realtime channel leaks.
///
/// The base_repository already has `subscribeToTableScoped` which auto-
/// cleans via `ref.onDispose`. This manager is the belt-and-suspenders:
/// call `cleanupAll()` on logout to guarantee no channel survives session
/// end, even if a provider forgot to dispose.
///
/// Usage in providers:
///   final rt = ref.watch(realtimeManagerProvider);
///   final channel = rt.track(repo.subscribeToTable(...));
///   ref.onDispose(() => rt.untrack(channel));
///
/// On logout:
///   ref.read(realtimeManagerProvider).cleanupAll();
class RealtimeManager {
  final SupabaseClient _client;
  final Set<RealtimeChannel> _active = {};

  RealtimeManager(this._client);

  /// Track a channel so it can be cleaned up on logout.
  /// Returns the same channel for fluent chaining.
  RealtimeChannel track(RealtimeChannel channel) {
    _active.add(channel);
    return channel;
  }

  /// Stop tracking a channel (after it's been disposed by its owner).
  void untrack(RealtimeChannel channel) {
    _active.remove(channel);
  }

  /// Remove and unsubscribe all tracked channels.
  /// Call on logout or when the user switches tenants.
  Future<void> cleanupAll() async {
    final channels = List<RealtimeChannel>.from(_active);
    _active.clear();
    for (final ch in channels) {
      try {
        await _client.removeChannel(ch);
      } catch (_) {
        // Channel may already be removed — ignore.
      }
    }
  }

  /// Number of currently tracked channels (for debugging / dashboards).
  int get activeCount => _active.length;
}

final realtimeManagerProvider = Provider<RealtimeManager>((ref) {
  return RealtimeManager(ref.watch(supabaseProvider));
});
