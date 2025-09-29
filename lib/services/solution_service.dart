import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/config/secrets.dart';

class SolutionService {
  final String apiKey;
  const SolutionService({String? apiKey}) : apiKey = apiKey ?? Secrets.geminiApiKey;

  /// Generate multiple solution approaches for a given problem
  Future<List<ProjectSolution>> generateSolutions({
    required Problem problem,
    required String difficulty,
    required String targetPlatform,
    required List<String> teamSkills,
    int solutionCount = 3,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Pass via --dart-define=GEMINI_API_KEY=...');
    }
    
    debugPrint('🚀 Generating $solutionCount detailed solutions for: ${problem.title}');
    
    try {
      // Build comprehensive problem context
      String problemContext = '''
**Problem Details:**
- Title: ${problem.title}
- Description: ${problem.hasDetailedInfo && problem.detailedDescription != null ? problem.detailedDescription : problem.description}
- Domain: ${problem.domain}
- Target Platform: $targetPlatform
- Difficulty Level: $difficulty
- Available Skills: ${teamSkills.join(', ')}
''';
      
      // Add real-life examples if available
      if (problem.hasDetailedInfo && problem.realLifeExample != null && problem.realLifeExample!.isNotEmpty) {
        problemContext += '''\n**Real-life Examples from Problem:**
${problem.realLifeExample!.map((example) => '- $example').join('\n')}
''';
      }
      
      // Add detailed features if available
      if (problem.hasDetailedInfo && problem.detailedFeatures != null && problem.detailedFeatures!.isNotEmpty) {
        problemContext += '''\n**Expected Features:**
${problem.detailedFeatures!.map((feature) => '- $feature').join('\n')}
''';
      }
      
      // Add implementation steps if available
      if (problem.hasDetailedInfo && problem.implementationSteps != null && problem.implementationSteps!.isNotEmpty) {
        problemContext += '''\n**Suggested Implementation Steps:**
${problem.implementationSteps!.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}
''';
      }
      
      // Add challenges if available
      if (problem.hasDetailedInfo && problem.challenges != null && problem.challenges!.isNotEmpty) {
        problemContext += '''\n**Known Challenges:**
${problem.challenges!.map((challenge) => '- $challenge').join('\n')}
''';
      }

      final prompt = '''
Generate $solutionCount comprehensive, detailed solution approaches for this project:

$problemContext

**Solution Requirements:**
1. Each solution must be DETAILED and COMPREHENSIVE with step-by-step implementation
2. Include real-life examples and practical applications
3. Solutions should match the difficulty level ($difficulty)
4. Use technologies that align with team skills: ${teamSkills.join(', ')}
5. Include specific implementation steps, challenges, and benefits
6. Provide learning outcomes for students
7. Include timeline estimates for each phase
8. Make solutions practical and achievable for students

**Response Format (JSON Array):**
[
  {
    "id": "sol_1",
    "title": "Comprehensive Solution Title",
    "description": "Brief overview of the solution approach",
    "detailedDescription": "Detailed explanation of how this solution works, why it's effective, and how it addresses the problem",
    "keyFeatures": ["Detailed Feature 1 with explanation", "Feature 2 with technical details", "Feature 3 with user benefits"],
    "techStack": ["Primary Technology 1", "Supporting Technology 2", "Database Technology", "Additional Tools"],
    "implementationSteps": [
      "Step 1: Detailed first step with specific actions",
      "Step 2: Second step with implementation details",
      "Step 3: Continue with specific, actionable steps",
      "Step 4: Include configuration and setup details",
      "Step 5: Testing and validation steps",
      "Step 6: Deployment and go-live steps"
    ],
    "realLifeExamples": [
      "Real example 1: How companies like X use similar solutions",
      "Real example 2: Practical application in industry Y",
      "Real example 3: Student project success story"
    ],
    "challenges": [
      "Technical challenge 1 and how to overcome it",
      "Implementation challenge 2 with solutions",
      "Common pitfall 3 and prevention strategies"
    ],
    "benefits": [
      "User benefit 1: Specific advantage for end users",
      "Technical benefit 2: System performance improvements",
      "Business benefit 3: Cost/time savings"
    ],
    "learningOutcomes": [
      "Students will learn skill 1 through implementation",
      "Gain experience with technology 2",
      "Understand concept 3 through practical application"
    ],
    "timeline": {
      "Phase 1 - Planning": "1-2 weeks",
      "Phase 2 - Development": "4-6 weeks",
      "Phase 3 - Testing": "1-2 weeks",
      "Phase 4 - Deployment": "1 week"
    },
    "architecture": {
      "frontend": "Frontend technology with specific framework version",
      "backend": "Backend technology with detailed setup",
      "database": "Database technology with schema considerations",
      "apis": ["API 1 with purpose", "API 2 with integration details"],
      "deployment": {
        "hosting": "Hosting platform with specific configuration",
        "cicd": "CI/CD approach with tools and workflow"
      }
    }
  }
]

**IMPORTANT GUIDELINES:**
- Make each solution COMPREHENSIVE and DETAILED
- Include practical, actionable implementation steps
- Provide real-world context and examples
- Address potential challenges proactively
- Focus on student learning and skill development
- Ensure solutions are different in approach and technology
- Include specific timeframes and milestones
- Make solutions achievable for $difficulty level students
''';

      // Use gemini-2.5-flash (same as GeminiProblemsService)
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.7),
      );

