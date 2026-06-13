import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

WhisperAudioHandler? _whisperAudioHandler;

/// True when [AudioService.init] succeeded and the handler is bound to Android.
bool whisperAudioServiceBound = false;

WhisperAudioHandler get whisperAudioHandler =>
    _whisperAudioHandler ??= WhisperAudioHandler();

set whisperAudioHandler(WhisperAudioHandler handler) =>
    _whisperAudioHandler = handler;

/// Album art for the media notification + lock screen.
final Uri _albumArtUri = Uri.parse(
  'android.resource://com.whisperback.whisperback/drawable/ic_notification',
);

/// Bridges [just_audio] to [audio_service] for Spotify-style media controls.
///
/// • [_clipPlayer] — all real audio (full quality)
/// • [_idlePlayer] — silent loop at volume 0 while Active + idle only
class WhisperAudioHandler extends BaseAudioHandler {
  WhisperAudioHandler() {
    playbackState.add(
      PlaybackState(
        controls: const [],
        systemActions: const {MediaAction.stop, MediaAction.seek},
        androidCompactActionIndices: const [0],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ),
    );

    _clipPlayer.playbackEventStream.listen((_) {
      if (_playingClip) _broadcastClipState();
    });
    _idlePlayer.playbackEventStream.listen((_) {
      if (!_playingClip && _keepAlive) _broadcastIdleState();
    });
    _clipPlayer.durationStream.listen(_onDurationReady);
  }

  final AudioPlayer _clipPlayer = AudioPlayer();
  final AudioPlayer _idlePlayer = AudioPlayer();

  AudioPlayer get player => _clipPlayer;

  bool _keepAlive = false;
  bool _standalonePlayback = false;
  bool _audioSessionReady = false;
  bool _playingClip = false;
  String? _silencePath;

  String _sessionSubtitle = 'Listening for scheduled whispers';
  int _scheduleCount = 0;
  String? _clipTitle;

  void Function()? onStopRequested;
  void Function()? onStopClipRequested;
  void Function()? onPlayRequested;
  void Function()? onPauseRequested;

  bool get isPlayingClip => _playingClip;
  String? get currentClipTitle => _clipTitle;

