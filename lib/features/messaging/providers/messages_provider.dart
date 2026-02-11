import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/message.dart';
import '../../../data/models/announcement.dart';
import '../../../data/repositories/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.watch(supabaseProvider));
});

final threadsProvider = FutureProvider<List<Thread>>((ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getThreads();
});

final threadByIdProvider = FutureProvider.family<Thread?, String>(
  (ref, threadId) async {
    final repository = ref.watch(messageRepositoryProvider);
    return repository.getThreadById(threadId);
  },
);

final messagesProvider = FutureProvider.family<List<Message>, MessagesFilter>(
  (ref, filter) async {
    final repository = ref.watch(messageRepositoryProvider);
    return repository.getMessages(
      threadId: filter.threadId,
      limit: filter.limit,
      beforeId: filter.beforeId,
    );
  },
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getUnreadCount();
});

final announcementsProvider = FutureProvider.family<List<Announcement>, bool>(
  (ref, activeOnly) async {
    final repository = ref.watch(messageRepositoryProvider);
    return repository.getAnnouncements(activeOnly: activeOnly);
  },
);

final announcementByIdProvider = FutureProvider.family<Announcement?, String>(
  (ref, announcementId) async {
    final repository = ref.watch(messageRepositoryProvider);
    return repository.getAnnouncementById(announcementId);
  },
);

class MessagesFilter {
  final String threadId;
  final int limit;
  final String? beforeId;

  const MessagesFilter({
    required this.threadId,
    this.limit = 50,
    this.beforeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesFilter &&
          other.threadId == threadId &&
          other.limit == limit &&
          other.beforeId == beforeId;

  @override
  int get hashCode => Object.hash(threadId, limit, beforeId);
}

class ThreadsNotifier extends StateNotifier<AsyncValue<List<Thread>>> {
  final MessageRepository _repository;

  ThreadsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadThreads() async {
    state = const AsyncValue.loading();
    try {
      final threads = await _repository.getThreads();
      state = AsyncValue.data(threads);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Thread> createThread({
    required String threadType,
    String? title,
    String? sectionId,
    required List<String> participantIds,
  }) async {
    final thread = await _repository.createThread(
      threadType: threadType,
      title: title,
      sectionId: sectionId,
      participantIds: participantIds,
    );
    await loadThreads();
    return thread;
  }

  Future<Thread?> getOrCreatePrivateThread(String otherUserId) async {
    final thread = await _repository.getOrCreatePrivateThread(otherUserId);
    await loadThreads();
    return thread;
  }

  Future<void> markAsRead(String threadId) async {
    await _repository.markThreadAsRead(threadId);
    await loadThreads();
  }

  Future<void> muteThread(String threadId, bool muted) async {
    await _repository.muteThread(threadId, muted);
    await loadThreads();
  }
}

final threadsNotifierProvider =
    StateNotifierProvider<ThreadsNotifier, AsyncValue<List<Thread>>>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return ThreadsNotifier(repository);
});

class MessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final MessageRepository _repository;
  String? _currentThreadId;

  MessagesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadMessages({
    required String threadId,
    int limit = 50,
    String? beforeId,
  }) async {
    _currentThreadId = threadId;
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessages(
        threadId: threadId,
        limit: limit,
        beforeId: beforeId,
      );
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Message> sendMessage({
    required String content,
    List<Map<String, dynamic>>? attachments,
    String? replyToId,
  }) async {
    if (_currentThreadId == null) {
      throw Exception('No thread selected');
    }
    final message = await _repository.sendMessage(
      threadId: _currentThreadId!,
      content: content,
      attachments: attachments,
      replyToId: replyToId,
    );
    await loadMessages(threadId: _currentThreadId!);
    return message;
  }

  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) async {
    final message = await _repository.editMessage(
      messageId: messageId,
      content: content,
    );
    if (_currentThreadId != null) {
      await loadMessages(threadId: _currentThreadId!);
    }
    return message;
  }

  Future<void> deleteMessage(String messageId) async {
    await _repository.deleteMessage(messageId);
    if (_currentThreadId != null) {
      await loadMessages(threadId: _currentThreadId!);
    }
  }

  Future<void> loadMoreMessages() async {
    if (_currentThreadId == null) return;
    final currentMessages = state.valueOrNull ?? [];
    if (currentMessages.isEmpty) return;

    final oldestMessageId = currentMessages.last.id;
    try {
      final moreMessages = await _repository.getMessages(
        threadId: _currentThreadId!,
        beforeId: oldestMessageId,
      );
      state = AsyncValue.data([...currentMessages, ...moreMessages]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final messagesNotifierProvider =
    StateNotifierProvider<MessagesNotifier, AsyncValue<List<Message>>>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MessagesNotifier(repository);
});

class AnnouncementsNotifier extends StateNotifier<AsyncValue<List<Announcement>>> {
  final MessageRepository _repository;

  AnnouncementsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadAnnouncements({bool activeOnly = true}) async {
    state = const AsyncValue.loading();
    try {
      final announcements = await _repository.getAnnouncements(activeOnly: activeOnly);
      state = AsyncValue.data(announcements);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> data) async {
    final announcement = await _repository.createAnnouncement(data);
    await loadAnnouncements(activeOnly: false);
    return announcement;
  }

  Future<Announcement> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> data,
  ) async {
    final announcement = await _repository.updateAnnouncement(announcementId, data);
    await loadAnnouncements(activeOnly: false);
    return announcement;
  }

  Future<void> publishAnnouncement(String announcementId) async {
    await _repository.publishAnnouncement(announcementId);
    await loadAnnouncements(activeOnly: false);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _repository.deleteAnnouncement(announcementId);
    await loadAnnouncements(activeOnly: false);
  }
}

final announcementsNotifierProvider =
    StateNotifierProvider<AnnouncementsNotifier, AsyncValue<List<Announcement>>>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return AnnouncementsNotifier(repository);
});

final selectedThreadIdProvider = StateProvider<String?>((ref) => null);
