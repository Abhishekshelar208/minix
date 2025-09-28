import 'package:minix/models/task.dart';

class ProjectRoadmap {
  final String projectSpaceId;
  final DateTime startDate;
  final DateTime endDate;
  final List<Task> tasks;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectRoadmap({
    required this.projectSpaceId,
    required this.startDate,
    required this.endDate,
    required this.tasks,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;
  
  int get totalTasksCount => tasks.length;
  
  double get completionPercentage => 
      totalTasksCount > 0 ? (completedTasksCount / totalTasksCount) * 100 : 0;

  List<Task> get upcomingTasks {
    final now = DateTime.now();
    return tasks
        .where((task) => !task.isCompleted && task.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Task> get overdueTasks {
    final now = DateTime.now();
    return tasks
        .where((task) => !task.isCompleted && task.dueDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Task> get completedTasks => tasks.where((task) => task.isCompleted).toList();

  ProjectRoadmap copyWith({
    String? projectSpaceId,
    DateTime? startDate,
    DateTime? endDate,
    List<Task>? tasks,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectRoadmap(
      projectSpaceId: projectSpaceId ?? this.projectSpaceId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tasks: tasks ?? this.tasks,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectSpaceId': projectSpaceId,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'settings': settings,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProjectRoadmap.fromMap(Map<String, dynamic> map, List<Task> tasks) {
    return ProjectRoadmap(
      projectSpaceId: map['projectSpaceId'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] ?? 0),
      tasks: tasks,
      settings: map['settings'] != null ? Map<String, dynamic>.from(map['settings']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  @override
  String toString() {
    return 'ProjectRoadmap(projectSpaceId: $projectSpaceId, totalTasks: $totalTasksCount, completed: $completedTasksCount, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectRoadmap &&
        other.projectSpaceId == projectSpaceId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return projectSpaceId.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        createdAt.hashCode;
  }
}

class ProjectSpaceSummary {
  final String id;
  final String teamName;
  final List<String> teamMembers;
  final int yearOfStudy;
  final String targetPlatform;
  final String difficulty;
  final String status;
  final int currentStep;
  final String? projectName;
  final String? selectedProblemTitle;
  final String? roadmapId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectSpaceSummary({
    required this.id,
    required this.teamName,
    required this.teamMembers,
    required this.yearOfStudy,
    required this.targetPlatform,
    required this.difficulty,
    required this.status,
    required this.currentStep,
    this.projectName,
    this.selectedProblemTitle,
    this.roadmapId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectSpaceSummary.fromMap(String id, Map<String, dynamic> map) {
    return ProjectSpaceSummary(
      id: id,
      teamName: map['teamName'] ?? '',
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      yearOfStudy: map['yearOfStudy'] ?? 1,
      targetPlatform: map['targetPlatform'] ?? '',
      difficulty: map['difficulty'] ?? 'Beginner',
      status: map['status'] ?? 'Draft',
      currentStep: map['currentStep'] ?? 1,
      projectName: map['projectName'],
      selectedProblemTitle: map['selectedProblemTitle'],
      roadmapId: map['roadmapId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  String get progressDescription {
    switch (currentStep) {
      case 1:
        return 'Project Space Created';
      case 2:
        return 'Topic Selected';
      case 3:
        return 'Project Named';
      case 4:
        return 'Roadmap Generated';
      default:
        return 'In Progress';
    }
  }

  @override
  String toString() {
    return 'ProjectSpaceSummary(id: $id, teamName: $teamName, step: $currentStep, status: $status)';
  }
}