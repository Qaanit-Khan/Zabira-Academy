/// Zabira Academy — Kids Portal Models
/// Maps `/kids/*` OpenAPI endpoints for categories, games, quizzes, and rewards.
library;

import '../../../../core/constants/api_config.dart';

class KidsCategoryItem {
  const KidsCategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.description,
    this.badge,
  });

  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? description;
  final String? badge;

  factory KidsCategoryItem.fromJson(Map<String, dynamic> json) {
    return KidsCategoryItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? json['title']?.toString() ?? 'Category',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      description: json['description']?.toString(),
      badge: json['badge']?.toString(),
    );
  }
}

class KidsGameItem {
  const KidsGameItem({
    required this.id,
    required this.title,
    required this.slug,
    this.icon,
    this.category,
    this.shortDescription,
    this.description,
    this.thumbnail,
    this.coverImage,
    this.ageGroup = '5-12',
    this.ageLabel,
    this.difficulty = 'Easy',
    this.instructions,
    this.pointsReward = 50,
    this.gameType = 'memory',
    this.gameTypeLabel,
    this.estimatedMinutes = 5,
    this.isLocked = false,
    this.gameConfig,
  });

  final int id;
  final String title;
  final String slug;
  final String? icon;
  final String? category;
  final String? shortDescription;
  final String? description;
  final String? thumbnail;
  final String? coverImage;
  final String ageGroup;
  final String? ageLabel;
  final String difficulty;
  final String? instructions;
  final int pointsReward;
  final String gameType;
  final String? gameTypeLabel;
  final int estimatedMinutes;
  final bool isLocked;
  final Map<String, dynamic>? gameConfig;

  String? get resolvedThumbnail => ApiConfig.resolveImageUrl(thumbnail ?? coverImage);

  KidsGameItem copyWith({
    int? id,
    String? title,
    String? slug,
    String? icon,
    String? category,
    String? shortDescription,
    String? description,
    String? thumbnail,
    String? coverImage,
    String? ageGroup,
    String? ageLabel,
    String? difficulty,
    String? instructions,
    int? pointsReward,
    String? gameType,
    String? gameTypeLabel,
    int? estimatedMinutes,
    bool? isLocked,
    Map<String, dynamic>? gameConfig,
  }) {
    return KidsGameItem(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      coverImage: coverImage ?? this.coverImage,
      ageGroup: ageGroup ?? this.ageGroup,
      ageLabel: ageLabel ?? this.ageLabel,
      difficulty: difficulty ?? this.difficulty,
      instructions: instructions ?? this.instructions,
      pointsReward: pointsReward ?? this.pointsReward,
      gameType: gameType ?? this.gameType,
      gameTypeLabel: gameTypeLabel ?? this.gameTypeLabel,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isLocked: isLocked ?? this.isLocked,
      gameConfig: gameConfig ?? this.gameConfig,
    );
  }

  factory KidsGameItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? config;
    if (json['game_config'] is Map<String, dynamic>) {
      config = json['game_config'] as Map<String, dynamic>;
    }

    return KidsGameItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Islamic Game',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      category: json['category_name']?.toString() ?? json['category']?.toString(),
      shortDescription: json['short_description']?.toString(),
      description: json['description']?.toString(),
      thumbnail: json['thumbnail']?.toString() ?? json['image']?.toString(),
      coverImage: json['cover_image']?.toString() ?? json['image_url']?.toString(),
      ageGroup: json['age_group']?.toString() ?? '5-12',
      ageLabel: json['age_label']?.toString() ?? json['age_group']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      instructions: json['instructions']?.toString(),
      pointsReward: int.tryParse(json['points']?.toString() ?? json['points_reward']?.toString() ?? '50') ?? 50,
      gameType: json['game_type']?.toString() ?? 'memory',
      gameTypeLabel: json['game_type_label']?.toString(),
      estimatedMinutes: int.tryParse(json['estimated_minutes']?.toString() ?? '5') ?? 5,
      isLocked: json['is_locked'] == true || json['is_locked']?.toString() == '1',
      gameConfig: config,
    );
  }
}

class KidsQuizItem {
  const KidsQuizItem({
    required this.id,
    required this.title,
    required this.slug,
    this.category,
    this.description,
    this.thumbnail,
    this.coverImage,
    this.ageGroup = '5-12',
    this.difficulty = 'Easy',
    this.questionsCount = 5,
    this.pointsReward = 100,
    this.timeLimitMinutes = 5,
    this.isLocked = false,
  });

  final int id;
  final String title;
  final String slug;
  final String? category;
  final String? description;
  final String? thumbnail;
  final String? coverImage;
  final String ageGroup;
  final String difficulty;
  final int questionsCount;
  final int pointsReward;
  final int timeLimitMinutes;
  final bool isLocked;

  String? get resolvedThumbnail => ApiConfig.resolveImageUrl(thumbnail ?? coverImage);

  factory KidsQuizItem.fromJson(Map<String, dynamic> json) {
    return KidsQuizItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Islamic Quiz',
      slug: json['slug']?.toString() ?? '',
      category: json['category_name']?.toString() ?? json['category']?.toString(),
      description: json['description']?.toString() ?? json['short_description']?.toString(),
      thumbnail: json['thumbnail']?.toString() ?? json['image']?.toString(),
      coverImage: json['cover_image']?.toString() ?? json['image_url']?.toString(),
      ageGroup: json['age_group']?.toString() ?? '5-12',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      questionsCount: int.tryParse(json['questions_count']?.toString() ?? json['total_questions']?.toString() ?? '5') ?? 5,
      pointsReward: int.tryParse(json['points']?.toString() ?? json['points_reward']?.toString() ?? '100') ?? 100,
      timeLimitMinutes: int.tryParse(json['time_limit_minutes']?.toString() ?? '5') ?? 5,
      isLocked: json['is_locked'] == true || json['is_locked']?.toString() == '1',
    );
  }
}

class KidsQuestionItem {
  const KidsQuestionItem({
    required this.id,
    required this.question,
    required this.options,
    this.correctAnswerIndex = 0,
    this.explanation,
    this.points = 10,
  });

  final int id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final int points;

  factory KidsQuestionItem.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ?? json['choices'] ?? [];
    final opts = <String>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        opts.add(o.toString());
      }
    }

    return KidsQuestionItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      question: json['question']?.toString() ?? json['title']?.toString() ?? json['prompt']?.toString() ?? '',
      options: opts.isNotEmpty ? opts : ['Option A', 'Option B', 'Option C', 'Option D'],
      correctAnswerIndex: int.tryParse(json['correct_answer']?.toString() ?? json['correct_index']?.toString() ?? json['correct']?.toString() ?? '0') ?? 0,
      explanation: json['explanation']?.toString(),
      points: int.tryParse(json['points']?.toString() ?? '10') ?? 10,
    );
  }
}
