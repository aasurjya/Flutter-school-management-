/// `flutter test`-runnable wrapper around [eval_runner.dart].
///
/// Gated: skips itself unless `AI_EVAL=1` is set. Run it explicitly:
///
///     AI_EVAL=1 flutter test test/ai_evals/
///
/// CI runs this in a nightly job, not on every PR.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'eval_runner.dart';

const _gate = String.fromEnvironment('AI_EVAL', defaultValue: '');
const _live = String.fromEnvironment('AI_EVAL_LIVE', defaultValue: '');

void main() {
  final enabled = _gate == '1' ||
      Platform.environment['AI_EVAL'] == '1';
  if (!enabled) {
    test('AI evals (gated — set AI_EVAL=1 to enable)', () {
      // Intentionally empty — the absence of `markTestSkipped` keeps the
      // overall test summary friendly. CI should run the nightly job.
    }, skip: 'set AI_EVAL=1 to run');
    return;
  }

  final fixturesRoot = Directory('test/ai_evals/fixtures');
  if (!fixturesRoot.existsSync()) {
    test('fixtures dir missing', () => fail('test/ai_evals/fixtures/'));
    return;
  }

  final backend = (_live == '1' || Platform.environment['AI_EVAL_LIVE'] == '1')
      ? throw UnimplementedError(
          'LiveGatewayBackend not implemented yet — '
          'wire to AiGatewayClient when streaming lands (P1.7).',
        )
      : ReplayBackend();

  for (final dir in fixturesRoot.listSync().whereType<Directory>()) {
    final feature = dir.path.split(Platform.pathSeparator).last;
    group(feature, () {
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.json')) continue;
        final fixture = EvalFixture.load(f);
        test(f.uri.pathSegments.last, () async {
          final output = await backend.complete(fixture);
          final failures = check(fixture, output);
          if (failures.isEmpty) return;
          fail(
            'eval failed for ${fixture.path}\n'
            '${failures.map((e) => '  • $e').join('\n')}\n'
            'output:\n$output\n'
            '${fixture.notes == null ? '' : 'note: ${fixture.notes}'}',
          );
        });
      }
    });
  }
}
