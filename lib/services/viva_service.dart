import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/viva_question.dart';
import '../models/mock_viva_session.dart';
import '../models/presentation_tip.dart';
import '../models/solution.dart';
import '../models/project_roadmap.dart';
import '../config/secrets.dart';

class VivaService {
  static final VivaService _instance = VivaService._internal();
  factory VivaService() => _instance;
  VivaService._internal();

  late final GenerativeModel _model;
  final List<VivaQuestion> _questionBank = [];
  final List<MockVivaSession> _mockSessions = [];
  final List<PresentationTip> _presentationTips = [];

  void initialize() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: Secrets.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 4096,
      ),
    );
    _initializePresentationTips();
  }

  // Question Generation
  Future<List<VivaQuestion>> generateProjectSpecificQuestions({
    required ProjectSolution solution,
    required ProjectRoadmap roadmap,
    int count = 15,
    List<VivaQuestionCategory>? categories,
    List<DifficultyLevel>? difficulties,
  }) async {
    try {
      final prompt = _buildQuestionGenerationPrompt(
        solution: solution,
        roadmap: roadmap,
        count: count,
        categories: categories,
        difficulties: difficulties,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        return _parseGeneratedQuestions(response.text!);
      }
      return [];
    } catch (e) {
      debugPrint('Error generating questions: $e');
      return [];
    }
  }

  String _buildQuestionGenerationPrompt({
    required ProjectSolution solution,
    required ProjectRoadmap roadmap,
    required int count,
    List<VivaQuestionCategory>? categories,
    List<DifficultyLevel>? difficulties,
  }) {
    final categoriesText = categories?.map((c) => c.displayName).join(', ') ?? 'all categories';
    final difficultiesText = difficulties?.map((d) => d.displayName).join(', ') ?? 'mixed difficulties';

    return '''
You are an expert examiner conducting project vivas for engineering students. Generate $count high-quality viva questions for the following project:

PROJECT DETAILS:
Title: ${solution.title}
Description: ${solution.description}
Technologies: ${solution.techStack.join(', ')}
Features: ${solution.keyFeatures.join(', ')}
Difficulty: ${solution.difficulty}

PROJECT ROADMAP:
${roadmap.tasks.map((t) => '- ${t.title}: ${t.description}').join('\n')}

REQUIREMENTS:
- Focus on categories: $categoriesText
- Difficulty levels: $difficultiesText
- Mix of technical, conceptual, and practical questions
- Include follow-up questions where appropriate
- Provide comprehensive suggested answers

For each question, provide:
1. The main question
2. Category (technical, conceptual, implementation, projectSpecific, architecture, testing, deployment, problemSolving, futureEnhancements, learningOutcome)
3. Difficulty level (easy, medium, hard, expert)
4. 2-3 possible answer approaches
5. A detailed suggested answer
6. Relevant keywords
7. Estimated time to answer (1-5 minutes)
8. Optional context or background
9. 1-2 follow-up questions

Format as JSON array:
[
  {
    "question": "Main question text",
    "category": "technical",
    "difficulty": "medium",
    "possibleAnswers": ["Approach 1", "Approach 2", "Approach 3"],
    "suggestedAnswer": "Comprehensive answer with explanation",
    "keywords": ["keyword1", "keyword2", "keyword3"],
    "estimatedTimeMinutes": 3,
    "context": "Optional background context",
    "followUpQuestions": ["Follow-up 1", "Follow-up 2"]
  }
]

Generate questions that would realistically be asked by professors during a project viva, covering both theoretical knowledge and practical implementation aspects.
''';
  }

  List<VivaQuestion> _parseGeneratedQuestions(String responseText) {
    try {
      // Clean the response to extract JSON
      final cleanedJson = _extractJsonFromResponse(responseText);
      final jsonList = jsonDecode(cleanedJson) as List;
      
      return jsonList.asMap().entries.map((entry) {
        final index = entry.key;
        final questionData = entry.value as Map<String, dynamic>;
        
        return VivaQuestion(
          id: 'generated_${DateTime.now().millisecondsSinceEpoch}_$index',
          question: (questionData['question'] as String?) ?? '',
          possibleAnswers: _parseStringList(questionData['possibleAnswers']),
          suggestedAnswer: (questionData['suggestedAnswer'] as String?) ?? '',
          category: _parseCategory(questionData['category'] as String?),
          difficulty: _parseDifficulty(questionData['difficulty'] as String?),
          keywords: _parseStringList(questionData['keywords']),
          estimatedTimeMinutes: (questionData['estimatedTimeMinutes'] as int?) ?? 3,
          context: questionData['context'] as String?,
          followUpQuestions: _parseStringList(questionData['followUpQuestions']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing generated questions: $e');
      return [];
    }
  }

  String _extractJsonFromResponse(String text) {
    // Find JSON array in the response
    final startIndex = text.indexOf('[');
    final endIndex = text.lastIndexOf(']');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return text.substring(startIndex, endIndex + 1);
    }
    
    throw Exception('No valid JSON found in response');
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  VivaQuestionCategory _parseCategory(String? category) {
    if (category == null) return VivaQuestionCategory.technical;
    
    return VivaQuestionCategory.values.firstWhere(
      (c) => c.toString().split('.').last.toLowerCase() == category.toLowerCase(),
      orElse: () => VivaQuestionCategory.technical,
    );
  }

  DifficultyLevel _parseDifficulty(String? difficulty) {
    if (difficulty == null) return DifficultyLevel.medium;
    
    return DifficultyLevel.values.firstWhere(
      (d) => d.toString().split('.').last.toLowerCase() == difficulty.toLowerCase(),
      orElse: () => DifficultyLevel.medium,
    );
  }

  // Question Bank Management
  List<VivaQuestion> getQuestionsByCategory(VivaQuestionCategory category) {
    return _questionBank.where((q) => q.category == category).toList();
  }

  List<VivaQuestion> getQuestionsByDifficulty(DifficultyLevel difficulty) {
    return _questionBank.where((q) => q.difficulty == difficulty).toList();
  }

  List<VivaQuestion> searchQuestions(String query) {
    final lowerQuery = query.toLowerCase();
    return _questionBank.where((q) =>
      q.question.toLowerCase().contains(lowerQuery) ||
      q.keywords.any((k) => k.toLowerCase().contains(lowerQuery)) ||
      q.suggestedAnswer.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  void addQuestionsToBank(List<VivaQuestion> questions) {
    _questionBank.addAll(questions);
  }

  void removeFromQuestionBank(String questionId) {
    _questionBank.removeWhere((q) => q.id == questionId);
  }

  // Mock Viva Session Management
  MockVivaSession createMockVivaSession({
    required String projectId,
    required String sessionName,
    required MockVivaSettings settings,
  }) {
    final session = MockVivaSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      sessionName: sessionName,
      startTime: DateTime.now(),
      questionAttempts: [],
      settings: settings,
      status: VivaSessionStatus.notStarted,
    );
    
    _mockSessions.add(session);
    return session;
  }

  List<VivaQuestion> generateMockVivaQuestions(MockVivaSettings settings) {
    final availableQuestions = _questionBank.where((q) {
      final categoryMatch = settings.categories.isEmpty || settings.categories.contains(q.category);
      final difficultyMatch = settings.difficulties.isEmpty || settings.difficulties.contains(q.difficulty);
      return categoryMatch && difficultyMatch;
    }).toList();

    if (availableQuestions.length < settings.totalQuestions) {
      // If not enough questions, return all available
      return availableQuestions;
    }

    // Randomly select questions
    final random = Random();
    final shuffled = List<VivaQuestion>.from(availableQuestions)..shuffle(random);
    
    return shuffled.take(settings.totalQuestions).toList();
  }

  MockVivaSession startMockViva(String sessionId) {
    final sessionIndex = _mockSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final questions = generateMockVivaQuestions(_mockSessions[sessionIndex].settings);
      final questionAttempts = questions.map((q) => VivaQuestionAttempt(
        questionId: q.id,
        question: q,
        startTime: DateTime.now(),
      )).toList();

      _mockSessions[sessionIndex] = _mockSessions[sessionIndex].copyWith(
        status: VivaSessionStatus.inProgress,
        startTime: DateTime.now(),
        questionAttempts: questionAttempts,
      );
    }
    return _mockSessions[sessionIndex];
  }

  MockVivaSession updateQuestionAttempt({
    required String sessionId,
    required String questionId,
    String? userAnswer,
    bool? skipped,
    List<String>? hints,
  }) {
    final sessionIndex = _mockSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _mockSessions[sessionIndex];
      final updatedAttempts = session.questionAttempts.map((attempt) {
        if (attempt.questionId == questionId) {
          return VivaQuestionAttempt(
            questionId: attempt.questionId,
            question: attempt.question,
            startTime: attempt.startTime,
            endTime: userAnswer != null || skipped == true ? DateTime.now() : attempt.endTime,
            userAnswer: userAnswer ?? attempt.userAnswer,
            skipped: skipped ?? attempt.skipped,
            hints: hints ?? attempt.hints,
            score: attempt.score,
            feedback: attempt.feedback,
          );
        }
        return attempt;
      }).toList();

      _mockSessions[sessionIndex] = session.copyWith(questionAttempts: updatedAttempts);
    }
    return _mockSessions[sessionIndex];
  }

  MockVivaSession completeMockViva(String sessionId) {
    final sessionIndex = _mockSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _mockSessions[sessionIndex];
      final overallScore = _calculateSessionScore(session);
      final feedback = _generateSessionFeedback(session);

      _mockSessions[sessionIndex] = session.copyWith(
        status: VivaSessionStatus.completed,
        endTime: DateTime.now(),
        overallScore: overallScore,
        feedback: feedback,
        totalTimeSeconds: session.duration.inSeconds,
      );
    }
    return _mockSessions[sessionIndex];
  }

  double _calculateSessionScore(MockVivaSession session) {
    final answeredQuestions = session.questionAttempts.where((a) => a.isAnswered && !a.skipped);
    if (answeredQuestions.isEmpty) return 0.0;

    // Simple scoring based on answer quality (this could be enhanced with AI)
    double totalScore = 0.0;
    for (final attempt in answeredQuestions) {
      final answerLength = attempt.userAnswer?.length ?? 0;
      final expectedLength = attempt.question.suggestedAnswer.length;
      final lengthScore = (answerLength / expectedLength).clamp(0.0, 1.0);
      
      // Keyword matching score
      final keywords = attempt.question.keywords;
      final userAnswer = attempt.userAnswer?.toLowerCase() ?? '';
      final keywordMatches = keywords.where((k) => userAnswer.contains(k.toLowerCase())).length;
      final keywordScore = keywords.isEmpty ? 0.5 : (keywordMatches / keywords.length).clamp(0.0, 1.0);
      
      final questionScore = (lengthScore * 0.4 + keywordScore * 0.6) * 100;
      totalScore += questionScore;
    }

    return totalScore / answeredQuestions.length;
  }

  String _generateSessionFeedback(MockVivaSession session) {
    final answeredCount = session.questionAttempts.where((a) => a.isAnswered).length;
    final skippedCount = session.questionAttempts.where((a) => a.skipped).length;
    final totalQuestions = session.questionAttempts.length;
    
    final completionRate = (answeredCount / totalQuestions * 100).round();
    final avgTime = session.questionAttempts
        .where((a) => a.timeSpent.inSeconds > 0)
        .map((a) => a.timeSpent.inSeconds)
        .fold<int>(0, (sum, time) => sum + time) / answeredCount;

    return '''
Session completed! Here's your performance summary:

📊 Completion Rate: $completionRate% ($answeredCount/$totalQuestions answered)
⏱️ Average Time per Question: ${(avgTime / 60).toStringAsFixed(1)} minutes
⚡ Questions Skipped: $skippedCount
📈 Overall Score: ${session.averageScore.toStringAsFixed(1)}%

${_getPerformanceFeedback(session.averageScore)}

Keep practicing to improve your viva performance!
''';
  }

  String _getPerformanceFeedback(double score) {
    if (score >= 85) {
      return '🌟 Excellent performance! You\'re well-prepared for your viva.';
    } else if (score >= 70) {
      return '👍 Good job! Review the areas where you struggled and practice more.';
    } else if (score >= 50) {
      return '📚 You need more preparation. Focus on understanding core concepts better.';
    } else {
      return '⚠️ Significant preparation needed. Review your project thoroughly and practice more.';
    }
  }

  List<MockVivaSession> getSessionsForProject(String projectId) {
    return _mockSessions.where((s) => s.projectId == projectId).toList();
  }

  MockVivaSession? getSession(String sessionId) {
    try {
      return _mockSessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  // Presentation Tips
  void _initializePresentationTips() {
    _presentationTips.addAll([
      // General Tips
      PresentationTip(
        id: 'general_1',
        title: 'Know Your Project Inside Out',
        description: 'Be prepared to discuss every aspect of your project in detail',
        category: PresentationTipCategory.general,
        keyPoints: [
          'Understand the problem you solved',
          'Know why you chose specific technologies',
          'Be ready to explain implementation details',
          'Prepare for "what if" scenarios'
        ],
        dosList: [
          'Review your entire codebase before the viva',
          'Practice explaining complex concepts simply',
          'Prepare examples and analogies'
        ],
        dontsList: [
          'Don\'t memorize answers word-for-word',
          'Don\'t claim to know something you don\'t',
          'Don\'t rush through explanations'
        ],
        priority: 1,
      ),

      // Body Language
      PresentationTip(
        id: 'body_1',
        title: 'Maintain Professional Posture',
        description: 'Your body language communicates confidence and competence',
        category: PresentationTipCategory.bodyLanguage,
        keyPoints: [
          'Stand or sit straight',
          'Make eye contact with examiners',
          'Use purposeful hand gestures',
          'Avoid fidgeting or nervous habits'
        ],
        dosList: [
          'Practice in front of a mirror',
          'Record yourself presenting',
          'Ask friends for feedback on your posture'
        ],
        dontsList: [
          'Don\'t cross your arms defensively',
          'Don\'t look down at your feet',
          'Don\'t pace nervously'
        ],
        priority: 2,
      ),

      // Voice and Speech
      PresentationTip(
        id: 'voice_1',
        title: 'Speak Clearly and Confidently',
        description: 'Your voice is your primary communication tool during the viva',
        category: PresentationTipCategory.voiceAndSpeech,
        keyPoints: [
          'Speak at a moderate pace',
          'Project your voice clearly',
          'Use pauses effectively',
          'Vary your tone to maintain interest'
        ],
        dosList: [
          'Practice speaking slowly',
          'Warm up your voice before the viva',
          'Use breathing exercises to stay calm'
        ],
        dontsList: [
          'Don\'t speak too fast when nervous',
          'Don\'t mumble or speak too quietly',
          'Don\'t use too many filler words (um, uh)'
        ],
        priority: 2,
      ),

      // Question Handling
      PresentationTip(
        id: 'questions_1',
        title: 'Listen Carefully to Questions',
        description: 'Understanding the question is the first step to giving a good answer',
        category: PresentationTipCategory.questionHandling,
        keyPoints: [
          'Listen to the complete question',
          'Ask for clarification if needed',
          'Think before you speak',
          'Structure your answers logically'
        ],
        dosList: [
          'Repeat the question to confirm understanding',
          'Take a moment to organize your thoughts',
          'Admit if you don\'t know something'
        ],
        dontsList: [
          'Don\'t interrupt the examiner',
          'Don\'t guess if you\'re unsure',
          'Don\'t give irrelevant information'
        ],
        priority: 1,
      ),

      // Time Management
      PresentationTip(
        id: 'time_1',
        title: 'Manage Your Time Effectively',
        description: 'Balance thoroughness with time constraints',
        category: PresentationTipCategory.timeManagement,
        keyPoints: [
          'Prepare a timed presentation outline',
          'Practice with time limits',
          'Prioritize key points',
          'Leave time for questions'
        ],
        dosList: [
          'Use a watch or timer during practice',
          'Prepare short and long versions of explanations',
          'Practice transitioning between topics smoothly'
        ],
        dontsList: [
          'Don\'t spend too much time on one topic',
          'Don\'t rush through important points',
          'Don\'t ignore time signals from examiners'
        ],
        priority: 2,
      ),
    ]);
  }

  List<PresentationTip> getPresentationTips({PresentationTipCategory? category}) {
    if (category != null) {
      return _presentationTips.where((tip) => tip.category == category).toList();
    }
    return List.from(_presentationTips);
  }

  List<PresentationTip> getTipsByPriority(int priority) {
    return _presentationTips.where((tip) => tip.priority <= priority).toList();
  }

  VivaPreparationGuide getVivaPreparationGuide() {
    return VivaPreparationGuide.defaultGuide.copyWith(tips: _presentationTips);
  }

  // Utility Methods
  Map<VivaQuestionCategory, int> getQuestionDistribution() {
    final distribution = <VivaQuestionCategory, int>{};
    for (final question in _questionBank) {
      distribution[question.category] = (distribution[question.category] ?? 0) + 1;
    }
    return distribution;
  }

  Map<DifficultyLevel, int> getDifficultyDistribution() {
    final distribution = <DifficultyLevel, int>{};
    for (final question in _questionBank) {
      distribution[question.difficulty] = (distribution[question.difficulty] ?? 0) + 1;
    }
    return distribution;
  }

  void clearQuestionBank() {
    _questionBank.clear();
  }

  void clearMockSessions() {
    _mockSessions.clear();
  }
}

extension VivaPreparationGuideExtension on VivaPreparationGuide {
  VivaPreparationGuide copyWith({
    String? title,
    String? description,
    List<PresentationTip>? tips,
    List<String>? commonMistakes,
    List<String>? preparationChecklist,
    Map<String, String>? quickTips,
  }) {
    return VivaPreparationGuide(
      title: title ?? this.title,
      description: description ?? this.description,
      tips: tips ?? this.tips,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      preparationChecklist: preparationChecklist ?? this.preparationChecklist,
      quickTips: quickTips ?? this.quickTips,
    );
  }
}