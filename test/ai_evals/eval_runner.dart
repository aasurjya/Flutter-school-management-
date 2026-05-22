/// AI evaluation harness — runs fixture-driven assertions on prompt output.
///
/// See `test/ai_evals/README.md` for fixture format + assertion kinds.
library;

import 'dart:convert';
import 'dart:io';

class EvalFixture {
  final String path;
  final String featureType;
  final Map<String, dynamic> input;
  final List<EvalAssertion> assertions;
  final String? notes;
  final String? expectedOutput;

  EvalFixture._({
    required this.path,
    required this.featureType,
    required this.input,
    required this.assertions,
    required this.notes,
    required this.expectedOutput,
  });

  static EvalFixture load(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final assertions = (json['assertions'] as List? ?? [])
        .map((a) => EvalAssertion._fromJson(a as Map<String, dynamic>))
        .toList(growable: false);
    final expected = File('${file.parent.path}/'
            '${file.uri.pathSegments.last.replaceFirst('.json', '_expected.txt')}')
        .existsSync()
        ? File('${file.parent.path}/'
                '${file.uri.pathSegments.last.replaceFirst('.json', '_expected.txt')}')
            .readAsStringSync()
        : null;
    return EvalFixture._(
      path: file.path,
      featureType: json['feature_type'] as String,
      input: (json['input'] as Map?)?.cast<String, dynamic>() ?? {},
      assertions: assertions,
      notes: json['notes'] as String?,
      expectedOutput: expected,
    );
  }
}

class EvalResult {
  final EvalFixture fixture;
  final String output;
  final List<EvalFailure> failures;

  EvalResult(this.fixture, this.output, this.failures);

  bool get passed => failures.isEmpty;
}

class EvalFailure {
  final String message;
  EvalFailure(this.message);
  @override
  String toString() => message;
}

/// Backend that produces text for a given fixture input. Implementations:
///   • [ReplayBackend]   — reads `*_expected.txt` (default, offline).
///   • [LiveGatewayBackend] — calls the deployed ai-gateway (CI nightly).
abstract class EvalBackend {
  Future<String> complete(EvalFixture fixture);
}

class ReplayBackend implements EvalBackend {
  @override
  Future<String> complete(EvalFixture fixture) async {
    if (fixture.expectedOutput == null) {
      throw StateError(
        'ReplayBackend requires `<fixture>_expected.txt` next to '
        '${fixture.path}. Either supply one or run with AI_EVAL_LIVE=1.',
      );
    }
    return fixture.expectedOutput!;
  }
}

/// Runs all assertions for [fixture] against [output] and returns the
/// failure list (empty == pass).
List<EvalFailure> check(EvalFixture fixture, String output) {
  final failures = <EvalFailure>[];
  final lower = output.toLowerCase();
  for (final a in fixture.assertions) {
    final f = a.check(output, lower);
    if (f != null) failures.add(f);
  }
  return failures;
}

abstract class EvalAssertion {
  EvalFailure? check(String output, String outputLower);

  static EvalAssertion _fromJson(Map<String, dynamic> j) {
    final kind = j['kind'] as String;
    final v = j['value'];
    switch (kind) {
      case 'contains_phrase':
        return _ContainsPhrase(v as String);
      case 'not_contains_phrase':
        return _NotContainsPhrase(v as String);
      case 'max_words':
        return _WordCount(max: (v as num).toInt());
      case 'min_words':
        return _WordCount(min: (v as num).toInt());
      case 'mentions_number_within':
        return _MentionsNumberWithin(
          target: (v as num).toInt(),
          tolerance: (j['tolerance'] as num?)?.toInt() ?? 0,
        );
      case 'matches_regex':
        return _MatchesRegex(RegExp(v as String));
      default:
        throw ArgumentError('Unknown assertion kind: $kind');
    }
  }
}

class _ContainsPhrase implements EvalAssertion {
  final String phrase;
  _ContainsPhrase(this.phrase);
  @override
  EvalFailure? check(String output, String outputLower) {
    if (outputLower.contains(phrase.toLowerCase())) return null;
    return EvalFailure('expected output to contain "$phrase"');
  }
}

class _NotContainsPhrase implements EvalAssertion {
  final String phrase;
  _NotContainsPhrase(this.phrase);
  @override
  EvalFailure? check(String output, String outputLower) {
    if (!outputLower.contains(phrase.toLowerCase())) return null;
    return EvalFailure(
      'expected output to NOT contain "$phrase" — it did',
    );
  }
}

class _WordCount implements EvalAssertion {
  final int? min;
  final int? max;
  _WordCount({this.min, this.max});
  @override
  EvalFailure? check(String output, String outputLower) {
    final n = output
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;
    if (min != null && n < min!) {
      return EvalFailure('word count $n < min $min');
    }
    if (max != null && n > max!) {
      return EvalFailure('word count $n > max $max');
    }
    return null;
  }
}

class _MentionsNumberWithin implements EvalAssertion {
  final int target;
  final int tolerance;
  _MentionsNumberWithin({required this.target, required this.tolerance});
  @override
  EvalFailure? check(String output, String outputLower) {
    final found = RegExp(r'\d+')
        .allMatches(output)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (found.any((n) => (n - target).abs() <= tolerance)) return null;
    return EvalFailure(
      'expected a number near $target (±$tolerance) — none of $found qualified',
    );
  }
}

class _MatchesRegex implements EvalAssertion {
  final RegExp pattern;
  _MatchesRegex(this.pattern);
  @override
  EvalFailure? check(String output, String outputLower) {
    if (pattern.hasMatch(output)) return null;
    return EvalFailure('expected output to match ${pattern.pattern}');
  }
}
