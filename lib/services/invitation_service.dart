import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:minix/models/project_invitation.dart';

class InvitationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _currentUserEmail => _auth.currentUser?.email ?? '';
  String get _currentUserName => _auth.currentUser?.displayName ?? 'User';

  // Generate unique invitation ID
  String _generateInvitationId() {
    return 'invitation_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId.substring(0, 8)}';
  }

  /// Send invitation to a team member
  /// Creates invitation record in Firebase that the member can see
  Future<String?> sendInvitation({
    required String projectSpaceId,
    required String projectName,
    required String teamName,
    required String targetPlatform,
    required int yearOfStudy,
    required String memberEmail,
    required String memberName,
    bool isLeader = false, // Add isLeader parameter
  }) async {
    try {
      final invitationId = _generateInvitationId();
      
      final invitation = ProjectInvitation(
        id: invitationId,
        projectSpaceId: projectSpaceId,
        projectName: projectName,
        teamLeaderId: _currentUserId,
        teamLeaderName: _currentUserName,
        teamLeaderEmail: _currentUserEmail,
        invitedMemberEmail: memberEmail.toLowerCase().trim(),
        invitedMemberName: memberName,
        status: 'pending',
        invitedAt: DateTime.now(),
        teamName: teamName,
        targetPlatform: targetPlatform,
        yearOfStudy: yearOfStudy,
        isLeader: isLeader, // Store leader status in invitation
      );

      // Store invitation indexed by email (so users can find their invitations)
      await _database
          .child('Invitations')
          .child(memberEmail.toLowerCase().trim().replaceAll('.', '_'))
          .child(invitationId)
          .set(invitation.toJson());

      // Also store invitation reference in project space
      await _database
          .child('ProjectInvitations')
          .child(projectSpaceId)
          .child(invitationId)
          .set({
            'invitationId': invitationId,
            'memberEmail': memberEmail.toLowerCase().trim(),
            'memberName': memberName,
            'status': 'pending',
            'isLeader': isLeader, // Store leader status
            'sentAt': DateTime.now().millisecondsSinceEpoch,
          });

      return invitationId;
    } catch (e) {
      throw Exception('Failed to send invitation: $e');
    }
  }

  /// Send invitations to multiple team members at once
  Future<void> sendBulkInvitations({
    required String projectSpaceId,
    required String projectName,
    required String teamName,
    required String targetPlatform,
    required int yearOfStudy,
    required List<Map<String, dynamic>> members, // Changed to dynamic to support isLeader
  }) async {
    try {
      for (final member in members) {
        await sendInvitation(
          projectSpaceId: projectSpaceId,
          projectName: projectName,
          teamName: teamName,
          targetPlatform: targetPlatform,
          yearOfStudy: yearOfStudy,
          memberEmail: member['email'] as String,
          memberName: member['name'] as String,
          isLeader: member['isLeader'] as bool? ?? false, // Pass isLeader flag
        );
      }
    } catch (e) {
      throw Exception('Failed to send bulk invitations: $e');
    }
  }

  /// Get all pending invitations for current user
  Stream<List<ProjectInvitation>> getPendingInvitations() {
    final userEmail = _currentUserEmail.toLowerCase().trim().replaceAll('.', '_');
    
    return _database
        .child('Invitations')
        .child(userEmail)
        .onValue
        .map((event) {
      final invitations = <ProjectInvitation>[];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          try {
            final invitation = ProjectInvitation.fromJson(
              Map<String, dynamic>.from(value as Map),
            );
            
            // Only include pending invitations
            if (invitation.isPending) {
              invitations.add(invitation);
            }
          } catch (e) {
            print('Error parsing invitation: $e');
          }
        });
      }
      
      // Sort by invitation date (newest first)
      invitations.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
      return invitations;
    });
  }

  /// Accept an invitation and join the project
  Future<void> acceptInvitation(ProjectInvitation invitation) async {
    try {
      // Update invitation status
      final userEmail = _currentUserEmail.toLowerCase().trim().replaceAll('.', '_');
      await _database
          .child('Invitations')
          .child(userEmail)
          .child(invitation.id)
          .update({
        'status': 'accepted',
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update invitation status in project space
      await _database
          .child('ProjectInvitations')
          .child(invitation.projectSpaceId)
          .child(invitation.id)
          .update({'status': 'accepted'});

      // Determine role based on invitation (leader or member)
      final role = invitation.isLeader ? 'leader' : 'member';
      
      // Add user to project space members
      await _database
          .child('ProjectMembers')
          .child(invitation.projectSpaceId)
          .child(_currentUserId)
          .set({
        'userId': _currentUserId,
        'name': _currentUserName,
        'email': _currentUserEmail,
        'role': role, // Use role from invitation
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
      });

      // Add project space reference to user's projects list
      await _database
          .child('UserProjects')
          .child(_currentUserId)
          .child(invitation.projectSpaceId)
          .set({
        'projectSpaceId': invitation.projectSpaceId,
        'role': role, // Use role from invitation
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Reject an invitation
  Future<void> rejectInvitation(ProjectInvitation invitation) async {
    try {
      final userEmail = _currentUserEmail.toLowerCase().trim().replaceAll('.', '_');
      
      // Update invitation status
      await _database
          .child('Invitations')
          .child(userEmail)
          .child(invitation.id)
          .update({
        'status': 'rejected',
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update invitation status in project space
      await _database
          .child('ProjectInvitations')
          .child(invitation.projectSpaceId)
          .child(invitation.id)
          .update({'status': 'rejected'});
    } catch (e) {
      throw Exception('Failed to reject invitation: $e');
    }
  }

  /// Check if current user is a member of a project
  Future<bool> isProjectMember(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(_currentUserId)
          .get();
      
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user's role in a project (leader or member)
  Future<String?> getUserRole(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(_currentUserId)
          .child('role')
          .get();
      
      if (snapshot.exists) {
        return snapshot.value as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all members of a project
  Future<List<Map<String, dynamic>>> getProjectMembers(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .get();
      
      final members = <Map<String, dynamic>>[];
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          members.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      return members;
    } catch (e) {
      return [];
    }
  }

  /// Get pending invitations for a project (leader view)
  Future<List<Map<String, dynamic>>> getProjectPendingInvitations(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectInvitations')
          .child(projectSpaceId)
          .get();
      
      final invitations = <Map<String, dynamic>>[];
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final invitation = Map<String, dynamic>.from(value as Map);
          if (invitation['status'] == 'pending') {
            invitations.add(invitation);
          }
        });
      }
      
      return invitations;
    } catch (e) {
      return [];
    }
  }

  /// Remove a member from project (leader only)
  Future<void> removeMember(String projectSpaceId, String memberId) async {
    try {
      // Remove from project members
      await _database
          .child('ProjectMembers')
          .child(projectSpaceId)
          .child(memberId)
          .remove();

      // Remove from user's projects list
      await _database
          .child('UserProjects')
          .child(memberId)
          .child(projectSpaceId)
          .remove();
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Get project invitations as a stream (for real-time updates)
  Stream<List<Map<String, dynamic>>> getProjectInvitationsStream(String projectSpaceId) {
    return _database
        .child('ProjectInvitations')
        .child(projectSpaceId)
        .onValue
        .map((event) {
      final invitations = <Map<String, dynamic>>[];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          invitations.add(Map<String, dynamic>.from(value as Map));
        });
      }
      
      return invitations;
    });
  }

  /// Get count of pending invitations for current user
  Future<int> getPendingInvitationCount() async {
    try {
      final userEmail = _currentUserEmail.toLowerCase().trim().replaceAll('.', '_');
      final snapshot = await _database
          .child('Invitations')
          .child(userEmail)
          .get();
      
      if (!snapshot.exists) return 0;
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      int count = 0;
      
      data.forEach((key, value) {
        final invitation = Map<String, dynamic>.from(value as Map);
        if (invitation['status'] == 'pending') {
          count++;
        }
      });
      
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Check if current user is a leader (can edit) for this project
  /// Returns true if user is leader, false if member or not in project
  Future<bool> canEditProject(String projectSpaceId) async {
    try {
      final role = await getUserRole(projectSpaceId);
      return role == 'leader';
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is the original project creator
  Future<bool> isProjectCreator(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectSpaces')
          .child(projectSpaceId)
          .child('createdBy')
          .get();
      
      if (snapshot.exists) {
        return snapshot.value == _currentUserId;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get permission details for current user in a project
  /// Returns map with 'canEdit', 'role', 'isMember', 'isCreator'
  Future<Map<String, dynamic>> getProjectPermissions(String projectSpaceId) async {
    try {
      final role = await getUserRole(projectSpaceId);
      final isCreator = await isProjectCreator(projectSpaceId);
      final isMember = role != null;
      final canEdit = role == 'leader';
      
      return {
        'canEdit': canEdit,
        'role': role ?? 'none',
        'isMember': isMember,
        'isCreator': isCreator,
      };
    } catch (e) {
      return {
        'canEdit': false,
        'role': 'none',
        'isMember': false,
        'isCreator': false,
      };
    }
  }
}
