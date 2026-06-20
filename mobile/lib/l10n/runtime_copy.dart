import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Localized copy for services that run outside the widget tree.
///
/// Bound on every frame in [WhisperBackApp]'s builder so notifications and
/// playback metadata follow the user's language.
abstract final class RuntimeCopy {
  static AppLocalizations _l10n = AppLocalizations(const Locale('en'));

  static void bind(AppLocalizations l10n) => _l10n = l10n;

  static AppLocalizations get l10n => _l10n;
}
