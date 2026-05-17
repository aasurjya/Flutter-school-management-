import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/transport.dart';
import '../../../data/repositories/transport_repository.dart';

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return TransportRepository(ref.watch(supabaseProvider));
});

// Routes providers
final routesProvider = FutureProvider.autoDispose.family<List<TransportRoute>, bool>(
  (ref, activeOnly) async {
    final repository = ref.watch(transportRepositoryProvider);
    return repository.getRoutes(activeOnly: activeOnly);
  },
);

final routeByIdProvider = FutureProvider.autoDispose.family<TransportRoute?, String>(
  (ref, routeId) async {
    final repository = ref.watch(transportRepositoryProvider);
    return repository.getRouteById(routeId);
  },
);

// Stops providers
final stopsProvider = FutureProvider.autoDispose.family<List<TransportStop>, String>(
  (ref, routeId) async {
    final repository = ref.watch(transportRepositoryProvider);
    return repository.getStops(routeId);
  },
);

// Student transport providers
final studentsByRouteProvider = FutureProvider.autoDispose.family<List<StudentTransport>, String>(
  (ref, routeId) async {
    final repository = ref.watch(transportRepositoryProvider);
    return repository.getStudentsByRoute(routeId);
  },
);

final studentsByStopProvider = FutureProvider.autoDispose.family<List<StudentTransport>, String>(
  (ref, stopId) async {
    final repository = ref.watch(transportRepositoryProvider);
    return repository.getStudentsByStop(stopId);
  },
);

final myTransportProvider = FutureProvider.autoDispose<StudentTransport?>((ref) async {
  final repository = ref.watch(transportRepositoryProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (userId == null) return null;
  return repository.getMyTransport(userId);
});

// Stats provider
final transportStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(transportRepositoryProvider);
  return repository.getTransportStats();
});
