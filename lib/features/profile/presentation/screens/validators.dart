// Validators extracted for testability — import in edit_profile_screen.dart.

/// Validates [value] as a full name: required, 2–80 characters.
/// Returns an error string on failure, null on success.
String? validateFullName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Full name is required.';
  }
  final trimmed = value.trim();
  if (trimmed.length < 2) {
    return 'Full name must be at least 2 characters.';
  }
  if (trimmed.length > 80) {
    return 'Full name must be 80 characters or fewer.';
  }
  return null;
}

/// Validates [value] as a phone number.
/// Empty / null is allowed (field is optional).
/// If non-empty: must be 10–15 digits, with an optional leading `+`.
/// Spaces within the value are stripped before length validation.
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final digits = value.trim().replaceAll(' ', '');
  final phoneRegex = RegExp(r'^\+?\d{10,15}$');
  if (!phoneRegex.hasMatch(digits)) {
    return 'Enter a valid phone number (10–15 digits, optional leading +).';
  }
  return null;
}
