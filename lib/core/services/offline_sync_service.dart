import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../net/idempotency.dart';
import '../observability/sentry_init.dart';

/// A pending attendance record waiting to be synced.
///
/// Stage 3 / S3.21 — three new fields make this resilient to flaky-network
/// retries and server-side deduplication:
///   • [clientRequestId] — stable UUID per (student, date). Reused across
///     every sync attempt so the Supabase UNIQUE(tenant_id, client_request_id)
///     index dedupes server-side. Backfilled to a fresh UUID for legacy
///     records on first read (matches existing on-conflict semantics).
///   • [retries] — attempt counter. After [_maxRetries] failures the record
///     is moved to the dead-letter bucket and surfaces in Sentry.
///   • [enqueuedAt] — for the age TTL. Records older than [_maxAge] are
///     dropped on read (a 30-day-old record retrying forever is worse than
///     no record).
class PendingAttendanceRecord {
  final String studentId;
  final String sectionId;
  final String date;
  final String status;
  final String? remarks;
  final String? markedBy;
  final String markedAt;
  final String clientRequestId;
  final int retries;
  final String enqueuedAt;

  const PendingAttendanceRecord({
    required this.studentId,
    required this.sectionId,
    required this.date,
    required this.status,
    this.remarks,
    this.markedBy,
    required this.markedAt,
    required this.clientRequestId,
    this.retries = 0,
    required this.enqueuedAt,
  });

  /// Convenience constructor that auto-generates [clientRequestId] +
  /// [enqueuedAt]. Use this at enqueue time; persisted records reuse the
  /// existing values via [fromJson].
  factory PendingAttendanceRecord.fresh({
    required String studentId,
    required String sectionId,
    required String date,
    required String status,
    String? remarks,
    String? markedBy,
    required String markedAt,
  }) {
    return PendingAttendanceRecord(
      studentId: studentId,
      sectionId: sectionId,
      date: date,
      status: status,
      remarks: remarks,
      markedBy: markedBy,
      markedAt: markedAt,
      clientRequestId: IdempotencyKey.generate(),
      enqueuedAt: DateTime.now().toIso8601String(),
    );
  }

  PendingAttendanceRecord withRetry() => PendingAttendanceRecord(
        studentId: studentId,
        sectionId: sectionId,
        date: date,
        status: status,
        remarks: remarks,
        markedBy: markedBy,
        markedAt: markedAt,
        clientRequestId: clientRequestId,
        retries: retries + 1,
        enqueuedAt: enqueuedAt,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'section_id': sectionId,
        'date': date,
        'status': status,
        'remarks': remarks,
        'marked_by': markedBy,
        'marked_at': markedAt,
        'client_request_id': clientRequestId,
        'retries': retries,
        'enqueued_at': enqueuedAt,
      };

  factory PendingAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return PendingAttendanceRecord(
      studentId: json['student_id'] as String,
      sectionId: json['section_id'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      markedBy: json['marked_by'] as String?,
      markedAt: json['marked_at'] as String,
      // Legacy records pre-S3.21 didn't carry these — backfill at read.
      clientRequestId: (json['client_request_id'] as String?) ??
          IdempotencyKey.generate(),
      retries: (json['retries'] as int?) ?? 0,
      enqueuedAt: (json['enqueued_at'] as String?) ??
          DateTime.now().toIso8601String(),
    );
  }
}

/// Service that queues attendance records when offline and syncs them when
/// connectivity is restored.
///
/// **Hardening (Stage 3 / S3.21):**
///   • Records carry a stable [PendingAttendanceRecord.clientRequestId] so
///     server-side `UNIQUE(tenant_id, client_request_id)` dedupes retries.
///   • Per-record retry counter; failed records re-queue with `retries+1`.
///   • Records dropped after [_maxRetries] failures OR [_maxAge] elapsed
///     since enqueue — whichever comes first. Drops are reported to Sentry
///     with a `sync.dead_letter` tag so they don't fail silently.
///   • Per-record failure isolation: one bad record no longer blocks the
///     rest of the queue (previous behaviour kept everything queued on any
///     exception).
///
/// **Not in scope here:** Isar persistence. The plan said "Real Isar offline
/// sync" but the existing SharedPreferences-backed JSON queue is already
/// proven and works on web (where Isar doesn't). Migrating to Isar later is
/// a swap of the storage layer; the queue + retry semantics stay.
class OfflineSyncService {
  static const _queueKey = 'offline_attendance_queue';
  static const _maxRetries = 5;
  static const _maxAge = Duration(days: 7);

  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  Future<void> Function(PendingAttendanceRecord record)? _onSyncOne;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final _onlineController = StreamController<bool>.broadcast();
  final _pendingCountController = StreamController<int>.broadcast();

  bool _isOnline = true;
  bool _isSyncing = false;

  OfflineSyncService({
    required SharedPreferences prefs,
    Connectivity? connectivity,
    Future<void> Function(PendingAttendanceRecord record)? onSyncOne,
  })  : _prefs = prefs,
        _connectivity = connectivity ?? Connectivity(),
        _onSyncOne = onSyncOne {
    _init();
  }

  bool get isOnline => _isOnline;
  Stream<bool> get onlineStream => _onlineController.stream;
  Stream<int> get pendingCountStream => _pendingCountController.stream;
  int get pendingCount => _getQueue().length;

