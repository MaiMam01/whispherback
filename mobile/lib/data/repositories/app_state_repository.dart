import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class AppStateRepository {
  AppStateRepository(this._db);

  final DatabaseHelper _db;

  Future<bool> isActive() async {
    final db = await _db.database;
    final rows = await db.query('app_state', where: 'id = 1');
    if (rows.isEmpty) return false;
    return (rows.first['is_active'] as int) == 1;
  }

  Future<bool> isGlobalShuffleEnabled() async {
    final db = await _db.database;
    final rows = await db.query('app_state', where: 'id = 1');
    if (rows.isEmpty) return false;
    return (rows.first['global_shuffle_enabled'] as int) == 1;
  }

  Future<void> _ensureRow() async {
    final db = await _db.database;
    await db.insert(
      'app_state',
      {'id': 1, 'is_active': 0, 'global_shuffle_enabled': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> setActive(bool active) async {
    await _ensureRow();
    final db = await _db.database;
    await db.update(
      'app_state',
      {'is_active': active ? 1 : 0},
      where: 'id = 1',
    );
  }

  Future<void> setGlobalShuffle(bool enabled) async {
    await _ensureRow();
    final db = await _db.database;
    await db.update(
      'app_state',
      {'global_shuffle_enabled': enabled ? 1 : 0},
      where: 'id = 1',
    );
  }
}
