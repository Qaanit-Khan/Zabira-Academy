import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../home/data/models/daily_supplement_model.dart';
import '../models/nasheed_category_model.dart';
import '../models/nasheed_item_model.dart';

/// Zabira Academy — Nasheed API Service
class NasheedApiService {
  NasheedApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is List) return data;
      if (data is Map) {
        final inner = data['items'] ?? data['categories'] ?? data['nasheeds'] ?? data['records'];
        if (inner is List) return inner;
      }
      final items = decoded['items'] ?? decoded['categories'] ?? decoded['nasheeds'];
      if (items is List) return items;
    }
    return const [];
  }

  Future<List<NasheedCategoryModel>> getCategories() async {
    final candidates = [
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_categories.php'),
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_categories'),
      Uri.parse('${ApiConfig.baseUrl}/media/public_categories.php'),
    ];

    for (final uri in candidates) {
      try {
        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json', 'User-Agent': 'ZabiraAcademy-Flutter/1.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = _extractList(decoded);
          if (list.isNotEmpty) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => NasheedCategoryModel.fromJson(item))
                .toList();
          }
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<List<NasheedItemModel>> getNasheedList({int? categoryId, String? search}) async {
    final query = <String, String>{};
    if (categoryId != null) query['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) query['search'] = search;

    final candidates = [
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list.php').replace(queryParameters: query.isEmpty ? null : query),
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list').replace(queryParameters: query.isEmpty ? null : query),
      Uri.parse('${ApiConfig.baseUrl}/media/public_list.php').replace(queryParameters: query.isEmpty ? null : query),
    ];

    for (final uri in candidates) {
      try {
        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json', 'User-Agent': 'ZabiraAcademy-Flutter/1.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = _extractList(decoded);
          if (list.isNotEmpty) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => NasheedItemModel.fromJson(item))
                .toList();
          }
        }
      } catch (_) {}
    }
    return const [];
  }

  String _formatDurationValue(dynamic raw) {
    if (raw == null) return '03:42';
    final str = raw.toString().trim();
    if (str.contains(':')) return str;
    final sec = int.tryParse(str);
    if (sec != null && sec > 0) {
      final m = (sec ~/ 60).toString().padLeft(2, '0');
      final s = (sec % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    return str.isNotEmpty ? str : '03:42';
  }

  Future<DailySupplementModel> getDailyNasheed() async {
    // 1. Primary mobile endpoint connected directly to Admin Daily Audio
    try {
      final primaryUri = Uri.parse('${ApiConfig.baseUrl}/mobile/daily_audio.php');
      debugPrint('[NASHEED API] GET $primaryUri');
      final res = await _client.get(
        primaryUri,
        headers: {'Accept': 'application/json', 'User-Agent': 'ZabiraAcademy-Flutter/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          final item = (data is Map<String, dynamic> ? data['item'] : null) ??
              (data is Map<String, dynamic> ? data : null) ??
              (decoded['item'] is Map<String, dynamic> ? decoded['item'] : null);

          if (item is Map<String, dynamic> && item.isNotEmpty) {
            final title = item['title']?.toString() ?? item['name']?.toString() ?? 'Daily Nasheed';
            final artist = item['artist']?.toString() ?? item['reciter']?.toString() ?? 'Zabira Audio';
            final rawDuration = _formatDurationValue(item['duration'] ?? item['duration_formatted']);
            final cover = item['cover_image']?.toString() ??
                item['thumbnail']?.toString() ??
                item['image']?.toString() ??
                item['image_url']?.toString();
            final audio = item['audio_url']?.toString() ??
                item['file_url']?.toString() ??
                item['stream_url']?.toString() ??
                item['audio']?.toString() ??
                item['path']?.toString();

            final resolvedAudio = ApiConfig.resolveMediaUrl(audio);

            if (resolvedAudio != null && resolvedAudio.isNotEmpty) {
              return DailySupplementModel(
                sectionLabel: 'DAILY NASHEED',
                contentTitle: title,
                contentType: artist,
                duration: rawDuration,
                progress: 0.35,
                artType: DailySupplementArtType.nasheed,
                imageUrl: ApiConfig.resolveImageUrl(cover),
                audioUrl: resolvedAudio,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[NASHEED API EXCEPTION daily_audio.php] $e');
    }

    final candidates = [
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list.php?limit=1'),
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list?limit=1'),
      Uri.parse('${ApiConfig.baseUrl}/media/public_list.php?limit=1'),
    ];

    for (final uri in candidates) {
      try {
        debugPrint('[NASHEED API] GET $uri');
        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json', 'User-Agent': 'ZabiraAcademy-Flutter/1.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = _extractList(decoded);

          if (list.isNotEmpty) {
            final item = list.first as Map<String, dynamic>;
            final title = item['title']?.toString() ?? item['name']?.toString() ?? 'Daily Nasheed';
            final artist = item['artist']?.toString() ?? item['reciter']?.toString() ?? 'Zabira Audio';
            final rawDuration = _formatDurationValue(item['duration'] ?? item['duration_formatted']);
            final cover = item['cover_image']?.toString() ?? item['thumbnail']?.toString() ?? item['image']?.toString() ?? item['image_url']?.toString();
            final audio = item['audio_url']?.toString() ?? item['file_url']?.toString() ?? item['stream_url']?.toString();

            final resolvedAudio = ApiConfig.resolveMediaUrl(audio);

            return DailySupplementModel(
              sectionLabel: 'DAILY NASHEED',
              contentTitle: title,
              contentType: artist,
              duration: rawDuration,
              progress: 0.35,
              artType: DailySupplementArtType.nasheed,
              imageUrl: ApiConfig.resolveImageUrl(cover),
              audioUrl: resolvedAudio,
            );
          }
        }
      } catch (e) {
        debugPrint('[NASHEED API EXCEPTION] $uri -> $e');
      }
    }

    // Graceful fallback to default local curated track if offline or empty
    return const DailySupplementModel(
      sectionLabel: 'DAILY NASHEED',
      contentTitle: 'Allah Knows',
      contentType: 'Zabira Vocals',
      duration: '03:42',
      progress: 0.42,
      artType: DailySupplementArtType.nasheed,
      audioUrl: 'https://api.zabiraacademy.com/uploads/audio/Dua-Ki-Taakat-by-Zabira-Academy.mp3',
    );
  }
}
