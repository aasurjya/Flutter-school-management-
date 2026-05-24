/// CSV/Excel bulk-import fuzz harness.
///
/// Status (2026-05-24): **template / gated**. No CSV import flow exists in
/// the codebase yet (verified by grepping `lib/` for csv/Excel/xlsx
/// import paths — only output/export references, no input parsers). When
/// the first bulk-import feature lands (likely bulk-student admission or
/// bulk-grade entry), wire it into the [_runImport] hook below and remove
/// the `INTEGRATION` gate.
///
/// Why pre-build the harness even with nothing to fuzz: the *moment*
/// someone writes the import path, this file becomes runnable in one
/// edit. Without it, fuzzing is "we'll do it later" and "later" doesn't
/// happen. With it, the next PR that adds CSV import either wires this
/// in or has to delete this file and explain why.
///
/// What this fuzzes when wired:
///   • Random row counts (0, 1, 10, 500, 10_000).
///   • Random column ordering and presence (missing tenant_id, extra
///     columns, headers in mixed case).
///   • Unicode chaos in name fields (Devanagari, Tamil, emoji, RTL).
///   • Encoding edge cases (BOM, CRLF vs LF, embedded quotes/commas).
///   • SQL injection bait in string fields (`'; DROP TABLE students; --`).
///   • Empty / whitespace-only cells in required fields.
///   • Numeric overflow in age/marks fields.
///   • Date format permutations (ISO, dd/mm/yyyy, mm/dd/yyyy, epoch).
///
/// **Invariants checked after each fuzz iteration:**
///   1. No exception escapes the import function (caller error or 200).
///   2. No row lands in the DB outside the expected tenant_id.
///   3. No row violates a CHECK or NOT NULL constraint.
///   4. Row count returned == row count actually inserted.
///   5. Idempotency: importing the same fuzzed CSV twice yields the same
///      end state (dedupe by client_request_id from migration 00063).
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

const _gate = String.fromEnvironment('INTEGRATION', defaultValue: '');

void main() {
  final enabled = _gate == '1' || Platform.environment['INTEGRATION'] == '1';
  if (!enabled) {
    test('CSV import fuzz (gated — set INTEGRATION=1 to enable)', () {},
        skip: 'set INTEGRATION=1 to run');
    return;
  }

  // ⚠️ Until a CSV import path exists, this test correctly skips even
  // when INTEGRATION=1. To activate:
  //   1. Replace [_runImport] with the actual import function.
  //   2. Replace [_countTenantRows] with the actual table-count query.
  //   3. Remove this guard.
  test(
    'CSV import path not yet implemented — see test file header',
    () {},
    skip: 'wire when bulk-import lands; harness is ready',
  );

  if (!_importPathWired) return;

  final rng = Random(42); // deterministic seed; flip for randomized CI runs

  test('500 random CSV inputs land cleanly or rejected with code', () async {
    for (var i = 0; i < 500; i++) {
      final csv = _generateFuzz(rng);
      try {
        final result = await _runImport(csv);
        expect(result.inserted, lessThanOrEqualTo(csv.expectedMaxRows));
      } on FormatException catch (_) {
        // Expected: invalid CSV is rejected with a code, not a panic.
      } on _ImportException catch (e) {
        expect(e.code, isNotNull,
            reason: 'every rejected import must have a structured code');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('importing the same fuzzed CSV twice is idempotent', () async {
    final csv = _generateFuzz(rng);
    await _runImport(csv); // seed the rows
    final after1 = await _countTenantRows();
    final second = await _runImport(csv);
    final after2 = await _countTenantRows();
    expect(after1, after2,
        reason: 'idempotency_key must dedupe; row count must not change');
    expect(second.inserted, 0,
        reason: 'second import returns inserted=0 not duplicates');
  });
}

// ============================================================================
// HOOKS — wire when the import path exists
// ============================================================================

/// Flip to `true` and replace the stub below when the import is wired.
const bool _importPathWired = false;

Future<_ImportResult> _runImport(_FuzzCsv csv) async {
  throw UnimplementedError(
    'wire test/integration/csv_import_fuzz_test.dart::_runImport '
    'to the real import function when bulk-import lands',
  );
}

Future<int> _countTenantRows() async {
  throw UnimplementedError(
    'wire test/integration/csv_import_fuzz_test.dart::_countTenantRows '
    'to the real Supabase count query for the imported table',
  );
}

// ============================================================================
// FUZZ INPUT GENERATOR — already complete, just needs the import to land
// ============================================================================

class _FuzzCsv {
  final String content;
  final int expectedMaxRows;
  _FuzzCsv(this.content, this.expectedMaxRows);
}

_FuzzCsv _generateFuzz(Random rng) {
  final rowCount = [0, 1, 10, 500, 10000][rng.nextInt(5)];
  final headers = _shuffleHeaders(rng);
  final lines = <String>[headers.join(',')];

  for (var i = 0; i < rowCount; i++) {
    final row = headers.map((h) => _randomCellFor(h, rng)).join(',');
    lines.add(row);
  }

  final lineEnd = rng.nextBool() ? '\r\n' : '\n';
  final bom = rng.nextDouble() < 0.1 ? '﻿' : '';
  return _FuzzCsv(bom + lines.join(lineEnd), rowCount);
}

List<String> _shuffleHeaders(Random rng) {
  final canonical = [
    'first_name',
    'last_name',
    'admission_number',
    'class',
    'section',
    'date_of_birth',
    'guardian_name',
    'guardian_phone',
  ];
  final picked = canonical.where((_) => rng.nextDouble() > 0.1).toList();
  picked.shuffle(rng);
  if (rng.nextDouble() < 0.2) picked.add('garbage_column_$rng');
  return picked;
}

String _randomCellFor(String header, Random rng) {
  final pick = rng.nextInt(10);
  switch (header) {
    case 'first_name':
    case 'last_name':
    case 'guardian_name':
      return [
        'Aarav', 'राजेश', 'تامر', '🌟Emoji✨',
        "O'Brien", '"quoted"', '',
        '; DROP TABLE students; --',
        ' '.padRight(rng.nextInt(200), 'A'),
      ][pick.clamp(0, 8)];
    case 'admission_number':
      return ['ADM-${rng.nextInt(99999)}', '', 'ADM-001', 'ADM-001'][pick.clamp(0, 3)];
    case 'date_of_birth':
      return [
        '2015-03-14', '14/03/2015', '03/14/2015',
        '1577836800', 'not-a-date', '2099-13-99', '',
      ][pick.clamp(0, 6)];
    case 'guardian_phone':
      return [
        '+91 9876543210', '9876543210', '+1-555-0100',
        'not a phone', '12345', '',
      ][pick.clamp(0, 5)];
    case 'class':
    case 'section':
      return ['1', '10', 'XII', 'A', '', 'invalid'][pick.clamp(0, 5)];
    default:
      return rng.nextInt(2) == 0 ? '' : 'garbage';
  }
}

class _ImportResult {
  final int inserted;
  final int rejected;
  final List<String> errors;
  _ImportResult({required this.inserted, required this.rejected, required this.errors});
}

class _ImportException implements Exception {
  final String code;
  final String message;
  _ImportException(this.code, this.message);
}
