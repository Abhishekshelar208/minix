class CodeModule {
  final String id;
  final String title;
  final String description;
  final List<CodeStep> steps;
  final String category; // 'setup', 'core', 'features', 'testing', 'deployment'
  final int order;
  final List<String> dependencies; // Required modules
  final bool isCompleted;

  CodeModule({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.category,
    required this.order,
    this.dependencies = const [],
    this.isCompleted = false,
  });

  factory CodeModule.fromMap(Map<String, dynamic> map) {
    return CodeModule(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      steps: (map['steps'] as List<dynamic>?)
          ?.map((step) => CodeStep.fromMap(Map<String, dynamic>.from(step)))
          .toList() ?? [],
      category: map['category'] ?? 'core',
      order: map['order'] ?? 0,
      dependencies: List<String>.from(map['dependencies'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'steps': steps.map((step) => step.toMap()).toList(),
      'category': category,
      'order': order,
      'dependencies': dependencies,
      'isCompleted': isCompleted,
    };
  }

  CodeModule copyWith({
    String? id,
    String? title,
    String? description,
    List<CodeStep>? steps,
    String? category,
    int? order,
    List<String>? dependencies,
    bool? isCompleted,
  }) {
    return CodeModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      category: category ?? this.category,
      order: order ?? this.order,
      dependencies: dependencies ?? this.dependencies,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class CodeStep {
  final String id;
  final String title;
  final String description;
  final CodePrompt prompt;
  final String? filePath;
  final String? generatedCode;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? userFeedback;

  CodeStep({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    this.filePath,
    this.generatedCode,
    this.isCompleted = false,
    this.completedAt,
    this.userFeedback,
  });

  factory CodeStep.fromMap(Map<String, dynamic> map) {
    return CodeStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      prompt: CodePrompt.fromMap(Map<String, dynamic>.from(map['prompt'] ?? {})),
      filePath: map['filePath'],
      generatedCode: map['generatedCode'],
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      userFeedback: map['userFeedback'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prompt': prompt.toMap(),
      'filePath': filePath,
      'generatedCode': generatedCode,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'userFeedback': userFeedback,
    };
  }

  CodeStep copyWith({
    String? id,
    String? title,
    String? description,
    CodePrompt? prompt,
    String? filePath,
    String? generatedCode,
    bool? isCompleted,
    DateTime? completedAt,
    String? userFeedback,
  }) {
    return CodeStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      filePath: filePath ?? this.filePath,
      generatedCode: generatedCode ?? this.generatedCode,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }
}

class CodePrompt {
  final String instruction;
  final String context;
  final List<String> requirements;
  final List<CodeExample> examples;
  final String expectedOutput;
  final List<String> hints;

  CodePrompt({
    required this.instruction,
    required this.context,
    required this.requirements,
    this.examples = const [],
    required this.expectedOutput,
    this.hints = const [],
  });

  factory CodePrompt.fromMap(Map<String, dynamic> map) {
    return CodePrompt(
      instruction: map['instruction'] ?? '',
      context: map['context'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      examples: (map['examples'] as List<dynamic>?)
          ?.map((example) => CodeExample.fromMap(Map<String, dynamic>.from(example)))
          .toList() ?? [],
      expectedOutput: map['expectedOutput'] ?? '',
      hints: List<String>.from(map['hints'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instruction': instruction,
      'context': context,
      'requirements': requirements,
      'examples': examples.map((example) => example.toMap()).toList(),
      'expectedOutput': expectedOutput,
      'hints': hints,
    };
  }
}

class CodeExample {
  final String title;
  final String code;
  final String explanation;

  CodeExample({
    required this.title,
    required this.code,
    required this.explanation,
  });

  factory CodeExample.fromMap(Map<String, dynamic> map) {
    return CodeExample(
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      'explanation': explanation,
    };
  }
}

class CodeGenerationProject {
  final String id;
  final String projectSpaceId;
  final String projectName;
  final String targetPlatform;
  final List<CodeModule> modules;
  final int currentModuleIndex;
  final int currentStepIndex;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  CodeGenerationProject({
    required this.id,
    required this.projectSpaceId,
    required this.projectName,
    required this.targetPlatform,
    required this.modules,
    this.currentModuleIndex = 0,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  factory CodeGenerationProject.fromMap(Map<String, dynamic> map) {
    return CodeGenerationProject(
      id: map['id'] ?? '',
      projectSpaceId: map['projectSpaceId'] ?? '',
      projectName: map['projectName'] ?? '',
      targetPlatform: map['targetPlatform'] ?? '',
      modules: (map['modules'] as List<dynamic>?)
          ?.map((module) => CodeModule.fromMap(Map<String, dynamic>.from(module)))
          .toList() ?? [],
      currentModuleIndex: map['currentModuleIndex'] ?? 0,
      currentStepIndex: map['currentStepIndex'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectSpaceId': projectSpaceId,
      'projectName': projectName,
      'targetPlatform': targetPlatform,
      'modules': modules.map((module) => module.toMap()).toList(),
      'currentModuleIndex': currentModuleIndex,
      'currentStepIndex': currentStepIndex,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  CodeModule? get currentModule {
    if (currentModuleIndex < modules.length) {
      return modules[currentModuleIndex];
    }
    return null;
  }

  CodeStep? get currentStep {
    final module = currentModule;
    if (module != null && currentStepIndex < module.steps.length) {
      return module.steps[currentStepIndex];
    }
    return null;
  }

  double get overallProgress {
    if (modules.isEmpty) return 0.0;
    
    int totalSteps = modules.fold(0, (sum, module) => sum + module.steps.length);
    int completedSteps = modules.fold(0, (sum, module) => 
        sum + module.steps.where((step) => step.isCompleted).length);
    
    return totalSteps > 0 ? completedSteps / totalSteps : 0.0;
  }
}