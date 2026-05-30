import 'package:uuid/uuid.dart';

import '../../domain/entities/sleep_window.dart';
import '../database/database_helper.dart';

class SleepRepository {
  SleepRepository(this._db);

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  Future<SleepWindow?> getActive() async {
    final db = await _db.database;
    final rows = await db.query('sleep_windows', where: 'active = 1');
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<List<SleepWindow>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('sleep_windows', orderBy: 'start_time DESC');
    return rows.map(_fromRow).toList();
  }

  Future<SleepWindow> create({
    required DateTime startTime,
    required DateTime endTime,
    String label = 'Sleep',
  }) async {
    final db = await _db.database;
    await db.update('sleep_windows', {'active': 0});
    final window = SleepWindow(
      id: _uuid.v4(),
      startTime: startTime,
      endTime: endTime,
      label: label,
      active: true,
    );
    await db.insert('sleep_windows', _toRow(window));
    return window;
  }

  Future<void> deactivateAll() async {
    final db = await _db.database;
    await db.update('sleep_windows', {'active': 0});
  }

  bool isSleepActive(SleepWindow? window) {
    if (window == null || !window.active) return false;
    return window.contains(DateTime.now());
  }

  SleepWindow _fromRow(Map<String, Object?> row) {
    return SleepWindow(
      id: row['id']! as String,
      startTime: DateTime.parse(row['start_time']! as String),
      endTime: DateTime.parse(row['end_time']! as String),
      label: row['label']! as String,
      active: (row['active'] as int) == 1,
    );
  }

  Map<String, Object?> _toRow(SleepWindow window) {
    return {
      'id': window.id,
      'start_time': window.startTime.toIso8601String(),
      'end_time': window.endTime.toIso8601String(),
      'label': window.label,
      'active': window.active ? 1 : 0,
    };
  }
}
