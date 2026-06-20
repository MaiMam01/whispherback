import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisperback/core/errors/user_facing_error.dart';
import 'package:whisperback/data/repositories/playlist_repository.dart';
import 'package:whisperback/data/repositories/schedule_repository.dart';
import 'package:whisperback/l10n/app_localizations.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  test('maps schedule conflict to friendly message', () {
    final message = userFacingError(
      ScheduleConflictException('Morning'),
      l10n,
    );
    expect(message, contains('Morning'));
    expect(message, isNot(contains('Exception')));
  });

  test('maps playlist limit to friendly message', () {
    final message = userFacingError(
      const PlaylistLimitException(20),
      l10n,
    );
    expect(message, contains('20'));
  });

  test('maps import format errors to friendly message', () {
    final message = userFacingError(
      ArgumentError('Only MP3 and M4A files are supported'),
      l10n,
    );
    expect(message, l10n.importInvalidFormat);
  });

  test('unknown errors fall back to generic message', () {
    final message = userFacingError(Exception('db locked'), l10n);
    expect(message, l10n.genericErrorTryAgain);
  });
}