  Future<void> _ensureAudioSession() async {
    if (_audioSessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _audioSessionReady = true;
  }

  Future<void> _activateAudioSession() async {
    await _ensureAudioSession();
    final session = await AudioSession.instance;
    await session.setActive(true);
  }

  // ── Active session (master toggle ON) ─────────────────────────────────────

  Future<void> enterForeground({
    String title = 'WhisperBack · Active',
    String subtitle = 'Listening for scheduled whispers',
    int scheduleCount = 0,
  }) async {
    _keepAlive = true;
    _sessionSubtitle = subtitle;
    _scheduleCount = scheduleCount;
    if (_playingClip) return;
    await _startIdleSession(title: title);
  }

  Future<void> _startIdleSession({String title = 'WhisperBack · Active'}) async {
    _playingClip = false;
    _clipTitle = null;
    final item = _activeMediaItem(title: title);
    mediaItem.add(item);
    queue.add([item]);

    try {
      final path = await _ensureSilenceFile();
      await _idlePlayer.stop();
      await _idlePlayer.setVolume(0);
      await _idlePlayer.setLoopMode(LoopMode.one);
      await _idlePlayer.setAudioSource(AudioSource.file(path));
      await _idlePlayer.play();
    } catch (_) {
      // Metadata-only fallback.
    }
    _broadcastIdleState();
  }

  Future<void> updateActiveSessionInfo({
    required String subtitle,
    int scheduleCount = 0,
  }) async {
    _sessionSubtitle = subtitle;
    _scheduleCount = scheduleCount;
    if (_playingClip) return;
    mediaItem.add(_activeMediaItem());
    if (_keepAlive && !_idlePlayer.playing) {
      await _startIdleSession();
    } else {
      _broadcastIdleState();
    }
  }

  MediaItem _activeMediaItem({String title = 'WhisperBack · Active'}) {
    return MediaItem(
      id: 'whisperback-active',
      title: title,
      album: 'WhisperBack',
      artist: _sessionSubtitle,
      artUri: _albumArtUri,
      displayTitle: title,
      displaySubtitle: _sessionSubtitle,
      displayDescription: _scheduleCount > 0
          ? '$_scheduleCount schedule(s) armed'
          : 'Listening for scheduled whispers',
      extras: const {'mode': 'active_idle'},
    );
  }

  Future<void> exitForeground() async {
    _keepAlive = false;
    _playingClip = false;
    _standalonePlayback = false;
    _clipTitle = null;
    await _idlePlayer.stop();
    await _clipPlayer.stop();
    queue.add([]);
    await super.stop();
  }

  // ── Clip playback ─────────────────────────────────────────────────────────

  Future<void> playFile(
    String path, {
    String title = 'WhisperBack',
    String? playlistName,
    String? subtitle,
  }) async {
    await _activateAudioSession();
    _playingClip = true;
    _clipTitle = title;
    if (!_keepAlive) _standalonePlayback = true;

    await _idlePlayer.stop();

    await _clipPlayer.stop();
    await _clipPlayer.setVolume(1);
    await _clipPlayer.setSpeed(1);
    await _clipPlayer.setLoopMode(LoopMode.off);

    final item = _clipMediaItem(
      path: path,
      title: title,
      playlistName: playlistName,
      subtitle: subtitle,
    );
    mediaItem.add(item);
    queue.add([item]);
    _broadcastClipState();

    await _clipPlayer.setAudioSource(
      AudioSource.file(path),
      preload: true,
    );
    await _clipPlayer.play();
    _broadcastClipState();
    // Second publish helps Android swap idle → now-playing on lock screen.
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 200),
      _broadcastClipState,
    ));
  }

  MediaItem _clipMediaItem({
    required String path,
    required String title,
    String? playlistName,
    String? subtitle,
    Duration? duration,
  }) {
    final line = subtitle ?? 'Now playing';
    return MediaItem(
      id: path,
      title: title,
      album: playlistName ?? 'WhisperBack',
      artist: line,
      duration: duration,
      artUri: _albumArtUri,
      displayTitle: title,
      displaySubtitle: playlistName ?? line,
      displayDescription: line,
      extras: const {'mode': 'clip'},
    );
  }

  void _onDurationReady(Duration? dur) {
    if (!_playingClip || dur == null) return;
    final current = mediaItem.value;
    if (current == null || current.extras?['mode'] != 'clip') return;
    if (current.duration == dur) return;
    mediaItem.add(_clipMediaItem(
      path: current.id,
      title: current.title,
      playlistName: current.album,
      subtitle: current.artist,
      duration: dur,
    ));
    _broadcastClipState();
  }

  Future<void> stopClip() async {
    _playingClip = false;
    _clipTitle = null;
    await _clipPlayer.stop();

    if (_keepAlive) {
      _standalonePlayback = false;
      await _startIdleSession();
      return;
    }

    if (_standalonePlayback) {
      _standalonePlayback = false;
      queue.add([]);
      await super.stop();
    }
    _broadcastStoppedState();
  }

  Future<String> _ensureSilenceFile() async {
    if (_silencePath != null && File(_silencePath!).existsSync()) {
      return _silencePath!;
    }
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'whisperback_session_silence.wav'));
    if (!file.existsSync()) {
      await file.writeAsBytes(_silentWav());
    }
    _silencePath = file.path;
    return file.path;
  }

  Uint8List _silentWav({int seconds = 1, int sampleRate = 44100}) {
    const channels = 2;
    final numSamples = seconds * sampleRate;
    final dataSize = numSamples * channels * 2;
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
    u32(16);
    u16(1);
    u16(channels);
    u32(sampleRate);
    u32(sampleRate * channels * 2);
    u16(channels * 2);
    u16(16);
    str('data');
    u32(dataSize);
    bytes.add(Uint8List(dataSize));
    return bytes.toBytes();
  }

  // ── Media controls (notification + lock screen) ───────────────────────────

  @override
  Future<void> play() async {
    if (_playingClip) {
      await _clipPlayer.play();
      onPlayRequested?.call();
      _broadcastClipState();
      return;
    }
    if (_keepAlive && _idlePlayer.volume == 0) return;
    await _idlePlayer.play();
    onPlayRequested?.call();
    _broadcastIdleState();
  }

  @override
  Future<void> pause() async {
    if (_playingClip) {
      await _clipPlayer.pause();
      onPauseRequested?.call();
      _broadcastClipState();
    }
  }

  @override
  Future<void> seek(Duration position) {
    if (_playingClip) return _clipPlayer.seek(position);
    return _idlePlayer.seek(position);
  }

  @override
  Future<void> stop() async {
    if (_playingClip) {
      onStopClipRequested?.call();
    } else {
      onStopRequested?.call();
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'stop_clip':
        onStopClipRequested?.call();
      case 'power_off':
        onStopRequested?.call();
    }
  }

  void _broadcastClipState() {
    final playing = _clipPlayer.playing;
    final processing = _clipPlayer.processingState;
    final completed = processing == ProcessingState.completed;

    final reportPlaying = !completed &&
        (playing ||
            processing == ProcessingState.loading ||
            processing == ProcessingState.buffering);

    final controls = <MediaControl>[
      if (!completed) playing ? MediaControl.pause : MediaControl.play,
      if (!completed)
        MediaControl.stop,
    ];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.stop,
          MediaAction.pause,
          MediaAction.play,
        },
        androidCompactActionIndices:
            controls.length >= 2 ? const [0, 1] : const [0],
        processingState: completed
            ? AudioProcessingState.completed
            : (reportPlaying
                ? AudioProcessingState.ready
                : _mapProcessingState(processing)),
        playing: reportPlaying,
        updatePosition: _clipPlayer.position,
        bufferedPosition: _clipPlayer.bufferedPosition,
        speed: _clipPlayer.speed,
        queueIndex: 0,
      ),
    );
  }

  void _broadcastIdleState() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.custom(
            androidIcon: 'drawable/ic_power',
            label: 'Power off',
            name: 'power_off',
          ),
        ],
        systemActions: const {MediaAction.stop},
        androidCompactActionIndices: const [0],
        processingState: AudioProcessingState.ready,
        playing: true,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  void _broadcastStoppedState() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        systemActions: const {MediaAction.stop},
        androidCompactActionIndices: const [],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    return switch (state) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }

  void disposePlayer() {
    _clipPlayer.dispose();
    _idlePlayer.dispose();
  }
}
