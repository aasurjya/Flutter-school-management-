import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/notice_board.dart';
import '../../../data/repositories/notice_board_repository.dart';

// ============================================================
// Repository
// ============================================================

final noticeBoardRepositoryProvider = Provider<NoticeBoardRepository>((ref) {
  return NoticeBoardRepository(ref.watch(supabaseProvider));
});

// ============================================================
// Read Providers
// ============================================================

final noticesProvider =
    FutureProvider.family<List<Notice>, NoticeFilter>((ref, filter) async {
  final repo = ref.watch(noticeBoardRepositoryProvider);
  return repo.getNotices(
    category: filter.category,
    audience: filter.audience,
    publishedOnly: true,
    pinnedFirst: true,
  );
});

final pinnedNoticesProvider = FutureProvider<List<Notice>>((ref) async {
  final repo = ref.watch(noticeBoardRepositoryProvider);
  return repo.getPinnedNotices(limit: 5);
});

final noticeByIdProvider =
    FutureProvider.family<Notice?, String>((ref, noticeId) async {
  final repo = ref.watch(noticeBoardRepositoryProvider);
  return repo.getNoticeById(noticeId);
});

// ============================================================
// Write Actions (exposed as plain async functions via notifier)
// ============================================================

class NoticeBoardActions {
  final NoticeBoardRepository _repo;
  final Ref _ref;

  NoticeBoardActions(this._repo, this._ref);

  Future<bool> createNotice(Map<String, dynamic> data) async {
    try {
      await _repo.createNotice(data);
      _ref.invalidate(noticesProvider);
      _ref.invalidate(pinnedNoticesProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateNotice(
      String noticeId, Map<String, dynamic> data) async {
    try {
      await _repo.updateNotice(noticeId, data);
      _ref.invalidate(noticesProvider);
      _ref.invalidate(pinnedNoticesProvider);
      _ref.invalidate(noticeByIdProvider(noticeId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> togglePin(String noticeId, {required bool pinned}) async {
    return updateNotice(noticeId, {'is_pinned': pinned});
  }

  Future<bool> deleteNotice(String noticeId) async {
    try {
      await _repo.deleteNotice(noticeId);
      _ref.invalidate(noticesProvider);
      _ref.invalidate(pinnedNoticesProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final noticeBoardActionsProvider = Provider<NoticeBoardActions>((ref) {
  return NoticeBoardActions(
    ref.watch(noticeBoardRepositoryProvider),
    ref,
  );
});
