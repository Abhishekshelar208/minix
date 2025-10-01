import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/code_generation.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/services/code_generation_service.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/invitation_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PromptGenerationPage extends StatefulWidget {
  final String projectSpaceId;
  final String projectName;
  final Problem problem;

  const PromptGenerationPage({
    super.key,
    required this.projectSpaceId,
    required this.projectName,
    required this.problem,
  });

  @override
  State<PromptGenerationPage> createState() => _PromptGenerationPageState();
}

class _PromptGenerationPageState extends State<PromptGenerationPage> {
  final CodeGenerationService _codeService = CodeGenerationService();
  final ProjectService _projectService = ProjectService();
  final InvitationService _invitationService = InvitationService();
  
  // Permissions
  bool _canEdit = true;
  bool _isCheckingPermissions = true;
  
  bool _isLoading = true;
  bool _isGeneratingPrompts = false;
  bool _showAITools = false;
  CodeGenerationProject? _promptProject;
  Map<String, dynamic>? _projectData;
  ProjectSolution? _solution;
  
  // AI Tools data
  final List<AITool> _aiTools = [
    AITool(
      name: 'Cursor',
      description: 'AI-powered code editor with context awareness',
      downloadUrl: 'https://cursor.sh/',
      logo: '🖱️',
      howToUse: 'Open Cursor → Create new project → Paste prompt in chat → Follow AI suggestions',
      features: ['Context-aware coding', 'Natural language commands', 'Code completion'],
    ),
    AITool(
      name: 'GitHub Copilot',
      description: 'AI pair programmer that suggests code in real-time',
      downloadUrl: 'https://github.com/features/copilot',
      logo: '🐙',
      howToUse: 'Install in VS Code/JetBrains → Type comment with your prompt → Accept suggestions',
      features: ['Inline code suggestions', 'Chat interface', 'Multi-language support'],
    ),
    AITool(
      name: 'Claude (Anthropic)',
      description: 'Advanced AI assistant for coding and project development',
      downloadUrl: 'https://claude.ai/',
      logo: '🤖',
      howToUse: 'Visit Claude.ai → Start new conversation → Paste project prompt → Follow instructions',
      features: ['Long context window', 'Code generation', 'Project planning'],
    ),
    AITool(
      name: 'V0 (Vercel)',
      description: 'AI-powered React component and UI generator',
      downloadUrl: 'https://v0.dev/',
      logo: '⚡',
      howToUse: 'Visit v0.dev → Describe your UI → Copy generated React code',
      features: ['UI component generation', 'React/Next.js focus', 'Instant previews'],
    ),
    AITool(
      name: 'ChatGPT',
      description: 'General-purpose AI for coding assistance and learning',
      downloadUrl: 'https://chat.openai.com/',
      logo: '💬',
      howToUse: 'Visit ChatGPT → Start new chat → Paste coding prompt → Get step-by-step guidance',
      features: ['Code explanation', 'Debugging help', 'Learning support'],
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadProjectData();
  }
  
  Future<void> _checkPermissions() async {
    final canEdit = await _invitationService.canEditProject(widget.projectSpaceId);
    setState(() {
      _canEdit = canEdit;
      _isCheckingPermissions = false;
    });
  }

  Future<void> _loadProjectData() async {
    try {
      // Load project space data
      final projectData = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      final solution = await _projectService.getProjectSolution(widget.projectSpaceId);
      
      if (projectData == null || solution == null) {
        throw Exception('Missing project data or solution');
      }

      // Check if prompt project already exists
      final existingPromptProject = await _codeService.getCodeProject(widget.projectSpaceId);
      
      setState(() {
        _projectData = projectData;
        _solution = solution;
        _promptProject = existingPromptProject;
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load project data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _toggleAIToolsView() {
    setState(() {
      _showAITools = !_showAITools;
    });
  }
  
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializePromptGeneration() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team leaders can generate code prompts')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final promptProject = await _codeService.generateCodeProject(
        projectSpaceId: widget.projectSpaceId,
        projectName: widget.projectName,
        problem: widget.problem,
        solution: _solution!,
        targetPlatform: (_projectData!['targetPlatform'] as String?) ?? 'App',
        difficulty: (_projectData!['difficulty'] as String?) ?? 'Intermediate',
        teamSkills: List<String>.from((_projectData!['skills'] as List?) ?? []),
      );

      // Update current step to 5 (Prompt Generation)
      await _projectService.updateCurrentStep(widget.projectSpaceId, 5);

      if (mounted) {
        setState(() {
          _promptProject = promptProject;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Prompt generation initialized with ${promptProject.modules.length} prompt modules!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to initialize prompt generation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePromptForStep(CodeStep step, CodeModule module) async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team leaders can generate prompts')),
      );
      return;
    }
    
    setState(() => _isGeneratingPrompts = true);

    try {
      final projectContext = '''
Project: ${widget.projectName}
Problem: ${widget.problem.description}
Platform: ${(_projectData!['targetPlatform'] as String?) ?? 'App'}
Solution: ${_solution!.title}
Features: ${_solution!.keyFeatures.join(', ')}
Tech Stack: ${_solution!.techStack.join(', ')}
''';

      final generatedPrompt = await _codeService.generateCodeForStep(
        step: step,
        projectContext: projectContext,
        projectData: _projectData!,
      );

      await _codeService.updateStepCompletion(
        projectSpaceId: widget.projectSpaceId,
        moduleId: module.id,
        stepId: step.id,
        generatedCode: generatedPrompt,
      );

      // Update current step for progression
      await _codeService.updateCurrentStep(
        projectSpaceId: widget.projectSpaceId,
        stepId: step.id,
      );

      // Reload the project to get updated data
      await _loadProjectData();
      
      // Check if all prompts are completed and enable Documentation step
      if (_promptProject != null && _promptProject!.isCompleted) {
        await _projectService.updateCurrentStep(widget.projectSpaceId, 6); // Enable Documentation
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Prompt generated for: ${step.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to generate prompt: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPrompts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showAITools) {
      return _buildAIToolsScreen();
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Prompt Generation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // AI Tools button
          IconButton(
            onPressed: _toggleAIToolsView,
            icon: const Icon(Icons.smart_toy),
            tooltip: 'View AI Tools',
          ),
          if (_promptProject != null) 
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${(_promptProject!.overallProgress * 100).toInt()}%',
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
          : _promptProject == null 
              ? _buildInitializationScreen()
              : _buildPromptGenerationScreen(),
    );
  }

  Widget _buildInitializationScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 5: Prompt Generation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate smart prompts for AI coding tools',
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'AI-Powered Prompt Generation',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _toggleAIToolsView,
                      icon: const Icon(Icons.smart_toy, size: 20),
                      label: Text(
                        'View AI Tools',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff2563eb),
                      ),
                    ),
                  ],
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
                              'Smart AI Prompts Generator',
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
                  'Generate a comprehensive project overview prompt first, then get step-by-step prompts for AI coding tools. Start by introducing your project to your AI assistant, then move through development phases systematically!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff374151),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _initializePromptGeneration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563eb),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Generate AI Prompts',
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
      ),
    );
  }

