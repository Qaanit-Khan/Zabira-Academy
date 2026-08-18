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
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.description,
    this.instructions,
    this.thumbnail,
    this.coverImage,
    this.icon,
    this.ageGroup = '7-9',
    this.ageLabel = '7-9',
    this.difficulty = 'Easy',
    this.questionsCount = 0,
    this.timeLimitSeconds = 0,
    this.passingScore = 60,
    this.pointsReward = 100,
    this.isLocked = false,
    this.featured = false,
    this.allowRetakes = true,
    this.randomizeQuestions = false,
    this.randomizeAnswers = false,
    this.showCorrectAfter = true,
    this.attemptCount = 0,
    this.publishStatus = 'published',
    this.displayOrder = 0,
    this.questions = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String? category;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String? description;
  final String? instructions;
  final String? thumbnail;
  final String? coverImage;
  final String? icon;
  final String ageGroup;
  final String ageLabel;
  final String difficulty;
  final int questionsCount;
  final int timeLimitSeconds;
  final int passingScore;
  final int pointsReward;
  final bool isLocked;
  final bool featured;
  final bool allowRetakes;
  final bool randomizeQuestions;
  final bool randomizeAnswers;
  final bool showCorrectAfter;
  final int attemptCount;
  final String publishStatus;
  final int displayOrder;
  final List<KidsQuestionItem> questions;

  String? get resolvedThumbnail => ApiConfig.resolveImageUrl(thumbnail ?? coverImage);
  String? get resolvedCoverImage => ApiConfig.resolveImageUrl(coverImage ?? thumbnail);

  /// Duration formatted as "X Min" or "X Sec"
  String get durationLabel {
    if (timeLimitSeconds <= 0) return 'Untimed';
    final minutes = timeLimitSeconds ~/ 60;
    final seconds = timeLimitSeconds % 60;
    if (minutes > 0 && seconds == 0) return '$minutes Min';
    if (minutes > 0) return '$minutes m $seconds s';
    return '$seconds Sec';
  }

  KidsQuizItem copyWith({
    int? id,
    String? title,
    String? slug,
    String? category,
    int? categoryId,
    String? categoryName,
    String? categorySlug,
    String? description,
    String? instructions,
    String? thumbnail,
    String? coverImage,
    String? icon,
    String? ageGroup,
    String? ageLabel,
    String? difficulty,
    int? questionsCount,
    int? timeLimitSeconds,
    int? passingScore,
    int? pointsReward,
    bool? isLocked,
    bool? featured,
    bool? allowRetakes,
    bool? randomizeQuestions,
    bool? randomizeAnswers,
    bool? showCorrectAfter,
    int? attemptCount,
    String? publishStatus,
    int? displayOrder,
    List<KidsQuestionItem>? questions,
  }) {
    return KidsQuizItem(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      thumbnail: thumbnail ?? this.thumbnail,
      coverImage: coverImage ?? this.coverImage,
      icon: icon ?? this.icon,
      ageGroup: ageGroup ?? this.ageGroup,
      ageLabel: ageLabel ?? this.ageLabel,
      difficulty: difficulty ?? this.difficulty,
      questionsCount: questionsCount ?? this.questionsCount,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      passingScore: passingScore ?? this.passingScore,
      pointsReward: pointsReward ?? this.pointsReward,
      isLocked: isLocked ?? this.isLocked,
      featured: featured ?? this.featured,
      allowRetakes: allowRetakes ?? this.allowRetakes,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      randomizeAnswers: randomizeAnswers ?? this.randomizeAnswers,
      showCorrectAfter: showCorrectAfter ?? this.showCorrectAfter,
      attemptCount: attemptCount ?? this.attemptCount,
      publishStatus: publishStatus ?? this.publishStatus,
      displayOrder: displayOrder ?? this.displayOrder,
      questions: questions ?? this.questions,
    );
  }

  factory KidsQuizItem.fromJson(Map<String, dynamic> json) {
    // Parse nested questions if present
    final rawQuestions = json['questions'];
    final questionList = <KidsQuestionItem>[];
    if (rawQuestions is List) {
      for (final q in rawQuestions) {
        if (q is Map<String, dynamic>) {
          questionList.add(KidsQuestionItem.fromJson(q));
        }
      }
    }

    final catName = json['category_name']?.toString() ?? json['category']?.toString();
    final qCount = int.tryParse(json['question_count']?.toString() ?? json['questions_count']?.toString() ?? json['total_questions']?.toString() ?? '') ?? questionList.length;

    return KidsQuizItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Islamic Quiz',
      slug: json['slug']?.toString() ?? '',
      category: catName,
      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: catName,
      categorySlug: json['category_slug']?.toString(),
      description: json['description']?.toString() ?? json['short_description']?.toString(),
      instructions: json['instructions']?.toString(),
      thumbnail: json['thumbnail']?.toString() ?? json['image']?.toString(),
      coverImage: json['cover_image']?.toString() ?? json['image_url']?.toString(),
      icon: json['icon']?.toString(),
      ageGroup: json['age_group']?.toString() ?? '7-9',
      ageLabel: json['age_label']?.toString() ?? json['age_group']?.toString() ?? '7-9',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      questionsCount: qCount,
      timeLimitSeconds: int.tryParse(json['time_limit_seconds']?.toString() ?? json['duration_seconds']?.toString() ?? '') ?? ((int.tryParse(json['time_limit_minutes']?.toString() ?? '') ?? 0) * 60),
      passingScore: int.tryParse(json['passing_score']?.toString() ?? '60') ?? 60,
      pointsReward: int.tryParse(json['points']?.toString() ?? json['points_reward']?.toString() ?? '100') ?? 100,
      isLocked: json['is_locked'] == true || json['is_locked']?.toString() == '1',
      featured: json['featured'] == true || json['featured']?.toString() == '1',
      allowRetakes: json['allow_retakes'] != false && json['allow_retakes']?.toString() != '0',
      randomizeQuestions: json['randomize_questions'] == true || json['randomize_questions']?.toString() == '1',
      randomizeAnswers: json['randomize_answers'] == true || json['randomize_answers']?.toString() == '1',
      showCorrectAfter: json['show_correct_after'] != false && json['show_correct_after']?.toString() != '0',
      attemptCount: int.tryParse(json['attempt_count']?.toString() ?? '0') ?? 0,
      publishStatus: json['publish_status']?.toString() ?? 'published',
      displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
      questions: questionList,
    );
  }
}

