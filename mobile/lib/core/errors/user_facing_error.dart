import 'package:flutter/foundation.dart';

import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../l10n/app_localizations.dart';

/// Maps thrown errors to friendly, localized user messages.
String userFacingError(Object error, AppLocalizations l10n) {
  if (error is ScheduleConflictException) {
    return l10n.scheduleConflictMessage(error.existingPlaylistName);
  }
  if (error is PlaylistLimitException) {
    return l10n.playlistLimitReached(error.limit);
  }
  if (error is ArgumentError) {
    final message = error.message?.toString() ?? '';
    if (message.contains('MP3') || message.contains('M4A')) {
      return l10n.importInvalidFormat;
    }
    return l10n.genericErrorTryAgain;
  }
  if (error is StateError || error is UnsupportedError) {
    return l10n.genericErrorTryAgain;
  }
  if (kDebugMode) {
    debugPrint('Unhandled user-facing error: $error');
  }
  return l10n.genericErrorTryAgain;
}
