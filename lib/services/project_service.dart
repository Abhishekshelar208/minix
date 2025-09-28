import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:minix/models/task.dart';
import 'package:minix/models/project_roadmap.dart';
import 'package:minix/models/solution.dart';

class ProjectService {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  ProjectService({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String?> createDraftProject({required String problemId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final ref = _db.ref('Projects').push();
    await ref.set({
      'ownerId': uid,
      'problemId': problemId,
      'status': 'Draft',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return ref.key;
  }

  Future<Set<String>> fetchBookmarks() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return <String>{};
    final snap = await _db.ref('Bookmarks/$uid').get();
    final value = snap.value;
    if (value is Map) {
      return value.keys.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  Future<void> setBookmark(String problemId, bool bookmarked) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _db.ref('Bookmarks/$uid/$problemId');
    if (bookmarked) {
      await ref.set(true);
    } else {
      await ref.remove();
    }
  }

  Future<void> updateDraftProject({
    required String projectId,
    required Map<String, dynamic> updates,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    
    final ref = _db.ref('Projects/$projectId');
    await ref.update(updates);
  }

  Future<Map<String, dynamic>?> getDraftProject(String projectId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    
    final snapshot = await _db.ref('Projects/$projectId').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    }
    return null;
  }

  Future<String?> createProjectSpace({
    required String teamName,
    required List<String> teamMembers,
    required int yearOfStudy,
    required String targetPlatform,
    required String difficulty,
  }) async {
    final uid = _auth.currentUser?.uid;
    final userEmail = _auth.currentUser?.email;
    if (uid == null) return null;

    final ref = _db.ref('ProjectSpaces').push();
    await ref.set({
      'ownerId': uid,
      'ownerEmail': userEmail ?? '',
      'teamName': teamName,
      'teamMembers': teamMembers,
      'yearOfStudy': yearOfStudy,
      'targetPlatform': targetPlatform,
      'difficulty': difficulty,
      'status': 'SpaceCreated',
      'currentStep': 1,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    
    print('✅ Project space created with owner email: $userEmail');
    return ref.key;
  }

  Future<void> updateProjectSpaceStep({
    required String projectSpaceId,
    required int step,
    Map<String, dynamic>? additionalData,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    
    final updates = <String, dynamic>{
      'currentStep': step,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (additionalData != null) {
      updates.addAll(additionalData);
    }
    
    final ref = _db.ref('ProjectSpaces/$projectSpaceId');
    await ref.update(updates);
  }

  Future<String?> saveRoadmap({
    required String projectSpaceId,
    required List<Task> tasks,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? settings,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final ref = _db.ref('Roadmaps').push();
    final roadmapData = {
      'projectSpaceId': projectSpaceId,
      'ownerId': uid,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'settings': settings,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    await ref.set(roadmapData);
    final roadmapId = ref.key!;
    
    // Save tasks
    final tasksRef = _db.ref('RoadmapTasks/$roadmapId');
    final taskUpdates = <String, dynamic>{};
    
    for (final task in tasks) {
      taskUpdates[task.id] = task.toMap();
    }
    
    await tasksRef.set(taskUpdates);
    
    // Update project space to include roadmap
    await updateProjectSpaceStep(
      projectSpaceId: projectSpaceId,
      step: 4, // Roadmap is now step 4
      additionalData: {
        'roadmapId': roadmapId,
        'status': 'RoadmapCreated',
      },
    );
    
    return roadmapId;
  }

  Future<ProjectRoadmap?> getRoadmap(String projectSpaceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Get roadmap by project space ID
    final roadmapQuery = await _db
        .ref('Roadmaps')
        .orderByChild('projectSpaceId')
        .equalTo(projectSpaceId)
        .limitToFirst(1)
        .get();

    if (!roadmapQuery.exists) return null;
    
    final roadmapData = roadmapQuery.value as Map<dynamic, dynamic>;
    final roadmapEntry = roadmapData.entries.first;
    final roadmapId = roadmapEntry.key;
    final roadmap = roadmapEntry.value as Map<dynamic, dynamic>;

    // Get tasks
    final tasksSnapshot = await _db.ref('RoadmapTasks/$roadmapId').get();
    final List<Task> tasks = [];
    
    if (tasksSnapshot.exists) {
      final tasksData = tasksSnapshot.value as Map<dynamic, dynamic>;
      for (final entry in tasksData.entries) {
        final taskId = entry.key.toString();
        final taskData = entry.value as Map<dynamic, dynamic>;
        tasks.add(Task.fromMap(taskId, taskData));
      }
    }

    return ProjectRoadmap(
      projectSpaceId: projectSpaceId,
      startDate: DateTime.fromMillisecondsSinceEpoch(roadmap['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(roadmap['endDate'] ?? 0),
      tasks: tasks,
      settings: roadmap['settings'] != null 
          ? Map<String, dynamic>.from(roadmap['settings'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(roadmap['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(roadmap['updatedAt'] ?? 0),
    );
  }

  Future<void> updateTaskStatus({
    required String roadmapId,
    required String taskId,
    required bool isCompleted,
    String? completedBy,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    
    final taskRef = _db.ref('RoadmapTasks/$roadmapId/$taskId');
    final updates = <String, dynamic>{
      'isCompleted': isCompleted,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (isCompleted) {
      updates['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      updates['completedBy'] = completedBy ?? 'Unknown';
    } else {
      updates['completedAt'] = null;
      updates['completedBy'] = null;
    }
    
    await taskRef.update(updates);
  }

  Future<void> updateTask({
    required String roadmapId,
    required Task task,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    
    final taskRef = _db.ref('RoadmapTasks/$roadmapId/${task.id}');
    await taskRef.set(task.toMap());
  }

  Future<Map<String, dynamic>?> getProjectSpaceData(String projectSpaceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    
    final snapshot = await _db.ref('ProjectSpaces/$projectSpaceId').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    }
    return null;
  }

  // Alias for getProjectSpaceData for consistency
  Future<Map<String, dynamic>?> getProjectSpace(String projectSpaceId) async {
    return await getProjectSpaceData(projectSpaceId);
  }

  /// Fetch all project spaces for the current user
  Future<List<ProjectSpaceSummary>> getUserProjectSpaces() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _db
        .ref('ProjectSpaces')
        .orderByChild('ownerId')
        .equalTo(uid)
        .get();

    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final projectSpaces = <ProjectSpaceSummary>[];

    for (final entry in data.entries) {
      final id = entry.key.toString();
      final spaceData = entry.value as Map<dynamic, dynamic>;
      final summary = ProjectSpaceSummary.fromMap(
        id,
        Map<String, dynamic>.from(spaceData),
      );
      projectSpaces.add(summary);
    }

    // Sort by most recent first
    projectSpaces.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projectSpaces;
  }

  /// Get current/active project roadmap for home page
  Future<ProjectRoadmap?> getCurrentRoadmap() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Get the most recent project space with a roadmap
    final projectSpaces = await getUserProjectSpaces();
    final spacesWithRoadmap = projectSpaces.where((space) => space.roadmapId != null).toList();
    
    if (spacesWithRoadmap.isEmpty) return null;
    final activeSpace = spacesWithRoadmap.first;
    
    return await getRoadmap(activeSpace.id);
  }

  /// Get roadmap by roadmap ID (for specific roadmap access)
  Future<ProjectRoadmap?> getRoadmapById(String roadmapId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final roadmapSnapshot = await _db.ref('Roadmaps/$roadmapId').get();
    if (!roadmapSnapshot.exists) return null;

    final roadmapData = roadmapSnapshot.value as Map<dynamic, dynamic>;
    
    // Get tasks
    final tasksSnapshot = await _db.ref('RoadmapTasks/$roadmapId').get();
    final List<Task> tasks = [];
    
    if (tasksSnapshot.exists) {
      final tasksData = tasksSnapshot.value as Map<dynamic, dynamic>;
      for (final entry in tasksData.entries) {
        final taskId = entry.key.toString();
        final taskData = entry.value as Map<dynamic, dynamic>;
        tasks.add(Task.fromMap(taskId, taskData));
      }
    }

    return ProjectRoadmap.fromMap(
      Map<String, dynamic>.from(roadmapData),
      tasks,
    );
  }

  /// Update task completion status (for home page task completion)
  Future<void> updateTaskCompletion({
    required String roadmapId,
    required String taskId,
    required bool isCompleted,
    String? completedBy,
  }) async {
    await updateTaskStatus(
      roadmapId: roadmapId,
      taskId: taskId,
      isCompleted: isCompleted,
      completedBy: completedBy,
    );
  }

  /// Get project statistics for home page summary
  Future<Map<String, int>> getProjectStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {'totalProjects': 0, 'completedProjects': 0, 'inProgress': 0};

    final projectSpaces = await getUserProjectSpaces();
    final totalProjects = projectSpaces.length;
    final completedProjects = projectSpaces.where((space) => space.currentStep >= 5).length; // Updated for new step count
    final inProgress = totalProjects - completedProjects;

    return {
      'totalProjects': totalProjects,
      'completedProjects': completedProjects,
      'inProgress': inProgress,
    };
  }

  /// Save project solution
  Future<void> saveSolution({
    required String projectSpaceId,
    required ProjectSolution solution,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');

    // Save solution to Solutions collection
    final solutionRef = _db.ref('Solutions').push();
    await solutionRef.set({
      'projectSpaceId': projectSpaceId,
      'ownerId': uid,
      ...solution.toMap(),
    });

    // Update project space with solution reference
    await updateProjectSpaceStep(
      projectSpaceId: projectSpaceId,
      step: 3, // Solution step completed
      additionalData: {
        'solutionId': solutionRef.key,
        'status': 'SolutionSelected',
        'solutionTitle': solution.title,
        'solutionType': solution.type,
      },
    );
  }

  /// Get project solution
  Future<ProjectSolution?> getProjectSolution(String projectSpaceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Get solution by project space ID
    final solutionQuery = await _db
        .ref('Solutions')
        .orderByChild('projectSpaceId')
        .equalTo(projectSpaceId)
        .limitToFirst(1)
        .get();

    if (!solutionQuery.exists) return null;
    
    final solutionData = solutionQuery.value as Map<dynamic, dynamic>;
    final solutionEntry = solutionData.entries.first;
    final solution = solutionEntry.value as Map<dynamic, dynamic>;

    return ProjectSolution.fromMap(Map<String, dynamic>.from(solution));
  }

  /// Update current step for project space
  Future<void> updateCurrentStep(String projectSpaceId, int step) async {
    await updateProjectSpaceStep(
      projectSpaceId: projectSpaceId,
      step: step,
    );
  }
}
