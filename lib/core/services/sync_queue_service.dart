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

  const PendingOperation({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    required this.enqueuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'operation': operation,
        'data': data,
        'enqueued_at': enqueuedAt.toIso8601String(),
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'] as String,
        table: json['table'] as String,
        operation: json['operation'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        enqueuedAt: DateTime.parse(json['enqueued_at'] as String),
      );

  @override
  String toString() =>
      'PendingOperation(id: $id, table: $table, op: $operation, '
      'enqueuedAt: $enqueuedAt)';
}

/// General-purpose offline sync queue backed by [SharedPreferences].
///
/// Persists pending Supabase operations (insert / upsert / update / delete)
/// as a JSON list so they survive app restarts.  When [processQueue] is
/// called with an active [SupabaseClient] every pending op is replayed in
/// insertion order.
class SyncQueueService {
  static const _queueKey = 'offline_sync_general_queue';

  final SharedPreferences _prefs;

  SyncQueueService({required SharedPreferences prefs}) : _prefs = prefs;

  // ─── Public API ──────────────────────────────────────────────────────────

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
  /// success. Failed operations are kept for the next attempt.
  Future<void> processQueue(SupabaseClient client) async {
    final ops = getPendingOps();
    if (ops.isEmpty) return;

    developer.log(
      'Processing ${ops.length} pending sync operations',
      name: 'SyncQueueService',
    );

    final failed = <PendingOperation>[];

    for (final op in ops) {
      try {
        await _executeOp(client, op);
        developer.log(
          'Synced ${op.operation} on ${op.table} (id: ${op.id})',
          name: 'SyncQueueService',
        );
      } catch (e) {
        developer.log(
          'Failed to sync ${op.operation} on ${op.table}: $e',
          name: 'SyncQueueService',
          error: e,
        );
        failed.add(op);
      }
    }

    // Persist only the operations that failed
    _saveOps(failed);
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
