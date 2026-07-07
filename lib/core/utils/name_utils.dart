/// Shared name-formatting helpers used across dashboard/profile greetings.
///
/// Centralised because `fullName.split(' ').first` was copied into 8+
/// screens. Any user whose name starts with an honorific ("Dr. Jane Doe")
/// broke every one of them: the greeting rendered "Welcome back, Dr.."
/// instead of "Welcome back, Jane." since the "first token" was the title.
library;

class NameUtils {
  NameUtils._();

  static const Set<String> _honorifics = {
    'dr', 'mr', 'mrs', 'ms', 'miss', 'prof', 'fr', 'sr', 'rev', 'capt',
  };

  /// The first "real" name token in [fullName], skipping a leading
  /// honorific (e.g. "Dr. Principal Smith" -> "Principal", not "Dr.").
  ///
  /// Falls back to [fallback] when [fullName] is null/empty/blank.
  static String firstNameOf(String? fullName, {required String fallback}) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;

    final tokens = trimmed.split(RegExp(r'\s+'));
    if (tokens.length == 1) return tokens.first;

    final firstToken = tokens.first.toLowerCase().replaceAll('.', '');
    if (_honorifics.contains(firstToken)) {
      return tokens[1];
    }
    return tokens.first;
  }
}
