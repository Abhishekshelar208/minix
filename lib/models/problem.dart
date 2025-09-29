class Problem {
  final String id;
  final String title;
  final String domain;
  final String description;
  final List<String> platform; // e.g., ["App", "Web", "Website"]
  final List<int> year; // e.g., [2,3]
  final List<String> skills; // e.g., ["Flutter", "Firebase"]
  final String difficulty; // e.g., "Beginner" | "Intermediate" | "Advanced"
  final String scope; // e.g., "Small" | "Medium" | "Large"
  final List<String> beneficiaries; // e.g., ["Students", "Faculty"]
  final List<String> features; // e.g., ["QR-based check-in", ...]
  final List<String> dataSources; // e.g., ["Firebase RTDB/Firestore", ...]
  final int updatedAt;
  
  // Detailed problem information (generated on demand)
  final String? detailedDescription;
  final List<String>? realLifeExample;
  final List<String>? detailedFeatures;
  final List<String>? implementationSteps;
  final List<String>? challenges;
  final List<String>? learningOutcomes;
  final bool hasDetailedInfo;

  Problem({
    required this.id,
    required this.title,
    required this.domain,
    required this.description,
    required this.platform,
    required this.year,
    required this.skills,
    required this.difficulty,
    required this.scope,
    required this.beneficiaries,
    required this.features,
    required this.dataSources,
    required this.updatedAt,
    this.detailedDescription,
    this.realLifeExample,
    this.detailedFeatures,
    this.implementationSteps,
    this.challenges,
    this.learningOutcomes,
    this.hasDetailedInfo = false,
  });

  factory Problem.fromMap(String id, Map<dynamic, dynamic> map) {
    List<String> toStringList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) return v.map((e) => e.toString()).toList();
      return <String>[];
    }

    List<int> toIntList(dynamic v) {
      if (v == null) return <int>[];
      if (v is List) {
        return v.map((e) {
          if (e is int) return e;
          return int.tryParse(e.toString()) ?? 0;
        }).toList();
      }
      return <int>[];
    }

    return Problem(
      id: id,
      title: map['title']?.toString() ?? '',
      domain: map['domain']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      platform: toStringList(map['platform']),
      year: toIntList(map['year']),
      skills: toStringList(map['skills']),
      difficulty: map['difficulty']?.toString() ?? '',
      scope: map['scope']?.toString() ?? '',
      beneficiaries: toStringList(map['beneficiaries']),
      features: toStringList(map['features']),
      dataSources: toStringList(map['data_sources']),
      updatedAt: (map['updatedAt'] is int)
          ? (map['updatedAt'] as int)
          : int.tryParse(map['updatedAt']?.toString() ?? '0') ?? 0,
      detailedDescription: map['detailedDescription']?.toString(),
      realLifeExample: toStringList(map['realLifeExample']),
      detailedFeatures: toStringList(map['detailedFeatures']),
      implementationSteps: toStringList(map['implementationSteps']),
      challenges: toStringList(map['challenges']),
      learningOutcomes: toStringList(map['learningOutcomes']),
      hasDetailedInfo: (map['hasDetailedInfo'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'domain': domain,
      'description': description,
      'platform': platform,
      'year': year,
      'skills': skills,
      'difficulty': difficulty,
      'scope': scope,
      'beneficiaries': beneficiaries,
      'features': features,
      'data_sources': dataSources,
      'updatedAt': updatedAt,
      if (detailedDescription != null) 'detailedDescription': detailedDescription,
      if (realLifeExample != null) 'realLifeExample': realLifeExample,
      if (detailedFeatures != null) 'detailedFeatures': detailedFeatures,
      if (implementationSteps != null) 'implementationSteps': implementationSteps,
      if (challenges != null) 'challenges': challenges,
      if (learningOutcomes != null) 'learningOutcomes': learningOutcomes,
      'hasDetailedInfo': hasDetailedInfo,
    };
  }
  
  Problem copyWith({
    String? id,
    String? title,
    String? domain,
    String? description,
    List<String>? platform,
    List<int>? year,
    List<String>? skills,
    String? difficulty,
    String? scope,
    List<String>? beneficiaries,
    List<String>? features,
    List<String>? dataSources,
    int? updatedAt,
    String? detailedDescription,
    List<String>? realLifeExample,
    List<String>? detailedFeatures,
    List<String>? implementationSteps,
    List<String>? challenges,
    List<String>? learningOutcomes,
    bool? hasDetailedInfo,
  }) {
    return Problem(
      id: id ?? this.id,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      difficulty: difficulty ?? this.difficulty,
      scope: scope ?? this.scope,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      features: features ?? this.features,
      dataSources: dataSources ?? this.dataSources,
      updatedAt: updatedAt ?? this.updatedAt,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      realLifeExample: realLifeExample ?? this.realLifeExample,
      detailedFeatures: detailedFeatures ?? this.detailedFeatures,
      implementationSteps: implementationSteps ?? this.implementationSteps,
      challenges: challenges ?? this.challenges,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      hasDetailedInfo: hasDetailedInfo ?? this.hasDetailedInfo,
    );
  }
}
