import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/solution_service.dart';
import 'package:minix/pages/solution_details_page.dart';
import 'package:minix/pages/project_steps_page.dart';

class ProjectSolutionPage extends StatefulWidget {
  final String projectSpaceId;
  final Problem problem;
  final String projectName;

  const ProjectSolutionPage({
    super.key,
    required this.projectSpaceId,
    required this.problem,
    required this.projectName,
  });

  @override
  State<ProjectSolutionPage> createState() => _ProjectSolutionPageState();
}

class _ProjectSolutionPageState extends State<ProjectSolutionPage> with TickerProviderStateMixin {
  final _solutionService = SolutionService();
  final _projectService = ProjectService();
  
  // Tab Controller
  late TabController _tabController;
  
  // State
  bool _showSolutions = false; // New: Control when to show solutions
  bool _isLoadingAISolutions = false;
  List<ProjectSolution> _aiSolutions = [];
  ProjectSolution? _selectedSolution;
  Map<String, dynamic>? _projectSpaceData;
  bool _isLoadingProjectData = true;
  
  // Custom Solution Form
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featureController = TextEditingController();
  final _techController = TextEditingController();
  
  final List<String> _customFeatures = [];
  final List<String> _customTechStack = [];
  bool _isSavingSolution = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _featureController.dispose();
    _techController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      final data = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      setState(() {
        _projectSpaceData = data;
        _isLoadingProjectData = false;
      });
      
