import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

WhisperAudioHandler? _whisperAudioHandler;

/// App-wide audio handler instance. Assigned during startup in `main()`.
/// Falls back to a plain handler if accessed before init (e.g. in tests),
/// so the app/tests never crash on a missing handler.
WhisperAudioHandler get whisperAudioHandler =>
    _whisperAudioHandler ??= WhisperAudioHandler();

set whisperAudioHandler(WhisperAudioHandler handler) =>
    _whisperAudioHandler = handler;

/// Bridges just_audio to audio_service so playback runs inside an Android
/// foreground service (keeps playing in the background / when the app is
/// backgrounded) and shows a media notification with lock-screen controls.
///
/// On platforms where audio_service isn't initialised (e.g. Windows desktop),
/// this still works as a plain just_audio wrapper.
class WhisperAudioHandler extends BaseAudioHandler {
  WhisperAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  /// Loads and plays a local file, updating the media notification metadata.
  Future<void> playFile(String path, {String title = 'WhisperBack'}) async {
    mediaItem.add(
      MediaItem(id: path, title: title, album: 'WhisperBack'),
    );
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1],
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
