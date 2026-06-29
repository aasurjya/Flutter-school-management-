/// Shared input validators used across forms.
///
/// Centralised so a single rule can't drift between screens. The auth-flow
/// audit found three copies of the email regex, two of which used a stale
/// `{2,4}` TLD bound that wrongly rejected valid addresses such as
/// `name@school.online` or `head@my.education`.
library;

class Validators {
  Validators._();

  /// Accepts any TLD of 2+ characters (e.g. `.io`, `.online`, `.education`).
  ///
  /// Intentionally permissive — the authoritative check is the confirmation
  /// email, not this client-side regex. The goal here is only to catch
  /// obvious typos before a network round-trip.
  static final RegExp _emailRegExp =
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// True when [value] looks like a syntactically valid email address.
  ///
  /// Trims surrounding whitespace and treats null/empty as invalid.
  static bool isValidEmail(String? value) {
    if (value == null) return false;
    final email = value.trim();
    if (email.isEmpty) return false;
    return _emailRegExp.hasMatch(email);
  }
}
