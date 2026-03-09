import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/offline_sync_service.dart';

/// State exposed by [offlineAttendanceProvider].
class OfflineAttendanceState {
  /// Number of attendance records queued offline and not yet synced.
  final int pendingCount;

  /// Whether a sync is currently in progress.
  final bool isSyncing;

  /// The most recent sync error, if any. Null when no error has occurred.
  final Object? lastError;

  const OfflineAttendanceState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastError,
  });

  OfflineAttendanceState copyWith({
    int? pendingCount,
    bool? isSyncing,
    Object? lastError,
    bool clearError = false,
  }) =>
      OfflineAttendanceState(
        pendingCount: pendingCount ?? this.pendingCount,
        isSyncing: isSyncing ?? this.isSyncing,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

/// StateNotifier that coordinates offline attendance recording.
///
/// On [markAttendance]:
///   - If **online**: delegates directly to the attendance repository's
///     [markBulkAttendance] / [markAttendance] methods (real Supabase write).
///   - If **offline**: enqueues a [PendingAttendanceRecord] in the
///     [OfflineSyncService]; the record is synced automatically on reconnect.
///
/// On connectivity restored: auto-triggers [OfflineSyncService.syncPendingRecords].
class OfflineAttendanceNotifier extends StateNotifier<OfflineAttendanceState> {
  final OfflineSyncService _syncService;
  final Ref _ref;

  StreamSubscription<bool>? _onlineSub;
  StreamSubscription<int>? _pendingCountSub;

  OfflineAttendanceNotifier(this._syncService, this._ref)
      : super(OfflineAttendanceState(
          pendingCount: _syncService.pendingCount,
        )) {
    _listenToConnectivity();
    _listenToPendingCount();
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Mark a single student's attendance.
  ///
  /// Returns `true` if saved directly to Supabase, `false` if queued offline.
  Future<bool> markAttendance({
    required String studentId,
    required String sectionId,
    required DateTime date,
    required String status,
    String? remarks,
  }) async {
    return markBulkAttendance(
      sectionId: sectionId,
      date: date,
      records: [
        {
          'student_id': studentId,
          'status': status,
          if (remarks != null) 'remarks': remarks,
        },
      ],
    );
  }

  /// Mark attendance for multiple students in one call.
  ///
  /// Returns `true` if saved directly to Supabase, `false` if queued offline.
  Future<bool> markBulkAttendance({
    required String sectionId,
    required DateTime date,
    required List<Map<String, dynamic>> records,
  }) async {
    if (_syncService.isOnline) {
      return _markOnline(sectionId: sectionId, date: date, records: records);
    } else {
      _markOffline(sectionId: sectionId, date: date, records: records);
      return false;
    }
  }

  /// Manually trigger a sync of all pending offline records.
  Future<void> syncNow() async {
    if (!_syncService.isOnline) {
      developer.log(
        'syncNow called while offline — skipping',
        name: 'OfflineAttendanceNotifier',
      );
      return;
    }
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      await _syncService.syncPendingRecords();
    } catch (e) {
      developer.log(
        'Manual sync failed',
        name: 'OfflineAttendanceNotifier',
        error: e,
      );
      state = state.copyWith(isSyncing: false, lastError: e);
      return;
    }
    state = state.copyWith(
      isSyncing: false,
      pendingCount: _syncService.pendingCount,
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<bool> _markOnline({
    required String sectionId,
    required DateTime date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final supabase = _ref.read(supabaseProvider);
      final dateStr = date.toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();
      final currentUserId = supabase.auth.currentUser?.id;
      final tenantId =
          supabase.auth.currentUser?.appMetadata['tenant_id'] as String?;

      final payload = records
          .map((r) => {
                if (tenantId != null) 'tenant_id': tenantId,
                'student_id': r['student_id'],
                'section_id': sectionId,
                'date': dateStr,
                'status': r['status'],
                if (r['remarks'] != null) 'remarks': r['remarks'],
                if (currentUserId != null) 'marked_by': currentUserId,
                'marked_at': now,
              })
          .toList();

      await supabase
          .from('attendance')
          .upsert(payload, onConflict: 'student_id,date');

      developer.log(
        'Online: saved ${records.length} attendance record(s)',
        name: 'OfflineAttendanceNotifier',
      );
      return true;
    } catch (e) {
      developer.log(
        'Online mark failed — falling back to queue',
        name: 'OfflineAttendanceNotifier',
        error: e,
      );
      _markOffline(sectionId: sectionId, date: date, records: records);
      return false;
    }
  }

  void _markOffline({
    required String sectionId,
    required DateTime date,
    required List<Map<String, dynamic>> records,
  }) {
    final dateStr = date.toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();
    final supabase = _ref.read(supabaseProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    final pending = records
        .map(
          (r) => PendingAttendanceRecord(
            studentId: r['student_id'] as String,
            sectionId: sectionId,
            date: dateStr,
            status: r['status'] as String,
            remarks: r['remarks'] as String?,
            markedBy: currentUserId,
            markedAt: now,
          ),
        )
        .toList();

    _syncService.enqueue(pending);

    developer.log(
      'Offline: queued ${pending.length} attendance record(s)',
      name: 'OfflineAttendanceNotifier',
    );
  }

  void _listenToConnectivity() {
    _onlineSub = _syncService.onlineStream.listen((isOnline) {
      if (isOnline) {
        developer.log(
          'Connectivity restored — triggering auto-sync',
          name: 'OfflineAttendanceNotifier',
        );
        syncNow();
      }
    });
  }

  void _listenToPendingCount() {
    _pendingCountSub = _syncService.pendingCountStream.listen((count) {
      if (mounted) {
        state = state.copyWith(pendingCount: count);
      }
    });
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    _pendingCountSub?.cancel();
    super.dispose();
  }
}

/// Provider for [OfflineAttendanceNotifier].
final offlineAttendanceProvider =
    StateNotifierProvider<OfflineAttendanceNotifier, OfflineAttendanceState>(
  (ref) {
    final syncService = ref.watch(offlineSyncServiceProvider);
    return OfflineAttendanceNotifier(syncService, ref);
  },
);

/// Convenience provider: the current count of unsynced attendance records.
/// Use this to drive badge indicators in the UI.
final pendingAttendanceCountProvider = Provider<int>((ref) {
  return ref.watch(offlineAttendanceProvider).pendingCount;
});
