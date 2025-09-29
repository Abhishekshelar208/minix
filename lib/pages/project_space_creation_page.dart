import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/services/project_service.dart';

class ProjectSpaceCreationPage extends StatefulWidget {
  const ProjectSpaceCreationPage({super.key});

  @override
  State<ProjectSpaceCreationPage> createState() => _ProjectSpaceCreationPageState();
}

class _ProjectSpaceCreationPageState extends State<ProjectSpaceCreationPage> {
  final _projectService = ProjectService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _teamNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  
  // Form state
  int _selectedYear = 2;
  List<String> _teamMembers = [];
  bool _isCreatingSpace = false;

  // Platform selection
  final List<String> _platforms = ['App', 'Web', 'Website'];
  String _selectedPlatform = 'App';

  @override
  void dispose() {
    _teamNameController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _addTeamMember() {
    final memberName = _memberNameController.text.trim();
    if (memberName.isNotEmpty && !_teamMembers.contains(memberName)) {
      setState(() {
        _teamMembers.add(memberName);
        _memberNameController.clear();
      });
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Project space "${_teamNameController.text.trim()}" created!'),
            backgroundColor: Colors.green,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _memberNameController,
                            decoration: InputDecoration(
                              hintText: 'Add team member name',
                              prefixIcon: const Icon(Icons.person_add),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
                              ),
                            ),
                            style: GoogleFonts.poppins(),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _teamMembers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final member = entry.value;
                          return Chip(
                            label: Text(member),
                            onDeleted: () => _removeTeamMember(index),
                            backgroundColor: const Color(0xff059669).withValues(alpha: 0.1),
                            labelStyle: GoogleFonts.poppins(
                              color: const Color(0xff059669),
                              fontSize: 12,
                            ),
                            deleteIconColor: const Color(0xff059669),
                          );
                        }).toList(),
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