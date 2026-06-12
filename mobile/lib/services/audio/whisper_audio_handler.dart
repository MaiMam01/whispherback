import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

WhisperAudioHandler? _whisperAudioHandler;

/// App-wide audio handler instance. Assigned during startup in `main()`.
/// Falls back to a plain handler if accessed before init (e.g. in tests),
/// so the app/tests never crash on a missing handler.
WhisperAudioHandler get whisperAudioHandler =>
    _whisperAudioHandler ??= WhisperAudioHandler();

set whisperAudioHandler(WhisperAudioHandler handler) =>
    _whisperAudioHandler = handler;

/// Bridges just_audio to audio_service so playback runs inside an Android
/// foreground service (background playback + media notification + lock-screen).
///
/// While the master toggle is ON, a silent looping track keeps the foreground
/// service (and therefore the scheduling isolate) alive between intervals so
/// schedules still fire when the app is backgrounded or swiped away — and the
/// ongoing notification signals the OS to keep the process around.
class WhisperAudioHandler extends BaseAudioHandler {
  WhisperAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  /// True while the keep-alive (Active) foreground session is running.
  bool _keepAlive = false;
  String? _silencePath;

  /// Invoked when the user taps Stop on the media notification — wired by the
  /// coordinator to turn the master toggle OFF.
  void Function()? onStopRequested;

  // ── Keep-alive foreground session ─────────────────────────────────────────

  /// Starts the foreground service and holds it open with a silent loop.
  Future<void> enterForeground({String title = 'WhisperBack active'}) async {
    _keepAlive = true;
    try {
      final path = await _ensureSilenceFile();
      mediaItem.add(
        MediaItem(id: 'whisperback-active', title: title, album: 'WhisperBack'),
      );
      await _player.setVolume(0);
      await _player.setLoopMode(LoopMode.one);
      await _player.setFilePath(path);
      await _player.play();
    } catch (_) {
      // If silence can't be prepared, the service still runs while clips play.
    }
  }

  /// Tears down the foreground session (master toggle OFF).
  Future<void> exitForeground() async {
    _keepAlive = false;
    await _player.stop();
    await super.stop();
  }

  /// Plays a real clip, interrupting the silent keep-alive.
  Future<void> playFile(String path, {String title = 'WhisperBack'}) async {
    mediaItem.add(MediaItem(id: path, title: title, album: 'WhisperBack'));
    await _player.setVolume(1);
    await _player.setLoopMode(LoopMode.off);
    await _player.setFilePath(path);
    await _player.play();
  }

  /// Stops the current clip; resumes the silent keep-alive if still Active.
  Future<void> stopClip() async {
    await _player.stop();
    if (_keepAlive) await enterForeground();
  }

  Future<String> _ensureSilenceFile() async {
    if (_silencePath != null && File(_silencePath!).existsSync()) {
      return _silencePath!;
    }
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'whisperback_silence.wav'));
    if (!file.existsSync()) {
      await file.writeAsBytes(_silentWav());
    }
    _silencePath = file.path;
    return file.path;
  }

  /// Builds a 1-second silent mono 16-bit PCM WAV (8 kHz) in memory.
  Uint8List _silentWav({int seconds = 1, int sampleRate = 8000}) {
    final numSamples = seconds * sampleRate;
    final dataSize = numSamples * 2;
    final bytes = BytesBuilder();
    void str(String s) => bytes.add(s.codeUnits);
    void u32(int v) {
      final b = ByteData(4)..setUint32(0, v, Endian.little);
      bytes.add(b.buffer.asUint8List());
    }

    void u16(int v) {
      final b = ByteData(2)..setUint16(0, v, Endian.little);
      bytes.add(b.buffer.asUint8List());
    }

    str('RIFF');
    u32(36 + dataSize);
    str('WAVE');
    str('fmt ');
    u32(16); // PCM chunk size
    u16(1); // PCM format
    u16(1); // mono
    u32(sampleRate);
    u32(sampleRate * 2); // byte rate
    u16(2); // block align
    u16(16); // bits per sample
    str('data');
    u32(dataSize);
    bytes.add(Uint8List(dataSize)); // zeros = silence
    return bytes.toBytes();
  }

  // ── audio_service media controls ──────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    // Stop on the media notification = turn the whole session off.
    final cb = onStopRequested;
    if (cb != null) {
      cb();
      return;
    }
    await exitForeground();
  }

  void _broadcastState(PlaybackEvent event) {
    // Don't surface controls for the silent keep-alive track.
    final silent = _keepAlive && _player.volume == 0;
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (!silent)
            (playing ? MediaControl.pause : MediaControl.play),
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  void disposePlayer() {
    _player.dispose();
  }
}
