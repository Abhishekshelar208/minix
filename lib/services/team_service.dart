import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:minix/models/team_member.dart';
import 'package:minix/models/team_activity.dart';

class TeamService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _currentUserName => _auth.currentUser?.displayName ?? 'User';

  /// Get all team members for a project
  Stream<List<TeamMember>> getTeamMembers(String projectSpaceId) {
    return _database
        .child('ProjectMembers')
        .child(projectSpaceId)
        .onValue
        .map((event) {
      final members = <TeamMember>[];

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          try {
            final member = TeamMember.fromJson(
              Map<String, dynamic>.from(value as Map),
            );
            members.add(member);
          } catch (e) {
            print('Error parsing team member: $e');
          }
        });
      }

      // Sort: leaders first, then by join date
      members.sort((a, b) {
        if (a.isLeader && !b.isLeader) return -1;
        if (!a.isLeader && b.isLeader) return 1;
        if (a.isCoLeader && !b.isCoLeader) return -1;
        if (!a.isCoLeader && b.isCoLeader) return 1;
        return b.joinedAt.compareTo(a.joinedAt);
      });

      return members;
    });
  }

  /// Get team member by user ID
  Future<TeamMember?> getTeamMember(String projectSpaceId, String userId) async {
    try {
      final snapshot = await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(userId)
          .get();

      if (snapshot.exists) {
        return TeamMember.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      print('Error getting team member: $e');
      return null;
    }
  }

  /// Update team member role
  Future<void> updateMemberRole(
    String projectSpaceId,
    String userId,
    String newRole,
  ) async {
    try {
      await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(userId)
          .update({'role': newRole});

      // Also update in UserProjects
      await _database
          .child('UserProjects')
          .child(userId)
          .child(projectSpaceId)
          .update({'role': newRole});

      // Log activity
      await logActivity(
        projectSpaceId: projectSpaceId,
        activityType: 'role_changed',
        description: 'Role updated to $newRole',
      );
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Remove team member
  Future<void> removeMember(String projectSpaceId, String userId) async {
    try {
      // Remove from ProjectMembers
      await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(userId)
          .remove();

      // Remove from UserProjects
      await _database
          .child('UserProjects')
          .child(userId)
          .child(projectSpaceId)
          .remove();

      // Log activity
      await logActivity(
        projectSpaceId: projectSpaceId,
        activityType: 'member_removed',
        description: 'Member removed from team',
      );
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Update member's last active timestamp
  Future<void> updateLastActive(String projectSpaceId) async {
    try {
      await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(_currentUserId)
          .update({
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  /// Get team statistics
  Future<Map<String, int>> getTeamStats(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .get();

      if (!snapshot.exists) {
        return {
          'totalMembers': 0,
          'activeMembers': 0,
          'leaders': 0,
          'members': 0,
        };
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      int totalMembers = 0;
      int activeMembers = 0;
      int leaders = 0;
      int members = 0;

      data.forEach((key, value) {
        final member = TeamMember.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
        totalMembers++;
        if (member.isActive) activeMembers++;
        if (member.isLeader || member.isCoLeader) {
          leaders++;
        } else {
          members++;
        }
      });

      return {
        'totalMembers': totalMembers,
        'activeMembers': activeMembers,
        'leaders': leaders,
        'members': members,
      };
    } catch (e) {
      print('Error getting team stats: $e');
      return {
        'totalMembers': 0,
        'activeMembers': 0,
        'leaders': 0,
        'members': 0,
      };
    }
  }

  /// Log team activity
  Future<void> logActivity({
    required String projectSpaceId,
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activityId = 'activity_${DateTime.now().millisecondsSinceEpoch}';

      final activity = TeamActivity(
        id: activityId,
        projectSpaceId: projectSpaceId,
        userId: _currentUserId,
        userName: _currentUserName,
        activityType: activityType,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _database
          .child('TeamActivities')
          .child(projectSpaceId)
          .child(activityId)
          .set(activity.toJson());
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  /// Get team activities
  Stream<List<TeamActivity>> getTeamActivities(String projectSpaceId, {int limit = 50}) {
    return _database
        .child('TeamActivities')
        .child(projectSpaceId)
        .limitToLast(limit)
        .onValue
        .map((event) {
      final activities = <TeamActivity>[];

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          try {
            final activity = TeamActivity.fromJson(
              Map<String, dynamic>.from(value as Map),
            );
            activities.add(activity);
          } catch (e) {
            print('Error parsing activity: $e');
          }
        });
      }

      // Sort by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities;
    });
  }

  /// Check if current user is team leader/co-leader
  Future<bool> canManageTeam(String projectSpaceId) async {
    try {
      final member = await getTeamMember(projectSpaceId, _currentUserId);
      return member?.canManageTeam ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get user's role in team
  Future<String> getUserRole(String projectSpaceId) async {
    try {
      final member = await getTeamMember(projectSpaceId, _currentUserId);
      return member?.role ?? 'viewer';
    } catch (e) {
      return 'viewer';
    }
  }

  /// Get all projects where user is a member
  Stream<List<Map<String, dynamic>>> getUserProjects() {
    return _database
        .child('UserProjects')
        .child(_currentUserId)
        .onValue
        .map((event) {
      final projects = <Map<String, dynamic>>[];

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          projects.add({
            'projectSpaceId': key,
            ...Map<String, dynamic>.from(value as Map),
          });
        });
      }

      return projects;
    });
  }

  /// Get team member count for a project
  Future<int> getMemberCount(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Promote member to co-leader
  Future<void> promoteToCoLeader(String projectSpaceId, String userId) async {
    await updateMemberRole(projectSpaceId, userId, 'co-leader');
  }

  /// Demote co-leader to member
  Future<void> demoteToMember(String projectSpaceId, String userId) async {
    await updateMemberRole(projectSpaceId, userId, 'member');
  }
}
