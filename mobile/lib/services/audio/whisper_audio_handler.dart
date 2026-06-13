import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

WhisperAudioHandler? _whisperAudioHandler;

WhisperAudioHandler get whisperAudioHandler =>
    _whisperAudioHandler ??= WhisperAudioHandler();

set whisperAudioHandler(WhisperAudioHandler handler) =>
    _whisperAudioHandler = handler;

/// Lock-screen artwork shown on the media notification.
final Uri _defaultArtUri = Uri.parse(
  'android.resource://com.whisperback.whisperback/drawable/ic_notification',
);

/// Bridges [just_audio] to [audio_service] for full-quality playback, media
/// notifications, and lock-screen controls (Spotify-style).
///
/// A single [AudioPlayer] handles all audio — no silent keep-alive loop that
/// can degrade quality via Android audio-focus mixing.
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

    _player.playbackEventStream.listen(_broadcastState);
    _player.durationStream.listen(_onDurationReady);
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  bool _keepAlive = false;
  bool _standalonePlayback = false;
  bool _audioSessionReady = false;

  void Function()? onStopRequested;
  void Function()? onStopClipRequested;
  void Function()? onPlayRequested;
  void Function()? onPauseRequested;

  String _sessionSubtitle = 'Listening for scheduled whispers';
  int _scheduleCount = 0;
  bool _playingClip = false;

  Future<void> _ensureAudioSession() async {
    if (_audioSessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _audioSessionReady = true;
  }

  // ── Keep-alive (Active toggle ON, no clip playing) ────────────────────────

  Future<void> enterForeground({
    String title = 'WhisperBack · Active',
    String subtitle = 'Listening for scheduled whispers',
    int scheduleCount = 0,
  }) async {
    _keepAlive = true;
    _sessionSubtitle = subtitle;
    _scheduleCount = scheduleCount;
    if (_playingClip) return;
    await _publishActiveIdle(title: title);
  }

  Future<void> _publishActiveIdle({String title = 'WhisperBack · Active'}) async {
    _playingClip = false;
    final item = _activeMediaItem(title: title);
    mediaItem.add(item);
    queue.add([item]);
    _broadcastState(null);
  }

  Future<void> updateActiveSessionInfo({
    required String subtitle,
    int scheduleCount = 0,
  }) async {
    _sessionSubtitle = subtitle;
    _scheduleCount = scheduleCount;
    if (_playingClip) return;
    await _publishActiveIdle();
  }

  MediaItem _activeMediaItem({String title = 'WhisperBack · Active'}) {
    return MediaItem(
      id: 'whisperback-active',
      title: title,
      album: 'WhisperBack',
      artist: _sessionSubtitle,
      artUri: _defaultArtUri,
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
    await _player.stop();
    queue.add([]);
    await super.stop();
  }

  // ── Clip playback (manual + scheduled) ────────────────────────────────────

  Future<void> playFile(
    String path, {
    String title = 'WhisperBack',
    String? playlistName,
    String? subtitle,
  }) async {
    await _ensureAudioSession();
    _playingClip = true;
    if (!_keepAlive) _standalonePlayback = true;

    await _player.stop();
    await _player.setVolume(1);
    await _player.setSpeed(1);
    await _player.setLoopMode(LoopMode.off);

    final item = MediaItem(
      id: path,
      title: title,
      album: playlistName ?? 'WhisperBack',
      artist: subtitle ?? 'Now playing',
      artUri: _defaultArtUri,
      displayTitle: title,
      displaySubtitle: playlistName ?? subtitle ?? 'Now playing',
      displayDescription: subtitle ?? 'Now playing',
      extras: const {'mode': 'clip'},
    );
    mediaItem.add(item);
    queue.add([item]);

    await _player.setAudioSource(
      AudioSource.file(path),
      preload: true,
    );
    await _player.play();
    _broadcastState(null);
  }

  void _onDurationReady(Duration? dur) {
    if (!_playingClip || dur == null) return;
    final current = mediaItem.value;
    if (current == null || current.extras?['mode'] != 'clip') return;
    if (current.duration == dur) return;
    mediaItem.add(
      MediaItem(
        id: current.id,
        title: current.title,
        album: current.album,
        artist: current.artist,
        duration: dur,
        artUri: current.artUri,
        displayTitle: current.displayTitle,
        displaySubtitle: current.displaySubtitle,
        displayDescription: current.displayDescription,
        extras: current.extras,
      ),
    );
  }

  Future<void> stopClip() async {
    _playingClip = false;
    await _player.stop();

    if (_keepAlive) {
      _standalonePlayback = false;
      await _publishActiveIdle();
      return;
    }

    if (_standalonePlayback) {
      _standalonePlayback = false;
      queue.add([]);
      await super.stop();
    }
    _broadcastState(null);
  }

  // ── audio_service media controls ──────────────────────────────────────────

  @override
  Future<void> play() async {
    if (_playingClip) {
      await _player.play();
      onPlayRequested?.call();
      _broadcastState(null);
      return;
    }
    if (_keepAlive) {
      onPlayRequested?.call();
      _broadcastState(null);
    }
  }

  @override
  Future<void> pause() async {
    if (_playingClip) {
      await _player.pause();
      onPauseRequested?.call();
      _broadcastState(null);
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

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

  void _broadcastState(PlaybackEvent? event) {
    final playing = _player.playing;
    final processing = _player.processingState;

    final reportPlaying = _playingClip
        ? (playing ||
            processing == ProcessingState.loading ||
            processing == ProcessingState.buffering)
        : _keepAlive;

    final mappedState = _playingClip
        ? _mapProcessingState(processing)
        : (_keepAlive
            ? AudioProcessingState.ready
            : _mapProcessingState(processing));

    final List<MediaControl> controls;
    final List<int> compact;

    if (_playingClip) {
      controls = [
        if (processing != ProcessingState.completed)
          playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
      ];
      compact = controls.length >= 2 ? [0, 1] : [0];
    } else if (_keepAlive) {
      controls = [
        MediaControl.custom(
          androidIcon: 'drawable/ic_power',
          label: 'Power off',
          name: 'power_off',
        ),
      ];
      compact = const [0];
    } else {
      controls = const [];
      compact = const [];
    }

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: {
          if (_playingClip) MediaAction.seek,
          MediaAction.stop,
        },
        androidCompactActionIndices: compact,
        processingState: mappedState,
        playing: reportPlaying,
        updatePosition: _playingClip ? _player.position : Duration.zero,
        bufferedPosition: _playingClip ? _player.bufferedPosition : Duration.zero,
        speed: _player.speed,
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
    _player.dispose();
  }
}
