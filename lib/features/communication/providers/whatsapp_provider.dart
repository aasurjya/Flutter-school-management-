import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/whatsapp_config.dart';
import '../../../data/repositories/whatsapp_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final whatsappRepositoryProvider = Provider<WhatsAppRepository>((ref) {
  return WhatsAppRepository(ref.watch(supabaseProvider));
});

// ============================================================
// Config — AsyncNotifier
// ============================================================

class WhatsAppConfigNotifier extends AsyncNotifier<WhatsAppConfig?> {
  @override
  Future<WhatsAppConfig?> build() async {
    final repo = ref.watch(whatsappRepositoryProvider);
    return repo.getConfig();
  }

  Future<void> save(WhatsAppConfig config) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(whatsappRepositoryProvider);
      return repo.saveConfig(config);
    });
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

final whatsappConfigProvider =
    AsyncNotifierProvider<WhatsAppConfigNotifier, WhatsAppConfig?>(
  WhatsAppConfigNotifier.new,
);

// ============================================================
// Notification Logs
// ============================================================

final notificationLogsProvider =
    FutureProvider<List<NotificationLog>>((ref) async {
  final repo = ref.watch(whatsappRepositoryProvider);
  return repo.getLogs(limit: 100);
});

// ============================================================
// Delivery Stats
// ============================================================

final deliveryStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(whatsappRepositoryProvider);
  return repo.getDeliveryStats();
});
