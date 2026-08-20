import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/islamic_ai_response.dart';

/// Service for communicating with the Zabira Islamic AI Voice Cloudflare Worker.
///
/// Sends raw binary audio directly to:
/// `POST https://zabira-islamic-ai.qaanitcode771.workers.dev/ai/voice`
class IslamicAiService {
  static const String _voiceEndpoint =
      'https://zabira-islamic-ai.qaanitcode771.workers.dev/ai/voice';
  static const String _greetingEndpoint =
      'https://zabira-islamic-ai.qaanitcode771.workers.dev/ai/greeting';

  /// Calls the Cloudflare Islamic AI greeting endpoint to get personalized spoken greeting.
  Future<IslamicAiResponse> queryGreeting({String? name}) async {
    try {
      final uri = Uri.parse(_greetingEndpoint);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': (name != null && name.trim().isNotEmpty) ? name.trim() : '',
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw http.ClientException('Greeting request timed out.'),
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return IslamicAiResponse.fromJson(decoded);
      } else {
        return IslamicAiResponse.failure('Greeting service unavailable.');
      }
    } catch (e) {
      debugPrint('[IslamicAiService] Greeting error: $e');
      return IslamicAiResponse.failure('Greeting service unavailable.');
    }
  }

  /// Sends recorded binary audio bytes to the Cloudflare Islamic AI Worker.
  ///
  /// [audioBytes] - The raw binary audio recorded from the microphone (e.g. WAV/MP3/AAC).
  /// [mimeType] - The MIME type of the audio bytes (default 'audio/wav').
  Future<IslamicAiResponse> queryVoice({
    required Uint8List audioBytes,
    String mimeType = 'audio/wav',
  }) async {
    try {
      if (audioBytes.isEmpty) {
        return IslamicAiResponse.failure('Recorded audio is empty. Please speak clearly.');
      }

      final uri = Uri.parse(_voiceEndpoint);

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': mimeType,
              'Accept': 'application/json',
            },
            body: audioBytes,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw http.ClientException('Connection timed out. Please check your internet.'),
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return IslamicAiResponse.fromJson(decoded);
      } else {
        debugPrint('[IslamicAiService] API error: ${response.statusCode} - ${response.body}');
        try {
          final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorJson is Map<String, dynamic> && errorJson.containsKey('error')) {
            return IslamicAiResponse.failure(errorJson['error'].toString());
          }
        } catch (_) {}
        return IslamicAiResponse.failure(
          'Could not connect to Islamic AI (${response.statusCode}). Please try again.',
        );
      }
    } catch (e) {
      debugPrint('[IslamicAiService] Request error: $e');
      return IslamicAiResponse.failure(
        'Unable to complete request. Please check your internet connection and try again.',
      );
    }
  }
}
