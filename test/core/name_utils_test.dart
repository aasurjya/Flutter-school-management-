import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/utils/name_utils.dart';

void main() {
  group('NameUtils.firstNameOf', () {
    test('strips a leading honorific with a period', () {
      expect(NameUtils.firstNameOf('Dr. Jane Doe', fallback: 'there'), 'Jane');
    });

    test('strips a leading honorific without a period', () {
      expect(NameUtils.firstNameOf('Dr Jane Doe', fallback: 'there'), 'Jane');
    });

    test('leaves a plain name unchanged', () {
      expect(NameUtils.firstNameOf('Jane Doe', fallback: 'there'), 'Jane');
    });

    test('strips other common honorifics', () {
      expect(
        NameUtils.firstNameOf('Prof. Alan Turing', fallback: 'there'),
        'Alan',
      );
      expect(
        NameUtils.firstNameOf('Capt. Marvel Danvers', fallback: 'there'),
        'Marvel',
      );
    });

    test('falls back on null', () {
      expect(NameUtils.firstNameOf(null, fallback: 'there'), 'there');
    });

    test('falls back on blank/whitespace-only input', () {
      expect(NameUtils.firstNameOf('   ', fallback: 'there'), 'there');
    });

    test('returns the only token when there is just one', () {
      expect(NameUtils.firstNameOf('Madonna', fallback: 'there'), 'Madonna');
    });

    test('returns the honorific itself when it is the only token', () {
      // No second token to fall through to — documents current behavior
      // so a future refactor changes it intentionally, not by accident.
      expect(NameUtils.firstNameOf('Dr.', fallback: 'there'), 'Dr.');
    });
  });
}
