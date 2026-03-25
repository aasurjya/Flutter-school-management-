/// Static audit: Hardcoded/mock data detection.
///
/// Greps dashboard and screen files for known mock data patterns,
/// hardcoded currency amounts, and placeholder percentages.
///
/// Run: flutter test test/audit/hardcoded_data_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AUDIT: find hardcoded/mock data in dashboard screens', () {
    final findings = <String>[];

    // Known files with hardcoded data
    final targetsAndPatterns = <String, List<RegExp>>{
      'lib/features/dashboard/presentation/screens/parent_dashboard_screen.dart':
          [
        RegExp('94%'),
        RegExp('#05'),
        RegExp('20,000'),
        RegExp('5,000'),
      ],
      'lib/features/dashboard/presentation/screens/teacher_dashboard_screen.dart':
          [
        RegExp("'04'"),
        RegExp('92%'),
        RegExp("'03'"),
      ],
      'lib/features/dashboard/presentation/screens/student_dashboard_screen.dart':
          [
        RegExp('Mathematics'),
        RegExp('Physics'),
        RegExp('Chemistry'),
        RegExp('08:30'),
      ],
    };

    for (final entry in targetsAndPatterns.entries) {
      final file = File(entry.key);
      if (!file.existsSync()) continue;

      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        for (final pattern in entry.value) {
          if (pattern.hasMatch(lines[i])) {
            findings.add(
              '${entry.key}:${i + 1}  ${lines[i].trim()}',
            );
          }
        }
      }
    }

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      HARDCODED DATA AUDIT REPORT                ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');
    // ignore: avoid_print
    print('║  Total findings: ${findings.length.toString().padLeft(3)} '
        '                           ║');
    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');

    for (final f in findings) {
      // ignore: avoid_print
      print('  $f');
    }
    // ignore: avoid_print
    print('');
  });

  test('AUDIT: find _mock prefixed variables in lib/', () {
    final libDir = Directory('lib');
    final mockFindings = <String>[];

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('_mock') || lines[i].contains('Mock')) {
          // Skip test files and imports
          if (lines[i].trimLeft().startsWith('//')) continue;
          if (lines[i].trimLeft().startsWith('import')) continue;

          mockFindings.add(
            '${file.path}:${i + 1}  ${lines[i].trim()}',
          );
        }
      }
    }

    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      MOCK DATA VARIABLES AUDIT                  ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');
    // ignore: avoid_print
    print('║  Total _mock/Mock references: ${mockFindings.length.toString().padLeft(3)} '
        '              ║');
    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');

    for (final f in mockFindings) {
      // ignore: avoid_print
      print('  $f');
    }
    // ignore: avoid_print
    print('');
  });

  test('AUDIT: find "placeholder" and "Placeholder" in lib/', () {
    final libDir = Directory('lib');
    final placeholderFindings = <String>[];

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final lower = lines[i].toLowerCase();
        if (lower.contains('placeholder') || lower.contains('todo')) {
          if (lines[i].trimLeft().startsWith('//')) {
            // Include comments too — they flag intent
            placeholderFindings.add(
              '${file.path}:${i + 1}  ${lines[i].trim()}',
            );
          }
        }
      }
    }

    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      PLACEHOLDER / TODO AUDIT                   ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');
    // ignore: avoid_print
    print('║  Total placeholder/TODO refs: ${placeholderFindings.length.toString().padLeft(3)} '
        '              ║');
    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');

    for (final f in placeholderFindings) {
      // ignore: avoid_print
      print('  $f');
    }
    // ignore: avoid_print
    print('');
  });
}
