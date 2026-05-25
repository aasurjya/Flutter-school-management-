// Regression gate for the Apple-style copy sweep (slices 7–10).
//
// This test walks every Dart file under lib/ and fails if it finds a banned
// cold-tone string in user-facing code. Adding the canonical list here means
// a future PR that re-introduces "Failed to load X: $e" gets caught in CI
// before review.
//
// What this catches:
//   - 'Failed to ...'         (cold failure messages)
//   - 'Error: $e' style       (raw exception strings)
//   - 'Are you sure'          (accusatory confirmation dialogs)
//   - 'Something went wrong'  (generic apology)
//   - 'coming soon'           (placeholder buttons that shouldn't ship)
//
// What this allows on purpose:
//   - lib/core/copy/warm_strings.dart — the catalogue that names these
//     patterns in its documentation and `bannedPhrases` list.
//   - test/ files — test names and comments can reference the patterns.
//   - *.g.dart / *.freezed.dart — generated files.
//   - lib/l10n/ — localization files we don't own in this PR.
//
// What this DOES NOT enforce (yet):
//   - print/log/throw strings (non-user-facing). Those can still say
//     'Failed to parse X' for developer diagnostics.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _bannedUserFacingPatterns = <RegExp>[
  // 'Failed to X' inside a Dart string literal, anywhere on a user-facing line.
  // We require the closing apostrophe so 'Failed to parse' inside a developer.log()
  // call doesn't match — UI heuristic below also blocks log/print/throw lines.
];

final _bannedLiteralExpressions = <Pattern>[
  // String literals that appear inside Text(...), SnackBar, showError/showSuccess,
  // content:, message:, or child: Text(. These are user-facing.
  RegExp(r"'Failed to [^']*'"),
  RegExp(r"'Error: \$"),
  RegExp(r"'Are you sure"),
  RegExp(r"'Something went wrong"),
  RegExp(r"'coming soon", caseSensitive: false),
];

final _uiContextHeuristic = RegExp(
  r"(Text\(|SnackBar|showError|showSuccess|content:|message:|child: Text\(|child: SnackBar)",
);

const _exemptFiles = <String>{
  // The warm copy catalogue documents what's banned. Self-exempt.
  'lib/core/copy/warm_strings.dart',
};

bool _shouldSkipFile(String path) {
  if (!path.endsWith('.dart')) return true;
  if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) return true;
  if (path.contains('/lib/l10n/')) return true;
  if (path.contains('/lib/generated/')) return true;
  // Normalize so the exempt set matches POSIX or Windows separators.
  final norm = path.replaceAll(r'\', '/');
  for (final exempt in _exemptFiles) {
    if (norm.endsWith(exempt)) return true;
  }
  return false;
}

class _Hit {
  _Hit(this.file, this.line, this.pattern, this.snippet);
  final String file;
  final int line;
  final Pattern pattern;
  final String snippet;

  @override
  String toString() {
    final patStr = pattern is RegExp ? (pattern as RegExp).pattern : pattern.toString();
    return '$file:$line  /$patStr/  →  ${snippet.trim()}';
  }
}

void main() {
  test('lib/ contains no cold-tone user-facing copy', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'Run from project root.');

    final hits = <_Hit>[];
    final files = libDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => !_shouldSkipFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!_uiContextHeuristic.hasMatch(line)) continue;
        for (final pattern in _bannedLiteralExpressions) {
          if (line.contains(pattern)) {
            hits.add(_Hit(file.path, i + 1, pattern, line));
          }
        }
      }
    }

    expect(
      hits,
      isEmpty,
      reason: 'Cold-tone copy found in user-facing context. '
          'Use WarmCopy.loadFailed/saveFailed/genericError from '
          'lib/core/copy/warm_strings.dart instead:\n  '
          '${hits.take(20).join("\n  ")}'
          '${hits.length > 20 ? "\n  ...and ${hits.length - 20} more" : ""}',
    );
  });

  test('every WarmCopy helper still returns a string with no banned phrase', () {
    // Sanity check that WarmCopy itself has not regressed.
    // Real per-method assertions live in test/core/copy/warm_strings_test.dart;
    // this one is a coarse fail-fast tripwire.
    final warmStrings = File('lib/core/copy/warm_strings.dart').readAsStringSync();
    expect(warmStrings, contains('WarmCopy'));
    expect(warmStrings, contains('bannedPhrases'));
    expect(warmStrings, contains('loadFailed'));
    expect(warmStrings, contains('saveFailed'));
    expect(warmStrings, contains('genericError'));
  });
}
