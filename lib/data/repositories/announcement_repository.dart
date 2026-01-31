import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import 'base_repository.dart';

class AnnouncementRepository extends BaseRepository {
  AnnouncementRepository(super.client);

  /// Get all announcements for the tenant
  Future<List<Announcement>> getAnnouncements({
    String? targetRole,
    bool? isPublished,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('announcements')
        .select('''
          *,
          users!created_by(id, full_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (targetRole != null) {
      query = query.contains('target_roles', [targetRole]);
    }
    
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) {
      // Handle joined user data
      if (json['users'] != null) {
        json['created_by_name'] = json['users']['full_name'];
      }
      return Announcement.fromJson(json);
    }).toList();
  }

  /// Get published announcements for a specific role
  Future<List<Announcement>> getPublishedAnnouncements({
    required String targetRole,
    int limit = 20,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    final response = await client
        .from('announcements')
        .select('''
          *,
          users!created_by(id, full_name)
        ''')
        .eq('tenant_id', tenantId!)
        .eq('is_published', true)
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('priority', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) {
      if (json['users'] != null) {
        json['created_by_name'] = json['users']['full_name'];
      }
      return Announcement.fromJson(json);
    }).toList();
  }

  /// Get announcement by ID
  Future<Announcement?> getAnnouncementById(String id) async {
    final response = await client
        .from('announcements')
        .select('''
          *,
          users!created_by(id, full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    
    if (response['users'] != null) {
      response['created_by_name'] = response['users']['full_name'];
    }
    return Announcement.fromJson(response);
  }

  /// Create a new announcement
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    List<String> targetRoles = const ['all'],
    List<String>? targetSections,
    String? priority,
    bool isPublished = false,
    DateTime? expiresAt,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final data = {
      'tenant_id': tenantId,
      'title': title,
      'content': content,
      'target_roles': targetRoles,
      'target_sections': targetSections ?? [],
      'priority': priority ?? 'normal',
      'is_published': isPublished,
      'expires_at': expiresAt?.toIso8601String(),
      'attachments': attachments ?? [],
      'created_by': currentUserId,
    };

    final response = await client
        .from('announcements')
        .insert(data)
        .select()
        .single();

    return Announcement.fromJson(response);
  }

  /// Update an announcement
  Future<Announcement> updateAnnouncement(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await client
        .from('announcements')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Announcement.fromJson(response);
  }

  /// Publish an announcement
  Future<void> publishAnnouncement(String id) async {
    await client
        .from('announcements')
        .update({'is_published': true})
        .eq('id', id);
  }

  /// Unpublish an announcement
  Future<void> unpublishAnnouncement(String id) async {
    await client
        .from('announcements')
        .update({'is_published': false})
        .eq('id', id);
  }

  /// Set priority to high (acts like pinning)
  Future<void> pinAnnouncement(String id) async {
    await client
        .from('announcements')
        .update({'priority': 'high'})
        .eq('id', id);
  }

  /// Set priority to normal (acts like unpinning)
  Future<void> unpinAnnouncement(String id) async {
    await client
        .from('announcements')
        .update({'priority': 'normal'})
        .eq('id', id);
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String id) async {
    await client.from('announcements').delete().eq('id', id);
  }

  /// Subscribe to announcements for real-time updates
  RealtimeChannel subscribeToAnnouncements({
    required void Function(Announcement) onInsert,
    required void Function(Announcement) onUpdate,
    required void Function(String) onDelete,
  }) {
    return client.channel('announcements-$tenantId').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'announcements',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tenant_id',
        value: tenantId,
      ),
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.insert) {
          onInsert(Announcement.fromJson(payload.newRecord));
        } else if (payload.eventType == PostgresChangeEvent.update) {
          onUpdate(Announcement.fromJson(payload.newRecord));
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          onDelete(payload.oldRecord['id'] as String);
        }
      },
    ).subscribe();
  }
}
