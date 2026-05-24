/// Central catalogue of user-facing strings for the Apple-style copy sweep.
///
/// Why this exists: the audit found ~300 `'Error: $e'`, ~58 `'Failed to ...'`,
/// ~32 `'Are you sure ...'`, and ~40 `'coming soon'` strings scattered across
/// screens. Each is a tiny cold-corporate moment. Funnelling them through
/// this file gives one place to enforce the tone:
///
///   - Direct, not apologetic. ("Couldn't reach the server" not "Oops!")
///   - Specific, not generic. ("No students yet" not "No data found.")
///   - Action-oriented. ("Pull to try again" not "Please try later.")
///   - No exclamation marks. No "Whoops". No emoji.
///   - No banned phrases — see `_bannedPhrases` and the lint test.
///
/// New strings get added here; existing screens migrate one at a time.
library;

class WarmCopy {
  WarmCopy._();

  // ---------------------------------------------------------------
  // Generic states — used when the screen has no domain-specific copy
  // ---------------------------------------------------------------

  /// Default error toast/banner when a network or DB call fails.
  /// Pairs with a retry affordance the screen already provides.
  static const String genericError = "Couldn't load that. Pull to try again.";

  /// Default empty-state line. Prefer [emptyList] with a domain noun.
  static const String genericEmpty = 'Nothing here yet.';

  /// Loading is implicit — text-free skeleton or spinner. Use [loadingShort]
  /// only when you genuinely need a single label (e.g. button-in-flight).
  static const String loadingShort = 'Loading';

  /// Saving is implicit — same rule. Use only for button-in-flight.
  static const String savingShort = 'Saving';

  /// After a save succeeds — no exclamation.
  static const String savedShort = 'Saved';

  // ---------------------------------------------------------------
  // Composable empty / failure messages
  // ---------------------------------------------------------------

  /// "No students yet." / "No invoices yet." — feed the noun.
  ///
  /// Do not write "No data" — the user is on a specific screen, name what
  /// they expected to see.
  static String emptyList(String pluralNoun) => 'No $pluralNoun yet.';

  /// "Couldn't load students." — for permanent-looking failures (offline).
  ///
  /// Pairs with a retry button rendered by the screen.
  static String loadFailed(String pluralNoun) => "Couldn't load $pluralNoun.";

  /// "Couldn't save attendance." — for a save action that failed.
  ///
  /// Pairs with the action remaining available so the user can try again.
  static String saveFailed(String pluralNoun) => "Couldn't save $pluralNoun.";

  /// "Attendance saved locally — will sync when online."
  ///
  /// Use when the local repo succeeded but the network sync didn't.
  static String savedOffline(String pluralNoun) =>
      '$pluralNoun saved locally — will sync when online.';

  // ---------------------------------------------------------------
  // Destructive action affordances
  // ---------------------------------------------------------------

  /// When discarding an in-progress edit. No "Are you sure" — the verb
  /// itself names the consequence.
  static const String discardChangesTitle = 'Discard changes?';
  static const String discardChangesConfirm = 'Discard';
  static const String discardChangesCancel = 'Keep editing';

  /// Inline undo banner copy after a saved write that was previously
  /// guarded by a confirm dialog (e.g. attendance overwrite).
  static String undoBanner(String savedNoun) => '$savedNoun saved.';
  static const String undoAction = 'Undo';

  /// Sign-out — replaces `'Are you sure you want to sign out?'`.
  ///
  /// The default action is signing out; the user can dismiss.
  static const String signOutTitle = 'Sign out?';
  static const String signOutConfirm = 'Sign out';
  static const String signOutCancel = 'Cancel';

  /// Generic delete confirmation. Provide the noun explicitly so screen
  /// readers and the affirmative button label match.
  static String deleteTitle(String noun) => 'Delete $noun?';
  static String deleteHint(String noun) =>
      'This removes $noun from your school. The history stays.';
  static const String deleteConfirm = 'Delete';
  static const String deleteCancel = 'Cancel';

  // ---------------------------------------------------------------
  // "coming soon" replacements
  // ---------------------------------------------------------------
  // The right answer in 90% of cases is to hide the button. When the
  // button must stay (because removing it would break the layout), use
  // [availableSoon] as the toast on tap.

  static String availableSoon(String feature) =>
      '$feature is coming with the next school term.';

  // ---------------------------------------------------------------
  // Financial tone — anti-shame
  // ---------------------------------------------------------------
  // "Overdue" sounds like a debt collector. Schools use this app to
  // talk to parents whose kids attend. Stay neutral.

  static String dueOn(String dateLabel) => 'Due by $dateLabel.';
  static String dueIn(int days) =>
      days == 1 ? 'Due tomorrow.' : 'Due in $days days.';
  static String dueWasOn(String dateLabel) => 'Was due $dateLabel.';

  // ---------------------------------------------------------------
  // Phrases we never ship — enforced by the lint test
  // ---------------------------------------------------------------

  /// Phrases that must not appear in any value returned by this class.
  /// The test in `test/core/copy/warm_strings_test.dart` asserts this.
  static const List<String> bannedPhrases = <String>[
    'Failed to',
    'Error:',
    'Something went wrong',
    'Oops',
    'Whoops',
    'Are you sure',
    'No data',
    'coming soon',
    'overdue',
  ];
}