  Widget _buildPromptGenerationScreen() {
    if (_promptProject == null) return const SizedBox();
    
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
                          'Step 5: Prompt Generation',
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
                    value: _promptProject!.overallProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff059669)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _promptProject!.overallProgress,
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
            itemCount: _promptProject!.modules.length,
            itemBuilder: (context, index) {
              final module = _promptProject!.modules[index];
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
    // Special styling for project overview step
    final isProjectOverview = step.id == 'project_overview';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: step.isCompleted 
              ? const Color(0xfff0fdf4) 
              : isProjectOverview 
                  ? const Color(0xfff0f9ff) // Special blue tint for overview
                  : const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: step.isCompleted 
                ? const Color(0xff059669) 
                : isProjectOverview
                    ? const Color(0xff2563eb) // Blue border for overview
                    : Colors.grey.shade200,
            width: isProjectOverview ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  step.isCompleted 
                      ? Icons.check_circle 
                      : isProjectOverview
                          ? Icons.rocket_launch
                          : Icons.radio_button_unchecked,
                  color: step.isCompleted 
                      ? const Color(0xff059669) 
                      : isProjectOverview
                          ? const Color(0xff2563eb)
                          : const Color(0xff6b7280),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                          if (isProjectOverview && !step.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff2563eb),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'START HERE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!step.isCompleted && !_isGeneratingPrompts)
                  IconButton(
                    onPressed: () => _generatePromptForStep(step, module),
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: 'Generate Prompt',
                    constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                    padding: const EdgeInsets.all(8),
                  ),
                if (_isGeneratingPrompts)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xff6b7280),
                  ),
                ),
                if (isProjectOverview && !step.isCompleted) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff2563eb).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xff2563eb),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How it works:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff2563eb),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. Generate and copy the project overview prompt\n2. Paste it in your AI tool (Cursor, Claude, etc.)\n3. Wait for AI confirmation\n4. Proceed to next prompts step by step',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xff374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (step.filePath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff2563eb).withValues(alpha: 0.1),
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
                            'Generated AI Prompt',
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
                                content: Text('Prompt copied to clipboard! 📋\nPaste it in your AI tool to generate code.'),
                                backgroundColor: Color(0xff059669),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                          tooltip: 'Copy Prompt',
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
  
  // AI Tools Screen
  Widget _buildAIToolsScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Development Tools',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleAIToolsView,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff2563eb), Color(0xff3b82f6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🤖 Choose Your AI Coding Partner',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Copy our smart prompts and paste them into these AI tools to build your ${widget.projectName} project!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // AI Tools List
            ..._aiTools.map((tool) => _buildAIToolCard(tool)),
            
            const SizedBox(height: 32),
            
            // Back to Prompts Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleAIToolsView,
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  'Back to Prompt Generation',
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
    );
  }
  
  Widget _buildAIToolCard(AITool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  tool.logo,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _launchUrl(tool.downloadUrl),
                  icon: const Icon(Icons.launch),
                  tooltip: 'Open ${tool.name}',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Features
            Text(
              'Key Features:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xff374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tool.features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff2563eb).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    feature,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff2563eb),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // How to Use
            Container(
              width: double.infinity,
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
                    'How to Use:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.howToUse,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(tool.downloadUrl),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  'Open ${tool.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AI Tool Model
class AITool {
  final String name;
  final String description;
  final String downloadUrl;
  final String logo;
  final String howToUse;
  final List<String> features;

  AITool({
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.logo,
    required this.howToUse,
    required this.features,
  });
}