/// Option within a question
class KidsQuestionOption {
  const KidsQuestionOption({
    required this.id,
    required this.text,
    this.correct,
    this.image,
  });

  final String id;
  final String text;
  final bool? correct;
  final String? image;

  factory KidsQuestionOption.fromJson(Map<String, dynamic> json) {
    return KidsQuestionOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? json['title']?.toString() ?? json['option']?.toString() ?? '',
      correct: json['correct'] == true || json['correct']?.toString() == '1',
      image: json['image']?.toString() ?? json['image_url']?.toString(),
    );
  }
}

/// A single Question in a quiz
class KidsQuestionItem {
  const KidsQuestionItem({
    required this.id,
    required this.question,
    required this.questionType,
    required this.options,
    this.points = 1,
    this.mediaType,
    this.mediaUrl,
    this.displayOrder = 0,
    this.explanation,
    this.correctAnswers = const [],
  });

  final int id;
  final String question;
  final String questionType; // mcq, multi, true_false, matching, ordering, etc.
  final List<KidsQuestionOption> options;
  final int points;
  final String? mediaType;
  final String? mediaUrl;
  final int displayOrder;
  final String? explanation;
  final List<String> correctAnswers;

  String? get resolvedMediaUrl => ApiConfig.resolveImageUrl(mediaUrl);

  bool get isImageQuestion => mediaType == 'image' || (mediaUrl != null && mediaUrl!.isNotEmpty);

  factory KidsQuestionItem.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'] ?? json['choices'];
    final parsedOptions = <KidsQuestionOption>[];

