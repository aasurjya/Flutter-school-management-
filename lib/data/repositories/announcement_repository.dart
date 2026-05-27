import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import 'base_repository.dart';

class AnnouncementRepository extends BaseRepository {
  AnnouncementRepository(super.client);

  // Null-safe snake_case row mapper — the Freezed generated fromJson reads
  // camelCase keys which don't match Supabase's snake_case columns.
  Announcement _fromRow(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;
    return Announcement(
      id: (j['id'] as String?) ?? '',
      tenantId: (j['tenant_id'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      content: (j['content'] as String?) ?? '',
      attachments: (j['attachments'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
      targetRoles:
          (j['target_roles'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      targetSections:
          (j['target_sections'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      priority: (j['priority'] as String?) ?? 'normal',
      publishAt: j['publish_at'] is String
          ? DateTime.tryParse(j['publish_at'] as String)
          : null,
      expiresAt: j['expires_at'] is String
          ? DateTime.tryParse(j['expires_at'] as String)
          : null,
      createdBy: (j['created_by'] as String?) ?? '',
      isPublished: j['is_published'] as bool? ?? false,
      createdAt: j['created_at'] is String
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
      createdByName:
          (j['created_by_name'] as String?) ?? (user?['full_name'] as String?),
    );
  }

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
        .eq('tenant_id', requireTenantId);

    if (targetRole != null) {
      query = query.contains('target_roles', [targetRole]);
    }
    
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => _fromRow(json as Map<String, dynamic>))
        .toList();
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
        .eq('tenant_id', requireTenantId)
        .eq('is_published', true)
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('priority', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => _fromRow(json as Map<String, dynamic>))
        .toList();
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
    return _fromRow(response);
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

    return _fromRow(response);
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

    return _fromRow(response);
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
          onInsert(_fromRow(payload.newRecord));
        } else if (payload.eventType == PostgresChangeEvent.update) {
          onUpdate(_fromRow(payload.newRecord));
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          onDelete(payload.oldRecord['id'] as String);
        }
      },
    ).subscribe();
  }
}
