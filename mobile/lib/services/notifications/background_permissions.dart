import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Asks the user to exempt WhisperBack from battery optimization so the
/// foreground service (and scheduling) survives aggressive OEM battery killers
/// (Xiaomi, Samsung, Oppo, etc.). No-op outside Android / when already granted.
Future<void> requestBatteryExemption() async {
  if (!Platform.isAndroid) return;
  final status = await Permission.ignoreBatteryOptimizations.status;
  if (!status.isGranted) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
