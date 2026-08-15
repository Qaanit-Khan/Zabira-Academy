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

  Future<List<NasheedCategoryModel>> getCategories() async {
    final candidates = [
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_categories'),
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_categories.php'),
      Uri.parse('${ApiConfig.baseUrl}/media/public_categories'),
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
          final list = decoded['data'] ?? decoded['categories'] ?? decoded;
          if (list is List) {
            return list
                .map((item) => NasheedCategoryModel.fromJson(item as Map<String, dynamic>))
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
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list').replace(queryParameters: query.isEmpty ? null : query),
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list.php').replace(queryParameters: query.isEmpty ? null : query),
      Uri.parse('${ApiConfig.baseUrl}/media/public_list').replace(queryParameters: query.isEmpty ? null : query),
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
          final list = decoded['data'] ?? decoded['items'] ?? decoded['nasheeds'] ?? decoded;
          if (list is List) {
            return list
                .map((item) => NasheedItemModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<DailySupplementModel> getDailyNasheed() async {
    final candidates = [
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list?limit=1'),
      Uri.parse('${ApiConfig.baseUrl}/nasheed/public_list.php?limit=1'),
      Uri.parse('${ApiConfig.baseUrl}/media/public_list?limit=1'),
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
          final list = decoded['data'] ?? decoded['items'] ?? decoded['nasheeds'] ?? decoded;

          if (list is List && list.isNotEmpty) {
            final item = list.first as Map<String, dynamic>;
            final title = item['title']?.toString() ?? item['name']?.toString() ?? 'Daily Nasheed';
            final artist = item['artist']?.toString() ?? item['reciter']?.toString() ?? 'Zabira Audio';
            final rawDuration = item['duration']?.toString() ?? item['duration_formatted']?.toString() ?? '04:12';
            final cover = item['cover_image']?.toString() ?? item['thumbnail']?.toString() ?? item['image']?.toString();
            final audio = item['audio_url']?.toString() ?? item['file_url']?.toString() ?? item['stream_url']?.toString();

            return DailySupplementModel(
              sectionLabel: 'DAILY NASHEED',
              contentTitle: title,
              contentType: artist,
              duration: rawDuration,
              progress: 0.35,
              artType: DailySupplementArtType.nasheed,
              imageUrl: ApiConfig.resolveImageUrl(cover),
              audioUrl: audio,
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
    );
  }
}
