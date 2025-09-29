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
    const String targetPlatform = 'App'; // Default platform for Flutter modules
    final modules = <CodeModule>[];

    // 1. Project Overview Module (First step)
    modules.add(CodeModule(
      id: 'project_overview',
      title: 'Project Overview',
      description: 'Introduce your project to AI coding assistant',
      category: 'overview',
      order: 1,
      steps: await _generateProjectOverviewSteps(problem, solution),
    ));

    // 2. Environment Setup Module (Second step)
    modules.add(CodeModule(
      id: 'environment_setup',
      title: 'Environment Setup & Dependencies',
      description: 'Check and install all required tools and dependencies',
      category: 'setup',
      order: 2,
      steps: await _generateEnvironmentSetupSteps(problem, solution),
    ));

    // 3. Project Creation & File Structure Module (Third step)
    modules.add(CodeModule(
      id: 'project_creation',
      title: 'Project Creation & File Structure',
      description: 'Create new project and set up complete folder structure',
      category: 'setup',
      order: 3,
      steps: await _generateProjectCreationSteps(problem, solution, targetPlatform),
    ));

    // 4. MVP Frontend UI Module (Fourth step)
    modules.add(CodeModule(
      id: 'mvp_frontend',
      title: 'Create MVP (Frontend UI)',
      description: 'Build professional UI with all frontend components and screens',
      category: 'ui',
      order: 4,
      steps: await _generateMVPFrontendSteps(problem, solution, targetPlatform),
    ));

    // 5. Backend Functionality Module (Fifth step)
    modules.add(CodeModule(
      id: 'backend_functionality',
      title: 'Implement Functionality (Backend Integration)',
      description: 'Add all backend functionality to make the project fully functional',
      category: 'backend',
      order: 5,
      steps: await _generateBackendFunctionalitySteps(problem, solution, targetPlatform),
    ));

    // 6. Testing & Bug Fixes Module (Sixth step)
    modules.add(CodeModule(
      id: 'testing_bugfixes',
      title: 'Testing & Bug Fixes',
      description: 'Test project thoroughly and fix all errors for perfect functionality',
      category: 'testing',
      order: 6,
      steps: await _generateTestingBugfixesSteps(problem, solution, targetPlatform),
    ));

    // 7. Run Project Module (Seventh and final step)
    modules.add(CodeModule(
      id: 'run_project',
      title: 'Run Project & Demo',
      description: 'Launch the completed project and showcase all functionality',
      category: 'demo',
      order: 7,
      steps: await _generateRunProjectSteps(problem, solution, targetPlatform),
    ));

    return modules;
  }
  
  // Generate Project Overview steps
  Future<List<CodeStep>> _generateProjectOverviewSteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'project_overview',
      title: 'Introduce Project to AI Assistant',
      description: 'Share complete project details with your AI coding partner',
      prompt: CodePrompt(
        instruction: 'Generate a comprehensive project introduction for AI assistant',
        context: 'Setting up AI collaboration for ${problem.title}',
        requirements: [
          'Include project name and team details',
          'Explain the problem being solved',
          'Describe the solution approach',
          'List key features and technology stack',
          'Set expectations for step-by-step guidance',
          'Request confirmation before proceeding',
        ],
        expectedOutput: 'A complete project overview prompt for AI assistant',
        hints: [
          'Copy this prompt and paste it to your AI tool (Cursor, Claude, ChatGPT, etc.)',
          'Wait for AI confirmation before sending next prompt',
          'This sets the context for all future prompts',
        ],
      ),
    ));

    return steps;
  }

  // Generate Environment Setup steps
  Future<List<CodeStep>> _generateEnvironmentSetupSteps(
    Problem problem,
    ProjectSolution solution,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'environment_check',
      title: 'Environment Setup & Dependencies Check',
      description: 'Verify and install all required development tools and dependencies',
      prompt: CodePrompt(
        instruction: 'Check and set up the complete development environment for this project',
        context: 'Ensuring all necessary tools, packages, and dependencies are installed and configured',
        requirements: [
          'Check current system environment (OS, versions, existing tools)',
          'Verify required development tools (Flutter SDK, Node.js, Python, etc.)',
          'Install missing packages and dependencies automatically where possible',
          'Provide manual installation instructions for complex software (MySQL, Docker, IDEs)',
          'Set up development environment configurations (environment variables, config files)',
          'Test all installations and connections to ensure everything works',
          'Create any necessary setup scripts or configuration files',
          'Verify database connections and third-party service configurations',
        ],
        expectedOutput: 'A fully configured development environment ready for coding',
        hints: [
          'Run system checks like: flutter doctor, node --version, python --version',
          'Use package managers: npm install, pip install, flutter pub get, etc.',
          'For manual installations, provide step-by-step instructions with download links',
          'Create environment files (.env) with placeholder values',
          'Test database connections and API endpoints if applicable',
          'Provide troubleshooting tips for common setup issues',
          'Do not start coding yet - wait for confirmation that environment is ready',
        ],
      ),
    ));

    return steps;
  }

  // Generate Project Creation & File Structure steps
  Future<List<CodeStep>> _generateProjectCreationSteps(
    Problem problem,
    ProjectSolution solution,
    String targetPlatform,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'project_creation',
      title: 'Create New Project & Setup File Structure',
      description: 'Create a new project and establish complete folder structure',
      prompt: CodePrompt(
        instruction: 'Create a new project and set up the complete file structure for this ${targetPlatform.toLowerCase()} application',
        context: 'Setting up project foundation with proper architecture and folder organization',
        requirements: [
          'Create new ${targetPlatform.toLowerCase()} project with appropriate commands',
          'Set up clean architecture folder structure',
          'Create all necessary directories (models, views, controllers, services, etc.)',
          'Initialize configuration files (pubspec.yaml, package.json, requirements.txt, etc.)',
          'Set up proper project naming and package structure',
          'Create initial placeholder files in each directory',
          'Set up version control (git) with proper .gitignore',
          'Configure project settings and metadata',
          'Create README.md with project information',
          'Set up development vs production configurations',
        ],
        expectedOutput: 'Complete project structure with all folders and initial files created',
        hints: [
          'Use platform-specific project creation commands (flutter create, create-react-app, etc.)',
          'Follow industry-standard folder structures for the chosen technology',
          'Create modular architecture with separation of concerns',
          'Include common folders: assets, configs, utils, constants, etc.',
          'Set up proper naming conventions for files and folders',
          'Initialize with sample/template files where appropriate',
          'Test the project setup by running initial build/compile commands',
          'Do not start implementing features yet - focus only on structure setup',
        ],
      ),
    ));

    return steps;
  }

  // Generate MVP Frontend UI steps
  Future<List<CodeStep>> _generateMVPFrontendSteps(
    Problem problem,
    ProjectSolution solution,
    String targetPlatform,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'mvp_frontend',
      title: 'Create MVP with Professional Frontend UI',
      description: 'Build complete user interface with all screens and components',
      prompt: CodePrompt(
        instruction: 'Create a complete MVP (Minimum Viable Product) with professional frontend UI for this ${targetPlatform.toLowerCase()} application',
        context: 'Building all user interface screens, components, and navigation with modern design principles',
        requirements: [
          'Create all main screens and pages as outlined in the solution',
          'Implement professional, modern UI design with consistent styling',
          'Build reusable UI components (buttons, cards, forms, etc.)',
          'Set up navigation between screens with proper routing',
          'Implement responsive design for different screen sizes',
          'Add loading states, error handling UI, and user feedback elements',
          'Create forms with validation UI (no backend validation yet)',
          'Implement dark/light theme support if applicable',
          'Add icons, images, and visual elements for better UX',
          'Create mock data and placeholder content to showcase features',
          'Ensure accessibility features (proper contrast, font sizes, etc.)',
          'Use platform-specific UI guidelines (Material Design, iOS, Web standards)',
        ],
        expectedOutput: 'Complete functional frontend with all screens and professional UI',
        hints: [
          'Focus ONLY on UI/UX - no backend integration or real data processing',
          'Use mock data and placeholder content to demonstrate features',
          'Create pixel-perfect designs with proper spacing and typography',
          'Implement smooth transitions and animations where appropriate',
          'Test the UI on different devices/screen sizes',
          'Make the app feel fully functional from a user perspective',
          'Use modern UI patterns and components for the chosen platform',
          'Do not implement backend logic - wait for backend integration prompt',
        ],
      ),
    ));

    return steps;
  }

  // Generate Backend Functionality steps
  Future<List<CodeStep>> _generateBackendFunctionalitySteps(
    Problem problem,
    ProjectSolution solution,
    String targetPlatform,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'backend_functionality',
      title: 'Implement Full Backend Functionality',
      description: 'Add all backend logic, database operations, and API integrations',
      prompt: CodePrompt(
        instruction: 'Implement complete backend functionality for this ${targetPlatform.toLowerCase()} application to make it fully functional',
        context: 'Building all backend logic, data operations, API integrations, and business logic to complete the project',
        requirements: [
          'Integrate with databases (Firebase, MySQL, PostgreSQL, etc.) for data persistence',
          'Implement authentication and user management system',
          'Create API endpoints and data services for all features',
          'Add real data validation, processing, and error handling',
          'Implement state management with real data flow',
          'Connect frontend forms to backend data operations (CRUD)',
          'Set up real-time data updates and synchronization',
          'Implement file upload/download functionality if needed',
          'Add push notifications and real-time messaging features',
          'Create data models and business logic for all features',
          'Implement security measures (authentication, authorization, data encryption)',
          'Add backend data validation and sanitization',
          'Set up proper error handling and logging',
          'Implement search, filtering, and pagination functionality',
          'Connect external APIs and third-party services',
          'Create backup and data recovery mechanisms',
        ],
        expectedOutput: 'Fully functional application with complete backend integration',
        hints: [
          'Replace all mock data with real database operations',
          'Implement proper authentication flows and session management',
          'Create comprehensive error handling for all operations',
          'Set up proper data models and relationships',
          'Implement real-time features using websockets or similar',
          'Add proper input validation and sanitization',
          'Create efficient database queries and optimize performance',
          'Test all functionality thoroughly with real data',
          'Implement proper logging and monitoring',
          'Ensure data consistency and transaction integrity',
          'Make the app production-ready with all features working',
        ],
      ),
    ));

    return steps;
  }

  // Generate Testing & Bug Fixes steps
  Future<List<CodeStep>> _generateTestingBugfixesSteps(
    Problem problem,
    ProjectSolution solution,
    String targetPlatform,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'testing_bugfixes',
      title: 'Complete Testing & Bug Fixes',
      description: 'Test the entire project and fix all errors for perfect functionality',
      prompt: CodePrompt(
        instruction: 'Thoroughly test the entire ${targetPlatform.toLowerCase()} application and fix all bugs, errors, and issues',
        context: 'Quality assurance phase to ensure the project works perfectly without any errors or issues',
        requirements: [
          'Run comprehensive testing on all features and functionalities',
          'Test user authentication, registration, login, and logout flows',
          'Verify all CRUD operations work correctly with real data',
          'Test all forms, validations, and error handling mechanisms',
          'Check responsive design on different screen sizes and devices',
          'Test navigation, routing, and all user interaction flows',
          'Verify database connections, queries, and data integrity',
          'Test API endpoints, request/response handling, and error cases',
          'Check performance, loading times, and optimization',
          'Test security features, authentication, and authorization',
          'Verify all business logic and calculations work correctly',
          'Test edge cases, boundary conditions, and error scenarios',
          'Check cross-platform compatibility (if applicable)',
          'Test real-time features, notifications, and synchronization',
          'Verify file uploads, downloads, and media handling',
          'Test search, filtering, sorting, and pagination features',
        ],
        expectedOutput: 'A perfectly working, bug-free, production-ready application',
        hints: [
          'Run the application and test every single feature manually',
          'Use debugging tools to identify and fix runtime errors',
          'Check console logs for errors, warnings, and issues',
          'Test with different data scenarios and edge cases',
          'Verify error messages are user-friendly and helpful',
          'Ensure proper loading states and user feedback',
          'Test on different browsers, devices, and screen sizes',
          'Fix any compilation errors, runtime errors, or crashes',
          'Optimize performance and fix any slow operations',
          'Ensure proper data validation and security measures',
          'Test backup, recovery, and data consistency features',
          'Document any known limitations or future improvements',
        ],
      ),
    ));

    return steps;
  }


  // Generate Run Project steps
  Future<List<CodeStep>> _generateRunProjectSteps(
    Problem problem,
    ProjectSolution solution,
    String targetPlatform,
  ) async {
    final steps = <CodeStep>[];

    steps.add(CodeStep(
      id: 'run_project',
      title: 'Run Project & See Output',
      description: 'Launch the completed project and demonstrate all functionality',
      prompt: CodePrompt(
        instruction: 'Run the completed ${targetPlatform.toLowerCase()} project and demonstrate all features working perfectly',
        context: 'Final demonstration phase to showcase the fully functional, production-ready application',
        requirements: [
          'Start the application using appropriate run commands',
          'Demonstrate all key features working seamlessly',
          'Show user registration, login, and authentication flows',
          'Display all main screens and navigation functionality',
          'Demonstrate CRUD operations with real data',
          'Show responsive design on different screen sizes',
          'Test all interactive elements and user workflows',
          'Display real-time features and data synchronization',
          'Show error handling and validation in action',
          'Demonstrate search, filtering, and advanced features',
          'Test performance and loading speeds',
          'Show the complete user experience from start to finish',
        ],
        expectedOutput: 'A live, running application demonstrating all features perfectly',
        hints: [
          'Use platform-specific run commands (flutter run, npm start, python app.py)',
          'Open the application in browser/emulator/device as appropriate',
          'Walk through each feature systematically',
          'Show both successful operations and error handling',
          'Demonstrate the app with realistic data scenarios',
          'Test different user roles and permissions if applicable',
          'Show the app working smoothly without crashes or errors',
          'Provide a complete tour of all implemented features',
        ],
      ),
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


  // Generate AI prompt for a specific step
  Future<String> generateCodeForStep({
    required CodeStep step,
    required String projectContext,
    required Map<String, dynamic> projectData,
  }) async {
    try {
      // Check if this is the first step (Project Overview)
      if (step.id == 'project_overview') {
        return _generateProjectOverviewPrompt(projectContext, projectData);
      }
      
      // Check if this is the second step (Environment Setup)
      if (step.id == 'environment_check') {
        return _generateEnvironmentSetupPrompt(projectContext, projectData);
      }
      
      // Check if this is the third step (Project Creation)
      if (step.id == 'project_creation') {
        return _generateProjectCreationPrompt(projectContext, projectData);
      }
      
      // Check if this is the fourth step (MVP Frontend)
      if (step.id == 'mvp_frontend') {
        return _generateMVPFrontendPrompt(projectContext, projectData);
      }
      
      // Check if this is the fifth step (Backend Functionality)
      if (step.id == 'backend_functionality') {
        return _generateBackendFunctionalityPrompt(projectContext, projectData);
      }
      
      // Check if this is the sixth step (Testing & Bug Fixes)
      if (step.id == 'testing_bugfixes') {
        return _generateTestingBugfixesPrompt(projectContext, projectData);
      }
      
      // Check if this is the seventh step (Run Project)
      if (step.id == 'run_project') {
        return _generateRunProjectPrompt(projectContext, projectData);
      }
      
      // For other steps, generate regular prompts
      final language = _getLanguageFromPlatform(projectData['targetPlatform']?.toString() ?? 'flutter');
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
      throw Exception('Failed to generate prompt for step: $e');
    }
  }
  
  // Generate comprehensive project overview prompt for AI agents
  String _generateProjectOverviewPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String problemDescription = 'A student project';
    String platformInfo = 'Mobile App';
    String solutionTitle = 'Custom Solution';
    String features = 'Basic functionality';
    String techStack = 'Modern technologies';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Problem:')) {
        problemDescription = line.replaceFirst('Problem:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      } else if (line.startsWith('Solution:')) {
        solutionTitle = line.replaceFirst('Solution:', '').trim();
      } else if (line.startsWith('Features:')) {
        features = line.replaceFirst('Features:', '').trim();
      } else if (line.startsWith('Tech Stack:')) {
        techStack = line.replaceFirst('Tech Stack:', '').trim();
      }
    }
    
    // Get additional data from project data
    final difficulty = projectData['difficulty']?.toString() ?? 'Intermediate';
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    final teamMembers = projectData['teamMembers'] as List<dynamic>? ?? ['Student'];
    final teamName = projectData['teamName']?.toString() ?? 'Development Team';
    
    return '''
🚀 **PROJECT OVERVIEW**

Hi! I'm a college student working on a semester project and I need your help to build it step by step. Let me give you all the details about my project:

📝 **PROJECT DETAILS:**
• **Project Name:** $projectName
• **Team:** $teamName
• **Team Members:** ${teamMembers.join(', ')}
• **Platform:** $targetPlatform
• **Difficulty Level:** $difficulty

🎯 **PROBLEM STATEMENT:**
$problemDescription

💡 **SOLUTION APPROACH:**
$solutionTitle

✨ **KEY FEATURES:**
$features

🛠️ **TECHNOLOGY STACK:**
$techStack

📚 **PROJECT CONTEXT:**
This is a college/university semester project that needs to be:
- Well-structured and educational
- Suitable for student skill level ($difficulty)
- Complete with proper documentation
- Ready for demonstration and evaluation

🎓 **LEARNING GOALS:**
- Hands-on experience with $techStack
- Understanding of $targetPlatform development
- Problem-solving and project management skills
- Building a portfolio-worthy application

---

🤖 **IMPORTANT:** 
Please confirm that you understand everything about my project: "$projectName". 

I'll be sending you step-by-step prompts to build this project, starting with project setup, then moving through development phases. 

**Please respond with "I understand your project details. I'm ready to help you build '$projectName' step by step. Please send me your next prompt!"**

Don't start coding yet - just wait for my next prompt! 🙏
''';
  }
  
  // Generate environment setup prompt for AI agents
  String _generateEnvironmentSetupPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String techStack = 'Modern technologies';
    String platformInfo = 'Mobile App';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Tech Stack:')) {
        techStack = line.replaceFirst('Tech Stack:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      }
    }
    
    // Get additional data from project data
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    
    return '''
🔧 **ENVIRONMENT SETUP & DEPENDENCIES CHECK**

Now that you understand my project "$projectName", let's set up the complete development environment and install all necessary dependencies.

🎯 **YOUR TASK:**
Check my system and help me install/configure everything needed for this $targetPlatform project.

🛠️ **TECHNOLOGY STACK TO SET UP:**
$techStack

📋 **STEP-BY-STEP ENVIRONMENT SETUP:**

**1. SYSTEM ENVIRONMENT CHECK:**
- Detect my operating system and versions
- Check what development tools are already installed
- Identify any missing requirements

**2. CORE DEVELOPMENT TOOLS:**
- Verify/install required SDKs (Flutter SDK, Node.js, Python, etc.)
- Check IDE/editor setup (VS Code, Android Studio, etc.)
- Install necessary IDE extensions/plugins

**3. PACKAGE MANAGERS & DEPENDENCIES:**
- Run system checks: flutter doctor, node --version, python --version
- Install missing packages using package managers (npm, pip, flutter pub get)
- Set up global dependencies if needed

**4. DATABASE & SERVICES SETUP:**
- Install database software (MySQL, PostgreSQL, etc.) if required
- Set up cloud service CLIs (Firebase CLI, AWS CLI, etc.)
- Configure service account credentials

**5. DEVELOPMENT ENVIRONMENT:**
- Create environment configuration files (.env, config files)
- Set up environment variables with placeholder values
- Configure development vs production settings

**6. TESTING & VERIFICATION:**
- Test all installations work correctly
- Verify database connections
- Check API endpoints and service connections
- Run sample commands to ensure everything is working

**7. TROUBLESHOOTING SETUP:**
- Provide common issue solutions
- Give troubleshooting steps for setup problems
- Share useful debugging commands

🚨 **IMPORTANT INSTRUCTIONS:**
- **Auto-install** what you can using terminal commands
- **Manual installation** instructions for complex software (with download links)
- **Don't skip any verification steps** - test everything works
- **Create setup scripts** if helpful for future use
- **Don't start coding yet** - focus only on environment setup

💡 **EXPECTED OUTPUT:**
- Complete environment setup with all tools installed
- All dependencies resolved and verified
- Environment files created with proper structure
- System ready for $targetPlatform development

---

🤖 **Please start checking my environment now and guide me through installing everything needed for "$projectName".**

**After everything is set up and verified, respond with: "✅ Environment setup complete! All tools and dependencies are installed and verified. Your system is ready for development. Please send me your next prompt!"**
''';
  }
  
  // Generate project creation prompt for AI agents
  String _generateProjectCreationPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String techStack = 'Modern technologies';
    String platformInfo = 'Mobile App';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Tech Stack:')) {
        techStack = line.replaceFirst('Tech Stack:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      }
    }
    
    // Get additional data from project data
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    
    // Generate platform-specific project creation command
    String projectCommand = 'flutter create';
    String projectType = 'Flutter';
    String mainConfigFile = 'pubspec.yaml';
    String mainLanguage = 'Dart';
    
    switch (targetPlatform.toLowerCase()) {
      case 'web':
        projectCommand = 'npx create-react-app';
        projectType = 'React';
        mainConfigFile = 'package.json';
        mainLanguage = 'JavaScript/TypeScript';
        break;
      case 'desktop':
        projectCommand = 'python -m venv';
        projectType = 'Python';
        mainConfigFile = 'requirements.txt';
        mainLanguage = 'Python';
        break;
      case 'app':
      case 'flutter':
      default:
        projectCommand = 'flutter create';
        projectType = 'Flutter';
        mainConfigFile = 'pubspec.yaml';
        mainLanguage = 'Dart';
    }
    
    return '''
🚀 **PROJECT CREATION & FILE STRUCTURE SETUP**

Great! Now that your environment is ready, let's create the actual project and set up the complete file structure for "$projectName".

🎯 **YOUR TASK:**
Create a new $projectType project and establish a well-organized folder structure following industry best practices.

🛠️ **PROJECT SPECIFICATIONS:**
- **Project Name:** $projectName
- **Platform:** $targetPlatform
- **Technology:** $techStack
- **Main Language:** $mainLanguage

📋 **STEP-BY-STEP PROJECT CREATION:**

**1. CREATE NEW PROJECT:**
- Use command: `$projectCommand project_name`
- Choose appropriate project name (lowercase, underscores/hyphens)
- Navigate to project directory
- Verify project creation was successful

**2. SET UP FOLDER STRUCTURE:**
- Create main directories: `lib/`, `assets/`, `configs/`, `utils/`
- Set up architecture folders: `models/`, `views/`, `controllers/`, `services/`
- Create feature-specific modules and sub-directories
- Add `constants/`, `helpers/`, `widgets/` folders as needed

**3. INITIALIZE CONFIGURATION FILES:**
- Configure $mainConfigFile with project dependencies
- Set up environment configuration files (.env, config.dart)
- Create app configuration and settings files
- Set up build and deployment configurations

**4. CREATE INITIAL FILE STRUCTURE:**
- Add placeholder files in each directory with comments
- Create main entry point files (main.dart, index.js, app.py)
- Set up routing and navigation structure
- Add sample model, view, and service files

**5. VERSION CONTROL SETUP:**
- Initialize git repository: `git init`
- Create appropriate .gitignore file for $projectType
- Add and commit initial project structure
- Set up branch strategy if needed

**6. PROJECT DOCUMENTATION:**
- Create comprehensive README.md with project info
- Add setup instructions and development guide
- Document folder structure and architecture decisions
- Include build and deployment instructions

**7. DEVELOPMENT ENVIRONMENT:**
- Set up IDE/editor configurations
- Configure debugging and testing setups
- Create development scripts and shortcuts
- Test initial project build/run commands

🚨 **IMPORTANT INSTRUCTIONS:**
- **Use clean architecture patterns** appropriate for $projectType
- **Follow naming conventions** for files and folders
- **Create modular structure** for easy maintenance and scaling
- **Include sample/template files** to guide development
- **Test the setup** by running build commands
- **Don't implement features yet** - focus only on structure

💡 **EXPECTED OUTPUT:**
- Complete project with proper folder structure
- All configuration files set up and ready
- Version control initialized and configured
- Documentation and README created
- Project successfully building/running

---

🤖 **Please start creating the project structure now for "$projectName" using $projectType technology.**

**After project creation and structure setup is complete, respond with: "✅ Project created successfully! Complete folder structure is set up and ready. The project builds without errors. Please send me your next prompt!"**
''';
  }
  
  // Generate MVP frontend prompt for AI agents
  String _generateMVPFrontendPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String features = 'Core features';
    String solutionTitle = 'Custom Solution';
    String techStack = 'Modern technologies';
    String platformInfo = 'Mobile App';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Features:')) {
        features = line.replaceFirst('Features:', '').trim();
      } else if (line.startsWith('Solution:')) {
        solutionTitle = line.replaceFirst('Solution:', '').trim();
      } else if (line.startsWith('Tech Stack:')) {
        techStack = line.replaceFirst('Tech Stack:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      }
    }
    
    // Get additional data from project data
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    
    // Generate platform-specific UI guidelines
    String uiFramework = 'Flutter Material Design';
    String designSystem = 'Material Design';
    String uiComponents = 'Material Components';
    
    switch (targetPlatform.toLowerCase()) {
      case 'web':
        uiFramework = 'React with modern CSS';
        designSystem = 'Modern Web Standards';
        uiComponents = 'React Components';
        break;
      case 'desktop':
        uiFramework = 'Python GUI (Tkinter/PyQt)';
        designSystem = 'Desktop UI Guidelines';
        uiComponents = 'Desktop Widgets';
        break;
      case 'app':
      case 'flutter':
      default:
        uiFramework = 'Flutter Material Design';
        designSystem = 'Material Design';
        uiComponents = 'Flutter Widgets';
    }
    
    return '''
🎨 **CREATE MVP (FRONTEND UI)**

Perfect! Now that the project structure is ready, let's create a stunning MVP (Minimum Viable Product) with professional frontend UI for "$projectName".

🎯 **YOUR TASK:**
Build a complete, professional-looking frontend with all screens and UI components. Focus ONLY on the visual/frontend part - no backend logic yet.

🛠️ **PROJECT SPECIFICATIONS:**
- **Project Name:** $projectName
- **Platform:** $targetPlatform
- **UI Framework:** $uiFramework
- **Design System:** $designSystem
- **Solution:** $solutionTitle

✨ **KEY FEATURES TO IMPLEMENT (UI ONLY):**
$features

📋 **STEP-BY-STEP MVP FRONTEND DEVELOPMENT:**

**1. DESIGN SYSTEM SETUP:**
- Create consistent color palette and typography
- Set up theme configuration (light/dark mode if applicable)
- Define spacing, sizing, and styling constants
- Create reusable UI component library

**2. CORE SCREENS DEVELOPMENT:**
- Build all main screens mentioned in the solution
- Create welcome/onboarding screens with attractive design
- Implement authentication UI (login/signup forms)
- Design dashboard/home screen with feature overview
- Create feature-specific screens with professional layouts

**3. UI COMPONENTS & WIDGETS:**
- Design custom buttons, cards, and input fields
- Create navigation components (app bar, bottom nav, drawer)
- Build form components with validation UI feedback
- Implement loading states and error message displays
- Create modal dialogs and confirmation screens

**4. NAVIGATION & ROUTING:**
- Set up complete navigation flow between screens
- Implement smooth transitions and animations
- Create proper routing structure for all features
- Add navigation guards and proper back button handling

**5. RESPONSIVE & ACCESSIBLE DESIGN:**
- Ensure responsive design for different screen sizes
- Implement proper accessibility features
- Use appropriate contrast ratios and font sizes
- Test UI on various device dimensions

**6. MOCK DATA & PLACEHOLDER CONTENT:**
- Create realistic mock data to showcase features
- Add placeholder images, avatars, and content
- Implement sample lists, cards, and data displays
- Show how the app will look with real content

**7. PROFESSIONAL POLISH:**
- Add icons, illustrations, and visual elements
- Implement micro-interactions and hover effects
- Create smooth loading animations and transitions
- Add empty states and error handling UI
- Ensure pixel-perfect design with proper spacing

🚨 **CRITICAL REQUIREMENTS:**
- **FRONTEND ONLY** - No backend integration, API calls, or real data processing
- **Professional Design** - Modern, clean, and visually appealing UI
- **Complete Functionality** - All screens should be navigable and interactive
- **Mock Everything** - Use placeholder data to demonstrate all features
- **Platform Guidelines** - Follow $designSystem principles
- **Responsive Design** - Works on different screen sizes
- **User Experience** - Intuitive navigation and smooth interactions

📱 **EXPECTED DELIVERABLES:**
- Complete UI with all screens and components
- Professional, modern design that looks production-ready
- Smooth navigation between all features
- Mock data displaying how features will work
- Responsive layout for different devices
- Loading states, error handling, and user feedback

💡 **UI/UX GUIDELINES:**
- Use $uiComponents for consistent design following $techStack principles
- Implement proper visual hierarchy
- Add meaningful animations and transitions
- Create intuitive user flows
- Ensure accessibility and usability
- Make it feel like a real, polished application

---

🤖 **Please start building the complete MVP frontend now for "$projectName".**

**Focus on creating a beautiful, professional UI that showcases all features. Use mock data to make everything look realistic and functional.**

**After MVP frontend is complete, respond with: "✅ MVP Frontend completed! Professional UI with all screens, components, and navigation is ready. The app looks and feels fully functional. Waiting for your backend integration prompt!"**

**Remember: NO BACKEND LOGIC - Just stunning frontend UI! 🎨**
''';
  }
  
  // Generate backend functionality prompt for AI agents
  String _generateBackendFunctionalityPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String features = 'Core features';
    String techStack = 'Modern technologies';
    String platformInfo = 'Mobile App';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Features:')) {
        features = line.replaceFirst('Features:', '').trim();
      } else if (line.startsWith('Tech Stack:')) {
        techStack = line.replaceFirst('Tech Stack:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      }
    }
    
    // Get additional data from project data
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    
    // Generate platform-specific backend technologies
    String backendTech = 'Firebase & Cloud Functions';
    String database = 'Firestore';
    String authentication = 'Firebase Auth';
    String apiEndpoints = 'REST APIs';
    
    switch (targetPlatform.toLowerCase()) {
      case 'web':
        backendTech = 'Node.js with Express';
        database = 'MongoDB/PostgreSQL';
        authentication = 'JWT & Passport.js';
        apiEndpoints = 'RESTful APIs';
        break;
      case 'desktop':
        backendTech = 'Python with Flask/Django';
        database = 'SQLite/PostgreSQL';
        authentication = 'Session-based Auth';
        apiEndpoints = 'API Services';
        break;
      case 'app':
      case 'flutter':
      default:
        backendTech = 'Firebase & Cloud Functions';
        database = 'Firestore';
        authentication = 'Firebase Auth';
        apiEndpoints = 'Firebase APIs';
    }
    
    return '''
🚀 **IMPLEMENT FUNCTIONALITY (BACKEND INTEGRATION)**

Excellent! Your beautiful frontend UI is ready. Now let's make "$projectName" FULLY FUNCTIONAL by implementing all the backend functionality and real data operations.

🎯 **YOUR TASK:**
Transform the frontend mockup into a completely functional application. Replace all mock data with real backend integration and make every feature work perfectly.

🛠️ **PROJECT SPECIFICATIONS:**
- **Project Name:** $projectName
- **Platform:** $targetPlatform
- **Backend Technology:** $backendTech
- **Database:** $database
- **Authentication:** $authentication
- **APIs:** $apiEndpoints

✨ **FEATURES TO MAKE FUNCTIONAL:**
$features

📋 **STEP-BY-STEP BACKEND IMPLEMENTATION:**

**1. DATABASE & DATA MODELS:**
- Set up $database with proper schema design
- Create data models for all entities (users, posts, products, etc.)
- Define relationships between different data entities
- Set up database indexes and optimization
- Create data validation rules and constraints

**2. AUTHENTICATION & USER MANAGEMENT:**
- Implement complete $authentication system
- Create user registration, login, and logout functionality
- Add password reset and email verification
- Set up user roles and permissions system
- Implement session management and security

**3. API DEVELOPMENT & INTEGRATION:**
- Create $apiEndpoints for all CRUD operations
- Implement proper request/response handling
- Add API authentication and authorization
- Set up rate limiting and security measures
- Create comprehensive error handling

**4. REAL DATA OPERATIONS:**
- Replace ALL mock data with real database operations
- Implement Create, Read, Update, Delete (CRUD) for all features
- Set up data fetching and caching mechanisms
- Add real-time data synchronization
- Implement proper data validation and sanitization

**5. BUSINESS LOGIC IMPLEMENTATION:**
- Code all the core business logic for each feature
- Implement complex workflows and processes
- Add calculations, algorithms, and processing logic
- Create automated tasks and background processes
- Set up proper state management with real data

**6. ADVANCED FEATURES:**
- Implement search, filtering, and sorting functionality
- Add file upload/download capabilities
- Set up push notifications and real-time updates
- Integrate external APIs and third-party services
- Create data export/import functionality

**7. SECURITY & PERFORMANCE:**
- Implement proper data encryption and security
- Add input validation and SQL injection protection
- Set up proper error logging and monitoring
- Optimize database queries and performance
- Implement backup and data recovery systems

**8. TESTING & VALIDATION:**
- Test all functionality with real data scenarios
- Verify all user workflows work end-to-end
- Test error handling and edge cases
- Validate data integrity and consistency
- Ensure all features work as expected

🚨 **CRITICAL REQUIREMENTS:**
- **FULLY FUNCTIONAL** - Every feature must work with real data
- **NO MOCK DATA** - Replace all placeholders with real operations
- **COMPLETE INTEGRATION** - Frontend and backend perfectly connected
- **PRODUCTION READY** - App should be deployable and scalable
- **SECURE & ROBUST** - Proper security and error handling
- **OPTIMIZED PERFORMANCE** - Fast and efficient operations
- **USER-FRIENDLY** - Smooth experience with real data

📊 **EXPECTED DELIVERABLES:**
- Fully functional app with real backend integration
- Complete database with proper data models
- Working authentication and user management
- All CRUD operations functioning properly
- Real-time features and data synchronization
- Comprehensive error handling and validation
- Production-ready, scalable application

💡 **IMPLEMENTATION GUIDELINES:**
- Use $techStack for backend development
- Follow best practices for security and performance
- Implement proper logging and monitoring
- Create comprehensive documentation
- Test thoroughly with various data scenarios
- Ensure scalability and maintainability

---

🤖 **Please start implementing the complete backend functionality now for "$projectName".**

**Make every single feature work perfectly with real data. Transform the beautiful UI into a fully functional, production-ready application.**

**After all functionality is implemented and tested, respond with: "✅ Full Backend Implementation Complete! The application is now 100% functional with real data operations. All features work perfectly. The project is production-ready and fully deployable!"**

**Goal: PERFECT & FULLY FUNCTIONAL PROJECT! 💪🎆**
''';
  }
  
  // Generate testing and bug fixes prompt for AI agents
  String _generateTestingBugfixesPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String features = 'Core features';
    String techStack = 'Modern technologies';
    String platformInfo = 'Mobile App';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Features:')) {
        features = line.replaceFirst('Features:', '').trim();
      } else if (line.startsWith('Tech Stack:')) {
        techStack = line.replaceFirst('Tech Stack:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      }
    }
    
    // Get additional data from project data
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    
    // Generate platform-specific testing commands
    String testCommands = 'flutter test, flutter analyze';
    String runCommands = 'flutter run';
    String debugTools = 'Flutter Inspector, DevTools';
    
    switch (targetPlatform.toLowerCase()) {
      case 'web':
        testCommands = 'npm test, npm run lint';
        runCommands = 'npm start, npm run dev';
        debugTools = 'Browser DevTools, React DevTools';
        break;
      case 'desktop':
        testCommands = 'python -m pytest, pylint';
        runCommands = 'python app.py';
        debugTools = 'Python Debugger, IDE debugging';
        break;
      case 'app':
      case 'flutter':
      default:
        testCommands = 'flutter test, flutter analyze';
        runCommands = 'flutter run';
        debugTools = 'Flutter Inspector, DevTools';
    }
    
    return '''
🔍 **TESTING & BUG FIXES**

Perfect! Your "$projectName" application is now fully functional. Let's thoroughly test everything and fix any bugs or issues to ensure it works flawlessly.

🎯 **YOUR TASK:**
Test every single feature, find and fix all bugs, errors, and issues. Make sure the application is production-ready and works perfectly.

🛠️ **PROJECT SPECIFICATIONS:**
- **Project Name:** $projectName
- **Platform:** $targetPlatform
- **Testing Tools:** $testCommands
- **Run Commands:** $runCommands
- **Debug Tools:** $debugTools

✨ **FEATURES TO TEST:**
$features

📋 **COMPREHENSIVE TESTING CHECKLIST:**

**1. CODE QUALITY & COMPILATION:**
- Run $testCommands to check for errors
- Fix all compilation errors, warnings, and linting issues
- Ensure code follows best practices and standards
- Check for unused imports, variables, and dead code
- Verify proper error handling throughout the application

**2. FUNCTIONALITY TESTING:**
- Test user registration, login, and authentication flows
- Verify all CRUD operations work correctly
- Test all forms, input validation, and data submission
- Check all buttons, links, and interactive elements
- Test navigation between all screens and pages
- Verify all business logic and calculations

**3. DATA & DATABASE TESTING:**
- Test database connections and queries
- Verify data integrity and consistency
- Test data validation rules and constraints
- Check real-time data synchronization
- Test backup and recovery mechanisms
- Verify API endpoints and responses

**4. USER INTERFACE TESTING:**
- Test responsive design on different screen sizes
- Check UI consistency across all screens
- Test loading states and progress indicators
- Verify error messages are user-friendly
- Test accessibility features and usability
- Check performance and smooth animations

**5. SECURITY & PERFORMANCE TESTING:**
- Test authentication and authorization
- Verify data encryption and security measures
- Test performance under different load conditions
- Check memory usage and optimization
- Test network connectivity and offline behavior
- Verify proper session management

**6. EDGE CASES & ERROR SCENARIOS:**
- Test with invalid inputs and edge cases
- Verify error handling for network failures
- Test boundary conditions and limits
- Check behavior with empty or corrupted data
- Test concurrent user operations
- Verify graceful handling of unexpected errors

**7. CROSS-PLATFORM COMPATIBILITY:**
- Test on different browsers (for web)
- Test on different devices and screen sizes
- Verify platform-specific features work correctly
- Test on different operating system versions
- Check compatibility with different hardware

🚨 **CRITICAL REQUIREMENTS:**
- **ZERO BUGS** - Fix every single error and issue
- **SMOOTH PERFORMANCE** - Optimize for speed and efficiency using $techStack best practices
- **USER-FRIENDLY** - Ensure excellent user experience
- **ROBUST ERROR HANDLING** - Graceful failure recovery
- **PRODUCTION READY** - Ready for real-world deployment
- **COMPREHENSIVE TESTING** - Test every possible scenario

📈 **EXPECTED DELIVERABLES:**
- Bug-free application with all issues resolved
- Optimized performance and smooth user experience
- Comprehensive test coverage and validation
- Production-ready code with proper error handling
- Documentation of any known limitations
- Performance benchmarks and optimization results

---

🤖 **Please start comprehensive testing now for "$projectName".**

**Find and fix EVERY bug, error, and issue. Make sure the application works perfectly in all scenarios.**

**After all testing and bug fixes are complete, respond with: "✅ Testing Complete! All bugs fixed and issues resolved. The application is now 100% bug-free, optimized, and production-ready!"**

**Goal: ZERO BUGS & PERFECT FUNCTIONALITY! 💯✨**
''';
  }
  
  // Generate run project prompt for AI agents
  String _generateRunProjectPrompt(String projectContext, Map<String, dynamic> projectData) {
    final lines = projectContext.split('\n');
    String projectName = 'My Project';
    String features = 'Core features';
    String platformInfo = 'Mobile App';
    
    // Extract information from project context
    for (final line in lines) {
      if (line.startsWith('Project:')) {
        projectName = line.replaceFirst('Project:', '').trim();
      } else if (line.startsWith('Features:')) {
        features = line.replaceFirst('Features:', '').trim();
      } else if (line.startsWith('Platform:')) {
        platformInfo = line.replaceFirst('Platform:', '').trim();
      }
    }
    
    // Get additional data from project data
    final targetPlatform = projectData['targetPlatform']?.toString() ?? platformInfo;
    
    // Generate platform-specific run commands
    String runCommand = 'flutter run';
    String buildCommand = 'flutter build';
    String outputLocation = 'mobile device/emulator';
    
    switch (targetPlatform.toLowerCase()) {
      case 'web':
        runCommand = 'npm start';
        buildCommand = 'npm run build';
        outputLocation = 'web browser (localhost:3000)';
        break;
      case 'desktop':
        runCommand = 'python app.py';
        buildCommand = 'pyinstaller --onefile app.py';
        outputLocation = 'desktop application window';
        break;
      case 'app':
      case 'flutter':
      default:
        runCommand = 'flutter run';
        buildCommand = 'flutter build apk/ios';
        outputLocation = 'mobile device/emulator';
    }
    
    return '''
🚀 **RUN PROJECT & DEMO**

Excellent! "$projectName" is now complete, tested, and bug-free. It's time for the final step - let's run the project and see all your hard work in action!

🎯 **YOUR TASK:**
Launch the completed application and provide a comprehensive demonstration of all features working perfectly.

🛠️ **PROJECT SPECIFICATIONS:**
- **Project Name:** $projectName
- **Platform:** $targetPlatform
- **Run Command:** $runCommand
- **Build Command:** $buildCommand
- **Output Location:** $outputLocation

✨ **FEATURES TO DEMONSTRATE:**
$features

📋 **COMPLETE PROJECT DEMONSTRATION:**

**1. PROJECT LAUNCH:**
- Execute: `$runCommand`
- Wait for successful compilation and startup
- Open the application in $outputLocation
- Verify the application launches without errors
- Show the loading/splash screen (if applicable)

**2. USER INTERFACE SHOWCASE:**
- Display the main/home screen with professional design
- Show navigation menu and all available options
- Demonstrate responsive design by resizing window
- Show dark/light theme switching (if implemented)
- Display all major screens and their layouts

**3. AUTHENTICATION DEMONSTRATION:**
- Show user registration process with form validation
- Demonstrate login functionality with credentials
- Show password reset/forgot password feature
- Test logout and session management
- Display user profile and account settings

**4. CORE FEATURES WALKTHROUGH:**
- Demonstrate each major feature systematically
- Show CRUD operations (Create, Read, Update, Delete)
- Test data input forms with validation
- Display data lists, tables, and search functionality
- Show filtering, sorting, and pagination in action
- Demonstrate real-time updates and synchronization

**5. ADVANCED FUNCTIONALITY:**
- Show file upload/download capabilities
- Demonstrate notifications and alerts
- Test API integrations and external services
- Show data export/import features
- Display charts, graphs, or analytics (if applicable)
- Test offline functionality and sync when online

**6. ERROR HANDLING & EDGE CASES:**
- Show graceful error handling with invalid inputs
- Demonstrate network error recovery
- Test form validation with various input scenarios
- Show loading states and progress indicators
- Display user-friendly error messages

**7. PERFORMANCE SHOWCASE:**
- Show fast loading times and smooth navigation
- Demonstrate responsive user interactions
- Test with large datasets (if applicable)
- Show optimized performance metrics
- Display smooth animations and transitions

🎥 **DEMONSTRATION REQUIREMENTS:**
- **LIVE DEMO** - Show the actual running application
- **COMPLETE TOUR** - Walk through every major feature
- **REAL DATA** - Use realistic data scenarios
- **SMOOTH OPERATION** - No crashes, errors, or glitches
- **PROFESSIONAL PRESENTATION** - Show production-quality results
- **USER EXPERIENCE** - Demonstrate intuitive usability

📄 **FINAL DELIVERABLES:**
- Live, running application accessible in $outputLocation
- Complete feature demonstration video/walkthrough
- Screenshots of key screens and functionality
- Performance metrics and benchmarks
- User guide or documentation highlights
- Deployment instructions (if applicable)

---

🤖 **Please launch "$projectName" now and provide a complete demonstration!**

**Show off your amazing, fully-functional application. Let's see everything working beautifully!**

**After the complete demo, respond with: "🎆 PROJECT COMPLETE! '$projectName' is now live and running perfectly. All features demonstrated successfully. The project is production-ready and fully deployable! 🚀✨"**

**CONGRATULATIONS ON COMPLETING YOUR PROJECT! 🎉🏆**
''';
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

  // Update current step and progress to next step
  Future<void> updateCurrentStep({
    required String projectSpaceId,
    required String stepId,
  }) async {
    final project = await getCodeProject(projectSpaceId);
    if (project == null) return;

    // Find the current step and mark it as completed
    final currentModule = project.currentModule;
    if (currentModule == null) return;

    final currentStep = project.currentStep;
    if (currentStep == null || currentStep.id != stepId) return;

    // Calculate next step position
    int nextStepIndex = project.currentStepIndex + 1;
    int nextModuleIndex = project.currentModuleIndex;

    // If we've completed all steps in current module, move to next module
    if (nextStepIndex >= currentModule.steps.length) {
      nextModuleIndex += 1;
      nextStepIndex = 0;
    }

    // Check if project is completed (no more modules)
    bool projectCompleted = nextModuleIndex >= project.modules.length;
    DateTime? completedAt = projectCompleted ? DateTime.now() : null;

    final updatedProject = CodeGenerationProject(
      id: project.id,
      projectSpaceId: project.projectSpaceId,
      projectName: project.projectName,
      targetPlatform: project.targetPlatform,
      modules: project.modules,
      currentModuleIndex: projectCompleted ? project.currentModuleIndex : nextModuleIndex,
      currentStepIndex: projectCompleted ? project.currentStepIndex : nextStepIndex,
      isCompleted: projectCompleted,
      createdAt: project.createdAt,
      completedAt: completedAt,
    );

    await _saveCodeProject(updatedProject);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
