import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/pages/topic_selection_page.dart';
import 'package:minix/pages/project_name_suggestions_page.dart';
import 'package:minix/pages/project_solution_page.dart';
import 'package:minix/pages/project_roadmap_page.dart';
import 'package:minix/pages/code_generation_page.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/models/problem.dart';

class ProjectStepsPage extends StatefulWidget {
  final String projectSpaceId;
  final String teamName;
  final int currentStep;
  final int yearOfStudy;
  final String targetPlatform;
  final int teamSize;

  const ProjectStepsPage({
    super.key,
    required this.projectSpaceId,
    required this.teamName,
    required this.currentStep,
    required this.yearOfStudy,
    required this.targetPlatform,
    required this.teamSize,
  });

  @override
  State<ProjectStepsPage> createState() => _ProjectStepsPageState();
}

class _ProjectStepsPageState extends State<ProjectStepsPage> {
  int _currentStep = 1;
  final ProjectService _projectService = ProjectService();
  bool _isLoading = true;
  
  final List<ProjectStep> _steps = [
    ProjectStep(
      number: 1,
      title: 'Topic Selection',
      description: 'Choose your project topic from AI-generated suggestions',
      icon: Icons.lightbulb_outline,
    ),
    ProjectStep(
      number: 2,
      title: 'Name Selection',
      description: 'Pick the perfect name for your project',
      icon: Icons.edit_outlined,
    ),
    ProjectStep(
      number: 3,
      title: 'Solution Design',
      description: 'Choose or design your project solution approach',
      icon: Icons.architecture_outlined,
    ),
    ProjectStep(
      number: 4,
      title: 'Roadmap Generation',
      description: 'Get automated project timeline with tasks',
      icon: Icons.route_outlined,
    ),
    ProjectStep(
      number: 5,
      title: 'Code Generation',
      description: 'Generate code and collaborate with team',
      icon: Icons.code_outlined,
    ),
    ProjectStep(
      number: 6,
      title: 'Documentation',
      description: 'Generate PPTs and reports automatically',
      icon: Icons.description_outlined,
    ),
    ProjectStep(
      number: 7,
      title: 'Viva Preparation',
      description: 'Practice with AI-generated Q&A',
      icon: Icons.school_outlined,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _fetchCurrentStep();
  }
  
  // Fetch current step from database on initial load
  Future<void> _fetchCurrentStep() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final projectSpaceData = await _projectService.getProjectSpace(widget.projectSpaceId);
      if (projectSpaceData != null && projectSpaceData.containsKey('currentStep')) {
        setState(() {
          _currentStep = projectSpaceData['currentStep'] ?? 1;
          _isLoading = false;
        });
      } else {
        // Default to step 1 if no current step is saved
        setState(() {
          _currentStep = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching current step: $e');
      // Fallback to widget.currentStep or 1
      setState(() {
        _currentStep = widget.currentStep;
        _isLoading = false;
      });
    }
  }
  
  // Refresh current step from database
  Future<void> _refreshCurrentStep() async {
    try {
      final projectSpaceData = await _projectService.getProjectSpace(widget.projectSpaceId);
      if (projectSpaceData != null && projectSpaceData.containsKey('currentStep')) {
        setState(() {
          _currentStep = projectSpaceData['currentStep'] ?? _currentStep;
        });
      }
    } catch (e) {
      print('Error refreshing current step: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xfff8f9fa),
        appBar: AppBar(
          backgroundColor: const Color(0xfff8f9fa),
          elevation: 0,
          title: Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff2563eb),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xff2563eb),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xfff8f9fa),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.teamName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff2563eb),
              ),
            ),
            Text(
              'Project Steps',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff2563eb), Color(0xff3b82f6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress Overview',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Step ${_currentStep} of ${_steps.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
                    child: Text(
                      '${((_currentStep / _steps.length) * 100).round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Steps List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isEnabled = step.number <= _currentStep;
                final isCompleted = step.number < _currentStep;
                final isCurrent = step.number == _currentStep;
                
                return _buildStepCard(step, isEnabled, isCompleted, isCurrent);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(ProjectStep step, bool isEnabled, bool isCompleted, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: const Color(0xff2563eb), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isEnabled ? () => _onStepTapped(step) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Step Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xff059669)
                      : isCurrent 
                          ? const Color(0xff2563eb)
                          : isEnabled
                              ? const Color(0xff2563eb).withOpacity(0.1)
                              : const Color(0xff6b7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.check : step.icon,
                  color: isCompleted 
                      ? Colors.white
                      : isCurrent 
                          ? Colors.white
                          : isEnabled
                              ? const Color(0xff2563eb)
                              : const Color(0xff6b7280),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Step Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${step.number}. ${step.title}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? const Color(0xff1f2937) : const Color(0xff6b7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isEnabled ? const Color(0xff6b7280) : const Color(0xff9ca3af),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Icon
              Icon(
                isCompleted 
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.play_circle_outline
                        : isEnabled
                            ? Icons.radio_button_unchecked
                            : Icons.lock_outline,
                color: isCompleted 
                    ? const Color(0xff059669)
                    : isCurrent
                        ? const Color(0xff2563eb)
                        : const Color(0xff6b7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStepTapped(ProjectStep step) {
    switch (step.number) {
      case 1:
        // Navigate to Topic Selection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicSelectionPage(
              projectSpaceId: widget.projectSpaceId,
              yearOfStudy: widget.yearOfStudy,
              targetPlatform: widget.targetPlatform,
              teamSize: widget.teamSize,
            ),
          ),
        ).then((_) async {
          // After returning, refresh the steps to reflect progress
          await _refreshCurrentStep();
        });
        break;
      case 2:
        // Navigate to Project Name Selection
        _navigateToNameSelection();
        break;
      case 3:
        // Navigate to Solution Design
        _navigateToSolutionDesign();
        break;
      case 4:
        // Navigate to Roadmap Generation
        _navigateToRoadmapGeneration();
        break;
      case 5:
        // Navigate to Code Generation
        _navigateToCodeGeneration();
        break;
      case 6:
        // TODO: Navigate to Documentation
        _showComingSoon('Documentation');
        break;
      case 7:
        // TODO: Navigate to Viva Preparation
        _showComingSoon('Viva Preparation');
        break;
    }
  }

  void _navigateToNameSelection() async {
    try {
      // Get project space data to extract problem information
      final projectSpaceData = await _projectService.getProjectSpace(widget.projectSpaceId);
      
      if (projectSpaceData != null) {
        // Check if we have a selected problem or create a default one
        Problem problem;
        if (projectSpaceData.containsKey('selectedProblem') && projectSpaceData['selectedProblem'] != null) {
          final problemData = projectSpaceData['selectedProblem'] as Map<dynamic, dynamic>;
          problem = Problem.fromMap(problemData['id'] ?? 'default', Map<String, dynamic>.from(problemData));
        } else {
          // Create a default problem based on project space data
          problem = Problem(
            id: 'generated',
            title: 'Custom Project - ${widget.teamName}',
            description: 'Project for ${widget.targetPlatform} platform by ${widget.teamName}',
            domain: widget.targetPlatform.toLowerCase(),
            platform: [widget.targetPlatform],
            year: [widget.yearOfStudy],
            skills: ['Development', 'Design', 'Testing'],
            difficulty: 'Medium',
            scope: 'Medium',
            beneficiaries: ['Students', 'Team Members'],
            features: ['Custom Development', 'Team Collaboration'],
            dataSources: ['Firebase', 'Local Storage'],
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectNameSuggestionsPage(
              projectId: widget.projectSpaceId,
              problem: problem,
            ),
          ),
        ).then((_) async {
          // After returning, refresh the steps to reflect progress
          await _refreshCurrentStep();
        });
      } else {
        _showComingSoon('Name Selection - Project data not found');
      }
    } catch (e) {
      print('Error navigating to name selection: $e');
      _showComingSoon('Name Selection - Error loading data');
    }
  }

  void _navigateToSolutionDesign() async {
    try {
      // Get project space data to extract problem and project name
      final projectSpaceData = await _projectService.getProjectSpace(widget.projectSpaceId);
      
      if (projectSpaceData != null) {
        // Get project name (should be saved from step 2)
        final projectName = projectSpaceData['projectName'] ?? 'Untitled Project';
        
        // Check if we have a selected problem or create a default one
        Problem problem;
        if (projectSpaceData.containsKey('selectedProblem') && projectSpaceData['selectedProblem'] != null) {
          final problemData = projectSpaceData['selectedProblem'] as Map<dynamic, dynamic>;
          problem = Problem.fromMap(problemData['id'] ?? 'default', Map<String, dynamic>.from(problemData));
        } else {
          // Create a default problem based on project space data
          problem = Problem(
            id: 'generated',
            title: 'Custom Project - ${widget.teamName}',
            description: 'Project for ${widget.targetPlatform} platform by ${widget.teamName}',
            domain: widget.targetPlatform.toLowerCase(),
            platform: [widget.targetPlatform],
            year: [widget.yearOfStudy],
            skills: ['Development', 'Design', 'Testing'],
            difficulty: 'Medium',
            scope: 'Medium',
            beneficiaries: ['Students', 'Team Members'],
            features: ['Custom Development', 'Team Collaboration'],
            dataSources: ['Firebase', 'Local Storage'],
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectSolutionPage(
              projectSpaceId: widget.projectSpaceId,
              problem: problem,
              projectName: projectName,
            ),
          ),
        ).then((_) async {
          // After returning, refresh the steps to reflect progress
          await _refreshCurrentStep();
        });
      } else {
        _showComingSoon('Solution Design - Project data not found');
      }
    } catch (e) {
      print('Error navigating to solution design: $e');
      _showComingSoon('Solution Design - Error loading data');
    }
  }

  void _navigateToRoadmapGeneration() async {
    try {
      // Get project space data to extract problem and project name
      final projectSpaceData = await _projectService.getProjectSpace(widget.projectSpaceId);
      
      if (projectSpaceData != null) {
        // Get project name (should be saved from step 2)
        final projectName = projectSpaceData['projectName'] ?? 'Untitled Project';
        
        // Check if we have a selected problem or create a default one
        Problem problem;
        if (projectSpaceData.containsKey('selectedProblem') && projectSpaceData['selectedProblem'] != null) {
          final problemData = projectSpaceData['selectedProblem'] as Map<dynamic, dynamic>;
          problem = Problem.fromMap(problemData['id'] ?? 'default', Map<String, dynamic>.from(problemData));
        } else {
          // Create a default problem based on project space data
          problem = Problem(
            id: 'generated',
            title: 'Custom Project - ${widget.teamName}',
            description: 'Project for ${widget.targetPlatform} platform by ${widget.teamName}',
            domain: widget.targetPlatform.toLowerCase(),
            platform: [widget.targetPlatform],
            year: [widget.yearOfStudy],
            skills: ['Development', 'Design', 'Testing'],
            difficulty: 'Medium',
            scope: 'Medium',
            beneficiaries: ['Students', 'Team Members'],
            features: ['Custom Development', 'Team Collaboration'],
            dataSources: ['Firebase', 'Local Storage'],
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectRoadmapPage(
              projectSpaceId: widget.projectSpaceId,
              problem: problem,
              projectName: projectName,
            ),
          ),
        ).then((_) async {
          // After returning, refresh the steps to reflect progress
          await _refreshCurrentStep();
        });
      } else {
        _showComingSoon('Roadmap Generation - Project data not found');
      }
    } catch (e) {
      print('Error navigating to roadmap generation: $e');
      _showComingSoon('Roadmap Generation - Error loading data');
    }
  }

  void _navigateToCodeGeneration() async {
    try {
      // Get project space data to extract problem and project name
      final projectSpaceData = await _projectService.getProjectSpace(widget.projectSpaceId);
      
      if (projectSpaceData != null) {
        // Get project name (should be saved from step 2)
        final projectName = projectSpaceData['projectName'] ?? 'Untitled Project';
        
        // Check if we have a selected problem or create a default one
        Problem problem;
        if (projectSpaceData.containsKey('selectedProblem') && projectSpaceData['selectedProblem'] != null) {
          final problemData = projectSpaceData['selectedProblem'] as Map<dynamic, dynamic>;
          problem = Problem.fromMap(problemData['id'] ?? 'default', Map<String, dynamic>.from(problemData));
        } else {
          // Create a default problem based on project space data
          problem = Problem(
            id: 'generated',
            title: 'Custom Project - ${widget.teamName}',
            description: 'Project for ${widget.targetPlatform} platform by ${widget.teamName}',
            domain: widget.targetPlatform.toLowerCase(),
            platform: [widget.targetPlatform],
            year: [widget.yearOfStudy],
            skills: ['Development', 'Design', 'Testing'],
            difficulty: 'Medium',
            scope: 'Medium',
            beneficiaries: ['Students', 'Team Members'],
            features: ['Custom Development', 'Team Collaboration'],
            dataSources: ['Firebase', 'Local Storage'],
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CodeGenerationPage(
              projectSpaceId: widget.projectSpaceId,
              projectName: projectName,
              problem: problem,
            ),
          ),
        ).then((_) async {
          // After returning, refresh the steps to reflect progress
          await _refreshCurrentStep();
        });
      } else {
        _showComingSoon('Code Generation - Project data not found');
      }
    } catch (e) {
      print('Error navigating to code generation: $e');
      _showComingSoon('Code Generation - Error loading data');
    }
  }

  void _showComingSoon(String stepName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$stepName coming soon!'),
        backgroundColor: const Color(0xff2563eb),
      ),
    );
  }
}

class ProjectStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;

  ProjectStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}