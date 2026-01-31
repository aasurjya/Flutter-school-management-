import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/hostel.dart';
import '../../../data/repositories/hostel_repository.dart';

final hostelRepositoryProvider = Provider<HostelRepository>((ref) {
  return HostelRepository(Supabase.instance.client);
});

// Hostels providers
final hostelsProvider = FutureProvider.family<List<Hostel>, bool>(
  (ref, activeOnly) async {
    final repository = ref.watch(hostelRepositoryProvider);
    return repository.getHostels(activeOnly: activeOnly);
  },
);

final hostelByIdProvider = FutureProvider.family<Hostel?, String>(
  (ref, hostelId) async {
    final repository = ref.watch(hostelRepositoryProvider);
    return repository.getHostelById(hostelId);
  },
);

// Rooms providers
final roomsProvider = FutureProvider.family<List<HostelRoom>, RoomsFilter>(
  (ref, filter) async {
    final repository = ref.watch(hostelRepositoryProvider);
    return repository.getRooms(
      filter.hostelId,
      availableOnly: filter.availableOnly,
    );
  },
);

final roomByIdProvider = FutureProvider.family<HostelRoom?, String>(
  (ref, roomId) async {
    final repository = ref.watch(hostelRepositoryProvider);
    return repository.getRoomById(roomId);
  },
);

// Allocations providers
final allocationsProvider = FutureProvider.family<List<RoomAllocation>, AllocationsFilter>(
  (ref, filter) async {
    final repository = ref.watch(hostelRepositoryProvider);
    return repository.getAllocations(
      hostelId: filter.hostelId,
      roomId: filter.roomId,
      studentId: filter.studentId,
      activeOnly: filter.activeOnly,
    );
  },
);

final myHostelProvider = FutureProvider<RoomAllocation?>((ref) async {
  final repository = ref.watch(hostelRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return repository.getMyHostel(userId);
});

// Stats provider
final hostelStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(hostelRepositoryProvider);
  return repository.getHostelStats();
});

// Filter classes
class RoomsFilter {
  final String hostelId;
  final bool availableOnly;

  const RoomsFilter({
    required this.hostelId,
    this.availableOnly = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomsFilter &&
        other.hostelId == hostelId &&
        other.availableOnly == availableOnly;
  }

  @override
  int get hashCode => Object.hash(hostelId, availableOnly);
}

class AllocationsFilter {
  final String? hostelId;
  final String? roomId;
  final String? studentId;
  final bool activeOnly;

  const AllocationsFilter({
    this.hostelId,
    this.roomId,
    this.studentId,
    this.activeOnly = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllocationsFilter &&
        other.hostelId == hostelId &&
        other.roomId == roomId &&
        other.studentId == studentId &&
        other.activeOnly == activeOnly;
  }

  @override
  int get hashCode => Object.hash(hostelId, roomId, studentId, activeOnly);
}
