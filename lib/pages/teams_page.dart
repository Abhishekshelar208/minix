import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:minix/services/team_service.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/models/team_member.dart';
import 'package:minix/models/team_activity.dart';
import 'package:minix/pages/team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> with AutomaticKeepAliveClientMixin {
  final TeamService _teamService = TeamService();
  final ProjectService _projectService = ProjectService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _userProjects = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
  }

  Future<void> _loadUserProjects() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all projects where user is a member
      final projectsStream = _teamService.getUserProjects();
      
      projectsStream.listen((projects) async {
        final enrichedProjects = <Map<String, dynamic>>[];
        
        for (final project in projects) {
          final projectSpaceId = project['projectSpaceId'] as String;
          
          // Get project details
          final projectData = await _projectService.getProjectSpace(projectSpaceId);
          
          if (projectData != null) {
            // Get team stats
            final stats = await _teamService.getTeamStats(projectSpaceId);
            
            enrichedProjects.add({
              ...project,
              'projectData': projectData,
              'stats': stats,
            });
          }
        }
        
        if (mounted) {
          setState(() {
            _userProjects = enrichedProjects;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProjects,
              child: _userProjects.isEmpty
                  ? _buildEmptyState()
                  : _buildTeamsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xff2563eb).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group,
                size: 80,
                color: Color(0xff2563eb),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Teams Yet',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Join a project team to collaborate with others!\n\nCreate a project or accept an invitation to get started.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xff6b7280),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.people,
                    'Collaborate in Real-Time',
                    'Work together with your team members',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.assignment_turned_in,
                    'Track Progress',
                    'See who\'s working on what tasks',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.timeline,
                    'Activity Feed',
                    'Stay updated with team activities',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff2563eb).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xff2563eb),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1f2937),
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildPageHeader(),
          
          const SizedBox(height: 24),
          
          // Team Stats Overview
          _buildTeamStatsOverview(),
          
          const SizedBox(height: 24),
          
          // Teams List
          Text(
            'My Teams (${_userProjects.length})',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userProjects.length,
            itemBuilder: (context, index) {
              return _buildTeamCard(_userProjects[index]);
            },
          ),
          
          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    final user = _auth.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'There';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff2563eb),
            Color(0xff3b82f6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2563eb).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teams & Collaboration',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your project teams, $firstName',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.groups,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsOverview() {
    int totalTeams = _userProjects.length;
    int totalMembers = 0;
    int teamsAsLeader = 0;
    
    for (final project in _userProjects) {
      final stats = project['stats'] as Map<String, int>?;
      if (stats != null) {
        totalMembers += stats['totalMembers'] ?? 0;
      }
      
      final role = project['role'] as String?;
      if (role == 'leader') {
        teamsAsLeader++;
      }
    }
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Teams',
            totalTeams.toString(),
            Icons.group,
            const Color(0xff2563eb),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Members',
            totalMembers.toString(),
            Icons.people,
            const Color(0xff059669),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Leading',
            teamsAsLeader.toString(),
            Icons.star,
            const Color(0xfff59e0b),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xff6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> projectInfo) {
    final projectData = projectInfo['projectData'] as Map<String, dynamic>?;
    final stats = projectInfo['stats'] as Map<String, int>?;
    final role = projectInfo['role'] as String? ?? 'member';
    final projectSpaceId = projectInfo['projectSpaceId'] as String;
    
    if (projectData == null) return const SizedBox.shrink();
    
    final teamName = projectData['teamName'] as String? ?? 'Unknown Team';
    final projectName = projectData['projectName'] as String?;
    final platform = projectData['targetPlatform'] as String? ?? 'App';
    final year = projectData['yearOfStudy'] as int? ?? 2;
    
    final totalMembers = stats?['totalMembers'] ?? 0;
    final leaders = stats?['leaders'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamDetailPage(
                  projectSpaceId: projectSpaceId,
                  teamName: teamName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRoleColor(role),
                            _getRoleColor(role).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 28,
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
                                  teamName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff1f2937),
                                  ),
                                ),
                              ),
                              _buildRoleBadge(role),
                            ],
                          ),
                          if (projectName != null) ...[ 
                            const SizedBox(height: 4),
                            Text(
                              projectName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xff6b7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Team Info
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.people,
                      '$totalMembers member${totalMembers == 1 ? '' : 's'}',
                      const Color(0xff2563eb),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.star,
                      '$leaders leader${leaders == 1 ? '' : 's'}',
                      const Color(0xfff59e0b),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.school,
                      'Year $year',
                      const Color(0xff7c3aed),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      _getPlatformIcon(platform),
                      platform,
                      const Color(0xff059669),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamDetailPage(
                                projectSpaceId: projectSpaceId,
                                teamName: teamName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(
                          'View Team',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff2563eb),
                          side: const BorderSide(color: Color(0xff2563eb)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String displayRole;
    
    switch (role) {
      case 'leader':
        color = const Color(0xfff59e0b);
        displayRole = 'Leader';
        break;
      case 'co-leader':
        color = const Color(0xff3b82f6);
        displayRole = 'Co-Leader';
        break;
      default:
        color = const Color(0xff6b7280);
        displayRole = 'Member';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayRole,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'app':
        return Icons.phone_android;
      case 'web':
        return Icons.web;
      case 'desktop':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }
}
