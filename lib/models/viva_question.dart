class VivaQuestion {
  final String id;
  final String question;
  final List<String> possibleAnswers;
  final String suggestedAnswer;
  final VivaQuestionCategory category;
  final DifficultyLevel difficulty;
  final List<String> keywords;
  final int estimatedTimeMinutes;
  final String? context;
  final List<String> followUpQuestions;

  const VivaQuestion({
    required this.id,
    required this.question,
    required this.possibleAnswers,
    required this.suggestedAnswer,
    required this.category,
    required this.difficulty,
    required this.keywords,
    this.estimatedTimeMinutes = 2,
    this.context,
    this.followUpQuestions = const [],
  });

  factory VivaQuestion.fromJson(Map<String, dynamic> json) {
    return VivaQuestion(
      id: (json['id'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      possibleAnswers: _parseStringList(json['possibleAnswers']),
      suggestedAnswer: (json['suggestedAnswer'] as String?) ?? '',
      category: VivaQuestionCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] as String?),
        orElse: () => VivaQuestionCategory.technical,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (json['difficulty'] as String?),
        orElse: () => DifficultyLevel.medium,
      ),
      keywords: _parseStringList(json['keywords']),
      estimatedTimeMinutes: (json['estimatedTimeMinutes'] as int?) ?? 2,
      context: json['context'] as String?,
      followUpQuestions: _parseStringList(json['followUpQuestions']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'possibleAnswers': possibleAnswers,
      'suggestedAnswer': suggestedAnswer,
      'category': category.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'keywords': keywords,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'context': context,
      'followUpQuestions': followUpQuestions,
    };
  }

  VivaQuestion copyWith({
    String? id,
    String? question,
    List<String>? possibleAnswers,
    String? suggestedAnswer,
    VivaQuestionCategory? category,
    DifficultyLevel? difficulty,
    List<String>? keywords,
    int? estimatedTimeMinutes,
    String? context,
    List<String>? followUpQuestions,
  }) {
    return VivaQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      possibleAnswers: possibleAnswers ?? this.possibleAnswers,
      suggestedAnswer: suggestedAnswer ?? this.suggestedAnswer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      keywords: keywords ?? this.keywords,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      context: context ?? this.context,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
    );
  }
}

enum VivaQuestionCategory {
  technical,
  conceptual,
  implementation,
  projectSpecific,
  architecture,
  testing,
  deployment,
  problemSolving,
  futureEnhancements,
  learningOutcome
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert
}

extension VivaQuestionCategoryExtension on VivaQuestionCategory {
  String get displayName {
    switch (this) {
      case VivaQuestionCategory.technical:
        return 'Technical';
      case VivaQuestionCategory.conceptual:
        return 'Conceptual';
      case VivaQuestionCategory.implementation:
        return 'Implementation';
      case VivaQuestionCategory.projectSpecific:
        return 'Project Specific';
      case VivaQuestionCategory.architecture:
        return 'Architecture';
      case VivaQuestionCategory.testing:
        return 'Testing';
      case VivaQuestionCategory.deployment:
        return 'Deployment';
      case VivaQuestionCategory.problemSolving:
        return 'Problem Solving';
      case VivaQuestionCategory.futureEnhancements:
        return 'Future Enhancements';
      case VivaQuestionCategory.learningOutcome:
        return 'Learning Outcome';
    }
  }

  String get description {
    switch (this) {
      case VivaQuestionCategory.technical:
        return 'Questions about technologies, frameworks, and tools used';
      case VivaQuestionCategory.conceptual:
        return 'Understanding of core concepts and principles';
      case VivaQuestionCategory.implementation:
        return 'How you implemented specific features and functionality';
      case VivaQuestionCategory.projectSpecific:
        return 'Questions unique to your project domain and problem';
      case VivaQuestionCategory.architecture:
        return 'System design, structure, and architectural decisions';
      case VivaQuestionCategory.testing:
        return 'Testing strategies, quality assurance, and validation';
      case VivaQuestionCategory.deployment:
        return 'Deployment process, hosting, and production considerations';
      case VivaQuestionCategory.problemSolving:
        return 'How you approached and solved challenges';
      case VivaQuestionCategory.futureEnhancements:
        return 'Improvements, scalability, and future development';
      case VivaQuestionCategory.learningOutcome:
        return 'What you learned and how it applies to your field';
    }
  }
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Basic questions about the project';
      case DifficultyLevel.medium:
        return 'Moderate questions requiring some detail';
      case DifficultyLevel.hard:
        return 'Complex questions requiring deep understanding';
      case DifficultyLevel.expert:
        return 'Advanced questions for exceptional students';
    }
  }
}