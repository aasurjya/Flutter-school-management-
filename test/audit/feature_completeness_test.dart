/// Static audit: Feature completeness check.
///
/// Verifies that key features have screens, providers, and repositories.
/// Flags stub features (data layer exists, no UI).
///
/// Run: flutter test test/audit/feature_completeness_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AUDIT: features with repositories but no screens', () {
    final stubs = <String>[];

    // Known stub features: repository exists, zero or minimal screens
    final featureChecks = <String, _FeatureCheck>{
      'Assignments': _FeatureCheck(
        repository: 'lib/data/repositories/assignment_repository.dart',
        screenDir: 'lib/features/assignments/presentation/screens',
        expectedScreens: 1,
      ),
      'Timetable': _FeatureCheck(
        repository: 'lib/data/repositories/timetable_repository.dart',
        screenDir: 'lib/features/timetable/presentation/screens',
        expectedScreens: 1,
      ),
      'Announcements': _FeatureCheck(
        repository: 'lib/data/repositories/announcement_repository.dart',
        screenDir: 'lib/features/announcements/presentation/screens',
        expectedScreens: 1,
      ),
    };

    for (final entry in featureChecks.entries) {
      final check = entry.value;
      final hasRepo = File(check.repository).existsSync();
      final screenDir = Directory(check.screenDir);
      final hasScreens = screenDir.existsSync();
      final screenCount = hasScreens
          ? screenDir
              .listSync()
              .where((f) => f.path.endsWith('.dart'))
              .length
          : 0;

      if (hasRepo && screenCount < check.expectedScreens) {
        stubs.add(
          '${entry.key}: repository EXISTS, '
          'screens: $screenCount (expected >= ${check.expectedScreens})',
        );
      }
    }

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      FEATURE COMPLETENESS AUDIT                 ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');

    if (stubs.isEmpty) {
      // ignore: avoid_print
      print('║  All checked features have screens.              ║');
    } else {
      // ignore: avoid_print
      print('║  STUB FEATURES (data layer, no UI):              ║');
      for (final s in stubs) {
        // ignore: avoid_print
        print('║    - $s');
      }
    }

    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');
  });

  test('AUDIT: repositories missing delete operations', () {
    final missing = <String>[];

    final reposToCheck = {
      'Exam': 'lib/data/repositories/exam_repository.dart',
      'Fee': 'lib/data/repositories/fee_repository.dart',
      'Health': 'lib/data/repositories/health_repository.dart',
    };

    for (final entry in reposToCheck.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) continue;

      final content = file.readAsStringSync();
      final hasDelete = content.contains('delete') ||
          content.contains('remove') ||
          content.contains('Delete');

      if (!hasDelete) {
        missing.add('${entry.key}: no delete/remove method in ${entry.value}');
      }
    }

    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      MISSING CRUD OPERATIONS AUDIT              ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');

    if (missing.isEmpty) {
      // ignore: avoid_print
      print('║  All checked repos have delete operations.       ║');
    } else {
      for (final m in missing) {
        // ignore: avoid_print
        print('║  MISSING: $m');
      }
    }

    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');
  });

  test('AUDIT: real-time subscriptions defined but unused', () {
    final unusedSubscriptions = <String>[];

    // Repos that define subscribe methods
    final reposWithSubscriptions = [
      'lib/data/repositories/attendance_repository.dart',
      'lib/data/repositories/assignment_repository.dart',
      'lib/data/repositories/announcement_repository.dart',
      'lib/data/repositories/message_repository.dart',
      'lib/data/repositories/notification_repository.dart',
    ];

    for (final repoPath in reposWithSubscriptions) {
      final file = File(repoPath);
      if (!file.existsSync()) continue;

      final content = file.readAsStringSync();
      if (content.contains('subscribeTo') || content.contains('subscribe')) {
        // Check if any provider or screen calls this method
        final methodMatch =
            RegExp(r'(subscribeTo\w+)').firstMatch(content);
        if (methodMatch != null) {
          final methodName = methodMatch.group(1)!;

          // Search for usage in providers/ and screens/
          final isUsed = _isMethodUsedInDir(methodName, 'lib/features') ||
              _isMethodUsedInDir(methodName, 'lib/core');

          if (!isUsed) {
            unusedSubscriptions.add('$repoPath: $methodName() — NEVER CALLED');
          }
        }
      }
    }

    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      UNUSED REAL-TIME SUBSCRIPTIONS             ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');

    if (unusedSubscriptions.isEmpty) {
      // ignore: avoid_print
      print('║  All subscriptions are wired to UI.              ║');
    } else {
      for (final s in unusedSubscriptions) {
        // ignore: avoid_print
        print('║  $s');
      }
    }

    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');
  });

  test('AUDIT: missing pagination on list screens', () {
    final noPagination = <String>[];
    final libDir = Directory('lib/features');
    if (!libDir.existsSync()) return;

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (!file.path.contains('screen')) continue;

      final content = file.readAsStringSync();
      // Screen has a ListView but no pagination indicator
      if (content.contains('ListView') &&
          !content.contains('pagination') &&
          !content.contains('loadMore') &&
          !content.contains('nextPage') &&
          !content.contains('PagedListView') &&
          !content.contains('ScrollController')) {
        noPagination.add(file.path);
      }
    }

    // ignore: avoid_print
    print('╔══════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║      MISSING PAGINATION AUDIT                   ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════════════╣');
    // ignore: avoid_print
    print('║  Screens with ListView but no pagination: '
        '${noPagination.length.toString().padLeft(3)}    ║');
    // ignore: avoid_print
    print('╚══════════════════════════════════════════════════╝');
    // ignore: avoid_print
    print('');

    for (final f in noPagination) {
      // ignore: avoid_print
      print('  $f');
    }
    // ignore: avoid_print
    print('');
  });
}

class _FeatureCheck {
  final String repository;
  final String screenDir;
  final int expectedScreens;

  const _FeatureCheck({
    required this.repository,
    required this.screenDir,
    required this.expectedScreens,
  });
}

bool _isMethodUsedInDir(String methodName, String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return false;

  for (final file in dir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    // Skip the repository file itself
    if (file.path.contains('repository')) continue;

    final content = file.readAsStringSync();
    if (content.contains(methodName)) return true;
  }
  return false;
}
