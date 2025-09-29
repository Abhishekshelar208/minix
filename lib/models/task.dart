class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority; // 'High', 'Medium', 'Low'
  final String category; // 'Planning', 'Development', 'Testing', 'Documentation'
  final List<String> assignedTo; // Team member names
  final int estimatedHours;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final List<String> dependencies; // Task IDs this task depends on
  final Map<String, dynamic>? metadata; // Additional data
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.category,
    required this.assignedTo,
    required this.estimatedHours,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.dependencies = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromMap(String id, Map<dynamic, dynamic> map) {
    return Task(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      dueDate: DateTime.fromMillisecondsSinceEpoch((map['dueDate'] as num? ?? 0).toInt()),
      priority: map['priority']?.toString() ?? 'Medium',
      category: map['category']?.toString() ?? 'Development',
      assignedTo: _toStringList(map['assignedTo']) ?? [],
      estimatedHours: (map['estimatedHours'] as num? ?? 0).toInt(),
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((map['completedAt'] as num).toInt())
          : null,
      completedBy: map['completedBy']?.toString(),
      dependencies: _toStringList(map['dependencies']) ?? [],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num? ?? 0).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as num? ?? 0).toInt()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'priority': priority,
      'category': category,
      'assignedTo': assignedTo,
      'estimatedHours': estimatedHours,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'completedBy': completedBy,
      'dependencies': dependencies,
      'metadata': metadata,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? category,
    List<String>? assignedTo,
    int? estimatedHours,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      dependencies: dependencies ?? this.dependencies,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return null;
  }

  // Helper getters
  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());
  bool get isDueToday => !isCompleted && _isSameDay(dueDate, DateTime.now());
  bool get isDueTomorrow => !isCompleted && _isSameDay(dueDate, DateTime.now().add(const Duration(days: 1)));
  
  String get priorityEmoji {
    switch (priority) {
      case 'High':
        return '🔴';
      case 'Medium':
        return '🟡';
      case 'Low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'Planning':
        return '📋';
      case 'Development':
        return '💻';
      case 'Testing':
        return '🧪';
      case 'Documentation':
        return '📚';
      case 'Design':
        return '🎨';
      case 'Research':
        return '🔍';
      default:
        return '📝';
    }
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