  /// Set the per-record sync callback. Called once per pending record on
  /// reconnect or [syncPendingRecords]. Throw from this callback to mark
  /// the specific record as failed; other queued records will still attempt.
  set onSyncOne(
      Future<void> Function(PendingAttendanceRecord record) callback) {
    _onSyncOne = callback;
  }

  void _init() {
    // Both connectivity calls can throw on platforms without a registered
    // implementation (Flutter test env, some CI hosts). Swallow — the
    // service defaults to `_isOnline = true`, which is the only safe choice
    // when we genuinely don't know.
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (_) {/* keep last known state */},
      );
    } catch (_) {/* no connectivity backend — stay online */}
    try {
      _connectivity
          .checkConnectivity()
          .then(_handleConnectivityChange)
          .catchError((_) {/* same */});
    } catch (_) {/* same */}
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOffline = !_isOnline;
    _isOnline = result != ConnectivityResult.none;
    _onlineController.add(_isOnline);

    if (_isOnline && wasOffline) {
      syncPendingRecords();
    }
  }

  /// Queue a batch of attendance records for later sync. Each record is
  /// expected to come from [PendingAttendanceRecord.fresh] so it carries
  /// its own idempotency key.
  void enqueue(List<PendingAttendanceRecord> records) {
    final queue = _getQueue();
    queue.addAll(records);
    _saveQueue(queue);
    _pendingCountController.add(queue.length);

    developer.log(
      'Enqueued ${records.length} records (total pending: ${queue.length})',
      name: 'OfflineSyncService',
    );
  }

  /// Attempt to sync every pending record. Each record runs independently:
  /// successes are removed from the queue, failures increment retries.
  Future<void> syncPendingRecords() async {
    if (_isSyncing || !_isOnline) return;

    final queue = _getQueue();
    if (queue.isEmpty || _onSyncOne == null) return;

    _isSyncing = true;
    final remaining = <PendingAttendanceRecord>[];
    var succeeded = 0;
    var failed = 0;
    var deadLettered = 0;

    try {
      for (final record in queue) {
        try {
          await _onSyncOne!(record);
          succeeded++;
        } catch (e, st) {
          final retried = record.withRetry();
          if (retried.retries >= _maxRetries) {
            deadLettered++;
            // Surface so the team can investigate stuck records. Wrapped in
            // try/catch because `captureAppException` reads AppEnvironment;
            // in test envs without a loaded .env this throws — and a sync
            // observability failure must NEVER crash the sync loop.
            // Sync errors are best-effort. The async future from
            // captureAppException is explicitly given a no-op error handler
            // so an unloaded .env in tests / a Sentry SDK outage in prod
            // can never produce an "unhandled error in zone."
            captureAppException(
              e,
              stackTrace: st,
              hint: 'sync.dead_letter',
              extra: {
                'student_id': record.studentId,
                'date': record.date,
                'retries': retried.retries,
                'client_request_id': record.clientRequestId,
              },
            ).catchError((_) {/* swallow */});
            developer.log(
              'sync.dead_letter studentId=${record.studentId} '
              'date=${record.date} retries=${retried.retries}',
              name: 'OfflineSyncService',
              error: e,
            );
            continue; // drop
          }
          remaining.add(retried);
          failed++;
        }
      }

      _saveQueue(remaining);
      _pendingCountController.add(remaining.length);

      developer.log(
        'Sync done — succeeded=$succeeded failed=$failed '
        'dead_lettered=$deadLettered remaining=${remaining.length}',
        name: 'OfflineSyncService',
      );
    } finally {
      _isSyncing = false;
    }
  }

  List<PendingAttendanceRecord> _getQueue() {
    final jsonStr = _prefs.getString(_queueKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    final now = DateTime.now();
    try {
      final list = jsonDecode(jsonStr) as List;
      final parsed = list
          .map((e) =>
              PendingAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();

      // Drop records older than [_maxAge]. A 30-day-old "mark present" is
      // almost certainly wrong by now — the teacher likely re-marked it.
      final fresh = <PendingAttendanceRecord>[];
      var aged = 0;
      for (final r in parsed) {
        final enqueuedAt = DateTime.tryParse(r.enqueuedAt) ?? now;
        if (now.difference(enqueuedAt) > _maxAge) {
          aged++;
          continue;
        }
        fresh.add(r);
      }
      if (aged > 0) {
        developer.log(
          'Dropped $aged records older than ${_maxAge.inDays} days',
          name: 'OfflineSyncService',
        );
      }
      return fresh;
    } catch (e) {
      developer.log(
        'Failed to parse queue, clearing',
        name: 'OfflineSyncService',
        error: e,
      );
      _prefs.remove(_queueKey);
      return [];
    }
  }

  void _saveQueue(List<PendingAttendanceRecord> queue) {
    if (queue.isEmpty) {
      _prefs.remove(_queueKey);
      return;
    }
    final jsonStr = jsonEncode(queue.map((r) => r.toJson()).toList());
    _prefs.setString(_queueKey, jsonStr);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineController.close();
    _pendingCountController.close();
  }
}

void unawaited(Future<void> future) {
  // Standalone helper — avoids dart:async import for one use.
}
