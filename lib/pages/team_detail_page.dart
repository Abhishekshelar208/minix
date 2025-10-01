import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minix/services/team_service.dart';
import 'package:minix/services/invitation_service.dart';
import 'package:minix/models/team_member.dart';
import 'package:minix/models/team_activity.dart';
import 'package:minix/models/project_invitation.dart';

class TeamDetailPage extends StatefulWidget {
  final String projectSpaceId;
  final String teamName;

  const TeamDetailPage({
    super.key,
    required this.projectSpaceId,
    required this.teamName,
  });

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> with SingleTickerProviderStateMixin {
  final TeamService _teamService = TeamService();
  final InvitationService _invitationService = InvitationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  bool _canManage = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final canManage = await _teamService.canManageTeam(widget.projectSpaceId);
    setState(() {
      _canManage = canManage;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1f2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.teamName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            Text(
              'Team Management',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xff6b7280),
              ),
            ),
          ],
        ),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.person_add, color: Color(0xff2563eb)),
              onPressed: _showAddMemberDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff2563eb),
          unselectedLabelColor: const Color(0xff6b7280),
          indicatorColor: const Color(0xff2563eb),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Activity'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildActivityTab(),
                _buildInvitationsTab(),
              ],
            ),
    );
  }

  // TAB 1: MEMBERS LIST
  Widget _buildMembersTab() {
    return StreamBuilder<List<TeamMember>>(
      stream: _teamService.getTeamMembers(widget.projectSpaceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyMembers();
        }

        final members = snapshot.data!;
        final leaders = members.where((m) => m.isLeader || m.isCoLeader).toList();
        final regularMembers = members.where((m) => !m.isLeader && !m.isCoLeader).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Stats Card
                _buildTeamStatsCard(members),

                const SizedBox(height: 24),

                // Leaders Section
                if (leaders.isNotEmpty) ...[
                  _buildSectionHeader('Leaders', leaders.length),
                  const SizedBox(height: 12),
                  ...leaders.map((member) => _buildMemberCard(member)),
                  const SizedBox(height: 24),
                ],

                // Members Section
                if (regularMembers.isNotEmpty) ...[
                  _buildSectionHeader('Members', regularMembers.length),
                  const SizedBox(height: 12),
                  ...regularMembers.map((member) => _buildMemberCard(member)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamStatsCard(List<TeamMember> members) {
    final activeMembers = members.where((m) => m.isActive).length;
    final totalTasks = members.fold<int>(0, (sum, m) => sum + m.tasksCompleted);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2563eb), Color(0xff3b82f6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(members.length.toString(), 'Total', Icons.people),
          _buildStatItem(activeMembers.toString(), 'Active', Icons.check_circle),
          _buildStatItem(totalTasks.toString(), 'Tasks', Icons.assignment_turned_in),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1f2937),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xff2563eb).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2563eb),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(TeamMember member) {
    final isCurrentUser = member.userId == _auth.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  member.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(member.role),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xff10b981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'You',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff10b981),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleBadge(member.role),
                      const SizedBox(width: 8),
                      if (member.tasksCompleted > 0) ...[
                        Icon(Icons.check_circle, size: 14, color: const Color(0xff10b981)),
                        const SizedBox(width: 4),
                        Text(
                          '${member.tasksCompleted} tasks',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xff6b7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            if (_canManage && !isCurrentUser)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xff6b7280)),
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  if (!member.isLeader) ...[
                    PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward, size: 18, color: Color(0xff3b82f6)),
                          const SizedBox(width: 12),
                          Text('Promote to Co-Leader', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ],
                  if (member.isCoLeader) ...[
                    PopupMenuItem(
                      value: 'demote',
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_downward, size: 18, color: Color(0xfff59e0b)),
                          const SizedBox(width: 12),
                          Text('Demote to Member', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.person_remove, size: 18, color: Color(0xffef4444)),
                        const SizedBox(width: 12),
                        Text('Remove from Team', style: GoogleFonts.poppins(color: const Color(0xffef4444))),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String displayRole;
    IconData icon;

    switch (role) {
      case 'leader':
        color = const Color(0xfff59e0b);
        displayRole = 'Leader';
        icon = Icons.star;
        break;
      case 'co-leader':
        color = const Color(0xff3b82f6);
        displayRole = 'Co-Leader';
        icon = Icons.star_half;
        break;
      default:
        color = const Color(0xff6b7280);
        displayRole = 'Member';
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            displayRole,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMembers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Team Members Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite members to start collaborating',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: ACTIVITY FEED
  Widget _buildActivityTab() {
    return StreamBuilder<List<TeamActivity>>(
      stream: _teamService.getTeamActivities(widget.projectSpaceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyActivity();
        }

        final activities = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(activities[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(TeamActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.activityType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getActivityIcon(activity.activityType),
              size: 20,
              color: _getActivityColor(activity.activityType),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                    ),
                    Text(
                      activity.getRelativeTime(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xff9ca3af),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Activity Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Team activities will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: PENDING INVITATIONS
  Widget _buildInvitationsTab() {
    if (!_canManage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1f2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only team leaders can view invitations',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff6b7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getProjectInvitations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyInvitations();
        }

        final invitations = snapshot.data!;
        final pending = invitations.where((i) => i['status'] == 'pending').toList();

        if (pending.isEmpty) {
          return _buildEmptyInvitations();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              return _buildInvitationCard(pending[index]);
            },
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getProjectInvitations() {
    return _invitationService.getProjectInvitationsStream(widget.projectSpaceId);
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final memberName = invitation['memberName'] as String? ?? 'Unknown';
    final memberEmail = invitation['memberEmail'] as String? ?? '';
    final sentAt = invitation['sentAt'] as int?;
    
    String timeAgo = 'Recently';
    if (sentAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(sentAt);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else {
        timeAgo = '${difference.inMinutes}m ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xfff59e0b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.mail_outline, color: Color(0xfff59e0b), size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  memberEmail,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xff6b7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sent $timeAgo',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xff9ca3af),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xfff59e0b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pending',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xfff59e0b),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvitations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Pending Invitations',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All team invitations have been responded to',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ACTIONS
  void _handleMemberAction(String action, TeamMember member) async {
    switch (action) {
      case 'promote':
        await _promoteMember(member);
        break;
      case 'demote':
        await _demoteMember(member);
        break;
      case 'remove':
        await _removeMember(member);
        break;
    }
  }

  Future<void> _promoteMember(TeamMember member) async {
    final confirmed = await _showConfirmDialog(
      'Promote Member',
      'Promote ${member.name} to Co-Leader? They will have management permissions.',
    );

    if (confirmed == true) {
      try {
        await _teamService.promoteToCoLeader(widget.projectSpaceId, member.userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} promoted to Co-Leader'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to promote member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _demoteMember(TeamMember member) async {
    final confirmed = await _showConfirmDialog(
      'Demote Co-Leader',
      'Demote ${member.name} to Member? They will lose management permissions.',
    );

    if (confirmed == true) {
      try {
        await _teamService.demoteToMember(widget.projectSpaceId, member.userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} demoted to Member'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to demote member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    final confirmed = await _showConfirmDialog(
      'Remove Member',
      'Remove ${member.name} from the team? This action cannot be undone.',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _teamService.removeMember(widget.projectSpaceId, member.userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed from team'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xff6b7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? const Color(0xffef4444) : const Color(0xff2563eb),
            ),
            child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    // This would show a dialog to add new members
    // For now, we'll show a simple info message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add members from the Project Space Creation page'),
        backgroundColor: Color(0xff2563eb),
      ),
    );
  }

  // HELPER METHODS
  Color _getRoleColor(String role) {
    switch (role) {
      case 'leader':
        return const Color(0xfff59e0b);
      case 'co-leader':
        return const Color(0xff3b82f6);
      default:
        return const Color(0xff6b7280);
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'member_joined':
        return Icons.person_add;
      case 'member_left':
      case 'member_removed':
        return Icons.person_remove;
      case 'role_changed':
        return Icons.admin_panel_settings;
      case 'task_completed':
        return Icons.check_circle;
      case 'step_completed':
        return Icons.flag;
      case 'document_generated':
        return Icons.description;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'member_joined':
        return const Color(0xff10b981);
      case 'member_left':
      case 'member_removed':
        return const Color(0xffef4444);
      case 'role_changed':
        return const Color(0xff3b82f6);
      case 'task_completed':
        return const Color(0xff10b981);
      case 'step_completed':
        return const Color(0xfff59e0b);
      case 'document_generated':
        return const Color(0xff8b5cf6);
      default:
        return const Color(0xff6b7280);
    }
  }
}
