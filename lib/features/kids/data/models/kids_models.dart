/// Zabira Academy — Kids Portal Models
/// Maps `/kids/*` OpenAPI endpoints for categories, games, quizzes, and rewards.
library;

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
    this.category,
    this.ageGroup = '5-12',
    this.difficulty = 'Easy',
    this.instructions,
    this.pointsReward = 50,
    this.gameType = 'memory_match',
  });

  final int id;
  final String title;
  final String slug;
  final String? category;
  final String ageGroup;
  final String difficulty;
  final String? instructions;
  final int pointsReward;
  final String gameType;

  factory KidsGameItem.fromJson(Map<String, dynamic> json) {
    return KidsGameItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Islamic Game',
      slug: json['slug']?.toString() ?? '',
      category: json['category']?.toString() ?? json['category_name']?.toString(),
      ageGroup: json['age_group']?.toString() ?? '5-12 Years',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      instructions: json['instructions']?.toString(),
      pointsReward: int.tryParse(json['points_reward']?.toString() ?? '50') ?? 50,
      gameType: json['game_type']?.toString() ?? 'memory_match',
    );
  }
}

class KidsQuizItem {
  const KidsQuizItem({
    required this.id,
    required this.title,
    required this.slug,
    this.category,
    this.ageGroup = '5-12',
    this.difficulty = 'Easy',
    this.questionsCount = 5,
    this.pointsReward = 100,
    this.timeLimitMinutes = 5,
  });

  final int id;
  final String title;
  final String slug;
  final String? category;
  final String ageGroup;
  final String difficulty;
  final int questionsCount;
  final int pointsReward;
  final int timeLimitMinutes;

  factory KidsQuizItem.fromJson(Map<String, dynamic> json) {
    return KidsQuizItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Islamic Quiz',
      slug: json['slug']?.toString() ?? '',
      category: json['category']?.toString() ?? json['category_name']?.toString(),
      ageGroup: json['age_group']?.toString() ?? '5-12 Years',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      questionsCount: int.tryParse(json['questions_count']?.toString() ?? json['total_questions']?.toString() ?? '5') ?? 5,
      pointsReward: int.tryParse(json['points_reward']?.toString() ?? '100') ?? 100,
      timeLimitMinutes: int.tryParse(json['time_limit_minutes']?.toString() ?? '5') ?? 5,
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
      question: json['question']?.toString() ?? json['title']?.toString() ?? '',
      options: opts.isNotEmpty ? opts : ['Option A', 'Option B', 'Option C', 'Option D'],
      correctAnswerIndex: int.tryParse(json['correct_answer']?.toString() ?? json['correct_index']?.toString() ?? '0') ?? 0,
      explanation: json['explanation']?.toString(),
      points: int.tryParse(json['points']?.toString() ?? '10') ?? 10,
    );
  }
}
