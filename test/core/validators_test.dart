import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/utils/validators.dart';

void main() {
  group('Validators.isValidEmail', () {
    test('accepts standard addresses', () {
      expect(Validators.isValidEmail('teacher@school.com'), isTrue);
      expect(Validators.isValidEmail('a.b-c@sub.domain.co.in'), isTrue);
    });

    test('accepts TLDs longer than 4 chars (regression for the {2,4} bug)', () {
      // The old regex used `{2,4}` and wrongly rejected these valid addresses.
      expect(Validators.isValidEmail('head@my.education'), isTrue);
      expect(Validators.isValidEmail('parent@campus.online'), isTrue);
      expect(Validators.isValidEmail('x@y.technology'), isTrue);
    });

    test('trims surrounding whitespace', () {
      expect(Validators.isValidEmail('  teacher@school.com  '), isTrue);
    });

    test('rejects null, empty, and malformed addresses', () {
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('   '), isFalse);
      expect(Validators.isValidEmail('not-an-email'), isFalse);
      expect(Validators.isValidEmail('missing@domain'), isFalse);
      expect(Validators.isValidEmail('@nodomain.com'), isFalse);
      expect(Validators.isValidEmail('spaces in@email.com'), isFalse);
    });
  });
}
