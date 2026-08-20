import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../../data/services/islamic_ai_service.dart';

enum IslamicAiState {
  idle,
  greeting,
  listening,
  processing,
  speaking,
  error,
}

/// Controller managing the state of the Islamic AI Voice Assistant.
class IslamicAiController extends ChangeNotifier {
  IslamicAiController({IslamicAiService? service})
      : _service = service ?? IslamicAiService() {
    _initPlayer();
  }

  final IslamicAiService _service;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  IslamicAiState _state = IslamicAiState.idle;
  String? _errorMessage;
  String? _greetingText;
  String? _transcription;
  String? _answer;
  Uint8List? _latestAudioBytes;
  Timer? _maxRecordingTimer;
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerStateSub;

  // Maximum audio recording duration (in seconds) - safety fallback only
  static const int maxRecordingSeconds = 60;
  int _recordingElapsedSeconds = 0;
  Timer? _elapsedTimer;

  IslamicAiState get state => _state;
  bool get isIdle => _state == IslamicAiState.idle;
  bool get isGreeting => _state == IslamicAiState.greeting;
  bool get isListening => _state == IslamicAiState.listening;
  bool get isProcessing => _state == IslamicAiState.processing;
  bool get isSpeaking => _state == IslamicAiState.speaking;
  bool get hasError => _state == IslamicAiState.error;

  String? get errorMessage => _errorMessage;
  String? get greetingText => _greetingText;
  String? get transcription => _transcription;
  String? get answer => _answer;
  int get recordingElapsedSeconds => _recordingElapsedSeconds;

  void _initPlayer() {
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      _handlePlaybackCompleted();
    });

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.completed || playerState == PlayerState.stopped) {
        if (_state == IslamicAiState.speaking) {
          _state = IslamicAiState.idle;
          notifyListeners();
        }
      }
    });
  }

  void _handlePlaybackCompleted() {
    if (_state == IslamicAiState.greeting) {
      // After spoken greeting completes, immediately start recording microphone
      startListening();
    } else if (_state == IslamicAiState.speaking) {
      _state = IslamicAiState.idle;
      notifyListeners();
    }
  }

  /// Initiates the Islamic AI Assistant flow:
  /// 1. Calls Cloudflare greeting endpoint with the user's name
  /// 2. Plays spoken ElevenLabs greeting audio automatically
  /// 3. Transitions to recording mode once greeting finishes
  Future<void> startGreetingAndFlow(String? userName) async {
    _errorMessage = null;
    _state = IslamicAiState.greeting;
    notifyListeners();

    try {
      final response = await _service.queryGreeting(name: userName);

      if (response.success && response.audioBytes != null && response.audioBytes!.isNotEmpty) {
        _greetingText = response.answer ?? response.transcription;
        notifyListeners();

        await _audioPlayer.stop();
        await _audioPlayer.play(
          BytesSource(
            response.audioBytes!,
            mimeType: response.audioMimeType ?? 'audio/mpeg',
          ),
        );
      } else {
        // Fallback: If greeting audio is not available, immediately start listening
        await startListening();
      }
    } catch (e) {
      debugPrint('[IslamicAiController] Greeting error: $e');
      await startListening();
    }
  }

  /// Start recording voice question.
  Future<void> startListening() async {
    try {
      // If already playing audio, stop playback first
      if (_state == IslamicAiState.speaking || _state == IslamicAiState.greeting) {
        await _audioPlayer.stop();
      }

      // Check microphone permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _setError('Microphone permission is required to ask voice questions.');
        return;
      }

      _errorMessage = null;
      _recordingElapsedSeconds = 0;
      _state = IslamicAiState.listening;
      notifyListeners();

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Start recording to temporary location
      if (kIsWeb) {
        await _audioRecorder.start(config, path: '');
      } else {
        final tempDir = Directory.systemTemp;
        final filePath = '${tempDir.path}/islamic_ai_query_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(config, path: filePath);
      }

      // Start elapsed seconds counter
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingElapsedSeconds++;
        notifyListeners();
      });

      // Safety timeout: automatically stop and process after 60s max
      _maxRecordingTimer?.cancel();
      _maxRecordingTimer = Timer(const Duration(seconds: maxRecordingSeconds), () {
        if (_state == IslamicAiState.listening) {
          stopListeningAndSend();
        }
      });
    } catch (e) {
      debugPrint('[IslamicAiController] Start recording error: $e');
      _setError('Could not start microphone recording. Please try again.');
    }
  }

  /// Stops the recording and uploads to Cloudflare AI voice endpoint.
  Future<void> stopListeningAndSend() async {
    if (_state != IslamicAiState.listening) return;

    _maxRecordingTimer?.cancel();
    _elapsedTimer?.cancel();

    _state = IslamicAiState.processing;
    notifyListeners();

    try {
      final path = await _audioRecorder.stop();
      Uint8List? audioBytes;

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          audioBytes = await file.readAsBytes();
          // Clean up temp recording file
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      if (audioBytes == null || audioBytes.isEmpty) {
        _setError('No audio recorded. Please try speaking again.');
        return;
      }

      // Send to Cloudflare Worker
      final response = await _service.queryVoice(
        audioBytes: audioBytes,
        mimeType: 'audio/wav',
      );

      if (!response.success) {
        _setError(response.error ?? 'Could not process Islamic AI query.');
        return;
      }

      _transcription = response.transcription;
      _answer = response.answer;
      _latestAudioBytes = response.audioBytes;

      // Play returned audio automatically
      if (_latestAudioBytes != null && _latestAudioBytes!.isNotEmpty) {
        _state = IslamicAiState.speaking;
        notifyListeners();

        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(
            BytesSource(
              _latestAudioBytes!,
              mimeType: response.audioMimeType ?? 'audio/mpeg',
            ),
          );
        } catch (playErr) {
          debugPrint('[IslamicAiController] Audio playback error: $playErr');
          _state = IslamicAiState.idle;
          notifyListeners();
        }
      } else {
        _state = IslamicAiState.idle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[IslamicAiController] Processing error: $e');
      _setError('Something went wrong while processing your question. Please try again.');
    }
  }

  /// Replays the last received audio response.
  Future<void> replayAnswerAudio() async {
    if (_latestAudioBytes == null || _latestAudioBytes!.isEmpty) return;

    try {
      _state = IslamicAiState.speaking;
      notifyListeners();

      await _audioPlayer.stop();
      await _audioPlayer.play(
        BytesSource(
          _latestAudioBytes!,
          mimeType: 'audio/mpeg',
        ),
      );
    } catch (e) {
      debugPrint('[IslamicAiController] Replay error: $e');
      _state = IslamicAiState.idle;
      notifyListeners();
    }
  }

  /// Stops current voice playback.
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (_state == IslamicAiState.speaking || _state == IslamicAiState.greeting) {
      _state = IslamicAiState.idle;
      notifyListeners();
    }
  }

  /// Cancels any ongoing recording or playback and resets state.
  Future<void> reset() async {
    _maxRecordingTimer?.cancel();
    _elapsedTimer?.cancel();
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    _state = IslamicAiState.idle;
    _errorMessage = null;
    _transcription = null;
    _answer = null;
    _latestAudioBytes = null;
    _recordingElapsedSeconds = 0;
    notifyListeners();
  }

  void _setError(String message) {
    _maxRecordingTimer?.cancel();
    _elapsedTimer?.cancel();
    _state = IslamicAiState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _maxRecordingTimer?.cancel();
    _elapsedTimer?.cancel();
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
