import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:whisperback/data/database/database_helper.dart';
import 'package:whisperback/data/repositories/playlist_repository.dart';
import 'package:whisperback/data/repositories/schedule_repository.dart';

void main() {
  late DatabaseHelper db;
  late PlaylistRepository playlists;
  late ScheduleRepository schedules;

  setUp(() async {
    db = DatabaseHelper.instance;
    await db.close();
    final dbPath = await getDatabasesPath();
    final file = File(p.join(dbPath, 'whisperback.db'));
    if (await file.exists()) await file.delete();
    playlists = PlaylistRepository(db);
    schedules = ScheduleRepository(db);
    await db.database;
  });

  tearDown(() async {
    await db.close();
  });

  test('schedule conflict blocks overlapping save', () async {
    final p1 = await playlists.create('Playlist A');
    final p2 = await playlists.create('Playlist B');
    final start = DateTime(2026, 5, 30, 9, 0);

    await schedules.save(
      playlistId: p1.id,
      startTime: start,
      intervalMinutes: 30,
    );

    expect(
      () => schedules.save(
        playlistId: p2.id,
        startTime: start,
        intervalMinutes: 30,
      ),
      throwsA(isA<ScheduleConflictException>()),
    );
  });
}
