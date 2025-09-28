class ProjectSolution {
  final String id;
  final String type; // 'app_suggested' or 'custom'
  final String title;
  final String description;
  final List<String> keyFeatures;
  final List<String> techStack;
  final String difficulty;
  final Map<String, dynamic> architecture;
  final DateTime createdAt;
  final bool isSelected;
  
  // New detailed fields
  final List<String>? implementationSteps;
  final List<String>? realLifeExamples;
  final List<String>? challenges;
  final List<String>? benefits;
  final String? detailedDescription;
  final Map<String, dynamic>? timeline; // phases with duration
  final List<String>? learningOutcomes;

  const ProjectSolution({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.keyFeatures,
    required this.techStack,
    required this.difficulty,
    required this.architecture,
    required this.createdAt,
    this.isSelected = false,
    this.implementationSteps,
    this.realLifeExamples,
    this.challenges,
    this.benefits,
    this.detailedDescription,
    this.timeline,
    this.learningOutcomes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'keyFeatures': keyFeatures,
      'techStack': techStack,
      'difficulty': difficulty,
      'architecture': architecture,
      'createdAt': createdAt.toIso8601String(),
      'isSelected': isSelected,
      'implementationSteps': implementationSteps,
      'realLifeExamples': realLifeExamples,
      'challenges': challenges,
      'benefits': benefits,
      'detailedDescription': detailedDescription,
      'timeline': timeline,
      'learningOutcomes': learningOutcomes,
    };
  }

  factory ProjectSolution.fromMap(Map<String, dynamic> map) {
    return ProjectSolution(
      id: map['id'] ?? '',
      type: map['type'] ?? 'custom',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      keyFeatures: List<String>.from(map['keyFeatures'] ?? []),
      techStack: List<String>.from(map['techStack'] ?? []),
      difficulty: map['difficulty'] ?? 'Intermediate',
      architecture: Map<String, dynamic>.from(map['architecture'] ?? {}),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isSelected: map['isSelected'] ?? false,
      implementationSteps: map['implementationSteps'] != null 
          ? List<String>.from(map['implementationSteps']) : null,
      realLifeExamples: map['realLifeExamples'] != null 
          ? List<String>.from(map['realLifeExamples']) : null,
      challenges: map['challenges'] != null 
          ? List<String>.from(map['challenges']) : null,
      benefits: map['benefits'] != null 
          ? List<String>.from(map['benefits']) : null,
      detailedDescription: map['detailedDescription'],
      timeline: map['timeline'] != null 
          ? Map<String, dynamic>.from(map['timeline']) : null,
      learningOutcomes: map['learningOutcomes'] != null 
          ? List<String>.from(map['learningOutcomes']) : null,
    );
  }

  ProjectSolution copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    List<String>? keyFeatures,
    List<String>? techStack,
    String? difficulty,
    Map<String, dynamic>? architecture,
    DateTime? createdAt,
    bool? isSelected,
    List<String>? implementationSteps,
    List<String>? realLifeExamples,
    List<String>? challenges,
    List<String>? benefits,
    String? detailedDescription,
    Map<String, dynamic>? timeline,
    List<String>? learningOutcomes,
  }) {
    return ProjectSolution(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      keyFeatures: keyFeatures ?? this.keyFeatures,
      techStack: techStack ?? this.techStack,
      difficulty: difficulty ?? this.difficulty,
      architecture: architecture ?? this.architecture,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
      implementationSteps: implementationSteps ?? this.implementationSteps,
      realLifeExamples: realLifeExamples ?? this.realLifeExamples,
      challenges: challenges ?? this.challenges,
      benefits: benefits ?? this.benefits,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      timeline: timeline ?? this.timeline,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
    );
  }
}

class SolutionArchitecture {
  final String frontend;
  final String backend;
  final String database;
  final List<String> apis;
  final Map<String, String> deployment;

  const SolutionArchitecture({
    required this.frontend,
    required this.backend,
    required this.database,
    required this.apis,
    required this.deployment,
  });

  Map<String, dynamic> toMap() {
    return {
      'frontend': frontend,
      'backend': backend,
      'database': database,
      'apis': apis,
      'deployment': deployment,
    };
  }

  factory SolutionArchitecture.fromMap(Map<String, dynamic> map) {
    return SolutionArchitecture(
      frontend: map['frontend'] ?? '',
      backend: map['backend'] ?? '',
      database: map['database'] ?? '',
      apis: List<String>.from(map['apis'] ?? []),
      deployment: Map<String, String>.from(map['deployment'] ?? {}),
    );
  }
}