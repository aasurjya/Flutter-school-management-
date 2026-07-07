import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/connectivity_provider.dart';

/// A single operation pending sync to Supabase.
class PendingOperation {
  final String id;
  final String table;
  final String operation; // 'insert' | 'update' | 'upsert' | 'delete'
  final Map<String, dynamic> data;
  final DateTime enqueuedAt;
  final int retries;

  const PendingOperation({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    required this.enqueuedAt,
    this.retries = 0,
  });

  /// Increment retry counter (used when an op fails).
  PendingOperation withRetry() => PendingOperation(
        id: id,
        table: table,
        operation: operation,
        data: data,
        enqueuedAt: enqueuedAt,
        retries: retries + 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'operation': operation,
        'data': data,
        'enqueued_at': enqueuedAt.toIso8601String(),
        'retries': retries,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'] as String,
        table: json['table'] as String,
        operation: json['operation'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        enqueuedAt: DateTime.parse(json['enqueued_at'] as String),
        retries: (json['retries'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() =>
      'PendingOperation(id: $id, table: $table, op: $operation, '
      'enqueuedAt: $enqueuedAt, retries: $retries)';
}

/// General-purpose offline sync queue backed by [SharedPreferences].
///
/// Persists pending Supabase operations (insert / upsert / update / delete)
/// as a JSON list so they survive app restarts.  When [processQueue] is
/// called with an active [SupabaseClient] every pending op is replayed in
/// insertion order.
///
/// Phase 2.3 — added connectivity-driven auto-processing + retry limits:
///   • [attachConnectivity] wires the queue to a connectivity stream so
///     pending ops are replayed automatically when the device comes back
///     online — no manual `processQueue()` call needed.
///   • Ops that fail [_maxRetries] times are dropped (dead-letter) to
///     prevent a poison-pill op from blocking the queue forever.
///   • Ops older than [_maxAge] are dropped on read.
class SyncQueueService {
  static const _queueKey = 'offline_sync_general_queue';
  static const _maxRetries = 5;
  static const _maxAge = Duration(days: 7);

  final SharedPreferences _prefs;
  StreamSubscription<bool>? _onlineSub;
  bool _isProcessing = false;

  SyncQueueService({required SharedPreferences prefs}) : _prefs = prefs;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Wire the queue to a connectivity stream + Supabase client so pending
  /// ops are replayed automatically when the device comes back online.
  /// Call once at app startup. The [onlineStream] should emit `true` when
  /// the device has connectivity and `false` when it doesn't.
  void attachConnectivity({
    required SupabaseClient client,
    required Stream<bool> onlineStream,
  }) {
    _onlineSub?.cancel();
    _onlineSub = onlineStream.listen((isOnline) {
      if (isOnline) {
        processQueue(client);
      }
    });
  }

  /// Detach from the connectivity stream. Call on logout.
  void detachConnectivity() {
    _onlineSub?.cancel();
    _onlineSub = null;
  }

  /// Adds a new operation to the persistent queue.
  void addToQueue(
    String table,
    String operation,
    Map<String, dynamic> data,
  ) {
    final ops = getPendingOps();
    final op = PendingOperation(
      id: _generateId(),
      table: table,
      operation: operation,
      data: Map<String, dynamic>.from(data), // immutable copy
      enqueuedAt: DateTime.now(),
    );
    final updated = [...ops, op];
    _saveOps(updated);

    developer.log(
      'Queued $operation on $table (total pending: ${updated.length})',
      name: 'SyncQueueService',
    );
  }

  /// Returns all pending operations in insertion order.
  List<PendingOperation> getPendingOps() {
    final raw = _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingOperation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Failed to parse sync queue — clearing corrupt data',
        name: 'SyncQueueService',
        error: e,
      );
      _prefs.remove(_queueKey);
      return const [];
    }
  }

  /// Replays all pending operations against [client] and clears each one on
  /// success. Failed operations are kept for the next attempt with retries+1.
  /// Ops that exceed [_maxRetries] or [_maxAge] are dropped (dead-letter).
  Future<void> processQueue(SupabaseClient client) async {
    if (_isProcessing) return;
    final ops = getPendingOps();
    if (ops.isEmpty) return;

    _isProcessing = true;
    developer.log(
      'Processing ${ops.length} pending sync operations',
      name: 'SyncQueueService',
    );

    final failed = <PendingOperation>[];
    final now = DateTime.now();

    for (final op in ops) {
      // Drop ops that are too old or have exceeded retry limit.
      if (now.difference(op.enqueuedAt) > _maxAge) {
        developer.log(
          'Dropping dead-letter op (expired): ${op.id} on ${op.table}',
          name: 'SyncQueueService',
        );
        continue;
      }
      if (op.retries >= _maxRetries) {
        developer.log(
          'Dropping dead-letter op (max retries): ${op.id} on ${op.table}',
          name: 'SyncQueueService',
        );
        continue;
      }
      try {
        await _executeOp(client, op);
        developer.log(
          'Synced ${op.operation} on ${op.table} (id: ${op.id})',
          name: 'SyncQueueService',
        );
      } catch (e) {
        developer.log(
          'Failed to sync ${op.operation} on ${op.table} (retry ${op.retries + 1}): $e',
          name: 'SyncQueueService',
          error: e,
        );
        failed.add(op.withRetry());
      }
    }

    // Persist only the operations that failed (with incremented retries).
    _saveOps(failed);
    _isProcessing = false;
  }

  /// Removes a single operation by its [id].
  void clearOp(String id) {
    final ops = getPendingOps().where((op) => op.id != id).toList();
    _saveOps(ops);
  }

  /// Removes ALL pending operations (use with confirmation dialog in UI).
  void clearAll() {
    _prefs.remove(_queueKey);
    developer.log('All pending ops cleared', name: 'SyncQueueService');
  }

  /// Total number of pending operations.
  int get pendingCount => getPendingOps().length;

  // ─── Internal helpers ─────────────────────────────────────────────────────

  Future<void> _executeOp(SupabaseClient client, PendingOperation op) async {
    switch (op.operation) {
      case 'insert':
        await client.from(op.table).insert(op.data);
      case 'upsert':
        await client.from(op.table).upsert(op.data);
      case 'update':
        final id = op.data['id'];
        if (id == null) throw StateError('update op missing data.id');
        await client
            .from(op.table)
            .update(Map<String, dynamic>.from(op.data)..remove('id'))
            .eq('id', id as Object);
      case 'delete':
        final id = op.data['id'];
        if (id == null) throw StateError('delete op missing data.id');
        await client.from(op.table).delete().eq('id', id as Object);
      default:
        throw UnsupportedError('Unknown operation: ${op.operation}');
    }
  }

  void _saveOps(List<PendingOperation> ops) {
    final encoded = jsonEncode(ops.map((op) => op.toJson()).toList());
    _prefs.setString(_queueKey, encoded);
  }

  /// Simple timestamp-based unique id.
  String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Object.hash(this, DateTime.now())}';
}

/// Riverpod provider for [SyncQueueService].
final syncQueueProvider = Provider<SyncQueueService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncQueueService(prefs: prefs);
});