      // Check if solution already exists
      final existingSolution = await _projectService.getProjectSolution(widget.projectSpaceId);
      if (existingSolution != null) {
        setState(() {
          _selectedSolution = existingSolution;
          _showSolutions = true; // Show solutions if already exists
        });
      }
      // Don't auto-generate solutions - let user review problem first
    } catch (e) {
      setState(() => _isLoadingProjectData = false);
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

  Future<void> _generateAISolutions() async {
    if (_projectSpaceData == null) return;
    
    setState(() => _isLoadingAISolutions = true);
    
    try {
      final difficulty = _projectSpaceData!['difficulty'] ?? 'Intermediate';
      final targetPlatform = _projectSpaceData!['targetPlatform'] ?? 'App';
      final teamSkills = widget.problem.skills; // Use skills from problem
      
      final solutions = await _solutionService.generateSolutions(
        problem: widget.problem,
        difficulty: difficulty.toString(),
        targetPlatform: targetPlatform.toString(),
        teamSkills: teamSkills,
        solutionCount: 3,
      );
      
      setState(() {
        _aiSolutions = solutions;
        _showSolutions = true; // Show solutions after successful generation
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Generated ${solutions.length} AI solution approaches!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating AI solutions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Failed to generate AI solutions: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAISolutions = false);
    }
  }

  void _selectSolution(ProjectSolution solution) {
    setState(() {
      _selectedSolution = solution;
    });
  }

  void _viewSolutionDetails(ProjectSolution solution) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SolutionDetailsPage(
          solution: solution,
          canEdit: solution.type == 'app_suggested', // Allow editing AI solutions
          onSolutionEdited: (editedSolution) {
            // Update the solution in the list
            final index = _aiSolutions.indexWhere((s) => s.id == editedSolution.id);
            if (index != -1) {
              setState(() {
                _aiSolutions[index] = editedSolution;
                if (_selectedSolution?.id == editedSolution.id) {
                  _selectedSolution = editedSolution;
                }
              });
            }
          },
        ),
      ),
    );
  }

  void _addCustomFeature() {
    final feature = _featureController.text.trim();
    if (feature.isNotEmpty && !_customFeatures.contains(feature)) {
      setState(() {
        _customFeatures.add(feature);
        _featureController.clear();
      });
    }
  }

  void _removeCustomFeature(int index) {
    setState(() {
      _customFeatures.removeAt(index);
    });
  }

  void _addCustomTech() {
    final tech = _techController.text.trim();
    if (tech.isNotEmpty && !_customTechStack.contains(tech)) {
      setState(() {
        _customTechStack.add(tech);
        _techController.clear();
      });
    }
  }

  void _removeCustomTech(int index) {
    setState(() {
      _customTechStack.removeAt(index);
    });
  }

  Future<void> _saveCustomSolution() async {
    if (!_formKey.currentState!.validate() || _customFeatures.isEmpty || _customTechStack.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingSolution = true);

    try {
      final difficulty = _projectSpaceData!['difficulty'] ?? 'Intermediate';
      
      final customSolution = _solutionService.createCustomSolution(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        keyFeatures: _customFeatures,
        techStack: _customTechStack,
        difficulty: difficulty.toString(),
      );

      setState(() {
        _selectedSolution = customSolution;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Custom solution created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to AI Solutions tab to show the selected solution
      _tabController.animateTo(0);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save custom solution: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingSolution = false);
    }
  }

  Future<void> _proceedToRoadmap() async {
    if (_selectedSolution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select a solution approach first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingSolution = true);

    try {
      // Save selected solution to Firebase
      await _projectService.saveSolution(
        projectSpaceId: widget.projectSpaceId,
        solution: _selectedSolution!,
      );

      // Update current step to 4 (Roadmap)
      await _projectService.updateCurrentStep(widget.projectSpaceId, 4);

      if (mounted) {
        // Navigate back to Project Steps page to show progress
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ProjectStepsPage(
              projectSpaceId: widget.projectSpaceId,
              teamName: (_projectSpaceData?['teamName']?.toString() ?? 'Team'),
              currentStep: 4, // Now at step 4 (Roadmap Generation)
              yearOfStudy: (_projectSpaceData?['yearOfStudy'] as int?) ?? 3,
              targetPlatform: (_projectSpaceData?['targetPlatform']?.toString() ?? 'App'),
              teamSize: (_projectSpaceData?['teamMembers'] as List?)?.length ?? 1,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save solution: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSolution = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProjectData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Loading...',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xfff8fafc),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xff2563eb)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: Text(
          _showSolutions ? 'Solution Design' : 'Review Problem',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
        bottom: _showSolutions ? TabBar(
          controller: _tabController,
          labelColor: const Color(0xff2563eb),
          unselectedLabelColor: const Color(0xff6b7280),
          indicatorColor: const Color(0xff2563eb),
          tabs: const [
            Tab(text: '🤖 AI Suggested'),
            Tab(text: '✏️ Custom Solution'),
          ],
        ) : null,
      ),
      body: _showSolutions 
          ? Column(
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
                        'Step 3: Solution Design',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff2563eb),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose or create your solution approach',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Problem: ${widget.problem.title}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAISolutionsTab(),
                      _buildCustomSolutionTab(),
                    ],
                  ),
                ),

                // Bottom Action Bar
                if (_selectedSolution != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffeef2ff),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xff2563eb), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected: ${_selectedSolution!.title}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff2563eb),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSavingSolution ? null : _proceedToRoadmap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2563eb),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSavingSolution
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Saving Solution...'),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_forward, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Proceed to Roadmap',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : _buildProblemReviewSection(),
    );
  }

  Widget _buildAISolutionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI-Generated Solutions',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: _isLoadingAISolutions ? null : _generateAISolutions,
                icon: _isLoadingAISolutions
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Regenerate Solutions',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from AI-powered solution approaches tailored to your project',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 24),

          // Loading indicator
          if (_isLoadingAISolutions)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xff2563eb)),
                  SizedBox(height: 16),
                  Text('Generating AI solutions...'),
                ],
              ),
            ),

          // AI Solutions list
          if (!_isLoadingAISolutions && _aiSolutions.isNotEmpty)
            ...(_aiSolutions.map((solution) => _buildSolutionCard(solution))),

          // Empty state
          if (!_isLoadingAISolutions && _aiSolutions.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 64,
                    color: Color(0xff6b7280),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No solutions generated yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the refresh button to generate AI solutions',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xff9ca3af),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomSolutionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Custom Solution',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Design your own solution approach with guided inputs',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
            ),
            const SizedBox(height: 24),

            // Solution Title
            _buildSectionTitle('Solution Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter your solution title (e.g., "Smart Attendance System")',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a solution title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Solution Description
            _buildSectionTitle('Solution Description *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your solution approach in detail (minimum 50 characters)',
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 50) {
                  return 'Please enter at least 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Key Features
            _buildSectionTitle('Key Features *'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _featureController,
                    decoration: const InputDecoration(
                      hintText: 'Add a key feature',
                      prefixIcon: Icon(Icons.star_outline),
                    ),
                    onFieldSubmitted: (_) => _addCustomFeature(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCustomFeature,
                  icon: const Icon(Icons.add_circle, color: Color(0xff2563eb)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildChipsList(_customFeatures, _removeCustomFeature, 'No features added yet'),
            const SizedBox(height: 20),

            // Tech Stack
            _buildSectionTitle('Technology Stack *'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _techController,
                    decoration: const InputDecoration(
                      hintText: 'Add a technology',
                      prefixIcon: Icon(Icons.code),
                    ),
                    onFieldSubmitted: (_) => _addCustomTech(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCustomTech,
                  icon: const Icon(Icons.add_circle, color: Color(0xff2563eb)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildChipsList(_customTechStack, _removeCustomTech, 'No technologies added yet'),
            const SizedBox(height: 32),

            // Create Solution Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingSolution ? null : _saveCustomSolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSavingSolution
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Creating Solution...'),
                        ],
                      )
                    : Text(
                        'Create Custom Solution',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionCard(ProjectSolution solution) {
    final isSelected = _selectedSolution?.id == solution.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xff2563eb), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with selection indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    solution.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1f2937),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xff2563eb),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              solution.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Key Features
            if (solution.keyFeatures.isNotEmpty) ...[
              Text(
                'Key Features:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff374151),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: solution.keyFeatures
                    .map((feature) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xfff3f4f6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            feature,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xff6b7280),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Tech Stack
            if (solution.techStack.isNotEmpty) ...[
              Text(
                'Tech Stack:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff374151),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: solution.techStack
                    .map((tech) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xffeef2ff),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tech,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff2563eb),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewSolutionDetails(solution),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff2563eb),
                      side: const BorderSide(color: Color(0xff2563eb)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectSolution(solution),
                    icon: Icon(
                      isSelected ? Icons.check : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    label: Text(
                      isSelected ? 'Selected' : 'Select',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? const Color(0xff059669)
                          : const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xff374151),
      ),
    );
  }

  Widget _buildChipsList(List<String> items, void Function(int) onRemove, String emptyText) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfff9fafb),
          border: Border.all(color: const Color(0xffe5e7eb)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          emptyText,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xff9ca3af),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffeef2ff),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onRemove(index),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xff6b7280),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProblemReviewSection() {
    return Column(
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
                'Step 3: Solution Design',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2563eb),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'First, let\'s review your selected problem',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1f2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review the problem details before generating solutions',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ),

        // Problem Details Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Problem Title
                Text(
                  widget.problem.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 16),

                // Problem Description
                Text(
                  widget.problem.hasDetailedInfo && widget.problem.detailedDescription != null
                      ? widget.problem.detailedDescription!
                      : widget.problem.description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xff6b7280),
                    height: 1.5,
                  ),
                ),

                // Real-life Examples (if available)
                if (widget.problem.hasDetailedInfo && 
                    widget.problem.realLifeExample != null && 
                    widget.problem.realLifeExample!.isNotEmpty) ...[
                  const SizedBox(height: 24),
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
                            const Icon(Icons.lightbulb_outline, 
                                color: Color(0xff0369a1), size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Real-life Examples',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0369a1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...widget.problem.realLifeExample!.map((example) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: Color(0xff1e40af),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  example,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xff1e40af),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                // Tags
                const SizedBox(height: 24),
                Text(
                  'Project Tags',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTagChip(widget.problem.domain, const Color(0xff2563eb)),
                    _buildTagChip('Scope: ${widget.problem.scope}', const Color(0xff059669)),
                    ...widget.problem.skills.map((skill) => 
                        _buildTagChip(skill, const Color(0xff7c3aed))),
                  ],
                ),

                // Additional Details (if available)
                if (widget.problem.hasDetailedInfo) ...[
                  // Detailed Features
                  if (widget.problem.detailedFeatures?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Key Features',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.problem.detailedFeatures!.map((feature) => 
                        _buildBulletPoint(feature)),
                  ],

                  // Implementation Steps
                  if (widget.problem.implementationSteps?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Implementation Steps',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.problem.implementationSteps!.asMap().entries.map(
                      (entry) => _buildNumberedPoint('${entry.key + 1}. ${entry.value}'),
                    ),
                  ],

                  // Challenges
                  if (widget.problem.challenges?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Potential Challenges',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.problem.challenges!.map((challenge) => 
                        _buildWarningPoint(challenge)),
                  ],
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Generate Solutions Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff0f9ff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffe0f2fe)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, 
                        color: Color(0xff0369a1), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ready to generate AI solutions based on this problem?',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff0369a1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingAISolutions ? null : _generateAISolutions,
                  icon: _isLoadingAISolutions
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    _isLoadingAISolutions 
                        ? 'Generating Solutions...' 
                        : 'Generate AI Solutions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 8, color: Color(0xff6b7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xff374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: const Color(0xff374151),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildWarningPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_outlined, 
                size: 20, color: Color(0xfff59e0b)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xff92400e),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
