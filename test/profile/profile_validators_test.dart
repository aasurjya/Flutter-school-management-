import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/features/profile/presentation/screens/validators.dart';

void main() {
  group('validateFullName', () {
    test('test_validateFullName_empty_returnsRequiredError', () {
      expect(validateFullName(''), isNotNull);
      expect(validateFullName(null), isNotNull);
    });

    test('test_validateFullName_oneChar_returnsTooShortError', () {
      final result = validateFullName('A');
      expect(result, isNotNull);
    });

    test('test_validateFullName_eightyOneChars_returnsTooLongError', () {
      final result = validateFullName('A' * 81);
      expect(result, isNotNull);
    });

    test('test_validateFullName_valid_twoChars_returnsNull', () {
      expect(validateFullName('Jo'), isNull);
    });

    test('test_validateFullName_valid_normalName_returnsNull', () {
      expect(validateFullName('John Doe'), isNull);
    });

    test('test_validateFullName_valid_eightyChars_returnsNull', () {
      expect(validateFullName('A' * 80), isNull);
    });
  });

  group('validatePhone', () {
    test('test_validatePhone_null_returnsNull', () {
      expect(validatePhone(null), isNull);
    });

    test('test_validatePhone_empty_returnsNull', () {
      expect(validatePhone(''), isNull);
    });

    test('test_validatePhone_letters_returnsError', () {
      expect(validatePhone('abc'), isNotNull);
    });

    test('test_validatePhone_tenDigits_returnsNull', () {
      expect(validatePhone('1234567890'), isNull);
    });

    test('test_validatePhone_withPlusPrefix_returnsNull', () {
      expect(validatePhone('+911234567890'), isNull);
    });

    test('test_validatePhone_withSpaces_returnsNullAfterTrim', () {
      expect(validatePhone('+91 98765 43210'), isNull);
    });

    test('test_validatePhone_nineDigits_returnsError', () {
      expect(validatePhone('123456789'), isNotNull);
    });

    test('test_validatePhone_sixteenDigits_returnsError', () {
      expect(validatePhone('1' * 16), isNotNull);
    });
  });
}
