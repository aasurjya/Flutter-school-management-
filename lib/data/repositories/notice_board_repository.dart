import '../models/notice_board.dart';
import 'base_repository.dart';

class NoticeBoardRepository extends BaseRepository {
  NoticeBoardRepository(super.client);

  // ============================================================
  // READ
  // ============================================================

  Future<List<Notice>> getNotices({
    NoticeCategory? category,
    NoticeAudience? audience,
    bool publishedOnly = true,
    bool pinnedFirst = true,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('notices')
        .select('*, author:users!created_by(full_name)')
        .eq('tenant_id', requireTenantId);

    if (publishedOnly) {
      query = query.eq('is_published', true);
    }
    if (category != null) {
      query = query.eq('category', category.value);
    }
    if (audience != null && audience != NoticeAudience.all) {
      // Include notices targeted at everyone OR the specific audience
      query = query.or('audience.eq.all,audience.eq.${audience.value}');
    }

    final response = await query
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final notices = (response as List)
        .map((json) => Notice.fromJson(json as Map<String, dynamic>))
        .toList();

    // Filter expired notices
    return notices.where((n) => !n.isExpired).toList();
  }

  Future<Notice?> getNoticeById(String noticeId) async {
    final response = await client
        .from('notices')
        .select('*, author:users!created_by(full_name)')
        .eq('id', noticeId)
        .maybeSingle();

    if (response == null) return null;
    return Notice.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<Notice>> getPinnedNotices({int limit = 5}) async {
    final response = await client
        .from('notices')
        .select('*, author:users!created_by(full_name)')
        .eq('tenant_id', requireTenantId)
        .eq('is_pinned', true)
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Notice.fromJson(json as Map<String, dynamic>))
        .where((n) => !n.isExpired)
        .toList();
  }

  Future<int> getNoticeCount({NoticeCategory? category}) async {
    var query = client
        .from('notices')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('is_published', true);

    if (category != null) {
      query = query.eq('category', category.value);
    }

    final response = await query;
    return (response as List).length;
  }

  // ============================================================
  // WRITE
  // ============================================================

  Future<Notice> createNotice(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;

    final response = await client
        .from('notices')
        .insert(data)
        .select('*, author:users!created_by(full_name)')
        .single();

    return Notice.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Notice> updateNotice(
    String noticeId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await client
        .from('notices')
        .update(data)
        .eq('id', noticeId)
        .select('*, author:users!created_by(full_name)')
        .single();

    return Notice.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Notice> togglePin(String noticeId, {required bool pinned}) async {
    return updateNotice(noticeId, {'is_pinned': pinned});
  }

  Future<Notice> togglePublish(
    String noticeId, {
    required bool published,
  }) async {
    return updateNotice(noticeId, {'is_published': published});
  }

  Future<void> deleteNotice(String noticeId) async {
    await client.from('notices').delete().eq('id', noticeId);
  }
}
