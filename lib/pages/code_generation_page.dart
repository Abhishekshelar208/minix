import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/code_generation.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/services/code_generation_service.dart';
import 'package:minix/services/project_service.dart';

class CodeGenerationPage extends StatefulWidget {
  final String projectSpaceId;
  final String projectName;
  final Problem problem;

  const CodeGenerationPage({
    super.key,
    required this.projectSpaceId,
    required this.projectName,
    required this.problem,
  });

  @override
  State<CodeGenerationPage> createState() => _CodeGenerationPageState();
}

class _CodeGenerationPageState extends State<CodeGenerationPage> {
  final CodeGenerationService _codeService = CodeGenerationService();
  final ProjectService _projectService = ProjectService();
  
  bool _isLoading = true;
  bool _isGeneratingCode = false;
  CodeGenerationProject? _codeProject;
  Map<String, dynamic>? _projectData;
  ProjectSolution? _solution;
  
  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      // Load project space data
      final projectData = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      final solution = await _projectService.getProjectSolution(widget.projectSpaceId);
      
      if (projectData == null || solution == null) {
        throw Exception('Missing project data or solution');
      }

      // Check if code project already exists
      final existingCodeProject = await _codeService.getCodeProject(widget.projectSpaceId);
      
      setState(() {
        _projectData = projectData;
        _solution = solution;
        _codeProject = existingCodeProject;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _initializeCodeGeneration() async {
    setState(() => _isLoading = true);

    try {
      final codeProject = await _codeService.generateCodeProject(
        projectSpaceId: widget.projectSpaceId,
        projectName: widget.projectName,
        problem: widget.problem,
        solution: _solution!,
        targetPlatform: _projectData!['targetPlatform'] ?? 'App',
        difficulty: _projectData!['difficulty'] ?? 'Intermediate',
        teamSkills: List<String>.from(_projectData!['skills'] ?? []),
      );

      // Update current step to 5 (Code Generation)
      await _projectService.updateCurrentStep(widget.projectSpaceId, 5);

      setState(() {
        _codeProject = codeProject;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Code generation project initialized with ${codeProject.modules.length} modules!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to initialize code generation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateCodeForStep(CodeStep step, CodeModule module) async {
    setState(() => _isGeneratingCode = true);

    try {
      final projectContext = '''
Project: ${widget.projectName}
Problem: ${widget.problem.description}
Platform: ${_projectData!['targetPlatform']}
Solution: ${_solution!.title}
Features: ${_solution!.keyFeatures.join(', ')}
Tech Stack: ${_solution!.techStack.join(', ')}
''';

      final generatedCode = await _codeService.generateCodeForStep(
        step: step,
        projectContext: projectContext,
        projectData: _projectData!,
      );

      await _codeService.updateStepCompletion(
        projectSpaceId: widget.projectSpaceId,
        moduleId: module.id,
        stepId: step.id,
        generatedCode: generatedCode,
      );

      // Reload the project to get updated data
      await _loadProjectData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Code generated for: ${step.title}'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to generate code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGeneratingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Code Generation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          if (_codeProject != null) 
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${(_codeProject!.overallProgress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff059669),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _codeProject == null 
              ? _buildInitializationScreen()
              : _buildCodeGenerationScreen(),
    );
  }

  Widget _buildInitializationScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 5: Code Generation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate step-by-step code for your project',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: ${widget.projectName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Mode Selection
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Learning Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Step-by-Step Mode (Enabled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0f9ff),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff2563eb)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, color: const Color(0xff2563eb), size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Step-by-Step Code Prompts',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff2563eb),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xff059669),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Recommended',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learn while building! Get modular code with explanations, allowing you to understand each component step by step.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff374151),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _initializeCodeGeneration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563eb),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Start Step-by-Step Generation',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Direct Code Mode (Disabled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff9fafb),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: Colors.grey.shade500, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Direct Code Generation',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Disabled',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate complete project code automatically. This feature is disabled to encourage learning through step-by-step building.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeGenerationScreen() {
    if (_codeProject == null) return const SizedBox();
    
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 5: Code Generation',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff2563eb),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.projectName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1f2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  CircularProgressIndicator(
                    value: _codeProject!.overallProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff059669)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _codeProject!.overallProgress,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff059669)),
              ),
            ],
          ),
        ),

        // Modules List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _codeProject!.modules.length,
            itemBuilder: (context, index) {
              final module = _codeProject!.modules[index];
              return _buildModuleCard(module, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(CodeModule module, int index) {
    final completedSteps = module.steps.where((step) => step.isCompleted).length;
    final totalSteps = module.steps.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: progress == 1.0 
              ? const Color(0xff059669) 
              : const Color(0xff2563eb),
          child: progress == 1.0
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
        title: Text(
          module.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xff1f2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xff6b7280),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? const Color(0xff059669) : const Color(0xff2563eb),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedSteps/$totalSteps',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: module.steps.map((step) => _buildStepTile(step, module)).toList(),
      ),
    );
  }

  Widget _buildStepTile(CodeStep step, CodeModule module) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: step.isCompleted ? const Color(0xfff0fdf4) : const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: step.isCompleted ? const Color(0xff059669) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  step.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: step.isCompleted ? const Color(0xff059669) : const Color(0xff6b7280),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1f2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                if (!step.isCompleted && !_isGeneratingCode)
                  IconButton(
                    onPressed: () => _generateCodeForStep(step, module),
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Generate Code',
                    constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                    padding: const EdgeInsets.all(8),
                  ),
                if (_isGeneratingCode)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xff6b7280),
              ),
            ),
            if (step.filePath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff2563eb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  step.filePath!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: const Color(0xff2563eb),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
            if (step.generatedCode != null && step.generatedCode!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff1f2937),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Generated Code',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: step.generatedCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard!'),
                                backgroundColor: Color(0xff059669),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                          tooltip: 'Copy Code',
                          constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Text(
                          step.generatedCode!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: const Color(0xff10b981),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}