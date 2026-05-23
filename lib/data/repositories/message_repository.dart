import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/net/idempotency.dart';
import '../../core/net/retry.dart';
import '../models/message.dart';
import '../models/announcement.dart';
import 'base_repository.dart';

class MessageRepository extends BaseRepository {
  MessageRepository(super.client);

  Future<List<Thread>> getThreads({int limit = 50, int offset = 0}) async {
    final response = await client
        .from('threads')
        .select('''
          *,
          users!created_by(id, full_name),
          sections(id, name),
          thread_participants!inner(
            *,
            users(id, full_name, avatar_url)
          )
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('thread_participants.user_id', requireUserId)
        .eq('is_active', true)
        .order('last_message_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Thread.fromJson(json)).toList();
  }

  Future<Thread?> getThreadById(String threadId) async {
    final response = await client
        .from('threads')
        .select('''
          *,
          users!created_by(id, full_name),
          sections(id, name),
          thread_participants(
            *,
            users(id, full_name, avatar_url)
          )
        ''')
        .eq('id', threadId)
        .single();

    return Thread.fromJson(response);
  }

  Future<Thread> createThread({
    required String threadType,
    String? title,
    String? sectionId,
    required List<String> participantIds,
  }) async {
    final threadResponse = await client.from('threads').insert({
      'tenant_id': tenantId,
      'thread_type': threadType,
      'title': title,
      'section_id': sectionId,
      'created_by': currentUserId,
    }).select().single();

    final threadId = threadResponse['id'] as String;

    final participants = [requireUserId, ...participantIds].map((userId) => {
      'thread_id': threadId,
      'user_id': userId,
    }).toList();

    await client.from('thread_participants').insert(participants);

    return Thread.fromJson(threadResponse);
  }

  Future<Thread?> getOrCreatePrivateThread(String otherUserId) async {
    final existingThreads = await client
        .from('threads')
        .select('''
          *,
          thread_participants!inner(user_id)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('thread_type', 'private')
        .eq('thread_participants.user_id', requireUserId);

    for (final thread in existingThreads) {
      final participants = thread['thread_participants'] as List;
      final userIds = participants.map((p) => p['user_id']).toSet();
      if (userIds.contains(otherUserId) && userIds.length == 2) {
        return Thread.fromJson(thread);
      }
    }

    return createThread(
      threadType: 'private',
      participantIds: [otherUserId],
    );
  }

  Future<List<Message>> getMessages({
    required String threadId,
    int limit = 50,
    String? beforeId,
  }) async {
    var query = client
        .from('messages')
        .select('''
          *,
          users!sender_id(id, full_name, avatar_url)
        ''')
        .eq('thread_id', threadId);

    if (beforeId != null) {
      final beforeMessage = await client
          .from('messages')
          .select('created_at')
          .eq('id', beforeId)
          .single();
      query = query.lt('created_at', beforeMessage['created_at']);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  /// Sends a message. Wrapped in [retryNetwork] + idempotency key (Stage 1
  /// / S1.8 + Stage 2 / S2.17) so a retried tap on the Send button after a
  /// network blip cannot create two messages — the second insert hits the
  /// UNIQUE(tenant_id, client_request_id) index and is silently rejected.
  ///
  /// Caller may pass a stable [clientRequestId] when wiring its own retry
  /// loop on top of this method.
  Future<Message> sendMessage({
    required String threadId,
    required String content,
    List<Map<String, dynamic>>? attachments,
    String? replyToId,
    String? clientRequestId,
  }) async {
    final key = clientRequestId ?? IdempotencyKey.generate();
    final response = await retryNetwork(
      () => client.from('messages').insert({
        'tenant_id': tenantId,
        'thread_id': threadId,
        'sender_id': currentUserId,
        'content': content,
        'attachments': attachments ?? [],
        'reply_to_id': replyToId,
        'client_request_id': key,
      }).select().single(),
      label: 'messages.send',
    );

    // Thread last_message_at update is best-effort — not part of the
    // idempotent transaction. If a retry beats the original to the UNIQUE
    // index and gets 23505, the row exists, and bumping last_message_at
    // again is harmless.
    await retryNetwork(
      () => client.from('threads').update({
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', threadId),
      label: 'threads.bump',
    );

    return Message.fromJson(response);
  }

  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) async {
    final response = await client
        .from('messages')
        .update({
          'content': content,
          'is_edited': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', requireUserId)
        .select()
        .single();

    return Message.fromJson(response);
  }

  Future<void> deleteMessage(String messageId) async {
    await client
        .from('messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', requireUserId);
  }

  Future<void> markThreadAsRead(String threadId) async {
    await client.from('thread_participants').update({
      'last_read_at': DateTime.now().toIso8601String(),
    }).eq('thread_id', threadId).eq('user_id', requireUserId);
  }

  Future<void> muteThread(String threadId, bool muted) async {
    await client.from('thread_participants').update({
      'is_muted': muted,
    }).eq('thread_id', threadId).eq('user_id', requireUserId);
  }

  Future<int> getUnreadCount() async {
    final threads = await getThreads();
    int unreadCount = 0;

    for (final thread in threads) {
      final participant = thread.participants?.firstWhere(
        (p) => p.userId == currentUserId,
        orElse: () => const ThreadParticipant(id: '', threadId: '', userId: ''),
      );

      if (participant != null && thread.lastMessageAt != null) {
        if (participant.lastReadAt == null ||
            thread.lastMessageAt!.isAfter(participant.lastReadAt!)) {
          unreadCount++;
        }
      }
    }

    return unreadCount;
  }

  Future<List<Announcement>> getAnnouncements({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('announcements')
        .select('''
          *,
          users!created_by(id, full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query
          .eq('is_published', true)
          .lte('publish_at', DateTime.now().toIso8601String())
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}');
    }

    final response = await query.order('publish_at', ascending: false).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => Announcement.fromJson(json))
        .toList();
  }

  Future<Announcement?> getAnnouncementById(String announcementId) async {
    final response = await client
        .from('announcements')
        .select('''
          *,
          users!created_by(id, full_name)
        ''')
        .eq('id', announcementId)
        .single();

    return Announcement.fromJson(response);
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['created_by'] = currentUserId;

    final response = await client
        .from('announcements')
        .insert(data)
        .select()
        .single();

    return Announcement.fromJson(response);
  }

  Future<Announcement> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('announcements')
        .update(data)
        .eq('id', announcementId)
        .select()
        .single();

    return Announcement.fromJson(response);
  }

  Future<void> publishAnnouncement(String announcementId) async {
    await client.from('announcements').update({
      'is_published': true,
      'publish_at': DateTime.now().toIso8601String(),
    }).eq('id', announcementId);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await client.from('announcements').delete().eq('id', announcementId);
  }

  RealtimeChannel subscribeToThread({
    required String threadId,
    required void Function(PostgresChangePayload) onNewMessage,
  }) {
    return subscribeToTable(
      'messages',
      filter: (column: 'thread_id', value: threadId),
      onInsert: onNewMessage,
    );
  }

  RealtimeChannel subscribeToAnnouncements({
    required void Function(PostgresChangePayload) onNewAnnouncement,
  }) {
    return subscribeToTable(
      'announcements',
      filter: (column: 'tenant_id', value: tenantId ?? ''),
      onInsert: onNewAnnouncement,
    );
  }
}