      // Retry with exponential backoff for better reliability (same pattern as GeminiProblemsService)
      const maxAttempts = 3;
      late String text;
      
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          debugPrint('🔄 Solution generation attempt $attempt/$maxAttempts');
          final response = await model
              .generateContent([Content.text(prompt)])
              .timeout(const Duration(minutes: 3)); // 3 minutes for complex solutions

          text = response.text ?? '';
          debugPrint('📥 Raw solution response (${text.length} chars): ${text.substring(0, text.length.clamp(0, 300))}...');

          if (text.isNotEmpty) break; // Success
          
          if (attempt < maxAttempts) {
            debugPrint('⚠️ Empty solution response, retrying...');
            await Future<void>.delayed(Duration(seconds: attempt * 2));
          }
        } catch (e) {
          debugPrint('⚠️ Solution attempt $attempt failed: $e');
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }

      if (text.isEmpty) {
        throw StateError('Gemini returned empty solution response after $maxAttempts attempts');
      }

      // Parse JSON from text using the same pattern as GeminiProblemsService
      final jsonString = _extractJsonArray(text);
      debugPrint('🔍 Extracted solution JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 500))}...');
      
      if (jsonString.isEmpty || jsonString == '[]') {
        throw StateError('No valid JSON found in solution response. Raw text: ${text.substring(0, 500)}...');
      }

      final List<dynamic> solutionsJson = jsonDecode(jsonString) as List<dynamic>;
      debugPrint('✅ Parsed ${solutionsJson.length} solution items from JSON');

      // Convert to ProjectSolution objects
      final solutions = <ProjectSolution>[];
      for (int i = 0; i < solutionsJson.length && i < solutionCount; i++) {
        final solutionData = solutionsJson[i];
        
        solutions.add(ProjectSolution(
          id: (solutionData['id'] as String?) ?? 'sol_${i + 1}',
          type: 'app_suggested',
          title: (solutionData['title'] as String?) ?? 'Solution ${i + 1}',
          description: (solutionData['description'] as String?) ?? '',
          detailedDescription: solutionData['detailedDescription'] as String?,
          keyFeatures: _parseStringList(solutionData['keyFeatures']),
          techStack: _parseStringList(solutionData['techStack']),
          implementationSteps: solutionData['implementationSteps'] != null 
              ? _parseStringList(solutionData['implementationSteps']) : null,
          realLifeExamples: solutionData['realLifeExamples'] != null 
              ? _parseStringList(solutionData['realLifeExamples']) : null,
          challenges: solutionData['challenges'] != null 
              ? _parseStringList(solutionData['challenges']) : null,
          benefits: solutionData['benefits'] != null 
              ? _parseStringList(solutionData['benefits']) : null,
          learningOutcomes: solutionData['learningOutcomes'] != null 
              ? _parseStringList(solutionData['learningOutcomes']) : null,
          timeline: solutionData['timeline'] != null 
              ? Map<String, dynamic>.from(solutionData['timeline'] as Map) : null,
          difficulty: difficulty,
          architecture: solutionData['architecture'] != null 
              ? Map<String, dynamic>.from(solutionData['architecture'] as Map) : {},
          createdAt: DateTime.now(),
        ));
      }

      debugPrint('🎉 Successfully generated ${solutions.length} detailed AI solutions');
      return solutions;

    } catch (e) {
      debugPrint('❌ Error generating solutions: $e');
      
      // Return fallback solutions based on problem domain
      return _generateFallbackSolutions(
        problem: problem,
        difficulty: difficulty,
        targetPlatform: targetPlatform,
        teamSkills: teamSkills,
        solutionCount: solutionCount,
      );
    }
  }

  /// Generate fallback solutions if AI fails
  List<ProjectSolution> _generateFallbackSolutions({
    required Problem problem,
    required String difficulty,
    required String targetPlatform,
    required List<String> teamSkills,
    int solutionCount = 3,
  }) {
    final solutions = <ProjectSolution>[];
    
    // Basic solution templates based on platform
    if (targetPlatform == 'App') {
      solutions.add(ProjectSolution(
        id: 'fallback_1',
        type: 'app_suggested',
        title: 'Flutter Mobile App Solution',
        description: 'A mobile-first approach using Flutter for cross-platform development',
        keyFeatures: ['Cross-platform mobile app', 'Offline support', 'Real-time updates'],
        techStack: ['Flutter', 'Firebase', 'Dart'],
        difficulty: difficulty,
        architecture: {
          'frontend': 'Flutter',
          'backend': 'Firebase Functions',
          'database': 'Firebase Firestore',
          'apis': ['Firebase Auth', 'Cloud Storage'],
          'deployment': {'hosting': 'Google Play Store', 'cicd': 'GitHub Actions'}
        },
        createdAt: DateTime.now(),
      ));
    }
    
    if (targetPlatform == 'Web' && solutions.length < solutionCount) {
      solutions.add(ProjectSolution(
        id: 'fallback_2',
        type: 'app_suggested',
        title: 'React Web Application',
        description: 'A responsive web application built with React and modern tools',
        keyFeatures: ['Responsive design', 'Progressive Web App', 'Real-time features'],
        techStack: ['React', 'Node.js', 'MongoDB'],
        difficulty: difficulty,
        architecture: {
          'frontend': 'React',
          'backend': 'Node.js + Express',
          'database': 'MongoDB',
          'apis': ['REST API', 'Socket.io'],
          'deployment': {'hosting': 'Vercel', 'cicd': 'GitHub Actions'}
        },
        createdAt: DateTime.now(),
      ));
    }

    return solutions.take(solutionCount).toList();
  }

  /// Validate a custom solution
  bool validateCustomSolution({
    required String title,
    required String description,
    required List<String> keyFeatures,
    required List<String> techStack,
  }) {
    return title.trim().isNotEmpty &&
           description.trim().length >= 50 &&
           keyFeatures.isNotEmpty &&
           techStack.isNotEmpty;
  }

  /// Create a custom solution
  ProjectSolution createCustomSolution({
    required String title,
    required String description,
    required List<String> keyFeatures,
    required List<String> techStack,
    required String difficulty,
    Map<String, dynamic>? architecture,
  }) {
    return ProjectSolution(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      type: 'custom',
      title: title,
      description: description,
      keyFeatures: keyFeatures,
      techStack: techStack,
      difficulty: difficulty,
      architecture: architecture ?? {},
      createdAt: DateTime.now(),
    );
  }
  
  /// Helper method to safely parse string lists from dynamic values
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  /// Extract JSON array from response text (same pattern as GeminiProblemsService)
  String _extractJsonArray(String text) {
    // Remove markdown code blocks
    text = text.replaceAll(RegExp(r'```json\s*'), '');
    text = text.replaceAll(RegExp(r'```\s*'), '');
    text = text.trim();
    
    // Find JSON array boundaries
    final startIndex = text.indexOf('[');
    final endIndex = text.lastIndexOf(']');
    
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return text.substring(startIndex, endIndex + 1);
    }
    
    return text; // Return as-is if no clear array boundaries
  }
}
