import 'dart:convert';
import 'dart:typed_data';

/// Represents the response received from the Cloudflare Islamic AI Voice endpoint.
///
/// Response JSON structure:
/// ```json
/// {
///   "success": true,
///   "transcription": "...",
///   "answer": "...",
///   "audio": {
///     "mimeType": "audio/mpeg",
///     "format": "mp3",
///     "data": "BASE64_AUDIO_DATA"
///   }
/// }
/// ```
class IslamicAiResponse {
  final bool success;
  final String? transcription;
  final String? answer;
  final String? audioMimeType;
  final String? audioFormat;
  final String? audioBase64;
  final Uint8List? audioBytes;
  final String? error;

  const IslamicAiResponse({
    required this.success,
    this.transcription,
    this.answer,
    this.audioMimeType,
    this.audioFormat,
    this.audioBase64,
    this.audioBytes,
    this.error,
  });

  factory IslamicAiResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final transcription = json['transcription']?.toString();
    final answer = json['answer']?.toString() ?? json['text']?.toString();

    String? audioMimeType;
    String? audioFormat;
    String? audioBase64;
    Uint8List? audioBytes;

    if (json['audio'] is Map<String, dynamic>) {
      final audioMap = json['audio'] as Map<String, dynamic>;
      audioMimeType = audioMap['mimeType']?.toString() ?? 'audio/mpeg';
      audioFormat = audioMap['format']?.toString() ?? 'mp3';
      audioBase64 = audioMap['data']?.toString();

      if (audioBase64 != null && audioBase64.isNotEmpty) {
        try {
          // Clean base64 string if it has data URL prefix or whitespace/newlines
          String sanitized = audioBase64.trim();
          if (sanitized.contains(',')) {
            sanitized = sanitized.split(',').last;
          }
          sanitized = sanitized.replaceAll(RegExp(r'\s+'), '');
          audioBytes = base64Decode(sanitized);
        } catch (_) {
          audioBytes = null;
        }
      }
    }

    return IslamicAiResponse(
      success: success,
      transcription: transcription,
      answer: answer,
      audioMimeType: audioMimeType,
      audioFormat: audioFormat,
      audioBase64: audioBase64,
      audioBytes: audioBytes,
      error: json['error']?.toString() ?? (success ? null : 'Failed to process request.'),
    );
  }

  factory IslamicAiResponse.failure(String errorMessage) {
    return IslamicAiResponse(
      success: false,
      error: errorMessage,
    );
  }
}
