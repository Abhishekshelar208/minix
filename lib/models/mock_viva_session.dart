import 'viva_question.dart';

class MockVivaSession {
  final String id;
  final String projectId;
  final String sessionName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<VivaQuestionAttempt> questionAttempts;
  final MockVivaSettings settings;
  final VivaSessionStatus status;
  final double? overallScore;
  final String? feedback;
  final int totalTimeSeconds;

  const MockVivaSession({
    required this.id,
    required this.projectId,
    required this.sessionName,
    required this.startTime,
    this.endTime,
    required this.questionAttempts,
    required this.settings,
    required this.status,
    this.overallScore,
    this.feedback,
    this.totalTimeSeconds = 0,
  });

  factory MockVivaSession.fromJson(Map<String, dynamic> json) {
    return MockVivaSession(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      sessionName: (json['sessionName'] ?? '').toString(),
      startTime: DateTime.parse((json['startTime'] ?? '').toString()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'].toString()) : null,
      questionAttempts: (json['questionAttempts'] as List<dynamic>?)
              ?.map((q) => VivaQuestionAttempt.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      settings: MockVivaSettings.fromJson((json['settings'] as Map<String, dynamic>?) ?? {}),
      status: VivaSessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? '').toString(),
        orElse: () => VivaSessionStatus.notStarted,
      ),
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      feedback: json['feedback']?.toString(),
      totalTimeSeconds: (json['totalTimeSeconds'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sessionName': sessionName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'questionAttempts': questionAttempts.map((q) => q.toJson()).toList(),
      'settings': settings.toJson(),
      'status': status.toString().split('.').last,
      'overallScore': overallScore,
      'feedback': feedback,
      'totalTimeSeconds': totalTimeSeconds,
    };
  }

  MockVivaSession copyWith({
    String? id,
    String? projectId,
    String? sessionName,
    DateTime? startTime,
    DateTime? endTime,
    List<VivaQuestionAttempt>? questionAttempts,
    MockVivaSettings? settings,
    VivaSessionStatus? status,
    double? overallScore,
    String? feedback,
    int? totalTimeSeconds,
  }) {
    return MockVivaSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sessionName: sessionName ?? this.sessionName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      questionAttempts: questionAttempts ?? this.questionAttempts,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      overallScore: overallScore ?? this.overallScore,
      feedback: feedback ?? this.feedback,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
    );
  }

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }

  bool get isCompleted => status == VivaSessionStatus.completed;
  bool get isInProgress => status == VivaSessionStatus.inProgress;

  double get averageScore {
    if (questionAttempts.isEmpty) return 0.0;
    final scoredAttempts = questionAttempts.where((a) => a.score != null);
    if (scoredAttempts.isEmpty) return 0.0;
    
    return scoredAttempts
            .map((a) => a.score!)
            .reduce((a, b) => a + b) /
        scoredAttempts.length;
  }
}

class VivaQuestionAttempt {
  final String questionId;
  final VivaQuestion question;
  final DateTime startTime;
  final DateTime? endTime;
  final String? userAnswer;
  final double? score;
  final String? feedback;
  final bool skipped;
  final List<String> hints;

  const VivaQuestionAttempt({
    required this.questionId,
    required this.question,
    required this.startTime,
    this.endTime,
    this.userAnswer,
    this.score,
    this.feedback,
    this.skipped = false,
    this.hints = const [],
  });

  factory VivaQuestionAttempt.fromJson(Map<String, dynamic> json) {
    return VivaQuestionAttempt(
      questionId: (json['questionId'] ?? '').toString(),
      question: VivaQuestion.fromJson((json['question'] as Map<String, dynamic>?) ?? {}),
      startTime: DateTime.parse((json['startTime'] ?? '').toString()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'].toString()) : null,
      userAnswer: json['userAnswer']?.toString(),
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback']?.toString(),
      skipped: (json['skipped'] as bool?) ?? false,
      hints: (json['hints'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'userAnswer': userAnswer,
      'score': score,
      'feedback': feedback,
      'skipped': skipped,
      'hints': hints,
    };
  }

  Duration get timeSpent {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }

  bool get isAnswered => userAnswer != null && userAnswer!.isNotEmpty;
  bool get isScored => score != null;
}

class MockVivaSettings {
  final int totalQuestions;
  final int timePerQuestionMinutes;
  final List<VivaQuestionCategory> categories;
  final List<DifficultyLevel> difficulties;
  final bool allowSkipping;
  final bool showHints;
  final bool recordAnswers;
  final bool autoNext;

  const MockVivaSettings({
    this.totalQuestions = 10,
    this.timePerQuestionMinutes = 3,
    this.categories = const [],
    this.difficulties = const [],
    this.allowSkipping = true,
    this.showHints = true,
    this.recordAnswers = false,
    this.autoNext = false,
  });

  factory MockVivaSettings.fromJson(Map<String, dynamic> json) {
    return MockVivaSettings(
      totalQuestions: (json['totalQuestions'] as int?) ?? 10,
      timePerQuestionMinutes: (json['timePerQuestionMinutes'] as int?) ?? 3,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((c) => VivaQuestionCategory.values.firstWhere(
                    (e) => e.toString().split('.').last == c.toString(),
                    orElse: () => VivaQuestionCategory.technical,
                  ))
              .toList() ??
          [],
      difficulties: (json['difficulties'] as List<dynamic>?)
              ?.map((d) => DifficultyLevel.values.firstWhere(
                    (e) => e.toString().split('.').last == d.toString(),
                    orElse: () => DifficultyLevel.medium,
                  ))
              .toList() ??
          [],
      allowSkipping: (json['allowSkipping'] as bool?) ?? true,
      showHints: (json['showHints'] as bool?) ?? true,
      recordAnswers: (json['recordAnswers'] as bool?) ?? false,
      autoNext: (json['autoNext'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'timePerQuestionMinutes': timePerQuestionMinutes,
      'categories': categories.map((c) => c.toString().split('.').last).toList(),
      'difficulties': difficulties.map((d) => d.toString().split('.').last).toList(),
      'allowSkipping': allowSkipping,
      'showHints': showHints,
      'recordAnswers': recordAnswers,
      'autoNext': autoNext,
    };
  }

  MockVivaSettings copyWith({
    int? totalQuestions,
    int? timePerQuestionMinutes,
    List<VivaQuestionCategory>? categories,
    List<DifficultyLevel>? difficulties,
    bool? allowSkipping,
    bool? showHints,
    bool? recordAnswers,
    bool? autoNext,
  }) {
    return MockVivaSettings(
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timePerQuestionMinutes: timePerQuestionMinutes ?? this.timePerQuestionMinutes,
      categories: categories ?? this.categories,
      difficulties: difficulties ?? this.difficulties,
      allowSkipping: allowSkipping ?? this.allowSkipping,
      showHints: showHints ?? this.showHints,
      recordAnswers: recordAnswers ?? this.recordAnswers,
      autoNext: autoNext ?? this.autoNext,
    );
  }
}

enum VivaSessionStatus {
  notStarted,
  inProgress,
  completed,
  paused,
  cancelled
}

extension VivaSessionStatusExtension on VivaSessionStatus {
  String get displayName {
    switch (this) {
      case VivaSessionStatus.notStarted:
        return 'Not Started';
      case VivaSessionStatus.inProgress:
        return 'In Progress';
      case VivaSessionStatus.completed:
        return 'Completed';
      case VivaSessionStatus.paused:
        return 'Paused';
      case VivaSessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}