import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';

/// Convenience re-export of [isOnlineProvider] for components that prefer
/// importing from the services layer.
///
/// Watches the [OfflineSyncService]'s connectivity stream which is backed by
/// connectivity_plus and emits `true` when the device has a usable network
/// interface and `false` when it is fully offline.
///
/// Usage:
/// ```dart
/// final isOnline = ref.watch(connectivityServiceProvider);
/// ```
final connectivityServiceProvider = Provider<bool>((ref) {
  return ref
      .watch(isOnlineProvider)
      .when(data: (v) => v, loading: () => true, error: (_, __) => true);
});

/// A [StreamProvider] that exposes the raw online/offline boolean stream from
/// the [OfflineSyncService]. Prefer [connectivityServiceProvider] for
/// synchronous access inside build methods.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return service.onlineStream;
});
