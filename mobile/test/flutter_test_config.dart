import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Enables SQLite in VM unit/widget tests (Windows/Linux/macOS dev machines).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
