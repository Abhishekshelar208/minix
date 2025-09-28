import 'dart:async';
import 'dart:convert';
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

    print('🚀 Calling Gemini API for domain: $domain, year: $year, skills: $skills');

    final prompt = _buildPrompt(
      domain: domain,
      year: year,
      platforms: platforms,
      skills: skills,
      difficulty: difficulty,
      count: count,
    );

    print('📝 Prompt sent to Gemini: ${prompt.substring(0, 100)}...');

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
        print('🔄 Attempt $attempt/$maxAttempts');
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(minutes: 2)); // 2 minutes timeout

        text = response.text ?? '';
        print('📥 Raw Gemini response (${text.length} chars): ${text.substring(0, text.length.clamp(0, 200))}...');

        if (text.isNotEmpty) break; // Success
        
        if (attempt < maxAttempts) {
          print('⚠️ Empty response, retrying...');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        print('⚠️ Attempt $attempt failed: $e');
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    if (text.isEmpty) {
      throw StateError('Gemini returned empty response after $maxAttempts attempts');
    }

    // Parse JSON from text. Be tolerant to code fences or prose.
    final jsonString = _extractJsonArray(text);
    print('🔍 Extracted JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 300))}...');
    
    if (jsonString.isEmpty || jsonString == '[]') {
      throw StateError('No valid JSON found in Gemini response. Raw text: ${text.substring(0, 500)}...');
    }

    final List<dynamic> arr = jsonDecode(jsonString) as List<dynamic>;
    print('✅ Parsed ${arr.length} items from JSON');

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
        print('✅ Created problem: ${map['title']}');
      }
    }
    
    print('🎉 Successfully created ${problems.length} AI problems');
    return problems;
  }
  
  // Generate detailed problem information with real-life examples
  Future<Problem> generateDetailedProblem(Problem baseProblem) async {
    if (apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Pass via --dart-define=GEMINI_API_KEY=...');
    }

    print('🔍 Generating detailed problem info for: ${baseProblem.title}');

    final prompt = _buildDetailedPrompt(baseProblem);
    print('📝 Detailed prompt sent to Gemini: ${prompt.substring(0, 100)}...');

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
      print('📥 Detailed response (${text.length} chars): ${text.substring(0, text.length.clamp(0, 200))}...');

      if (text.isEmpty) {
        throw StateError('Gemini returned empty detailed response');
      }

      // Parse JSON from text
      final jsonString = _extractJsonObject(text);
      print('🔍 Extracted detailed JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 300))}...');
      
      if (jsonString.isEmpty || jsonString == '{}') {
        throw StateError('No valid JSON found in detailed response. Raw text: ${text.substring(0, 500)}...');
      }

      final Map<String, dynamic> detailedData = jsonDecode(jsonString) as Map<String, dynamic>;
      print('✅ Parsed detailed data successfully');
      
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
      
      print('🎉 Successfully generated detailed problem info');
      return detailedProblem;
    } catch (e) {
      print('⚠️ Error generating detailed problem: $e');
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
    final plat = platforms.isEmpty ? 'App, Web, Website (choose best fit)' : platforms.join(', ');
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

  List<Problem> _getFallbackProblems({
    required String domain,
    required int year,
    required List<String> platforms,
    required List<String> skills,
    String? difficulty,
    required int count,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaultPlatforms = platforms.isEmpty ? ['App', 'Web'] : platforms;
    final defaultSkills = skills.isEmpty ? ['Flutter', 'Firebase'] : skills;
    final defaultDifficulty = difficulty ?? 'Intermediate';
    
    final Map<String, List<Map<String, dynamic>>> sampleProblems = {
      'College': [
        {
          'title': 'Smart Attendance System',
          'description': 'Automate attendance tracking using QR codes or face recognition',
          'features': ['QR code scanning', 'Face recognition', 'Attendance reports', 'Student dashboard', 'Teacher interface'],
          'beneficiaries': ['Students', 'Teachers', 'Administration'],
          'data_sources': ['Firebase Firestore', 'Camera API', 'CSV export'],
        },
        {
          'title': 'Campus Event Management',
          'description': 'Platform for organizing and managing college events and activities',
          'features': ['Event creation', 'Registration system', 'Notifications', 'Calendar integration', 'Feedback system'],
          'beneficiaries': ['Students', 'Event organizers', 'Administration'],
          'data_sources': ['Firebase RTDB', 'Push notifications', 'Calendar API'],
        },
        {
          'title': 'Library Book Tracker',
          'description': 'Digital system to track book borrowing and returns',
          'features': ['Book search', 'Issue/return tracking', 'Due date reminders', 'Fine calculation', 'Inventory management'],
          'beneficiaries': ['Students', 'Librarians'],
          'data_sources': ['SQLite', 'Barcode scanner', 'SMS API'],
        },
      ],
      'Hospital': [
        {
          'title': 'Patient Appointment System',
          'description': 'Online booking and management of patient appointments',
          'features': ['Online booking', 'Doctor schedules', 'Patient records', 'Appointment reminders', 'Payment integration'],
          'beneficiaries': ['Patients', 'Doctors', 'Hospital staff'],
          'data_sources': ['Firebase Firestore', 'Payment gateway', 'SMS API'],
        },
        {
          'title': 'Medicine Inventory Tracker',
          'description': 'Track medicine stock levels and expiry dates',
          'features': ['Stock monitoring', 'Expiry alerts', 'Supplier management', 'Purchase orders', 'Reports'],
          'beneficiaries': ['Pharmacists', 'Hospital management'],
          'data_sources': ['MySQL', 'Barcode scanner', 'Email notifications'],
        },
      ],
      'E-commerce': [
        {
          'title': 'Local Marketplace App',
          'description': 'Connect local buyers and sellers in your community',
          'features': ['Product listings', 'Search and filters', 'Chat system', 'Payment gateway', 'Order tracking'],
          'beneficiaries': ['Local sellers', 'Customers', 'Community'],
          'data_sources': ['Firebase Firestore', 'Image storage', 'Payment API'],
        },
      ],
      'Parking': [
        {
          'title': 'Smart Parking Finder',
          'description': 'Help drivers find available parking spots in real-time',
          'features': ['Spot availability', 'Reservation system', 'Payment integration', 'Navigation', 'History tracking'],
          'beneficiaries': ['Drivers', 'Parking lot owners'],
          'data_sources': ['Firebase RTDB', 'Maps API', 'Payment gateway'],
        },
      ],
    };

    final domainProblems = sampleProblems[domain] ?? sampleProblems['College']!;
    final selectedProblems = domainProblems.take(count.clamp(1, domainProblems.length)).toList();
    
    return selectedProblems.asMap().entries.map((entry) {
      final i = entry.key;
      final problem = entry.value;
      final id = 'fallback_${domain.toLowerCase()}_${now}_$i';
      
      return Problem.fromMap(id, {
        'title': problem['title'],
        'domain': domain,
        'description': problem['description'],
        'platform': defaultPlatforms,
        'year': [year, if (year > 1) year - 1, if (year < 4) year + 1].take(2).toList(),
        'skills': defaultSkills,
        'difficulty': defaultDifficulty,
        'scope': 'Medium',
        'beneficiaries': problem['beneficiaries'],
        'features': problem['features'],
        'data_sources': problem['data_sources'],
        'updatedAt': now,
      });
    }).toList();
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
      return '[' + cleanText.substring(s2, e2 + 1) + ']';
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

    print('🚀 Generating roadmap for: $projectTitle');

    final durationInDays = endDate.difference(startDate).inDays;
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

    print('📝 Roadmap prompt sent to Gemini');

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
    );

    const maxAttempts = 3;
    late String text;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('🔄 Roadmap generation attempt $attempt/$maxAttempts');
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(minutes: 3)); // 3 minutes for roadmap

        text = response.text ?? '';
        print('📥 Raw roadmap response (${text.length} chars)');

        if (text.isNotEmpty) break;
        
        if (attempt < maxAttempts) {
          print('⚠️ Empty roadmap response, retrying...');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        print('⚠️ Roadmap attempt $attempt failed: $e');
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    if (text.isEmpty) {
      throw StateError('Gemini returned empty roadmap after $maxAttempts attempts');
    }

    // Parse JSON from text
    final jsonString = _extractJsonArray(text);
    print('🔍 Extracted roadmap JSON: ${jsonString.substring(0, jsonString.length.clamp(0, 300))}...');
    
    if (jsonString.isEmpty || jsonString == '[]') {
      throw StateError('No valid roadmap JSON found in response');
    }

    final List<dynamic> arr = jsonDecode(jsonString) as List<dynamic>;
    print('✅ Parsed ${arr.length} tasks from roadmap JSON');

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
            taskDueDate = DateTime.parse(item['dueDate']);
          } else if (item['dayOffset'] is int) {
            taskDueDate = startDate.add(Duration(days: item['dayOffset']));
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
          estimatedHours: item['estimatedHours'] ?? 8,
          dependencies: _toStringList(item['dependencies']) ?? [],
          metadata: metadata.isNotEmpty ? metadata : null,
          createdAt: now,
          updatedAt: now,
        );
        
        tasks.add(task);
        print('✅ Created task: ${task.title} (Due: ${task.dueDate.day}/${task.dueDate.month})');
      }
    }
    
    print('🎉 Successfully generated ${tasks.length} roadmap tasks');
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
    
    // Build comprehensive problem context
    String problemContext = '''**Problem Context:**
- Title: $projectTitle
- Basic Description: $projectDescription
- Domain: ${problem?.domain ?? 'Not specified'}
- Scope: ${problem?.scope ?? 'Medium'}
- Platform: $targetPlatform
- Difficulty: $difficulty''';
    
    // Add detailed problem info if available
    if (problem?.hasDetailedInfo == true) {
      if (problem!.detailedDescription != null && problem.detailedDescription!.isNotEmpty) {
        problemContext += '''\n- Detailed Description: ${problem.detailedDescription}''';
      }
      
      if (problem.realLifeExample != null && problem.realLifeExample!.isNotEmpty) {
        problemContext += '''\n- Real-life Examples:
${problem.realLifeExample!.map((example) => '  • $example').join('\n')}''';
      }
      
      if (problem.detailedFeatures != null && problem.detailedFeatures!.isNotEmpty) {
        problemContext += '''\n- Expected Features:
${problem.detailedFeatures!.map((feature) => '  • $feature').join('\n')}''';
      }
      
      if (problem.implementationSteps != null && problem.implementationSteps!.isNotEmpty) {
        problemContext += '''\n- Suggested Implementation Steps:
${problem.implementationSteps!.asMap().entries.map((entry) => '  ${entry.key + 1}. ${entry.value}').join('\n')}''';
      }
      
      if (problem.challenges != null && problem.challenges!.isNotEmpty) {
        problemContext += '''\n- Known Challenges:
${problem.challenges!.map((challenge) => '  • $challenge').join('\n')}''';
      }
      
      if (problem.learningOutcomes != null && problem.learningOutcomes!.isNotEmpty) {
        problemContext += '''\n- Learning Outcomes:
${problem.learningOutcomes!.map((outcome) => '  • $outcome').join('\n')}''';
      }
    }
    
    // Build solution context
    String solutionContext = '';
    if (solution != null) {
      solutionContext = '''\n\n**Selected Solution Context:**
- Solution Title: ${solution['title'] ?? 'Custom Solution'}
- Approach: ${solution['description'] ?? 'No description available'}''';
      
      if (solution['detailedDescription'] != null && solution['detailedDescription'].toString().isNotEmpty) {
        solutionContext += '''\n- Detailed Approach: ${solution['detailedDescription']}''';
      }
      
      if (solution['keyFeatures'] != null) {
        final features = solution['keyFeatures'] as List?;
        if (features != null && features.isNotEmpty) {
          solutionContext += '''\n- Key Features:
${features.map((feature) => '  • $feature').join('\n')}''';
        }
      }
      
      if (solution['techStack'] != null) {
        final techStack = solution['techStack'] as List?;
        if (techStack != null && techStack.isNotEmpty) {
          solutionContext += '''\n- Technology Stack:
${techStack.map((tech) => '  • $tech').join('\n')}''';
        }
      }
      
      if (solution['implementationSteps'] != null) {
        final steps = solution['implementationSteps'] as List?;
        if (steps != null && steps.isNotEmpty) {
          solutionContext += '''\n- Implementation Steps:
${steps.asMap().entries.map((entry) => '  ${entry.key + 1}. ${entry.value}').join('\n')}''';
        }
      }
      
      if (solution['challenges'] != null) {
        final challenges = solution['challenges'] as List?;
        if (challenges != null && challenges.isNotEmpty) {
          solutionContext += '''\n- Expected Challenges:
${challenges.map((challenge) => '  • $challenge').join('\n')}''';
        }
      }
      
      if (solution['timeline'] != null) {
        final timeline = solution['timeline'] as Map?;
        if (timeline != null && timeline.isNotEmpty) {
          solutionContext += '''\n- Estimated Timeline:
${timeline.entries.map((entry) => '  • ${entry.key}: ${entry.value}').join('\n')}''';
        }
      }
    }
    
    return '''
You are an expert project management consultant creating a comprehensive, detailed roadmap for an engineering project. Use ALL the provided context to generate the most relevant and practical roadmap.

$problemContext$solutionContext

**Team & Timeline:**
- Duration: $durationInDays days (from ${startDate.day}/${startDate.month}/${startDate.year} to ${endDate.day}/${endDate.month}/${endDate.year})
- Team Members: $teamMembersStr
- Team Skills: $teamSkillsStr


**STUDENT-FRIENDLY MINI PROJECT ROADMAP:**
Create a SIMPLE, EASY-TO-FOLLOW roadmap perfect for college students building mini projects. Generate 12-18 basic tasks as a STRICT JSON array.

**Focus on SIMPLICITY and LEARNING:**
- Tasks should be beginner-friendly and achievable for students
- Use simple language that students can easily understand
- Break down complex concepts into small, manageable steps
- Focus on core functionality rather than advanced features
- Include learning and practice tasks for skill development

Each task should include:
- title (string): Simple, clear task name (e.g., "Create Basic Login Page")
- description (string): Easy-to-understand description with simple steps
- category (string): One of "Planning", "Learning", "Setup", "Development", "Testing", "Final"
- priority (string): "High", "Medium", or "Low"
- estimatedHours (number): Realistic hours for students (2-12 hours per task)
- assignedTo (string): Team member name or "Team"
- dayOffset (number): Days from start when due
- dependencies (array of strings): Which tasks must be done first
- deliverables (array of strings): What student will create/complete
- skills_required (array of strings): Basic skills needed

**STUDENT-FOCUSED GUIDELINES:**
1. **Start with basics**: Planning, learning, and simple setup tasks
2. **Use student language**: Avoid complex technical jargon
3. **Small steps**: Each task should take max 1-2 days for students
4. **Learning focus**: Include tasks to learn technologies step-by-step
5. **Core features only**: Focus on main functionality, not advanced features
6. **Simple testing**: Basic manual testing, not complex automated tests
7. **Practical deliverables**: Working code, simple documentation, demo
8. **Achievable timeline**: Realistic for student schedules and skill level

**SIMPLE TASK CATEGORIES:**
- **Planning**: Understanding requirements, creating project plan
- **Learning**: Tutorials, practice with new technologies
- **Setup**: Installing tools, creating basic project structure
- **Development**: Building core features step by step
- **Testing**: Simple manual testing and bug fixes
- **Final**: Documentation, demo preparation, project completion

**EXAMPLE STUDENT TASKS:**
- "Watch Flutter Tutorial Videos" (Learning)
- "Create Basic App Structure" (Setup)
- "Build Simple Login Form" (Development)
- "Test Login Functionality" (Testing)
- "Write Simple README File" (Final)

Return ONLY the JSON array for a STUDENT-FRIENDLY mini project:
[{"title": "Create Project Plan", "description": "Write down what your app will do and list the main features", "category": "Planning", ...}]
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
}
