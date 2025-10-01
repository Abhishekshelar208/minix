import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/viva_question.dart';
import '../models/mock_viva_session.dart';
import '../models/presentation_tip.dart';
import '../models/solution.dart';
import '../models/project_roadmap.dart';
import '../models/problem.dart';
import '../config/secrets.dart';

class VivaService {
  static final VivaService _instance = VivaService._internal();
  factory VivaService() => _instance;
  VivaService._internal();

  late final GenerativeModel _model;
  final List<VivaQuestion> _questionBank = [];
  final List<MockVivaSession> _mockSessions = [];
  final List<PresentationTip> _presentationTips = [];
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',  // Same model as documentation service
      apiKey: Secrets.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.6,  // Same temperature as documentation service
      ),
    );
    _initializePresentationTips();
    _isInitialized = true;
  }

  // Question Generation with full project context
  Future<List<VivaQuestion>> generateProjectSpecificQuestions({
    required String projectSpaceId,
    required String projectName,
    required Problem? problem,
    required ProjectSolution? solution,
    required ProjectRoadmap? roadmap,
    required Map<String, dynamic>? projectData,
    int count = 15,
    List<VivaQuestionCategory>? categories,
    List<DifficultyLevel>? difficulties,
  }) async {
    if (Secrets.geminiApiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Please configure your API key.');
    }

    try {
      debugPrint('🚀 Starting viva question generation...');
      
      final prompt = _buildQuestionGenerationPrompt(
        projectSpaceId: projectSpaceId,
        projectName: projectName,
        problem: problem,
        solution: solution,
        roadmap: roadmap,
        projectData: projectData,
        count: count,
        categories: categories,
        difficulties: difficulties,
      );

      debugPrint('📝 Generated prompt for Gemini API (${prompt.length} chars, ~${(prompt.length / 4).round()} tokens)');
      
      // Use same retry logic as documentation service
      const maxAttempts = 3;
      late String responseText;
      
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          debugPrint('🔄 Calling Gemini API - Attempt $attempt/$maxAttempts');
          final response = await _model
              .generateContent([Content.text(prompt)])
              .timeout(const Duration(minutes: 3)); // Longer timeout for complex question generation
              
          responseText = response.text ?? '';
          debugPrint('📥 Received response (${responseText.length} chars)');
          
          if (responseText.isNotEmpty) break; // Success
          
          if (attempt < maxAttempts) {
            debugPrint('⚠️ Empty response, retrying...');
            await Future<void>.delayed(Duration(seconds: attempt * 2));
          }
        } catch (e) {
          debugPrint('⚠️ Attempt $attempt failed: $e');
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
      
      if (responseText.isEmpty) {
        throw StateError('Gemini returned empty response after $maxAttempts attempts');
      }
      
      final questions = _parseGeneratedQuestions(responseText);
      debugPrint('🎉 Generated ${questions.length} viva questions successfully');
      
      return questions;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in generateProjectSpecificQuestions: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      throw Exception('Failed to generate viva questions: $e');
    }
  }

  String _buildQuestionGenerationPrompt({
    required String projectSpaceId,
    required String projectName,
    required Problem? problem,
    required ProjectSolution? solution,
    required ProjectRoadmap? roadmap,
    required Map<String, dynamic>? projectData,
    required int count,
    List<VivaQuestionCategory>? categories,
    List<DifficultyLevel>? difficulties,
  }) {
    final categoriesText = categories?.map((c) => c.displayName).join(', ') ?? 'all categories';
    final difficultiesText = difficulties?.map((d) => d.displayName).join(', ') ?? 'mixed difficulties';
    
    // Build comprehensive project context like documentation service
    final context = StringBuffer();
    
    context.writeln('PROJECT INFORMATION:');
    context.writeln('Project Name: $projectName');
    
    if (projectData != null) {
      context.writeln('Team Name: ${projectData['teamName'] ?? 'Unknown'}');
      context.writeln('Target Platform: ${projectData['targetPlatform'] ?? 'Unknown'}');
      context.writeln('Year of Study: ${projectData['yearOfStudy'] ?? 'Unknown'}');
      context.writeln('Difficulty Level: ${projectData['difficulty'] ?? 'Unknown'}');
      
      try {
        final teamMembers = projectData['teamMembers'] as List<dynamic>?;
        if (teamMembers != null && teamMembers.isNotEmpty) {
          final memberNames = teamMembers.map((m) {
            if (m is Map) {
              return m['name']?.toString() ?? 'Unknown Member';
            } else {
              return m.toString();
            }
          }).join(', ');
          context.writeln('Team Members: $memberNames');
        }
      } catch (e) {
        context.writeln('Team Members: Unable to retrieve team member details');
      }
    }
    
    if (problem != null) {
      context.writeln('\nPROBLEM STATEMENT:');
      context.writeln('Title: ${problem.title}');
      context.writeln('Description: ${problem.description}');
      context.writeln('Domain: ${problem.domain}');
      context.writeln('Platform: ${problem.platform.join(', ')}');
      context.writeln('Skills Required: ${problem.skills.join(', ')}');
      context.writeln('Features: ${problem.features.join(', ')}');
      context.writeln('Beneficiaries: ${problem.beneficiaries.join(', ')}');
    }
    
    if (solution != null) {
      context.writeln('\nSOLUTION DETAILS:');
      context.writeln('Solution Title: ${solution.title}');
      context.writeln('Description: ${solution.description}');
      context.writeln('Type: ${solution.type}');
      context.writeln('Technologies: ${solution.techStack.join(', ')}');
      context.writeln('Key Features: ${solution.keyFeatures.join(', ')}');
      context.writeln('Difficulty: ${solution.difficulty}');
      
      if (solution.architecture.isNotEmpty) {
        context.writeln('Architecture: ${solution.architecture}');
      }
    }
    
    if (roadmap != null && roadmap.tasks.isNotEmpty) {
      context.writeln('\nPROJECT ROADMAP:');
      context.writeln('Start Date: ${_formatDate(roadmap.startDate)}');
      context.writeln('End Date: ${_formatDate(roadmap.endDate)}');
      context.writeln('Total Tasks: ${roadmap.totalTasksCount}');
      context.writeln('Completed Tasks: ${roadmap.completedTasksCount}');
      context.writeln('Progress: ${(roadmap.completedTasksCount / roadmap.totalTasksCount * 100).toStringAsFixed(1)}%');
      
      // Only include key high-priority tasks to reduce prompt size
      context.writeln('\nKey Tasks:');
      final keyTasks = roadmap.tasks
          .where((task) => task.priority == 'High' || task.priority == 'Critical')
          .take(5)
          .toList();
      
      if (keyTasks.isEmpty) {
        // If no high priority tasks, take first 5
        for (final task in roadmap.tasks.take(5)) {
          context.writeln('- ${task.title} (${task.category})');
        }
      } else {
        for (final task in keyTasks) {
          context.writeln('- ${task.title} (${task.category})');
        }
      }
      
      if (roadmap.tasks.length > 5) {
        context.writeln('... and ${roadmap.tasks.length - (keyTasks.isEmpty ? 5 : keyTasks.length)} more tasks');
      }
    }

    return '''
You are an expert examiner conducting project vivas for engineering students. Generate $count high-quality, realistic viva questions for the following project:

${context.toString()}

QUESTION GENERATION REQUIREMENTS:
- Focus on categories: $categoriesText
- Difficulty levels: $difficultiesText
- Create questions that professors would realistically ask during a project viva
- Mix technical depth with practical implementation understanding
- Include both theoretical knowledge and hands-on experience questions
- Cover problem-solving approach, technology choices, and implementation challenges
- Include questions about future improvements and learning outcomes

For each question, provide:
1. A clear, specific question that tests understanding
2. Category classification
3. Appropriate difficulty level
4. Multiple possible answer approaches
5. A comprehensive suggested answer with explanations
6. Relevant keywords for answer evaluation
7. Realistic time estimation
8. Context or background if needed
9. Follow-up questions to deepen understanding

Return ONLY a valid JSON array in this exact format:
[
  {
    "question": "Detailed question about the project",
    "category": "technical|conceptual|implementation|projectSpecific|architecture|testing|deployment|problemSolving|futureEnhancements|learningOutcome",
    "difficulty": "easy|medium|hard|expert",
    "possibleAnswers": ["Answer approach 1", "Answer approach 2", "Answer approach 3"],
    "suggestedAnswer": "Comprehensive answer with detailed explanation",
    "keywords": ["keyword1", "keyword2", "keyword3", "keyword4"],
    "estimatedTimeMinutes": 3,
    "context": "Background context for the question (optional)",
    "followUpQuestions": ["Follow-up question 1", "Follow-up question 2"]
  }
]

Generate questions that demonstrate deep project understanding and practical implementation knowledge.
''';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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