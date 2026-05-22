import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot of a tenant's current AI budget as returned by the gateway.
class QuotaSnapshot {
  final double usedUsd;
  final double budgetUsd;
  final int callsUsed;
  final int callsLimit;
  final DateTime fetchedAt;

  QuotaSnapshot({
    required this.usedUsd,
    required this.budgetUsd,
    required this.callsUsed,
    required this.callsLimit,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  double get usedPct =>
      budgetUsd > 0 ? (usedUsd / budgetUsd).clamp(0, 1.5) : 0;

  bool get isSoftCapHit => usedPct >= 0.8;
  bool get isHardCapHit => usedPct >= 1.0 || callsUsed >= callsLimit;
}

/// Event surfaced when the gateway blocks a call. UI layer can listen to the
/// stream and show a non-blocking snackbar / banner.
class QuotaBlockEvent {
  final String featureType;
  final String reason;
  final DateTime at;

  QuotaBlockEvent({
    required this.featureType,
    required this.reason,
    DateTime? at,
  }) : at = at ?? DateTime.now();
}

/// Riverpod controller that tracks the latest known quota snapshot for the
/// signed-in tenant and exposes a stream of block events for UI banners.
class QuotaController extends StateNotifier<QuotaSnapshot?> {
  QuotaController() : super(null);

  final StreamController<QuotaBlockEvent> _blockEvents =
      StreamController<QuotaBlockEvent>.broadcast();

  Stream<QuotaBlockEvent> get blockEvents => _blockEvents.stream;

  void updateFromServer(QuotaSnapshot snapshot) {
    state = snapshot;
  }

  void notifyBlocked({required String featureType, required String reason}) {
    _blockEvents.add(QuotaBlockEvent(featureType: featureType, reason: reason));
  }

  @override
  void dispose() {
    _blockEvents.close();
    super.dispose();
  }
}

final quotaControllerProvider =
    StateNotifierProvider<QuotaController, QuotaSnapshot?>((ref) {
  return QuotaController();
});

/// Convenience provider — UI banners listen here.
final quotaBlockEventsProvider = StreamProvider.autoDispose<QuotaBlockEvent>(
  (ref) => ref.watch(quotaControllerProvider.notifier).blockEvents,
);
