import 'dart:convert';
// Note: Isar is disabled for web builds. This model is kept for mobile/desktop.
// import 'package:isar/isar.dart';
// part 'sync_queue.g.dart';

/// Sync queue for offline operations
// @collection
class SyncQueue {
  SyncQueue();

  int? isarId;

  late String id;

  /// Table name (e.g., 'attendance', 'marks')
  late String tableName;

  /// Operation type
  late SyncOperation operation;

  /// Record ID in the remote table
  late String recordId;

  /// JSON payload to sync
  late String payload;

  /// Created timestamp
  late DateTime createdAt;

  /// Number of retry attempts
  int retryCount = 0;

  /// Last error message
  String? lastError;

  /// Synced timestamp (null if pending)
  DateTime? syncedAt;

  /// Priority (higher = sync first)
  int priority = 0;

  /// Create a new sync queue entry
  factory SyncQueue.create({
    required String tableName,
    required SyncOperation operation,
    required String recordId,
    required Map<String, dynamic> data,
    int priority = 0,
  }) {
    return SyncQueue()
      ..id = '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}'
      ..tableName = tableName
      ..operation = operation
      ..recordId = recordId
      ..payload = jsonEncode(data)
      ..createdAt = DateTime.now()
      ..priority = priority;
  }

  /// Get payload as Map
  Map<String, dynamic> get payloadMap => jsonDecode(payload);

  /// Check if this should be retried
  bool get shouldRetry => retryCount < 5 && syncedAt == null;

  /// Mark as synced
  void markSynced() {
    syncedAt = DateTime.now();
  }

  /// Mark as failed
  void markFailed(String error) {
    retryCount++;
    lastError = error;
  }
}

/// Sync operation types
enum SyncOperation {
  insert,
  update,
  upsert,
  delete,
}