    if (rawOpts is List) {
      for (int i = 0; i < rawOpts.length; i++) {
        final opt = rawOpts[i];
        if (opt is Map<String, dynamic>) {
          parsedOptions.add(KidsQuestionOption.fromJson(opt));
        } else if (opt is String) {
          final id = String.fromCharCode(97 + i); // 'a', 'b', 'c'...
          parsedOptions.add(KidsQuestionOption(id: id, text: opt));
        }
      }
    }

    final rawCorrect = json['correct'] ?? json['correct_answers'];
    final parsedCorrect = <String>[];
    if (rawCorrect is List) {
      for (final c in rawCorrect) {
        if (c != null) parsedCorrect.add(c.toString());
      }
    } else if (rawCorrect is String && rawCorrect.isNotEmpty) {
      parsedCorrect.add(rawCorrect);
    }

    final prompt = json['question_text']?.toString() ?? json['question']?.toString() ?? json['title']?.toString() ?? json['prompt']?.toString() ?? '';

    return KidsQuestionItem(
      id: int.tryParse(json['id']?.toString() ?? json['question_id']?.toString() ?? '0') ?? 0,
      question: prompt,
      questionType: (json['question_type']?.toString() ?? json['type']?.toString() ?? 'mcq').toLowerCase(),
      options: parsedOptions,
      points: int.tryParse(json['points']?.toString() ?? '1') ?? 1,
      mediaType: json['media_type']?.toString(),
      mediaUrl: json['media_url']?.toString() ?? json['image']?.toString() ?? json['image_url']?.toString(),
      displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
      explanation: json['explanation']?.toString(),
      correctAnswers: parsedCorrect,
    );
  }
}

/// Answer submission item sent to `quiz_submit.php`
class QuizSubmitAnswer {
  const QuizSubmitAnswer({
    required this.questionId,
    required this.selected,
  });

  final int questionId;
  final List<String> selected;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'selected': selected,
      };
}

/// Option inside question review
class QuizReviewOption {
  const QuizReviewOption({
    required this.id,
    required this.text,
    required this.correct,
  });

  final String id;
  final String text;
  final bool correct;

  factory QuizReviewOption.fromJson(Map<String, dynamic> json) {
    return QuizReviewOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      correct: json['correct'] == true || json['correct']?.toString() == '1',
    );
  }
}

/// Review item returned by `quiz_submit.php`
class QuizReviewItem {
  const QuizReviewItem({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.selected,
    required this.isCorrect,
    required this.points,
    required this.earned,
    required this.correct,
    this.explanation,
    this.options = const [],
  });

  final int questionId;
  final String questionText;
  final String questionType;
  final List<String> selected;
  final bool isCorrect;
  final int points;
  final int earned;
  final List<String> correct;
  final String? explanation;
  final List<QuizReviewOption> options;

  factory QuizReviewItem.fromJson(Map<String, dynamic> json) {
    final rawSel = json['selected'] as List? ?? [];
    final rawCor = json['correct'] as List? ?? [];
    final rawOpts = json['options'] as List? ?? [];

    return QuizReviewItem(
      questionId: int.tryParse(json['question_id']?.toString() ?? '0') ?? 0,
      questionText: json['question_text']?.toString() ?? json['question']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? 'mcq',
      selected: rawSel.map((e) => e.toString()).toList(),
      isCorrect: json['is_correct'] == true || json['is_correct']?.toString() == '1',
      points: int.tryParse(json['points']?.toString() ?? '1') ?? 1,
      earned: int.tryParse(json['earned']?.toString() ?? '0') ?? 0,
      correct: rawCor.map((e) => e.toString()).toList(),
      explanation: json['explanation']?.toString(),
      options: rawOpts
          .whereType<Map<String, dynamic>>()
          .map(QuizReviewOption.fromJson)
          .toList(),
    );
  }
}

/// Complete submission result returned by `quiz_submit.php`
class QuizSubmitResult {
  const QuizSubmitResult({
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.correctCount,
    required this.incorrectCount,
    required this.passed,
    required this.timeTakenSeconds,
    this.showCorrectAfter = true,
    this.alreadySubmitted = false,
    this.review = const [],
    this.feedbackMessage,
  });

