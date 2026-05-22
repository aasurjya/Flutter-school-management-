import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Concise accessor for the generated [AppLocalizations].
///
/// Saves typing `AppLocalizations.of(context)!` at every call site:
///
/// ```dart
/// final l = context.l10n;
/// Text(l.dashboard); // instead of AppLocalizations.of(context)!.dashboard
/// ```
///
/// Throws (via the `!`) only when used outside the `MaterialApp` subtree,
/// which would already be a programming error — the delegate is registered
/// at `lib/main.dart`.
extension BuildContextL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
