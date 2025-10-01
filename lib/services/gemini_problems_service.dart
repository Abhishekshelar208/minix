import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:minix/config/secrets.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/task.dart';

class GeminiProblemsService {
  final String apiKey;
  const GeminiProblemsService({String? apiKey}) : apiKey = apiKey ?? Secrets.geminiApiKey;

  Future<List<Problem>> fetchProblems({
    required String domain,
    required int year,
    required List<String> platforms,
    required List<String> skills,
    String? difficulty,
    int count = 15,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Pass via --dart-define=GEMINI_API_KEY=...');
    }

    debugPrint('🚀 Calling Gemini API for domain: $domain, year: $year, skills: $skills');

    final prompt = _buildPrompt(
      domain: domain,
      year: year,
      platforms: platforms,
      skills: skills,
      difficulty: difficulty,
      count: count,
    );

    debugPrint('📝 Prompt sent to Gemini: ${prompt.substring(0, 100)}...');

    // Use gemini-2.5-flash (confirmed working with your API key)
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.6),
    );

    // Retry with exponential backoff for better reliability
    const maxAttempts = 3;
    late String text;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('🔄 Attempt $attempt/$maxAttempts');
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(minutes: 2)); // 2 minutes timeout

        text = response.text ?? '';
        debugPrint('📥 Raw Gemini response (${text.length} chars): ${text.substring(0, text.length.clamp(0, 200))}...');

        if (text.isNotEmpty) break; // Success
        
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

    if (text.isEmpty) {
      throw StateError('Gemini returned empty response after $maxAttempts attempts');
    }

    // Parse JSON from text. Be tolerant to code fences or prose.
    final jsonString = _extractJsonArray(text);
    debugPrint('🔍 Extracted JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 300))}...');
    
    if (jsonString.isEmpty || jsonString == '[]') {
      throw StateError('No valid JSON found in Gemini response. Raw text: ${text.substring(0, 500)}...');
    }

    final List<dynamic> arr = jsonDecode(jsonString) as List<dynamic>;
    debugPrint('✅ Parsed ${arr.length} items from JSON');

    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Problem> problems = [];
    for (var i = 0; i < arr.length; i++) {
      final item = arr[i];
      if (item is Map) {
        // Always use ai_ prefix for AI-generated problems
        final id = 'ai_${now}_$i';
        // Normalize keys for our model
        final map = <String, dynamic>{
          'title': item['title'] ?? 'Untitled Project',
          'domain': item['domain'] ?? domain,
          'description': item['description'] ?? item['problem'] ?? 'AI-generated project description',
          'platform': _ensureList(item['platform'] ?? item['platforms']) ?? ['App', 'Web'],
          'year': _ensureIntList(item['year']) ?? [year],
          'skills': _ensureList(item['skills']) ?? skills,
          'difficulty': item['difficulty']?.toString() ?? (difficulty ?? 'Intermediate'),
          'scope': item['scope']?.toString() ?? 'Medium',
          'beneficiaries': _ensureList(item['beneficiaries']) ?? ['Students', 'Users'],
          'features': _ensureList(item['features']) ?? ['Core functionality'],
          'data_sources': _ensureList(item['data_sources']) ?? ['Database'],
          'updatedAt': item['updatedAt'] ?? now,
        };
        problems.add(Problem.fromMap(id, map));
        debugPrint('✅ Created problem: ${map['title']}');
      }
    }
    
    debugPrint('🎉 Successfully created ${problems.length} AI problems');
    return problems;
  }
  
  // Generate detailed problem information with real-life examples
  Future<Problem> generateDetailedProblem(Problem baseProblem) async {
    if (apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Pass via --dart-define=GEMINI_API_KEY=...');
    }

    debugPrint('🔍 Generating detailed problem info for: ${baseProblem.title}');

    final prompt = _buildDetailedPrompt(baseProblem);
    debugPrint('📝 Detailed prompt sent to Gemini: ${prompt.substring(0, 100)}...');

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
    );

    try {
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(minutes: 2));

      final text = response.text ?? '';
      debugPrint('📥 Detailed response (${text.length} chars): ${text.substring(0, text.length.clamp(0, 200))}...');

      if (text.isEmpty) {
        throw StateError('Gemini returned empty detailed response');
      }

      // Parse JSON from text
      final jsonString = _extractJsonObject(text);
      debugPrint('🔍 Extracted detailed JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 300))}...');
      
      if (jsonString.isEmpty || jsonString == '{}') {
        throw StateError('No valid JSON found in detailed response. Raw text: ${text.substring(0, 500)}...');
      }

      final Map<String, dynamic> detailedData = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('✅ Parsed detailed data successfully');
      
      // Create updated problem with detailed information
      final detailedProblem = baseProblem.copyWith(
        detailedDescription: detailedData['detailedDescription']?.toString() ?? '',
        realLifeExample: _ensureList(detailedData['realLifeExample']) ?? [],
        detailedFeatures: _ensureList(detailedData['detailedFeatures']) ?? [],
        implementationSteps: _ensureList(detailedData['implementationSteps']) ?? [],
        challenges: _ensureList(detailedData['challenges']) ?? [],
        learningOutcomes: _ensureList(detailedData['learningOutcomes']) ?? [],
        hasDetailedInfo: true,
      );
      
      debugPrint('🎉 Successfully generated detailed problem info');
      return detailedProblem;
    } catch (e) {
      debugPrint('⚠️ Error generating detailed problem: $e');
      rethrow;
    }
  }

  String _buildPrompt({
    required String domain,
    required int year,
    required List<String> platforms,
    required List<String> skills,
    String? difficulty,
    required int count,
  }) {
    final sk = skills.isEmpty ? 'Flutter, React, Firebase, Node (choose sensible)' : skills.join(', ');
    final diff = (difficulty == null || difficulty.isEmpty) ? 'Beginner or Intermediate' : difficulty;

    return '''
You are helping engineering students pick real-world project problems.
Generate a STRICT JSON array (no markdown, no text outside JSON) of $count items.
Each item must be an object with these exact keys:
- id (string, short unique id like prob_1234)
- title (string)
- domain (string, exactly "$domain")
- description (string, one-line problem statement)
- platform (array of strings; allowed: ["App","Web","Website"]) — include 1-2 relevant values
- year (array of integers; choose from [1,2,3,4]) — include 1-2 most relevant years, must include $year or near ($year±1) when appropriate
- skills (array of strings; e.g., ["Flutter","Firebase","Node","React"]) — pick 2-5 relevant from [$sk]
- difficulty (string; one of "Beginner","Intermediate","Advanced") — prefer $diff
- scope (string; one of "Small","Medium","Large") — prefer "Medium" for semester fit
- beneficiaries (array of strings)
- features (array of strings; 3-6 sample features)
- data_sources (array of strings; e.g., ["Firebase RTDB","Firestore","CSV export","Open APIs"])
- updatedAt (unix ms number)

Focus on domain "$domain". Ensure problems are practical and not generic.
Return ONLY the JSON array. Do not wrap in code fences.
''';
  }
  
  String _buildDetailedPrompt(Problem baseProblem) {
    return '''
You are helping engineering students understand a project problem in detail with real-life examples.

Given this basic problem:
Title: ${baseProblem.title}
Description: ${baseProblem.description}
Domain: ${baseProblem.domain}
Difficulty: ${baseProblem.difficulty}
Features: ${baseProblem.features.join(', ')}
Tech Stack: ${baseProblem.skills.join(', ')}

Generate a STRICT JSON object (no markdown, no text outside JSON) with these exact keys:
- detailedDescription (string): Simple 2-3 sentences explaining what this project does and why it's needed
- realLifeExample (array of strings): 4-5 point-wise real-world problems that this project solves (e.g., ["Students wait in long queues to issue books", "Library staff manually track all book records", "No way to check book availability before visiting library"])
- detailedFeatures (array of strings): 6-8 specific, detailed features with clear descriptions
- implementationSteps (array of strings): 5-7 step-by-step implementation phases
- challenges (array of strings): 4-5 potential technical/practical challenges students might face
- learningOutcomes (array of strings): 5-6 specific skills/knowledge students will gain

Make it student-friendly and easy to understand for ${baseProblem.difficulty.toLowerCase()} level students.
Use simple language and concrete examples, avoid complex technical terms.
Return ONLY the JSON object. Do not wrap in code fences.
''';
  }


  List<String>? _ensureList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return null;
  }

  List<int>? _ensureIntList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) {
        if (e is int) return e;
        return int.tryParse(e.toString()) ?? 0;
      }).toList();
    }
    if (value is int) return [value];
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null ? [parsed] : null;
    }
    return null;
  }

  String _extractJsonArray(String text) {
    // Remove markdown code fences if present
    String cleanText = text;
    if (text.contains('```json')) {
      final start = text.indexOf('```json') + 7;
      final end = text.indexOf('```', start);
      if (end != -1) {
        cleanText = text.substring(start, end).trim();
      }
    } else if (text.contains('```')) {
      final start = text.indexOf('```') + 3;
      final end = text.indexOf('```', start);
      if (end != -1) {
        cleanText = text.substring(start, end).trim();
      }
    }
    
    // If the model emits markdown or prose, try to extract the first JSON array
    final start = cleanText.indexOf('[');
    final end = cleanText.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return cleanText.substring(start, end + 1);
    }
    
    // As a fallback, try to extract single object and wrap in array
    final s2 = cleanText.indexOf('{');
    final e2 = cleanText.lastIndexOf('}');
    if (s2 != -1 && e2 != -1 && e2 > s2) {
      return '[${cleanText.substring(s2, e2 + 1)}]';
    }
    
    // Last resort: try original text
    final origStart = text.indexOf('[');
    final origEnd = text.lastIndexOf(']');
    if (origStart != -1 && origEnd != -1 && origEnd > origStart) {
      return text.substring(origStart, origEnd + 1);
    }
    
    // Give up
    return '[]';
  }
  
  String _extractJsonObject(String text) {
    // Remove markdown code fences if present
    String cleanText = text;
    if (text.contains('```json')) {
      final start = text.indexOf('```json') + 7;
      final end = text.indexOf('```', start);
      if (end != -1) {
        cleanText = text.substring(start, end).trim();
      }
    } else if (text.contains('```')) {
      final start = text.indexOf('```') + 3;
      final end = text.indexOf('```', start);
      if (end != -1) {
        cleanText = text.substring(start, end).trim();
      }
    }
    
    // Try to find JSON object in response
    final start = cleanText.indexOf('{');
    final end = cleanText.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return cleanText.substring(start, end + 1);
    }
    
    // Last resort: try original text
    final origStart = text.indexOf('{');
    final origEnd = text.lastIndexOf('}');
    if (origStart != -1 && origEnd != -1 && origEnd > origStart) {
      return text.substring(origStart, origEnd + 1);
    }
    
    return '{}';
  }

  Future<List<Task>> generateRoadmap({
    required String projectTitle,
    required String projectDescription,
    required List<String> teamMembers,
    required List<String> teamSkills,
    required DateTime startDate,
    required DateTime endDate,
    required String difficulty,
    required String targetPlatform,
    Problem? problem,
    Map<String, dynamic>? solution,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Pass via --dart-define=GEMINI_API_KEY=...');
    }
    
    // Validate API key format
    if (apiKey.length < 30) {
      debugPrint('⚠️ API key seems too short (${apiKey.length} chars). Please check your Gemini API key.');
    }
    
    debugPrint('🔑 Using API key: ${apiKey.substring(0, 8)}...');
    debugPrint('📊 Roadmap params: Platform=$targetPlatform, Duration=${endDate.difference(startDate).inDays} days, Team=${teamMembers.length}');
    
    // Early fallback for very short timelines
    final durationInDays = endDate.difference(startDate).inDays;
    if (durationInDays < 7) {
      debugPrint('⚠️ Timeline too short (<7 days), using fallback roadmap');
      return _generateFallbackRoadmap(
        projectTitle: projectTitle,
        durationInDays: durationInDays,
        startDate: startDate,
        endDate: endDate,
        targetPlatform: targetPlatform,
        teamMembers: teamMembers,
      );
    }

    debugPrint('🚀 Generating roadmap for: $projectTitle');
    final prompt = _buildRoadmapPrompt(
      projectTitle: projectTitle,
      projectDescription: projectDescription,
      teamMembers: teamMembers,
      teamSkills: teamSkills,
      startDate: startDate,
      endDate: endDate,
      durationInDays: durationInDays,
      difficulty: difficulty,
      targetPlatform: targetPlatform,
      problem: problem,
      solution: solution,
    );

    debugPrint('📝 Roadmap prompt sent to Gemini');

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
    );

    const maxAttempts = 3;
    late String text;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('🔄 Roadmap generation attempt $attempt/$maxAttempts');
        
        // Reduce timeout for better error handling
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 90)); // Reduced from 3 minutes

        text = response.text ?? '';
        debugPrint('📥 Raw roadmap response (${text.length} chars)');

        if (text.isNotEmpty) break;
        
        if (attempt < maxAttempts) {
          debugPrint('⚠️ Empty roadmap response, retrying...');
          await Future<void>.delayed(Duration(seconds: attempt * 3));
        }
      } catch (e) {
        debugPrint('⚠️ Roadmap attempt $attempt failed: $e');
        
        // Check for specific API errors
        if (e.toString().contains('500') || e.toString().contains('INTERNAL')) {
          debugPrint('🚨 Server error detected, using fallback after attempt $attempt');
          if (attempt >= 2) {
            // Use fallback after 2 attempts on server errors
            debugPrint('🔄 Switching to fallback roadmap generation');
            return _generateFallbackRoadmap(
              projectTitle: projectTitle,
              durationInDays: durationInDays,
              startDate: startDate,
              endDate: endDate,
              targetPlatform: targetPlatform,
              teamMembers: teamMembers,
            );
          }
        }
        
        if (attempt == maxAttempts) {
          debugPrint('🚨 All attempts failed, using fallback roadmap');
          return _generateFallbackRoadmap(
            projectTitle: projectTitle,
            durationInDays: durationInDays,
            startDate: startDate,
            endDate: endDate,
            targetPlatform: targetPlatform,
            teamMembers: teamMembers,
          );
        }
        
        await Future<void>.delayed(Duration(seconds: attempt * 3));
      }
    }

    if (text.isEmpty) {
      throw StateError('Gemini returned empty roadmap after $maxAttempts attempts');
    }

    // Parse JSON from text
    final jsonString = _extractJsonArray(text);
    debugPrint('🔍 Extracted roadmap JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 300))}...');
    
    if (jsonString.isEmpty || jsonString == '[]') {
      throw StateError('No valid roadmap JSON found in response');
    }

    final List<dynamic> arr = jsonDecode(jsonString) as List<dynamic>;
    debugPrint('✅ Parsed ${arr.length} tasks from roadmap JSON');

    final now = DateTime.now();
    final List<Task> tasks = [];
    
    for (var i = 0; i < arr.length; i++) {
      final item = arr[i];
      if (item is Map) {
        final taskId = 'task_${now.millisecondsSinceEpoch}_$i';
        
        // Parse due date
        DateTime taskDueDate;
        try {
          if (item['dueDate'] is String) {
            taskDueDate = DateTime.parse(item['dueDate'] as String);
          } else if (item['dayOffset'] is int) {
            taskDueDate = startDate.add(Duration(days: item['dayOffset'] as int));
          } else {
            // Default distribution across project timeline
            final progressRatio = (i + 1) / arr.length;
            taskDueDate = startDate.add(Duration(
              days: (durationInDays * progressRatio).round(),
            ));
          }
        } catch (e) {
          // Fallback: distribute evenly
          final progressRatio = (i + 1) / arr.length;
          taskDueDate = startDate.add(Duration(
            days: (durationInDays * progressRatio).round(),
          ));
        }
        
        // Parse additional metadata for enhanced roadmap info
        final metadata = <String, dynamic>{};
        if (item['deliverables'] != null) {
          metadata['deliverables'] = _toStringList(item['deliverables']) ?? [];
        }
        if (item['skills_required'] != null) {
          metadata['skills_required'] = _toStringList(item['skills_required']) ?? [];
        }
        
        final task = Task(
          id: taskId,
          title: item['title']?.toString() ?? 'Task ${i + 1}',
          description: item['description']?.toString() ?? '',
          dueDate: taskDueDate,
          priority: item['priority']?.toString() ?? 'Medium',
          category: item['category']?.toString() ?? 'Development',
          assignedTo: _parseAssignedTo(item['assignedTo'], teamMembers),
          estimatedHours: (item['estimatedHours'] as int?) ?? 8,
          dependencies: _toStringList(item['dependencies']) ?? [],
          metadata: metadata.isNotEmpty ? metadata : null,
          createdAt: now,
          updatedAt: now,
        );
        
        tasks.add(task);
        debugPrint('✅ Created task: ${task.title} (Due: ${task.dueDate.day}/${task.dueDate.month})');
      }
    }
    
    debugPrint('🎉 Successfully generated ${tasks.length} roadmap tasks');
    return tasks;
  }

  String _buildRoadmapPrompt({
    required String projectTitle,
    required String projectDescription,
    required List<String> teamMembers,
    required List<String> teamSkills,
    required DateTime startDate,
    required DateTime endDate,
    required int durationInDays,
    required String difficulty,
    required String targetPlatform,
    Problem? problem,
    Map<String, dynamic>? solution,
  }) {
    final teamSkillsStr = teamSkills.join(', ');
    final teamMembersStr = teamMembers.join(', ');
    
    // Build essential project context (optimized for API limits)
    String problemContext = '''**Project:** $projectTitle
**Description:** ${_truncateText(projectDescription, 200)}
**Platform:** $targetPlatform | **Difficulty:** $difficulty''';
    
    // Add key features from problem (limited)
    if (problem?.features.isNotEmpty == true) {
      final limitedFeatures = problem!.features.take(3).map((f) => _truncateText(f, 50)).join(', ');
      problemContext += '''\n**Features:** $limitedFeatures''';
    }
    
    // Add essential solution info (limited)
    String solutionContext = '';
    if (solution != null) {
      // Safely extract title (handle both String and nested structures)
      String solutionTitle = '';
      final titleValue = solution['title'];
      if (titleValue is String) {
        solutionTitle = _truncateText(titleValue, 50);
      } else if (titleValue != null) {
        // If it's not a string, try to extract meaningful value
        solutionTitle = 'Custom Solution';
      }
      
      if (solutionTitle.isNotEmpty) {
        solutionContext = '''\n**Solution:** $solutionTitle''';
      }
      
      // Safely extract tech stack
      if (solution['techStack'] != null) {
        final techStackValue = solution['techStack'];
        List<String>? techStack;
        
        if (techStackValue is List) {
          techStack = techStackValue
              .whereType<String>()
              .toList();
        } else if (techStackValue is String) {
          techStack = [techStackValue];
        }
        
        if (techStack != null && techStack.isNotEmpty) {
          final limitedTech = techStack.take(4).join(', ');
          solutionContext += ''' | **Tech:** $limitedTech''';
        }
      }
    }
    
    return '''
Create a student-friendly project roadmap with 12-16 simple tasks.

$problemContext$solutionContext

**Team:** $teamMembersStr | **Duration:** $durationInDays days | **Skills:** $teamSkillsStr

**Task Format (JSON Array):**
[
  {
    "title": "Task name",
    "description": "Simple description",
    "category": "Planning|Learning|Setup|Development|Testing|Final",
    "priority": "High|Medium|Low",
    "estimatedHours": 4,
    "assignedTo": "Team",
    "dayOffset": 1,
    "dependencies": [],
    "deliverables": ["What to create"],
    "skills_required": ["Skills needed"]
  }
]

**Guidelines:**
1. Use simple, clear language for students
2. Each task: 2-8 hours, 1-2 days max
3. Focus on core features, avoid complexity
4. Include learning tasks for new technologies
5. Start with planning, end with demo/docs

**Categories:**
- Planning: Requirements, project plan
- Learning: Tutorials, skill practice
- Setup: Tools, project structure
- Development: Build features step-by-step
- Testing: Manual testing, bug fixes
- Final: Documentation, demo prep

Return ONLY the JSON array:
''';
  }

  List<String> _parseAssignedTo(dynamic assignedTo, List<String> teamMembers) {
    if (assignedTo == null) {
      // Default: assign to first team member or "Team"
      return teamMembers.isNotEmpty ? [teamMembers.first] : ['Team'];
    }
    
    final parsed = _toStringList(assignedTo) ?? [];
    
    // Validate assigned members exist in team
    final validAssignments = parsed.where((name) => 
        teamMembers.contains(name) || name == 'Team'
    ).toList();
    
    return validAssignments.isNotEmpty 
        ? validAssignments 
        : (teamMembers.isNotEmpty ? [teamMembers.first] : ['Team']);
  }

  List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      // Handle comma-separated string
      return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    
    // Single value
    return [value.toString().trim()];
  }
  
  /// Helper method to truncate text to prevent token overflow
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
  
  /// Generate fallback roadmap when AI fails
  List<Task> _generateFallbackRoadmap({
    required String projectTitle,
    required int durationInDays,
    required DateTime startDate,
    required DateTime endDate,
    required String targetPlatform,
    required List<String> teamMembers,
  }) {
    debugPrint('🔄 Generating fallback roadmap for $projectTitle');
    
    final now = DateTime.now();
    final List<Task> tasks = [];
    
    // Create basic task templates based on platform
    List<Map<String, dynamic>> taskTemplates;
    
    if (targetPlatform.toLowerCase().contains('app') || targetPlatform.toLowerCase().contains('mobile')) {
      taskTemplates = [
        {'title': 'Project Planning', 'description': 'Define requirements and create project plan', 'category': 'Planning', 'hours': 4, 'days': 1},
        {'title': 'Setup Development Environment', 'description': 'Install Flutter/React Native and setup project', 'category': 'Setup', 'hours': 6, 'days': 3},
        {'title': 'Learn Framework Basics', 'description': 'Complete tutorials and understand framework fundamentals', 'category': 'Learning', 'hours': 8, 'days': 7},
        {'title': 'Create App Structure', 'description': 'Setup basic app navigation and folder structure', 'category': 'Development', 'hours': 6, 'days': 10},
        {'title': 'Design UI Screens', 'description': 'Create wireframes and basic UI components', 'category': 'Development', 'hours': 8, 'days': 14},
        {'title': 'Implement Core Features', 'description': 'Build main functionality step by step', 'category': 'Development', 'hours': 12, 'days': 21},
        {'title': 'Add Data Storage', 'description': 'Implement database or local storage', 'category': 'Development', 'hours': 8, 'days': 28},
        {'title': 'User Authentication', 'description': 'Add login/signup functionality if needed', 'category': 'Development', 'hours': 10, 'days': 35},
        {'title': 'Test Core Features', 'description': 'Manual testing of all implemented features', 'category': 'Testing', 'hours': 6, 'days': 42},
        {'title': 'Fix Bugs and Issues', 'description': 'Resolve any bugs found during testing', 'category': 'Testing', 'hours': 8, 'days': 49},
        {'title': 'Polish UI/UX', 'description': 'Improve design and user experience', 'category': 'Development', 'hours': 6, 'days': 56},
        {'title': 'Create Documentation', 'description': 'Write README and basic documentation', 'category': 'Final', 'hours': 4, 'days': 63},
        {'title': 'Prepare Demo', 'description': 'Create demo presentation and test run', 'category': 'Final', 'hours': 4, 'days': 70},
        {'title': 'Final Testing', 'description': 'Complete final testing and validation', 'category': 'Testing', 'hours': 6, 'days': 77},
      ];
    } else {
      // Web project templates
      taskTemplates = [
        {'title': 'Project Planning', 'description': 'Define requirements and create project plan', 'category': 'Planning', 'hours': 4, 'days': 1},
        {'title': 'Setup Development Environment', 'description': 'Install Node.js/React and setup project structure', 'category': 'Setup', 'hours': 6, 'days': 3},
        {'title': 'Learn Web Technologies', 'description': 'Study HTML, CSS, JavaScript fundamentals', 'category': 'Learning', 'hours': 8, 'days': 7},
        {'title': 'Create Project Structure', 'description': 'Setup basic web app structure and routing', 'category': 'Development', 'hours': 6, 'days': 10},
        {'title': 'Design Homepage', 'description': 'Create main landing page and navigation', 'category': 'Development', 'hours': 8, 'days': 14},
        {'title': 'Implement Core Pages', 'description': 'Build main functionality pages', 'category': 'Development', 'hours': 12, 'days': 21},
        {'title': 'Add Database Integration', 'description': 'Connect to database and implement CRUD operations', 'category': 'Development', 'hours': 10, 'days': 28},
        {'title': 'User Management', 'description': 'Add user registration and login features', 'category': 'Development', 'hours': 8, 'days': 35},
        {'title': 'Test Website Features', 'description': 'Manual testing across different browsers', 'category': 'Testing', 'hours': 6, 'days': 42},
        {'title': 'Fix Issues and Bugs', 'description': 'Resolve any issues found during testing', 'category': 'Testing', 'hours': 8, 'days': 49},
        {'title': 'Improve Styling', 'description': 'Polish CSS and make responsive design', 'category': 'Development', 'hours': 6, 'days': 56},
        {'title': 'Write Documentation', 'description': 'Create user guide and technical docs', 'category': 'Final', 'hours': 4, 'days': 63},
        {'title': 'Deploy Website', 'description': 'Deploy to hosting platform and test live', 'category': 'Final', 'hours': 6, 'days': 70},
      ];
    }
    
    // Adjust timeline based on actual duration
    final scaleFactor = durationInDays / 77.0; // 77 is the base timeline
    
    for (int i = 0; i < taskTemplates.length; i++) {
      final template = taskTemplates[i];
      final adjustedDays = ((template['days'] as int) * scaleFactor).round();
      final dueDate = startDate.add(Duration(days: adjustedDays));
      
      // Ensure due date doesn't exceed end date
      final finalDueDate = dueDate.isAfter(endDate) ? endDate : dueDate;
      
      final task = Task(
        id: 'fallback_task_${now.millisecondsSinceEpoch}_$i',
        title: template['title'] as String,
        description: template['description'] as String,
        dueDate: finalDueDate,
        priority: i < 3 ? 'High' : (i < 8 ? 'Medium' : 'Low'),
        category: template['category'] as String,
        assignedTo: teamMembers.isNotEmpty ? [teamMembers.first] : ['Team'],
        estimatedHours: template['hours'] as int,
        dependencies: i > 0 ? [tasks[i-1].id] : [],
        metadata: {
          'fallback': true,
          'platform': targetPlatform,
        },
        createdAt: now,
        updatedAt: now,
      );
      
      tasks.add(task);
    }
    
    debugPrint('✅ Generated ${tasks.length} fallback roadmap tasks');
    return tasks.take(14).toList(); // Limit to 14 tasks
  }
}
