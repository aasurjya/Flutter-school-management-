import 'dart:math';

/// Generates secure credentials for admin-created users.
class CredentialGenerator {
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _special = '@#\$!';
  static const _all = _upper + _lower + _digits + _special;

  /// Generates a secure random password.
  /// Guarantees at least 1 uppercase, 1 lowercase, 1 digit, 1 special char.
  static String generatePassword({int length = 10}) {
    assert(length >= 8, 'Password length must be at least 8');
    final rng = Random.secure();
    final required = [
      _upper[rng.nextInt(_upper.length)],
      _lower[rng.nextInt(_lower.length)],
      _digits[rng.nextInt(_digits.length)],
      _special[rng.nextInt(_special.length)],
    ];
    final rest = List.generate(
      length - required.length,
      (_) => _all[rng.nextInt(_all.length)],
    );
    final chars = [...required, ...rest]..shuffle(rng);
    return chars.join();
  }

  /// Derives an email-format username from name + tenant slug.
  /// Example: firstName=John, lastName=Smith, slug=greenview → john.smith@greenview.edu
  static String generateUsername({
    required String firstName,
    required String lastName,
    required String tenantSlug,
  }) {
    final first =
        firstName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final last =
        lastName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final slug = tenantSlug
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    return '$first.$last@$slug.edu';
  }

  /// Generates a unique username with a numeric suffix if needed.
  static String generateUsernameWithSuffix({
    required String firstName,
    required String lastName,
    required String tenantSlug,
    int suffix = 0,
  }) {
    final base = generateUsername(
      firstName: firstName,
      lastName: lastName,
      tenantSlug: tenantSlug,
    );
    if (suffix == 0) return base;
    final parts = base.split('@');
    return '${parts[0]}$suffix@${parts[1]}';
  }
}
