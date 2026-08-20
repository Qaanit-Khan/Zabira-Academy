import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:zabira_academy/features/islamic_ai/data/models/islamic_ai_response.dart';

void main() {
  group('IslamicAiResponse Tests', () {
    test('parses successful Cloudflare response correctly with base64 audio', () {
      final sampleAudioBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final base64Audio = base64Encode(sampleAudioBytes);

      final json = {
        'success': true,
        'transcription': 'What is Salah?',
        'answer': 'Salah is the second pillar of Islam.',
        'audio': {
          'mimeType': 'audio/mpeg',
          'format': 'mp3',
          'data': base64Audio,
        },
      };

      final response = IslamicAiResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.transcription, equals('What is Salah?'));
      expect(response.answer, equals('Salah is the second pillar of Islam.'));
      expect(response.audioMimeType, equals('audio/mpeg'));
      expect(response.audioFormat, equals('mp3'));
      expect(response.audioBytes, isNotNull);
      expect(response.audioBytes, equals(sampleAudioBytes));
      expect(response.error, isNull);
    });

    test('parses greeting response with text field correctly', () {
      final sampleAudioBytes = Uint8List.fromList([10, 20, 30]);
      final base64Audio = base64Encode(sampleAudioBytes);

      final json = {
        'success': true,
        'text': 'Assalamu Alaikum Qaanit, Aap Islam ke related kya puchna chahoge?',
        'audio': {
          'mimeType': 'audio/mpeg',
          'format': 'mp3',
          'data': base64Audio,
        },
      };

      final response = IslamicAiResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.answer, equals('Assalamu Alaikum Qaanit, Aap Islam ke related kya puchna chahoge?'));
      expect(response.audioBytes, equals(sampleAudioBytes));
    });

    test('handles failure response cleanly', () {
      final json = {
        'success': false,
        'error': 'Speech could not be recognized.',
      };

      final response = IslamicAiResponse.fromJson(json);

      expect(response.success, isFalse);
      expect(response.error, equals('Speech could not be recognized.'));
      expect(response.transcription, isNull);
      expect(response.audioBytes, isNull);
    });

    test('handles failure helper factory', () {
      final response = IslamicAiResponse.failure('Network timeout');
      expect(response.success, isFalse);
      expect(response.error, equals('Network timeout'));
    });
  });
}
