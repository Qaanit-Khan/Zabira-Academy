import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/nasheed_item_model.dart';

class NasheedAudioPlayerController extends ChangeNotifier {
  NasheedAudioPlayerController() {
    _initAudioPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  NasheedItemModel? _currentTrack;
  NasheedItemModel? get currentTrack => _currentTrack;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  final Set<int> _favoriteIds = {};
  bool isFavorite(int id) => _favoriteIds.contains(id);

  void _initAudioPlayer() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
      notifyListeners();
    });

    _posSub = _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _durSub = _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
  }

  Future<void> playTrack(NasheedItemModel track) async {
    if (_currentTrack?.id == track.id) {
      togglePlayPause();
      return;
    }

    _currentTrack = track;
    _position = Duration.zero;
    _duration = Duration(seconds: track.duration > 0 ? track.duration : 240);
    notifyListeners();

    final url = track.resolvedAudioUrl;
    if (url.isNotEmpty) {
      try {
        await _player.stop();
        await _player.play(UrlSource(url));
      } catch (e) {
        debugPrint('[NASHEED PLAYER ERROR] $e');
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _player.seek(Duration.zero);
      }
      final url = _currentTrack!.resolvedAudioUrl;
      if (url.isNotEmpty) {
        await _player.resume().catchError((_) {
          return _player.play(UrlSource(url));
        });
      }
    }
  }

  Future<void> seek(Duration newPos) async {
    _position = newPos;
    notifyListeners();
    await _player.seek(newPos);
  }

  void toggleFavorite(int id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
