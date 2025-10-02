import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/project_roadmap.dart';
import 'package:minix/models/task.dart';
import 'package:minix/services/gemini_problems_service.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/invitation_service.dart';
import 'package:minix/widgets/read_only_banner.dart';

class ProjectRoadmapPage extends StatefulWidget {
  final String projectSpaceId;
  final Problem problem;
  final dynamic projectName; // Can be String or Map - we'll handle safely

  const ProjectRoadmapPage({
    super.key,
    required this.projectSpaceId,
    required this.problem,
    required this.projectName, // Dynamic type to handle String or Map
  });

  @override
  State<ProjectRoadmapPage> createState() => _ProjectRoadmapPageState();
}

class _ProjectRoadmapPageState extends State<ProjectRoadmapPage> {
  final _projectService = ProjectService();
  final _gemini = const GeminiProblemsService();
  final _invitationService = InvitationService();
  final _formKey = GlobalKey<FormState>();
  
  // Permissions
  bool _canEdit = true;

  // Form controllers
  final _deadlineController = TextEditingController();
  final _skillController = TextEditingController();

  // State
  DateTime? _selectedDeadline;
  Map<String, dynamic>? _projectSpaceData;
  Map<String, dynamic>? _selectedSolution;
  bool _isLoadingData = true;
  bool _isGeneratingRoadmap = false;
  List<Task>? _generatedTasks;
  ProjectRoadmap? _roadmap;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadProjectSpaceData();
  }
  
  Future<void> _checkPermissions() async {
    final canEdit = await _invitationService.canEditProject(widget.projectSpaceId);
    setState(() {
      _canEdit = canEdit;
    });
  }

  @override
  void dispose() {
    _deadlineController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectSpaceData() async {
    try {
      final data = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      setState(() {
        _projectSpaceData = data;
        _isLoadingData = false;
      });

      // Load selected solution data for enhanced roadmap generation
      final solutionData = await _projectService.getProjectSolution(widget.projectSpaceId);
      if (solutionData != null) {
        setState(() {
          _selectedSolution = solutionData.toMap();
        });
      }
      
      // Check if roadmap already exists
      final existingRoadmap = await _projectService.getRoadmap(widget.projectSpaceId);
      if (existingRoadmap != null) {
        setState(() {
          _roadmap = existingRoadmap;
          _generatedTasks = existingRoadmap.tasks;
          _selectedDeadline = existingRoadmap.endDate;
          _deadlineController.text = '${existingRoadmap.endDate.day}/${existingRoadmap.endDate.month}/${existingRoadmap.endDate.year}';
        });
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load project data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final lastDate = now.add(const Duration(days: 365)); // Max 1 year

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 60)),
      firstDate: now.add(const Duration(days: 7)), // At least 1 week from now
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff2563eb),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _generateRoadmap() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team leaders can generate roadmap')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate() || _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select a deadline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingRoadmap = true);

    try {
      final startDate = DateTime.now();
      final teamMembers = _projectSpaceData?['teamMembers'] != null 
          ? List<String>.from(_projectSpaceData!['teamMembers'] as List)
          : <String>['Team'];
      
      // Safely extract difficulty and targetPlatform as strings
      final difficultyValue = _projectSpaceData?['difficulty'];
      final difficulty = difficultyValue is String ? difficultyValue : 'Intermediate';
      
      final platformValue = _projectSpaceData?['targetPlatform'];
      final targetPlatform = platformValue is String ? platformValue : 'App';
      
      // Use skills from the selected problem instead of manual input
      final problemSkills = widget.problem.skills;
      
      // Safely extract projectName as string to prevent Map type issues
      String safeProjectName;
      if (widget.projectName is String) {
        safeProjectName = widget.projectName as String;
      } else {
        debugPrint('⚠️ projectName is not a String, type: ${widget.projectName.runtimeType}');
        safeProjectName = 'Project';
      }
      
      // Use problem description (should always be a String from Problem model)
      String safeDescription = widget.problem.description;
      
      // Debug ALL parameters to find any remaining Map issues
      debugPrint('🔍 === DEBUGGING ROADMAP PARAMETERS ===');
      debugPrint('projectName type: ${safeProjectName.runtimeType} = "$safeProjectName"');
      debugPrint('problem.description type: ${safeDescription.runtimeType}');
      debugPrint('teamMembers type: ${teamMembers.runtimeType}');
      debugPrint('problemSkills type: ${problemSkills.runtimeType}');
      debugPrint('difficulty type: ${difficulty.runtimeType} = "$difficulty"');
      debugPrint('targetPlatform type: ${targetPlatform.runtimeType} = "$targetPlatform"');
      debugPrint('=== END DEBUG ===');

      // Generate enhanced roadmap using AI with full context
      final tasks = await _gemini.generateRoadmap(
        projectTitle: safeProjectName,
        projectDescription: safeDescription,
        teamMembers: teamMembers,
        teamSkills: problemSkills,
        startDate: startDate,
        endDate: _selectedDeadline!,
        difficulty: difficulty,
        targetPlatform: targetPlatform,
        problem: null, // Temporarily null
        solution: null, // Temporarily null
      );

      // Save roadmap to Firebase
      final roadmapId = await _projectService.saveRoadmap(
        projectSpaceId: widget.projectSpaceId,
        tasks: tasks,
        startDate: startDate,
        endDate: _selectedDeadline!,
        settings: {
          'teamSkills': problemSkills,
          'difficulty': difficulty,
          'targetPlatform': targetPlatform,
        },
      );

      if (mounted && roadmapId != null) {
        setState(() {
          _generatedTasks = tasks;
        });

        // Update current step to 5 (Code Generation)
        await _projectService.updateCurrentStep(widget.projectSpaceId, 5);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Roadmap with ${tasks.length} tasks generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Auto-return to project steps page after 2 seconds
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          // Return to Project Steps page to show progress and allow further steps
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to generate roadmap: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingRoadmap = false);
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team leaders can update tasks')),
      );
      return;
    }
    
    if (_roadmap == null) return;

    try {
      final roadmapId = _projectSpaceData?['roadmapId'];
      if (roadmapId == null) return;

      await _projectService.updateTaskStatus(
        roadmapId: roadmapId.toString(),
        taskId: task.id,
        isCompleted: !task.isCompleted,
        completedBy: (_projectSpaceData?['teamMembers'] as List?)?.first?.toString() ?? 'User',
      );

      // Update local state
      setState(() {
        final index = _generatedTasks?.indexWhere((t) => t.id == task.id);
        if (index != null && index >= 0) {
          _generatedTasks![index] = task.copyWith(
            isCompleted: !task.isCompleted,
            completedAt: !task.isCompleted ? DateTime.now() : null,
            completedBy: !task.isCompleted ? ((_projectSpaceData?['teamMembers'] as List?)?.first?.toString() ?? 'User') : null,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(task.isCompleted 
                ? '✅ Task "${task.title}" marked as incomplete' 
                : '✅ Task "${task.title}" completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Roadmap',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
      ),
      body: Column(
        children: [
          // Read-only banner for non-leaders
          if (!_canEdit) const ReadOnlyBanner(),
          
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
                  'Step 4: Project Roadmap',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Project: ${widget.projectName is String ? widget.projectName as String : 'Untitled Project'}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.problem.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoadingData 
                ? const Center(child: CircularProgressIndicator())
                : _isGeneratingRoadmap
                    ? _buildGeneratingRoadmapView()
                    : _generatedTasks != null 
                        ? _buildRoadmapView()
                        : _buildRoadmapForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingRoadmapView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation
            Lottie.asset(
              'lib/assets/animations/loading1.json',
              width: double.infinity,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              '🛣️ AI is crafting your project roadmap...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: const Color(0xff1f2937),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Creating detailed tasks, milestones, and timelines tailored to your project',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff6b7280),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Detailed Project Roadmap',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will create a comprehensive roadmap based on your problem and solution context',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
            ),
            const SizedBox(height: 32),
            
            // Problem & Solution Context Display
            _buildContextDisplay(),
            const SizedBox(height: 32),

            // Team Info Display
            if (_projectSpaceData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.group, color: const Color(0xff2563eb), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Team: ${_projectSpaceData!['teamName']}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, color: const Color(0xff059669), size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Members: ${(_projectSpaceData!['teamMembers'] as List).join(', ')}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff374151),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.school, color: const Color(0xff7c3aed), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Year: ${_projectSpaceData!['yearOfStudy']} (${_projectSpaceData!['difficulty']})',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff374151),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Deadline Selection
            _buildSectionTitle('Project Deadline *'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              enabled: _canEdit,
              decoration: InputDecoration(
                hintText: _canEdit ? 'Select project deadline' : 'Read-only mode',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: _canEdit ? IconButton(
                  onPressed: _selectDeadline,
                  icon: const Icon(Icons.date_range),
                ) : null,
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
                if (value == null || value.isEmpty || _selectedDeadline == null) {
                  return 'Please select a project deadline';
                }
                return null;
              },
              onTap: _canEdit ? _selectDeadline : null,
            ),
            const SizedBox(height: 24),

            // Selected Technologies Display
            _buildSectionTitle('Selected Technologies'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xfff3f4f6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technologies from selected problem:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.problem.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff2563eb).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          skill,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff2563eb),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (!_canEdit || _isGeneratingRoadmap) ? null : _generateRoadmap,
                icon: _isGeneratingRoadmap
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGeneratingRoadmap ? 'Generating Roadmap...' : 
                  !_canEdit ? 'Only leaders can generate roadmap' :
                  'Generate AI Roadmap',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canEdit ? const Color(0xff2563eb) : Colors.grey,
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
    );
  }

  Widget _buildRoadmapView() {
    if (_generatedTasks == null || _generatedTasks!.isEmpty) {
      return const Center(child: Text('No tasks generated'));
    }

    final completedTasks = _generatedTasks!.where((task) => task.isCompleted).length;
    final totalTasks = _generatedTasks!.length;
    final completionPercentage = (completedTasks / totalTasks * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: completedTasks / totalTasks,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff059669)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildProgressStat('Completed', completedTasks.toString(), const Color(0xff059669)),
                    const SizedBox(width: 24),
                    _buildProgressStat('Remaining', (totalTasks - completedTasks).toString(), const Color(0xff2563eb)),
                    const SizedBox(width: 24),
                    _buildProgressStat('Total', totalTasks.toString(), const Color(0xff6b7280)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tasks List
          Text(
            'Project Tasks',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),

          ...(_generatedTasks!.map((task) => _buildTaskCard(task))),

          const SizedBox(height: 32),

          // Success Message
          if (completedTasks == totalTasks) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff059669).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 48,
                    color: Color(0xff059669),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Congratulations! 🎉',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff059669),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have completed all tasks for ${widget.projectName is String ? widget.projectName as String : 'your project'}!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xff059669),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xff6b7280),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted 
              ? const Color(0xff059669).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: task.isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox
              InkWell(
                onTap: () => _toggleTaskCompletion(task),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted 
                        ? const Color(0xff059669) 
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted 
                          ? const Color(0xff059669) 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted 
                            ? const Color(0xff6b7280) 
                            : const Color(0xff1f2937),
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Priority and category
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${task.priorityEmoji} ${task.priority}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.categoryEmoji} ${task.category}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Task metadata
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: task.isOverdue 
                    ? Colors.red 
                    : const Color(0xff6b7280),
              ),
              const SizedBox(width: 4),
              Text(
                'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: task.isOverdue 
                      ? Colors.red 
                      : const Color(0xff6b7280),
                  fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: const Color(0xff6b7280),
              ),
              const SizedBox(width: 4),
              Text(
                '${task.estimatedHours}h',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xff6b7280),
                ),
              ),
              if (task.assignedTo.isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.person,
                  size: 16,
                  color: const Color(0xff6b7280),
                ),
                const SizedBox(width: 4),
                Text(
                  task.assignedTo.first,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ],
          ),
          
          if (task.isOverdue && !task.isCompleted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⚠️ Overdue',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
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
  
  Widget _buildContextDisplay() {
    return Column(
      children: [
        // Problem Context
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfff0f9ff),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe0f2fe)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xff0369a1), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Problem Context',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0369a1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.problem.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1e40af),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.problem.hasDetailedInfo && widget.problem.detailedDescription != null
                    ? widget.problem.detailedDescription!
                    : widget.problem.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff1e40af),
                  height: 1.4,
                ),
              ),
              
              // Real-life Examples if available
              if (widget.problem.hasDetailedInfo && 
                  widget.problem.realLifeExample != null && 
                  widget.problem.realLifeExample!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Real-life Examples:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1e40af),
                  ),
                ),
                const SizedBox(height: 6),
                ...widget.problem.realLifeExample!.take(2).map((example) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $example',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xff1e40af),
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
        
        // Solution Context if available
        if (_selectedSolution != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xfff0fdf4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffd1fae5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Color(0xff059669), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Solution',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedSolution!['title']?.toString() ?? 'Custom Solution',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff065f46),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedSolution!['description']?.toString() ?? 'No description available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff065f46),
                    height: 1.4,
                  ),
                ),
                
                // Tech Stack if available
                if (_selectedSolution!['techStack'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Technology Stack:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff065f46),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: (_selectedSolution!['techStack'] as List).take(6).map((tech) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xff059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tech.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff059669),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffeef2ff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe5e7eb)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xff2563eb), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The AI will generate detailed tasks based on this context, including implementation steps, technology setup, testing, and deployment.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff2563eb),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
