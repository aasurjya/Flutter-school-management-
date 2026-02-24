import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pending attendance record waiting to be synced.
class PendingAttendanceRecord {
  final String studentId;
  final String sectionId;
  final String date;
  final String status;
  final String? remarks;
  final String? markedBy;
  final String markedAt;

  const PendingAttendanceRecord({
    required this.studentId,
    required this.sectionId,
    required this.date,
    required this.status,
    this.remarks,
    this.markedBy,
    required this.markedAt,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'section_id': sectionId,
        'date': date,
        'status': status,
        'remarks': remarks,
        'marked_by': markedBy,
        'marked_at': markedAt,
      };

  factory PendingAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return PendingAttendanceRecord(
      studentId: json['student_id'],
      sectionId: json['section_id'],
      date: json['date'],
      status: json['status'],
      remarks: json['remarks'],
      markedBy: json['marked_by'],
      markedAt: json['marked_at'],
    );
  }
}

/// Service that queues attendance records when offline and syncs them when
/// connectivity is restored.
class OfflineSyncService {
  static const _queueKey = 'offline_attendance_queue';

  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  Future<void> Function(List<PendingAttendanceRecord> records)? _onSync;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final _onlineController = StreamController<bool>.broadcast();
  final _pendingCountController = StreamController<int>.broadcast();

  bool _isOnline = true;
  bool _isSyncing = false;

  OfflineSyncService({
    required SharedPreferences prefs,
    Connectivity? connectivity,
    Future<void> Function(List<PendingAttendanceRecord> records)? onSync,
  })  : _prefs = prefs,
        _connectivity = connectivity ?? Connectivity(),
        _onSync = onSync {
    _init();
  }

  bool get isOnline => _isOnline;
  Stream<bool> get onlineStream => _onlineController.stream;
  Stream<int> get pendingCountStream => _pendingCountController.stream;
  int get pendingCount => _getQueue().length;

  /// Set the sync callback (called when connectivity is restored).
  set onSync(
      Future<void> Function(List<PendingAttendanceRecord> records) callback) {
    _onSync = callback;
  }

  void _init() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    // Check initial state
    _connectivity.checkConnectivity().then(_handleConnectivityChange);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOffline = !_isOnline;
    _isOnline = result != ConnectivityResult.none;
    _onlineController.add(_isOnline);

    if (_isOnline && wasOffline) {
      // Just came back online — sync queued records
      syncPendingRecords();
    }
  }

  /// Queue a batch of attendance records for later sync.
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

  /// Attempt to sync all pending records.
  Future<void> syncPendingRecords() async {
    if (_isSyncing || !_isOnline) return;

    final queue = _getQueue();
    if (queue.isEmpty) return;

    _isSyncing = true;

    developer.log(
      'Syncing ${queue.length} pending attendance records',
      name: 'OfflineSyncService',
    );

    try {
      if (_onSync != null) {
        await _onSync!(queue);
      }
      // Clear queue on success
      await _prefs.remove(_queueKey);
      _pendingCountController.add(0);

      developer.log(
        'Successfully synced ${queue.length} records',
        name: 'OfflineSyncService',
      );
    } catch (e) {
      developer.log(
        'Sync failed, keeping ${queue.length} records in queue',
        name: 'OfflineSyncService',
        error: e,
      );
      // Keep queue intact for next attempt
    } finally {
      _isSyncing = false;
    }
  }

  List<PendingAttendanceRecord> _getQueue() {
    final jsonStr = _prefs.getString(_queueKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) =>
              PendingAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
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
    final jsonStr = jsonEncode(queue.map((r) => r.toJson()).toList());
    _prefs.setString(_queueKey, jsonStr);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineController.close();
    _pendingCountController.close();
  }
}
