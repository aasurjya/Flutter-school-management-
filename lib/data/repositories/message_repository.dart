import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/announcement.dart';
import 'base_repository.dart';

class MessageRepository extends BaseRepository {
  MessageRepository(super.client);

  Future<List<Thread>> getThreads() async {
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
        .eq('tenant_id', tenantId!)
        .eq('thread_participants.user_id', currentUserId!)
        .eq('is_active', true)
        .order('last_message_at', ascending: false);

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

    final participants = [currentUserId!, ...participantIds].map((userId) => {
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
        .eq('tenant_id', tenantId!)
        .eq('thread_type', 'private')
        .eq('thread_participants.user_id', currentUserId!);

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

  Future<Message> sendMessage({
    required String threadId,
    required String content,
    List<Map<String, dynamic>>? attachments,
    String? replyToId,
  }) async {
    final response = await client.from('messages').insert({
      'tenant_id': tenantId,
      'thread_id': threadId,
      'sender_id': currentUserId,
      'content': content,
      'attachments': attachments ?? [],
      'reply_to_id': replyToId,
    }).select().single();

    await client.from('threads').update({
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', threadId);

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
        .eq('sender_id', currentUserId!)
        .select()
        .single();

    return Message.fromJson(response);
  }

  Future<void> deleteMessage(String messageId) async {
    await client
        .from('messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', currentUserId!);
  }

  Future<void> markThreadAsRead(String threadId) async {
    await client.from('thread_participants').update({
      'last_read_at': DateTime.now().toIso8601String(),
    }).eq('thread_id', threadId).eq('user_id', currentUserId!);
  }

  Future<void> muteThread(String threadId, bool muted) async {
    await client.from('thread_participants').update({
      'is_muted': muted,
    }).eq('thread_id', threadId).eq('user_id', currentUserId!);
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
  }) async {
    var query = client
        .from('announcements')
        .select('''
          *,
          users!created_by(id, full_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (activeOnly) {
      query = query
          .eq('is_published', true)
          .lte('publish_at', DateTime.now().toIso8601String())
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}');
    }

    final response = await query.order('publish_at', ascending: false);
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
