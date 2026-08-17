import 'package:flutter/foundation.dart';
import '../../data/models/nasheed_item_model.dart';
import '../../../../core/audio/global_audio_controller.dart';

/// Zabira Academy — Nasheed Audio Player Controller
///
/// Thin adapter around [GlobalAudioController] so nasheed-specific widgets
/// continue to work with nasheed models while audio is global and persistent.
class NasheedAudioPlayerController extends ChangeNotifier {
  NasheedAudioPlayerController(this._globalAudio) {
    // Mirror global audio changes as our own notifier
    _globalAudio.addListener(_onGlobalChange);
  }

  final GlobalAudioController _globalAudio;

  NasheedItemModel? _currentTrack;
  final Set<int> _favoriteIds = {};

  NasheedItemModel? get currentTrack => _currentTrack;

  bool get isPlaying =>
      _currentTrack != null &&
      _globalAudio.currentUrl == _currentTrack!.resolvedAudioUrl &&
      _globalAudio.isPlaying;

  bool get isLoading =>
      _currentTrack != null &&
      _globalAudio.currentUrl == _currentTrack!.resolvedAudioUrl &&
      _globalAudio.isLoading;

  Duration get position => _globalAudio.position;
  Duration get duration => _globalAudio.duration;

  bool isFavorite(int id) => _favoriteIds.contains(id);

  void _onGlobalChange() => notifyListeners();

  Future<void> playTrack(NasheedItemModel track) async {
    if (_currentTrack?.id == track.id) {
      await _globalAudio.togglePlayPause();
      return;
    }

    _currentTrack = track;
    notifyListeners();

    final url = track.resolvedAudioUrl;
    if (url.isNotEmpty) {
      await _globalAudio.playUrl(
        url,
        title: track.title,
        artist: track.artist,
        coverUrl: track.resolvedThumbnail,
        source: 'nasheed',
      );
    } else {
      debugPrint('[NASHEED PLAYER] No audio URL for track: ${track.title}');
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;
    await _globalAudio.togglePlayPause();
  }

  Future<void> seek(Duration newPos) async {
    await _globalAudio.seek(newPos);
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
    _globalAudio.removeListener(_onGlobalChange);
    // Do NOT dispose _globalAudio — it is global and lives beyond this page
    super.dispose();
  }
}
