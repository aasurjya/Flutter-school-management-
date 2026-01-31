import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/announcement.dart';
import '../../../data/repositories/announcement_repository.dart';

/// Repository provider
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(Supabase.instance.client);
});

/// All announcements provider (for admin)
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  return repository.getAnnouncements();
});

/// Published announcements for a specific role
final publishedAnnouncementsProvider = FutureProvider.family<List<Announcement>, String>(
  (ref, targetRole) async {
    final repository = ref.watch(announcementRepositoryProvider);
    return repository.getPublishedAnnouncements(targetRole: targetRole);
  },
);

/// Single announcement by ID
final announcementByIdProvider = FutureProvider.family<Announcement?, String>(
  (ref, id) async {
    final repository = ref.watch(announcementRepositoryProvider);
    return repository.getAnnouncementById(id);
  },
);

/// State notifier for managing announcements
class AnnouncementsNotifier extends StateNotifier<AsyncValue<List<Announcement>>> {
  final AnnouncementRepository _repository;

  AnnouncementsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    state = const AsyncValue.loading();
    try {
      final announcements = await _repository.getAnnouncements();
      state = AsyncValue.data(announcements);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    List<String> targetRoles = const ['all'],
    String? priority,
    bool isPublished = false,
    DateTime? expiresAt,
  }) async {
    final announcement = await _repository.createAnnouncement(
      title: title,
      content: content,
      targetRoles: targetRoles,
      priority: priority,
      isPublished: isPublished,
      expiresAt: expiresAt,
    );
    
    // Refresh the list
    await loadAnnouncements();
    return announcement;
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> updates) async {
    await _repository.updateAnnouncement(id, updates);
    await loadAnnouncements();
  }

  Future<void> publishAnnouncement(String id) async {
    await _repository.publishAnnouncement(id);
    await loadAnnouncements();
  }

  Future<void> unpublishAnnouncement(String id) async {
    await _repository.unpublishAnnouncement(id);
    await loadAnnouncements();
  }

  Future<void> pinAnnouncement(String id) async {
    await _repository.pinAnnouncement(id);
    await loadAnnouncements();
  }

  Future<void> unpinAnnouncement(String id) async {
    await _repository.unpinAnnouncement(id);
    await loadAnnouncements();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _repository.deleteAnnouncement(id);
    await loadAnnouncements();
  }
}

final announcementsNotifierProvider =
    StateNotifierProvider<AnnouncementsNotifier, AsyncValue<List<Announcement>>>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return AnnouncementsNotifier(repository);
});
