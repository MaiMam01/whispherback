import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:whisperback/data/database/database_helper.dart';
import 'package:whisperback/data/repositories/playlist_repository.dart';
import 'package:whisperback/data/repositories/schedule_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper db;
  late PlaylistRepository playlists;
  late ScheduleRepository schedules;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = DatabaseHelper.instance;
    await db.close();
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
