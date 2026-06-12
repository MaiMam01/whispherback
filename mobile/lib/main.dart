import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'services/audio/whisper_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Allow lazy font fetch with instant system fallback — never block launch.
  GoogleFonts.config.allowRuntimeFetching = true;

  if (Platform.isAndroid || Platform.isIOS) {
    whisperAudioHandler = await AudioService.init(
      builder: WhisperAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.whisperback.playback',
        androidNotificationChannelName: 'WhisperBack playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF2E8BFF),
      ),
    );
  } else {
    whisperAudioHandler = WhisperAudioHandler();
  }

  runApp(const ProviderScope(child: WhisperBackApp()));
}
