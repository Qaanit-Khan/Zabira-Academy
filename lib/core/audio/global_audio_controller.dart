import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Zabira Academy — Global Audio Controller
///
/// Single shared audio player that survives navigation.
/// Register at app root via MultiProvider.
/// All audio sources (Nasheed, Media, Kids) route through this controller
/// so only ONE audio source plays at a time.
class GlobalAudioController extends ChangeNotifier {
  GlobalAudioController() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _completeSub;

  // ── Current Track Info ─────────────────────────────────────────────────────
  String? _currentUrl;
  String? _currentTitle;
  String? _currentArtist;
  String? _currentCoverUrl;
  String? _currentSource; // 'nasheed', 'media', 'kids', etc.

  String? get currentUrl => _currentUrl;
  String? get currentTitle => _currentTitle;
  String? get currentArtist => _currentArtist;
  String? get currentCoverUrl => _currentCoverUrl;
  String? get currentSource => _currentSource;

  // ── Playback State ─────────────────────────────────────────────────────────
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isCompleted = false;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isCompleted => _isCompleted;
  bool get hasActiveTrack => _currentUrl != null && _currentUrl!.isNotEmpty;

  // ── Position & Duration ────────────────────────────────────────────────────
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Duration get position => _position;
  Duration get duration => _duration;

  double get progress {
    if (_duration == Duration.zero) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get formattedPosition => _formatDuration(_position);
  String get formattedDuration => _formatDuration(_duration);

  // ── Init ───────────────────────────────────────────────────────────────────
  void _initPlayer() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
      _isLoading = false;
      if (state == PlayerState.stopped) {
        _isCompleted = false;
      }
      notifyListeners();
    });

    _posSub = _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durSub = _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _isCompleted = true;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  // ── Play ───────────────────────────────────────────────────────────────────

  /// Play a URL alias
  Future<void> play({
    required String url,
    String? title,
    String? artist,
    String? coverUrl,
    String? source,
  }) =>
      playUrl(url, title: title, artist: artist, coverUrl: coverUrl, source: source);

  /// Play a URL. If same URL is already loaded, toggles play/pause.
  Future<void> playUrl(
    String url, {
    String? title,
    String? artist,
    String? coverUrl,
    String? source,
  }) async {
    if (url.isEmpty) {
      _hasError = true;
      _errorMessage = 'Audio URL is not available.';
      notifyListeners();
      return;
    }

    // Same track — toggle
    if (_currentUrl == url) {
      await togglePlayPause();
      return;
    }

    // New track — stop existing
    _hasError = false;
    _errorMessage = null;
    _isLoading = true;
    _isCompleted = false;
    _currentUrl = url;
    _currentTitle = title;
    _currentArtist = artist;
    _currentCoverUrl = coverUrl;
    _currentSource = source;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();

    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('[GLOBAL AUDIO] Error playing url: $e');
      _isLoading = false;
      _isPlaying = false;
      _hasError = true;
      _errorMessage = 'Could not play audio. Please check your connection.';
      notifyListeners();
    }
  }

  // ── Toggle Play/Pause ──────────────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (_currentUrl == null || _currentUrl!.isEmpty) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      try {
        if (_isCompleted) {
          await _player.play(UrlSource(_currentUrl!));
        } else {
          await _player.resume().catchError((_) async {
            await _player.play(UrlSource(_currentUrl!));
          });
        }
      } catch (e) {
        debugPrint('[GLOBAL AUDIO] Toggle error: $e');
        _hasError = true;
        _errorMessage = 'Could not resume playback.';
        notifyListeners();
      }
    }
  }

  // ── Seek ───────────────────────────────────────────────────────────────────
  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    await _player.seek(position);
  }

  // ── Stop ───────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
