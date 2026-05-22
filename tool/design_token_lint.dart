// Design-token discipline lint.
//
// Bans:
//   - `Color(0xFF…)` literals in lib/features/** (use AppColors / theme).
//   - `fontSize:` numeric literals in lib/features/** (use Theme.of(context).textTheme).
//
// Strategy: ratchet, not big-bang. A baseline file pins the current violation
// counts. CI fails ONLY when a PR adds violations beyond the baseline. Deletes
// are tracked so the baseline auto-shrinks over time:
//   1. Run locally → if you removed violations, run with --update-baseline.
//   2. Commit baseline.
//   3. CI will then enforce the lower number on the next PR.
//
// Usage:
//   dart run tool/design_token_lint.dart                 # check against baseline
//   dart run tool/design_token_lint.dart --update-baseline
//
// Exit codes:
//   0  - within baseline
//   1  - new violations introduced
//   2  - usage / IO error

import 'dart:io';
import 'dart:convert';

const _baselinePath = 'tool/design_token_lint_baseline.json';
const _featuresRoot = 'lib/features';

const _rules = <_Rule>[
  _Rule(
    id: 'hardcoded_color',
    description: 'Color(0xFF…) literal — use AppColors / theme tokens',
    pattern: r'Color\(0x[0-9a-fA-F]{6,8}\)',
  ),
  _Rule(
    id: 'hardcoded_font_size',
    description: 'fontSize: literal — use Theme.of(context).textTheme.*',
    pattern: r'\bfontSize:\s*[0-9]+(?:\.[0-9]+)?',
  ),
];

class _Rule {
  final String id;
  final String description;
  final String pattern;
  const _Rule({
    required this.id,
    required this.description,
    required this.pattern,
  });
}

Future<void> main(List<String> args) async {
  final updateBaseline = args.contains('--update-baseline');
  final featuresDir = Directory(_featuresRoot);
  if (!featuresDir.existsSync()) {
    stderr.writeln('error: $_featuresRoot not found — run from repo root');
    exit(2);
  }

  final counts = <String, int>{for (final r in _rules) r.id: 0};
  final samples = <String, List<String>>{for (final r in _rules) r.id: []};

  await for (final entity in featuresDir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = await entity.readAsString();
    final relative = entity.path;
    for (final rule in _rules) {
      final re = RegExp(rule.pattern);
      final matches = re.allMatches(content).toList();
      counts[rule.id] = counts[rule.id]! + matches.length;
      if (samples[rule.id]!.length < 3 && matches.isNotEmpty) {
        samples[rule.id]!.add('$relative (${matches.length})');
      }
    }
  }

  if (updateBaseline) {
    final file = File(_baselinePath);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        for (final r in _rules) r.id: counts[r.id],
      }),
    );
    stdout.writeln('updated baseline → $_baselinePath');
    for (final r in _rules) {
      stdout.writeln('  ${r.id}: ${counts[r.id]}');
    }
    exit(0);
  }

  final baseline = _readBaseline();
  var failed = false;
  stdout.writeln('design-token-lint: scanning $_featuresRoot');
  for (final rule in _rules) {
    final actual = counts[rule.id]!;
    final allowed = baseline[rule.id] ?? 0;
    final delta = actual - allowed;
    if (delta > 0) {
      failed = true;
      stdout.writeln(
        'FAIL [${rule.id}] ${rule.description}\n'
        '  actual: $actual, baseline: $allowed, new: $delta\n'
        '  samples: ${samples[rule.id]!.join(', ')}',
      );
    } else if (delta < 0) {
      stdout.writeln(
        'OK   [${rule.id}] removed ${-delta} — run --update-baseline to lock',
      );
    } else {
      stdout.writeln('OK   [${rule.id}] $actual (at baseline)');
    }
  }

  if (failed) {
    stderr.writeln(
      '\nNew design-token violations introduced.\n'
      'Fix by using AppColors / Theme.of(context).textTheme instead of literals.',
    );
    exit(1);
  }
  exit(0);
}

Map<String, int> _readBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) {
    return {for (final r in _rules) r.id: 0};
  }
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {for (final r in _rules) r.id: (raw[r.id] as num?)?.toInt() ?? 0};
}
