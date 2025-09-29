class PresentationTip {
  final String id;
  final String title;
  final String description;
  final PresentationTipCategory category;
  final List<String> keyPoints;
  final String? example;
  final List<String> dosList;
  final List<String> dontsList;
  final int priority;
  final String? videoUrl;
  final String? imageUrl;

  const PresentationTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.keyPoints,
    this.example,
    this.dosList = const [],
    this.dontsList = const [],
    this.priority = 1,
    this.videoUrl,
    this.imageUrl,
  });

  factory PresentationTip.fromJson(Map<String, dynamic> json) {
    return PresentationTip(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: PresentationTipCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] as String?),
        orElse: () => PresentationTipCategory.general,
      ),
      keyPoints: _parseStringList(json['keyPoints']),
      example: json['example'] as String?,
      dosList: _parseStringList(json['dosList']),
      dontsList: _parseStringList(json['dontsList']),
      priority: (json['priority'] as int?) ?? 1,
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'keyPoints': keyPoints,
      'example': example,
      'dosList': dosList,
      'dontsList': dontsList,
      'priority': priority,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
    };
  }
}

enum PresentationTipCategory {
  general,
  bodyLanguage,
  voiceAndSpeech,
  contentStructure,
  visualAids,
  timeManagement,
  nervesManagement,
  questionHandling,
  technicalPrep,
  dressCode
}

extension PresentationTipCategoryExtension on PresentationTipCategory {
  String get displayName {
    switch (this) {
      case PresentationTipCategory.general:
        return 'General Tips';
      case PresentationTipCategory.bodyLanguage:
        return 'Body Language';
      case PresentationTipCategory.voiceAndSpeech:
        return 'Voice & Speech';
      case PresentationTipCategory.contentStructure:
        return 'Content Structure';
      case PresentationTipCategory.visualAids:
        return 'Visual Aids';
      case PresentationTipCategory.timeManagement:
        return 'Time Management';
      case PresentationTipCategory.nervesManagement:
        return 'Managing Nerves';
      case PresentationTipCategory.questionHandling:
        return 'Handling Questions';
      case PresentationTipCategory.technicalPrep:
        return 'Technical Preparation';
      case PresentationTipCategory.dressCode:
        return 'Dress Code';
    }
  }

  String get description {
    switch (this) {
      case PresentationTipCategory.general:
        return 'Overall presentation best practices';
      case PresentationTipCategory.bodyLanguage:
        return 'Posture, gestures, and non-verbal communication';
      case PresentationTipCategory.voiceAndSpeech:
        return 'Speaking clearly, pace, and vocal techniques';
      case PresentationTipCategory.contentStructure:
        return 'Organizing your presentation effectively';
      case PresentationTipCategory.visualAids:
        return 'Using slides, demos, and other visual elements';
      case PresentationTipCategory.timeManagement:
        return 'Managing presentation and Q&A time effectively';
      case PresentationTipCategory.nervesManagement:
        return 'Dealing with anxiety and building confidence';
      case PresentationTipCategory.questionHandling:
        return 'Responding to examiner questions professionally';
      case PresentationTipCategory.technicalPrep:
        return 'Equipment setup and technical considerations';
      case PresentationTipCategory.dressCode:
        return 'Professional appearance and attire guidelines';
    }
  }

  String get icon {
    switch (this) {
      case PresentationTipCategory.general:
        return '💡';
      case PresentationTipCategory.bodyLanguage:
        return '🤝';
      case PresentationTipCategory.voiceAndSpeech:
        return '🗣️';
      case PresentationTipCategory.contentStructure:
        return '📋';
      case PresentationTipCategory.visualAids:
        return '📊';
      case PresentationTipCategory.timeManagement:
        return '⏰';
      case PresentationTipCategory.nervesManagement:
        return '😌';
      case PresentationTipCategory.questionHandling:
        return '❓';
      case PresentationTipCategory.technicalPrep:
        return '⚙️';
      case PresentationTipCategory.dressCode:
        return '👔';
    }
  }
}

class VivaPreparationGuide {
  final String title;
  final String description;
  final List<PresentationTip> tips;
  final List<String> commonMistakes;
  final List<String> preparationChecklist;
  final Map<String, String> quickTips;

  const VivaPreparationGuide({
    required this.title,
    required this.description,
    required this.tips,
    required this.commonMistakes,
    required this.preparationChecklist,
    required this.quickTips,
  });

  static const VivaPreparationGuide defaultGuide = VivaPreparationGuide(
    title: 'Complete Viva Preparation Guide',
    description: 'Everything you need to know for a successful project viva',
    tips: [],
    commonMistakes: [
      'Not knowing your project thoroughly',
      'Speaking too fast due to nervousness',
      'Poor eye contact with examiners',
      'Not having backup plans for technical issues',
      'Inadequate preparation for follow-up questions',
      'Not practicing the presentation beforehand',
      'Forgetting to explain the problem statement clearly',
      'Not being able to justify design decisions',
      'Lack of knowledge about related technologies',
      'Poor time management during presentation',
    ],
    preparationChecklist: [
      'Review your entire project documentation',
      'Prepare a clear problem statement explanation',
      'Practice explaining your solution approach',
      'Review all technologies and frameworks used',
      'Prepare for potential questions on each feature',
      'Test all demos and code examples',
      'Prepare backup slides and materials',
      'Practice your presentation multiple times',
      'Research recent developments in your project domain',
      'Prepare answers for "why" questions about your choices',
    ],
    quickTips: {
      'Before Viva': 'Arrive early, test equipment, stay calm',
      'During Presentation': 'Speak clearly, maintain eye contact, use gestures',
      'During Q&A': 'Listen carefully, think before answering, admit if you don\'t know',
      'Body Language': 'Stand straight, smile, use open gestures',
      'Voice': 'Speak slowly, project your voice, pause for emphasis',
    },
  );
}