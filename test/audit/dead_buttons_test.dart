/// Static audit: Dead button detection.
///
/// Greps the lib/ directory for empty `onPressed: () {}` and `onTap: () {}`
/// handlers. Reports file:line for each occurrence.
///
/// Run: flutter test test/audit/dead_buttons_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AUDIT: find all dead onPressed/onTap handlers in lib/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

    final deadButtons = <String>[];

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        // Match patterns like: onPressed: () {}, onTap: () {}
        if (_isEmptyHandler(line)) {
          final relativePath =
              file.path.replaceFirst(RegExp(r'^lib/'), 'lib/');
          deadButtons.add('$relativePath:${i + 1}  $line');
        }
      }
    }

    // Print report
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║         DEAD BUTTON AUDIT REPORT                ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');
    // ignore: avoid_print
    print('║  Total dead handlers: ${deadButtons.length.toString().padLeft(3)} '
        '                       ║');
    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');

    // Group by file
    final byFile = <String, List<String>>{};
    for (final entry in deadButtons) {
      final file = entry.split(':').first;
      byFile.putIfAbsent(file, () => []).add(entry);
    }

    for (final entry in byFile.entries) {
      // ignore: avoid_print
      print('${entry.key} (${entry.value.length} dead handlers):');
      for (final line in entry.value) {
        // ignore: avoid_print
        print('  $line');
      }
      // ignore: avoid_print
      print('');
    }

    // This is an audit — we expect known dead buttons.
    // Uncomment to enforce zero dead buttons:
    // expect(deadButtons, isEmpty, reason: 'No dead handlers allowed');
  });
}

/// Heuristic to detect empty callback handlers.
///
/// Matches common patterns:
///   onPressed: () {}
///   onPressed: () { }
///   onTap: () {}
///   onTap: () { }
bool _isEmptyHandler(String line) {
  // Match onPressed/onTap followed by empty closure
  final patterns = [
    RegExp(r'onPressed:\s*\(\)\s*\{\s*\}'),
    RegExp(r'onTap:\s*\(\)\s*\{\s*\}'),
    RegExp(r'onPressed:\s*\(\)\s*=>\s*null'),
    RegExp(r'onTap:\s*\(\)\s*=>\s*null'),
  ];

  return patterns.any((p) => p.hasMatch(line));
}
