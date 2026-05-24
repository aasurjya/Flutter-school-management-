import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/copy/warm_strings.dart';

void main() {
  group('WarmCopy', () {
    test('exposes non-empty constants', () {
      expect(WarmCopy.genericError, isNotEmpty);
      expect(WarmCopy.genericEmpty, isNotEmpty);
      expect(WarmCopy.savedShort, isNotEmpty);
      expect(WarmCopy.discardChangesTitle, isNotEmpty);
      expect(WarmCopy.signOutTitle, isNotEmpty);
      expect(WarmCopy.undoAction, equals('Undo'));
    });

    test('helper builders produce non-empty domain-specific copy', () {
      expect(WarmCopy.emptyList('students'), 'No students yet.');
      expect(WarmCopy.loadFailed('invoices'), "Couldn't load invoices.");
      expect(WarmCopy.saveFailed('attendance'), "Couldn't save attendance.");
      expect(
        WarmCopy.savedOffline('Attendance'),
        'Attendance saved locally — will sync when online.',
      );
      expect(WarmCopy.deleteTitle('this announcement'), 'Delete this announcement?');
      expect(WarmCopy.availableSoon('PDF export'),
          'PDF export is coming with the next school term.');
      expect(WarmCopy.dueOn('15 June'), 'Due by 15 June.');
      expect(WarmCopy.dueIn(1), 'Due tomorrow.');
      expect(WarmCopy.dueIn(7), 'Due in 7 days.');
      expect(WarmCopy.dueWasOn('1 June'), 'Was due 1 June.');
    });

    test('undo banner names the saved noun explicitly', () {
      expect(WarmCopy.undoBanner('Attendance'), 'Attendance saved.');
      expect(WarmCopy.undoBanner('Marks'), 'Marks saved.');
    });

    test('no value returned by WarmCopy contains a banned phrase', () {
      // Aggregate every user-facing value into one list and assert the
      // tone gate. New strings get added here when the API grows.
      final List<String> userFacingValues = <String>[
        WarmCopy.genericError,
        WarmCopy.genericEmpty,
        WarmCopy.loadingShort,
        WarmCopy.savingShort,
        WarmCopy.savedShort,
        WarmCopy.emptyList('students'),
        WarmCopy.emptyList('records'),
        WarmCopy.loadFailed('classes'),
        WarmCopy.saveFailed('attendance'),
        WarmCopy.savedOffline('Marks'),
        WarmCopy.discardChangesTitle,
        WarmCopy.discardChangesConfirm,
        WarmCopy.discardChangesCancel,
        WarmCopy.undoBanner('Attendance'),
        WarmCopy.undoAction,
        WarmCopy.signOutTitle,
        WarmCopy.signOutConfirm,
        WarmCopy.signOutCancel,
        WarmCopy.deleteTitle('this fee head'),
        WarmCopy.deleteHint('this fee head'),
        WarmCopy.deleteConfirm,
        WarmCopy.deleteCancel,
        WarmCopy.availableSoon('Bulk import'),
        WarmCopy.dueOn('15 June'),
        WarmCopy.dueIn(3),
        WarmCopy.dueWasOn('1 June'),
      ];

      for (final value in userFacingValues) {
        for (final banned in WarmCopy.bannedPhrases) {
          expect(
            value.toLowerCase().contains(banned.toLowerCase()),
            isFalse,
            reason:
                'WarmCopy value "$value" contains banned phrase "$banned". '
                'Either rewrite the value or revisit whether that phrase should be banned.',
          );
        }
      }
    });

    test('bannedPhrases catalogue stays in sync', () {
      // If a banned phrase is added, this test is the canary that nothing
      // already in the catalogue trips over it. Add new bans here and
      // ensure the test above still passes.
      expect(WarmCopy.bannedPhrases, contains('Failed to'));
      expect(WarmCopy.bannedPhrases, contains('Error:'));
      expect(WarmCopy.bannedPhrases, contains('Are you sure'));
      expect(WarmCopy.bannedPhrases, contains('coming soon'));
      expect(WarmCopy.bannedPhrases, contains('overdue'));
    });
  });
}
