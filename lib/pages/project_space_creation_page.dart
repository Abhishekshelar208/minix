import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/invitation_service.dart';
import 'package:minix/utils/theme_helper.dart';

class ProjectSpaceCreationPage extends StatefulWidget {
  const ProjectSpaceCreationPage({super.key});

  @override
  State<ProjectSpaceCreationPage> createState() => _ProjectSpaceCreationPageState();
}

class _ProjectSpaceCreationPageState extends State<ProjectSpaceCreationPage> {
  final _projectService = ProjectService();
  final _invitationService = InvitationService();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  
  // Controllers
  final _teamNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _memberEmailController = TextEditingController();
  
  // Form state
  int _selectedYear = 2;
  List<Map<String, dynamic>> _teamMembers = []; // Changed to dynamic to support isLeader bool
  bool _isCreatingSpace = false;

  // Platform selection
  final List<String> _platforms = ['App', 'Web', 'Website'];
  String _selectedPlatform = 'App';

  @override
  void dispose() {
    _teamNameController.dispose();
    _memberNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  void _addTeamMember() {
    final memberName = _memberNameController.text.trim();
    final memberEmail = _memberEmailController.text.trim();
    
    if (memberName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter member name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (memberEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter member email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Basic email validation
    if (!memberEmail.contains('@') || !memberEmail.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a valid email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if email already exists
    if (_teamMembers.any((member) => member['email'] == memberEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ This email is already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _teamMembers.add({
        'name': memberName, 
        'email': memberEmail,
        'isLeader': false, // Default to false, user can toggle
      });
      _memberNameController.clear();
      _memberEmailController.clear();
    });
  }

  void _removeTeamMember(int index) {
    setState(() {
      _teamMembers.removeAt(index);
    });
  }

  String _getDifficultyLevel() {
    switch (_selectedYear) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Beginner-Intermediate';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Intermediate-Advanced';
      default:
        return 'Intermediate';
    }
  }

  Future<void> _createProjectSpace() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_teamMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please add at least one team member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreatingSpace = true);

    try {
      // Create project space with team details
      final projectSpaceId = await _projectService.createProjectSpace(
        teamName: _teamNameController.text.trim(),
        teamMembers: _teamMembers,
        yearOfStudy: _selectedYear,
        targetPlatform: _selectedPlatform,
        difficulty: _getDifficultyLevel(),
      );

      if (mounted && projectSpaceId != null) {
        // Add leader as project member
        await _database
            .child('ProjectMembers')
            .child(projectSpaceId)
            .child(_auth.currentUser!.uid)
            .set({
          'userId': _auth.currentUser!.uid,
          'name': _auth.currentUser!.displayName ?? 'Team Leader',
          'email': _auth.currentUser!.email,
          'role': 'leader',
          'joinedAt': DateTime.now().millisecondsSinceEpoch,
          'isActive': true,
        });

        // Add project to leader's UserProjects
        await _database
            .child('UserProjects')
            .child(_auth.currentUser!.uid)
            .child(projectSpaceId)
            .set({
          'projectSpaceId': projectSpaceId,
          'role': 'leader',
          'joinedAt': DateTime.now().millisecondsSinceEpoch,
        });

        // Send invitations to all team members
        if (_teamMembers.isNotEmpty) {
          try {
            await _invitationService.sendBulkInvitations(
              projectSpaceId: projectSpaceId,
              projectName: _teamNameController.text.trim(),
              teamName: _teamNameController.text.trim(),
              targetPlatform: _selectedPlatform,
              yearOfStudy: _selectedYear,
              members: _teamMembers,
            );
          } catch (e) {
            print('Failed to send invitations: $e');
            // Don't block project creation if invitations fail
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Project space "${_teamNameController.text.trim()}" created!\n'
              '📧 Invitations sent to ${_teamMembers.length} member(s)'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to home page to show the created project space
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(); // Go back to home page
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create project space: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingSpace = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Project Space',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffeef2ff),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 1: Project Space',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your team and project basics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps us suggest projects tailored to your team\'s year and skills.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Name Section
                    _buildSectionTitle('Team Name *'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _teamNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your team name (e.g., "Tech Innovators")',
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a team name';
                        }
                        if (value.trim().length < 3) {
                          return 'Team name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Year Selection
                    _buildSectionTitle('Year of Study *'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, color: Color(0xff2563eb)),
                              const SizedBox(width: 8),
                              Text(
                                'Select your current year:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xff374151),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [1, 2, 3, 4].map((year) {
                              final isSelected = _selectedYear == year;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedYear = year),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xff2563eb) 
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Year $year',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : const Color(0xff6b7280),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            year == 1 ? 'Beginner' : 
                                            year == 2 ? 'Basic' :
                                            year == 3 ? 'Intermediate' : 'Advanced',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: isSelected ? Colors.white70 : const Color(0xff9ca3af),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Difficulty Level: ${_getDifficultyLevel()}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Platform Selection
                    _buildSectionTitle('Target Platform *'),
                    const SizedBox(height: 12),
                    Row(
                      children: _platforms.map((platform) {
                        final isSelected = _selectedPlatform == platform;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setState(() => _selectedPlatform = platform),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xff7c3aed).withValues(alpha: 0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xff7c3aed) 
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      platform == 'App' ? Icons.phone_android :
                                      platform == 'Web' ? Icons.web :
                                      Icons.language,
                                      color: isSelected 
                                          ? const Color(0xff7c3aed) 
                                          : const Color(0xff6b7280),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      platform,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected 
                                            ? const Color(0xff7c3aed) 
                                            : const Color(0xff6b7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Team Members Section
                    _buildSectionTitle('Team Members *'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _memberNameController,
                      decoration: InputDecoration(
                        hintText: 'Member name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _memberEmailController,
                            decoration: InputDecoration(
                              hintText: 'Member email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                            keyboardType: TextInputType.emailAddress,
                            onFieldSubmitted: (_) => _addTeamMember(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addTeamMember,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff059669),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_teamMembers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Team Members (${_teamMembers.length}):',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xff059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xff059669).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Color(0xff059669),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              (member['name'] as String?) ?? '',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xff059669),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (member['isLeader'] == true) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xffeab308),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'LEADER',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        (member['email'] as String?) ?? '',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xff059669).withValues(alpha: 0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Team Leader Toggle
                                Tooltip(
                                  message: 'Toggle Team Leader',
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        final currentValue = member['isLeader'] as bool? ?? false;
                                        member['isLeader'] = !currentValue;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: member['isLeader'] == true 
                                            ? const Color(0xffeab308).withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: member['isLeader'] == true
                                              ? const Color(0xffeab308)
                                              : Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        color: member['isLeader'] == true
                                            ? const Color(0xffeab308)
                                            : Colors.grey.shade400,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  color: const Color(0xff059669),
                                  iconSize: 20,
                                  onPressed: () => _removeTeamMember(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Create Space Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingSpace ? null : _createProjectSpace,
                        icon: _isCreatingSpace
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(
                          _isCreatingSpace ? 'Creating Space...' : 'Create Project Space',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563eb),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xff1f2937),
      ),
    );
  }
}