  final int score;
  final int maxScore;
  final int percentage;
  final int correctCount;
  final int incorrectCount;
  final bool passed;
  final int timeTakenSeconds;
  final bool showCorrectAfter;
  final bool alreadySubmitted;
  final List<QuizReviewItem> review;
  final String? feedbackMessage;

  String get formattedTime {
    final m = timeTakenSeconds ~/ 60;
    final s = timeTakenSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'] as List? ?? [];
    final parsedReview = rawReview
        .whereType<Map<String, dynamic>>()
        .map(QuizReviewItem.fromJson)
        .toList();

    return QuizSubmitResult(
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      maxScore: int.tryParse(json['max_score']?.toString() ?? '10') ?? 10,
      percentage: int.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
      incorrectCount: int.tryParse(json['incorrect_count']?.toString() ?? '0') ?? 0,
      passed: json['passed'] == true || json['passed']?.toString() == '1',
      timeTakenSeconds: int.tryParse(json['time_taken_seconds']?.toString() ?? '0') ?? 0,
      showCorrectAfter: json['show_correct_after'] != false && json['show_correct_after']?.toString() != '0',
      alreadySubmitted: json['already_submitted'] == true,
      review: parsedReview,
      feedbackMessage: json['message']?.toString(),
    );
  }
}

/// Zabira Academy — Kids Story Model
class KidsStoryItem {
  const KidsStoryItem({
    required this.id,
    required this.title,
    required this.slug,
    this.coverImage,
    this.thumbnail,
    this.categoryName,
    this.categorySlug,
    this.shortDescription,
    this.description,
    this.content,
    this.ageGroup = '4-12',
    this.ageLabel = '4–12',
    this.readTimeMinutes = 5,
    this.prophetName,
    this.isFeatured = false,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String slug;
  final String? coverImage;
  final String? thumbnail;
  final String? categoryName;
  final String? categorySlug;
  final String? shortDescription;
  final String? description;
  final String? content;
  final String ageGroup;
  final String ageLabel;
  final int readTimeMinutes;
  final String? prophetName;
  final bool isFeatured;
  final DateTime? publishedAt;

  String? get resolvedCoverImage => ApiConfig.resolveImageUrl(coverImage);
  String? get resolvedThumbnail => ApiConfig.resolveImageUrl(thumbnail);
  String get readTimeLabel => '$readTimeMinutes min read';

  factory KidsStoryItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['story_id'] ?? 0;
    final id = int.tryParse(rawId.toString()) ?? 0;
    final title = json['title']?.toString() ?? json['name']?.toString() ?? 'Story';
    final slug = json['slug']?.toString() ?? '';
    final cover = json['cover_image']?.toString() ?? json['image']?.toString() ?? json['banner']?.toString();
    final thumb = json['thumbnail']?.toString();
    final catName = json['category_name']?.toString() ?? json['category']?.toString();
    final catSlug = json['category_slug']?.toString();
    final shortDesc = json['short_description']?.toString() ?? json['summary']?.toString();
    final desc = json['description']?.toString();
    final content = json['content']?.toString() ?? json['body']?.toString() ?? desc;
    final ageGroup = json['age_group']?.toString() ?? '4-12';
    final ageLabel = json['age_label']?.toString() ?? ageGroup;
    final readTime = int.tryParse(json['read_time_minutes']?.toString() ?? json['read_time']?.toString() ?? '5') ?? 5;
    final prophet = json['prophet_name']?.toString() ?? json['prophet']?.toString();
    final featured = json['is_featured'] == 1 || json['is_featured'] == true || json['featured'] == true;
    final pubAt = DateTime.tryParse(json['published_at']?.toString() ?? json['created_at']?.toString() ?? '');

    return KidsStoryItem(
      id: id,
      title: title,
      slug: slug,
      coverImage: cover,
      thumbnail: thumb,
      categoryName: catName,
      categorySlug: catSlug,
      shortDescription: shortDesc,
      description: desc,
      content: content,
      ageGroup: ageGroup,
      ageLabel: ageLabel,
      readTimeMinutes: readTime,
      prophetName: prophet,
      isFeatured: featured,
      publishedAt: pubAt,
    );
  }
}
