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
      'architecture': _sanitizeMap(architecture),
      'createdAt': createdAt.toIso8601String(),
      'isSelected': isSelected,
      'implementationSteps': implementationSteps,
      'realLifeExamples': realLifeExamples,
      'challenges': challenges,
      'benefits': benefits,
      'detailedDescription': detailedDescription,
      'timeline': timeline != null ? _sanitizeMap(timeline!) : null,
      'learningOutcomes': learningOutcomes,
    };
  }

  /// Sanitize map keys to be Firebase-compatible
  /// Firebase keys cannot contain: . # $ / [ ] 
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};
    for (final entry in map.entries) {
      // Replace invalid characters with underscores
      String sanitizedKey = entry.key
          .replaceAll('.', '_')
          .replaceAll('#', '_')
          .replaceAll(r'$', '_')
          .replaceAll('/', '_')
          .replaceAll('[', '_')
          .replaceAll(']', '_')
          .replaceAll('(', '_')
          .replaceAll(')', '_')
          .replaceAll('!', '_')
          .replaceAll('?', '_')
          .replaceAll('@', '_')
          .replaceAll('%', '_')
          .replaceAll('^', '_')
          .replaceAll('&', '_')
          .replaceAll('*', '_')
          .replaceAll('+', '_')
          .replaceAll('=', '_')
          .replaceAll('|', '_')
          .replaceAll('\\', '_')
          .replaceAll('"', '_')
          .replaceAll("'", '_')
          .replaceAll('<', '_')
          .replaceAll('>', '_')
          .replaceAll(',', '_')
          .replaceAll(';', '_')
          .replaceAll(':', '_')
          .trim();
      
      // Ensure key doesn't start with underscore (Firebase requirement)
      while (sanitizedKey.startsWith('_')) {
        sanitizedKey = sanitizedKey.substring(1);
      }
      
      // Ensure key is not empty
      if (sanitizedKey.isEmpty) {
        sanitizedKey = 'key_${map.keys.toList().indexOf(entry.key)}';
      }
      
      // Recursively sanitize nested maps
      if (entry.value is Map<String, dynamic>) {
        sanitized[sanitizedKey] = _sanitizeMap(entry.value as Map<String, dynamic>);
      } else {
        sanitized[sanitizedKey] = entry.value;
      }
    }
    return sanitized;
  }

  factory ProjectSolution.fromMap(Map<String, dynamic> map) {
    return ProjectSolution(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? 'custom').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      keyFeatures: (map['keyFeatures'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      techStack: (map['techStack'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      difficulty: (map['difficulty'] ?? 'Intermediate').toString(),
      architecture: (map['architecture'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{},
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
      isSelected: (map['isSelected'] as bool?) ?? false,
      implementationSteps: map['implementationSteps'] != null 
          ? (map['implementationSteps'] as List<dynamic>?)?.cast<String>() : null,
      realLifeExamples: map['realLifeExamples'] != null 
          ? (map['realLifeExamples'] as List<dynamic>?)?.cast<String>() : null,
      challenges: map['challenges'] != null 
          ? (map['challenges'] as List<dynamic>?)?.cast<String>() : null,
      benefits: map['benefits'] != null 
          ? (map['benefits'] as List<dynamic>?)?.cast<String>() : null,
      detailedDescription: map['detailedDescription']?.toString(),
      timeline: map['timeline'] != null 
          ? (map['timeline'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) : null,
      learningOutcomes: map['learningOutcomes'] != null 
          ? (map['learningOutcomes'] as List<dynamic>?)?.cast<String>() : null,
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
      frontend: (map['frontend'] ?? '').toString(),
      backend: (map['backend'] ?? '').toString(),
      database: (map['database'] ?? '').toString(),
      apis: (map['apis'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      deployment: (map['deployment'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ) ?? <String, String>{},
    );
  }
}