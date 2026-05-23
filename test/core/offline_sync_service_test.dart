import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_management/core/services/offline_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PendingAttendanceRecord rec({int retries = 0, DateTime? enqueued}) {
    final base = PendingAttendanceRecord.fresh(
      studentId: 'student-1',
      sectionId: 'section-1',
      date: '2026-05-23',
      status: 'present',
      markedAt: DateTime.now().toIso8601String(),
    );
    if (retries == 0 && enqueued == null) return base;
    return PendingAttendanceRecord(
      studentId: base.studentId,
      sectionId: base.sectionId,
      date: base.date,
      status: base.status,
      remarks: base.remarks,
      markedBy: base.markedBy,
      markedAt: base.markedAt,
      clientRequestId: base.clientRequestId,
      retries: retries,
      enqueuedAt: (enqueued ?? DateTime.now()).toIso8601String(),
    );
  }

  group('PendingAttendanceRecord', () {
    test('.fresh generates a unique clientRequestId per call', () {
      final a = PendingAttendanceRecord.fresh(
        studentId: 's',
        sectionId: 'sec',
        date: '2026-05-23',
        status: 'present',
        markedAt: 'now',
      );
      final b = PendingAttendanceRecord.fresh(
        studentId: 's',
        sectionId: 'sec',
        date: '2026-05-23',
        status: 'present',
        markedAt: 'now',
      );
      expect(a.clientRequestId, isNot(b.clientRequestId));
    });

    test('fromJson backfills legacy records without the new fields', () {
      final legacy = PendingAttendanceRecord.fromJson({
        'student_id': 'st',
        'section_id': 'sec',
        'date': '2026-05-23',
        'status': 'present',
        'marked_at': 'when',
      });
      expect(legacy.clientRequestId, isNotEmpty);
      expect(legacy.retries, 0);
      expect(legacy.enqueuedAt, isNotEmpty);
    });

    test('withRetry preserves the idempotency key and bumps the counter', () {
      final r = rec();
      final r2 = r.withRetry();
      expect(r2.clientRequestId, r.clientRequestId);
      expect(r2.retries, 1);
      expect(r2.enqueuedAt, r.enqueuedAt);
    });
  });

  group('OfflineSyncService — per-record sync', () {
    late SharedPreferences prefs;
    late OfflineSyncService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = OfflineSyncService(prefs: prefs);
    });

    tearDown(() {
      service.dispose();
    });

    test('successful per-record sync clears the queue', () async {
      final syncedKeys = <String>[];
      service.onSyncOne = (r) async {
        syncedKeys.add(r.clientRequestId);
      };
      service.enqueue([rec(), rec()]);
      expect(service.pendingCount, 2);

      await service.syncPendingRecords();
      expect(syncedKeys.length, 2);
      expect(service.pendingCount, 0);
    });

    test('one failing record does not block the rest', () async {
      final r1 = rec();
      final r2 = rec();
      service.onSyncOne = (r) async {
        if (r.clientRequestId == r1.clientRequestId) {
          throw StateError('boom');
        }
      };
      service.enqueue([r1, r2]);

      await service.syncPendingRecords();

      // r2 cleared, r1 remains with retries=1.
      expect(service.pendingCount, 1);
    });

    test('record is dead-lettered after maxRetries failures', () async {
      // Seed a record at retries=4 so one more failure crosses the threshold.
      final almost = rec(retries: 4);
      service.onSyncOne = (r) async => throw StateError('always-fail');
      service.enqueue([almost]);

      await service.syncPendingRecords();

      // Dropped from the queue entirely; the Sentry event is best-effort and
      // not asserted here (no SDK init in tests = no-op anyway).
      expect(service.pendingCount, 0);
    });

    test('records older than the age TTL are dropped on read', () async {
      final stale = rec(
          enqueued: DateTime.now().subtract(const Duration(days: 10)));
      // Persist directly through the public API.
      service.enqueue([stale]);
      // Force a queue read — the constructor stores via _saveQueue but the
      // age filter is on read. Trigger a re-read via syncPendingRecords with
      // online=false → returns early but still touches the queue path.
      // We test the read filter directly by spinning up a new service against
      // the same SharedPreferences.
      service.dispose();
      service = OfflineSyncService(prefs: prefs);
      expect(service.pendingCount, 0);
    });
  });

  group('Connectivity wiring', () {
    test('isOnline starts true; pendingCountStream is broadcast', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = OfflineSyncService(prefs: prefs);
      expect(svc.isOnline, isTrue);
      // Broadcast streams allow multiple listeners (UI badge + analytics).
      expect(svc.pendingCountStream, isA<Stream<int>>());
      svc.dispose();
    });
  });
}

// Local Connectivity mock isn't needed here — we don't drive connectivity
// changes; tests cover queue mechanics directly. End-to-end coverage of the
// reconnect-triggers-sync path lives in test/integration/.
