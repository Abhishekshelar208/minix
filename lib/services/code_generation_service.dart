import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:minix/models/code_generation.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:minix/config/secrets.dart';

class CodeGenerationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _apiKey = Secrets.geminiApiKey;

  // Generate code modules and steps based on project requirements
  Future<CodeGenerationProject> generateCodeProject({
    required String projectSpaceId,
    required String projectName,
    required Problem problem,
    required ProjectSolution solution,
    required String targetPlatform,
    required String difficulty,
    required List<String> teamSkills,
  }) async {
    try {
      // Generate modules based on project requirements
      final modules = await _generateModulesForPlatform(
        targetPlatform: targetPlatform,
        problem: problem,
        solution: solution,
        difficulty: difficulty,
        teamSkills: teamSkills,
      );

      final codeProject = CodeGenerationProject(
        id: _generateId(),
        projectSpaceId: projectSpaceId,
        projectName: projectName,
        targetPlatform: targetPlatform,
        modules: modules,
        createdAt: DateTime.now(),
      );

      // Save to Firebase
      await _saveCodeProject(codeProject);

      return codeProject;
    } catch (e) {
      throw Exception('Failed to generate code project: $e');
    }
  }

  // Generate platform-specific modules
  Future<List<CodeModule>> _generateModulesForPlatform({
    required String targetPlatform,
    required Problem problem,
    required ProjectSolution solution,
    required String difficulty,
    required List<String> teamSkills,
  }) async {
    final modules = <CodeModule>[];

    switch (targetPlatform.toLowerCase()) {
      case 'app':
      case 'flutter':
        modules.addAll(await _generateFlutterModules(problem, solution, difficulty));
        break;
      case 'web':
        modules.addAll(await _generateWebModules(problem, solution, difficulty));
        break;
      case 'desktop':
        modules.addAll(await _generateDesktopModules(problem, solution, difficulty));
        break;
      default:
        modules.addAll(await _generateGenericModules(problem, solution, difficulty));
    }

    return modules;
  }

  // Generate Flutter-specific modules
  Future<List<CodeModule>> _generateFlutterModules(
    Problem problem,
    ProjectSolution solution,
    String difficulty,
  ) async {
    final modules = <CodeModule>[];

    // 1. Project Setup Module
    modules.add(CodeModule(
      id: 'flutter_setup',
      title: 'Project Setup',
      description: 'Initialize Flutter project with necessary dependencies',
      category: 'setup',
      order: 1,
      steps: await _generateFlutterSetupSteps(problem, solution),
    ));

    // 2. UI/UX Module
    modules.add(CodeModule(
      id: 'flutter_ui',
      title: 'User Interface',
      description: 'Build the app\'s user interface with Flutter widgets',
      category: 'core',
      order: 2,
      dependencies: ['flutter_setup'],
      steps: await _generateFlutterUISteps(problem, solution),
    ));

    // 3. State Management Module
    modules.add(CodeModule(
      id: 'flutter_state',
      title: 'State Management',
      description: 'Implement state management for app functionality',
      category: 'core',
      order: 3,
      dependencies: ['flutter_ui'],
      steps: await _generateFlutterStateSteps(problem, solution),
    ));

    // 4. Backend Integration Module
    modules.add(CodeModule(
      id: 'flutter_backend',
      title: 'Backend Integration',
      description: 'Connect to Firebase and handle data operations',
      category: 'features',
      order: 4,
      dependencies: ['flutter_state'],
      steps: await _generateFlutterBackendSteps(problem, solution),
    ));

    // 5. Features Module
    modules.add(CodeModule(
      id: 'flutter_features',
      title: 'Core Features',
      description: 'Implement main app features and functionality',
      category: 'features',
      order: 5,
      dependencies: ['flutter_backend'],
      steps: await _generateFlutterFeaturesSteps(problem, solution),
    ));

    return modules;
  }

  // Generate Flutter setup steps
  Future<List<CodeStep>> _generateFlutterSetupSteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'create_project',
      title: 'Create Flutter Project',
      description: 'Initialize a new Flutter project with proper structure',
      prompt: CodePrompt(
        instruction: 'Create a new Flutter project for ${problem.title}',
        context: 'Setting up a Flutter application with clean architecture',
        requirements: [
          'Use flutter create command',
          'Set up proper folder structure',
          'Configure pubspec.yaml with required dependencies',
        ],
        expectedOutput: 'A properly initialized Flutter project structure',
        hints: [
          'Use meaningful package name',
          'Include common dependencies like firebase_core, provider, etc.',
        ],
      ),
      filePath: 'pubspec.yaml',
    ));

    steps.add(CodeStep(
      id: 'setup_dependencies',
      title: 'Configure Dependencies',
      description: 'Add all necessary Flutter packages and dependencies',
      prompt: CodePrompt(
        instruction: 'Configure pubspec.yaml with required dependencies for ${solution.title}',
        context: 'Adding Flutter packages for ${solution.keyFeatures.join(", ")}',
        requirements: [
          'Add Firebase dependencies',
          'Include UI packages (google_fonts, etc.)',
          'Add state management packages',
          'Include necessary utility packages',
        ],
        expectedOutput: 'Complete pubspec.yaml with all required dependencies',
        hints: [
          'Use latest stable versions',
          'Group dependencies logically',
          'Include dev_dependencies for testing',
        ],
      ),
      filePath: 'pubspec.yaml',
    ));

    return steps;
  }

  // Generate Flutter UI steps
  Future<List<CodeStep>> _generateFlutterUISteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'main_app_structure',
      title: 'Main App Structure',
      description: 'Create the main app widget and navigation structure',
      prompt: CodePrompt(
        instruction: 'Create the main Flutter app structure for ${problem.title}',
        context: 'Building the root widget with theme and navigation',
        requirements: [
          'Create MaterialApp with custom theme',
          'Set up navigation structure',
          'Configure app-wide settings',
        ],
        expectedOutput: 'Complete main.dart file with app structure',
        hints: [
          'Use consistent color scheme',
          'Set up proper routing',
          'Configure Firebase initialization',
        ],
      ),
      filePath: 'lib/main.dart',
    ));

    return steps;
  }

  // Generate other platform modules (simplified for now)
  Future<List<CodeModule>> _generateWebModules(
    Problem problem,
    ProjectSolution solution,
    String difficulty,
  ) async {
    // TODO: Implement web-specific modules
    return [];
  }

  Future<List<CodeModule>> _generateDesktopModules(
    Problem problem,
    ProjectSolution solution,
    String difficulty,
  ) async {
    // TODO: Implement desktop-specific modules
    return [];
  }

  Future<List<CodeModule>> _generateGenericModules(
    Problem problem,
    ProjectSolution solution,
    String difficulty,
  ) async {
    // TODO: Implement generic modules
    return [];
  }

  // Generate remaining Flutter steps methods (simplified)
  Future<List<CodeStep>> _generateFlutterStateSteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    return [
      // Add state management steps
    ];
  }

  Future<List<CodeStep>> _generateFlutterBackendSteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    return [
      // Add backend integration steps
    ];
  }

  Future<List<CodeStep>> _generateFlutterFeaturesSteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    return [
      // Add feature implementation steps
    ];
  }

  // Generate code using AI for a specific step
  Future<String> generateCodeForStep({
    required CodeStep step,
    required String projectContext,
    required Map<String, dynamic> projectData,
  }) async {
    try {
      final language = _getLanguageFromPlatform(projectData['targetPlatform'] ?? 'flutter');
      final prompt = '''
Generate ${language.toUpperCase()} code for ${step.filePath ?? 'file'}: ${step.title}

Project Context: $projectContext
Step Description: ${step.description}

Instructions: ${step.prompt.instruction}
Context: ${step.prompt.context}

Requirements:
${step.prompt.requirements.map((req) => '- $req').join('\n')}

Expected Output: ${step.prompt.expectedOutput}

Please provide clean, well-commented $language code that follows best practices.
Return ONLY the code without markdown formatting or explanations.
''';

      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.3),
      );

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(minutes: 2));

      final generatedCode = response.text ?? '';
      return generatedCode.trim();
    } catch (e) {
      throw Exception('Failed to generate code for step: $e');
    }
  }

  String _getLanguageFromPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'app':
      case 'flutter':
        return 'dart';
      case 'web':
        return 'javascript';
      case 'desktop':
        return 'python';
      default:
        return 'text';
    }
  }

  // Save code project to Firebase
  Future<void> _saveCodeProject(CodeGenerationProject project) async {
    await _database
        .child('CodeProjects')
        .child(project.projectSpaceId)
        .set(project.toMap());
  }

  // Get existing code project
  Future<CodeGenerationProject?> getCodeProject(String projectSpaceId) async {
    final snapshot = await _database
        .child('CodeProjects')
        .child(projectSpaceId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return CodeGenerationProject.fromMap(data);
    }
    return null;
  }

  // Update step completion
  Future<void> updateStepCompletion({
    required String projectSpaceId,
    required String moduleId,
    required String stepId,
    required String generatedCode,
    String? userFeedback,
  }) async {
    final project = await getCodeProject(projectSpaceId);
    if (project == null) return;

    final updatedModules = project.modules.map((module) {
      if (module.id == moduleId) {
        final updatedSteps = module.steps.map((step) {
          if (step.id == stepId) {
            return step.copyWith(
              generatedCode: generatedCode,
              isCompleted: true,
              completedAt: DateTime.now(),
              userFeedback: userFeedback,
            );
          }
          return step;
        }).toList();
        return module.copyWith(steps: updatedSteps);
      }
      return module;
    }).toList();

    final updatedProject = CodeGenerationProject(
      id: project.id,
      projectSpaceId: project.projectSpaceId,
      projectName: project.projectName,
      targetPlatform: project.targetPlatform,
      modules: updatedModules,
      currentModuleIndex: project.currentModuleIndex,
      currentStepIndex: project.currentStepIndex,
      isCompleted: project.isCompleted,
      createdAt: project.createdAt,
      completedAt: project.completedAt,
    );

    await _saveCodeProject(updatedProject);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}