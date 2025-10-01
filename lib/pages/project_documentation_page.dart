import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/models/code_generation.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/code_generation_service.dart';
import 'package:minix/services/documentation_service.dart';
import 'package:minix/services/invitation_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class ProjectDocumentationPage extends StatefulWidget {
  final String projectSpaceId;
  final String projectName;

  const ProjectDocumentationPage({
    super.key,
    required this.projectSpaceId,
    required this.projectName,
  });

  @override
  State<ProjectDocumentationPage> createState() => _ProjectDocumentationPageState();
}

class _ProjectDocumentationPageState extends State<ProjectDocumentationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProjectService _projectService = ProjectService();
  final CodeGenerationService _codeService = CodeGenerationService();
  final DocumentationService _documentationService = DocumentationService();
  final InvitationService _invitationService = InvitationService();
  
  // Permissions
  bool _canEdit = true;
  bool _isCheckingPermissions = true;

  bool _isLoading = true;
  String? _currentlyGenerating; // Track which document is being generated
  
  // Project data
  Map<String, dynamic>? _projectData;
  Problem? _problem;
  ProjectSolution? _solution;
  CodeGenerationProject? _codeProject;
  
  // Documentation state
  final Map<String, String> _generatedDocuments = {}; // Store all generated documents by type
  String? _uploadedTemplateUrl;
  
  // Available document types
  final List<DocumentType> _documentTypes = [
    DocumentType(
      id: 'project_report',
      title: 'Project Report',
      description: 'Concise technical documentation (2-3 pages)',
      icon: Icons.description,
      estimatedTime: '1-2 min',
    ),
    DocumentType(
      id: 'technical_specification',
      title: 'Technical Specification',
      description: 'Brief system architecture overview (2-3 pages)',
      icon: Icons.architecture,
      estimatedTime: '1-2 min',
    ),
    DocumentType(
      id: 'synopsis',
      title: 'Project Synopsis',
      description: 'Brief overview document (2-3 pages)',
      icon: Icons.summarize,
      estimatedTime: '1-2 min',
    ),
    DocumentType(
      id: 'user_manual',
      title: 'User Manual',
      description: 'Quick start guide (2-3 pages)',
      icon: Icons.help_outline,
      estimatedTime: '1-2 min',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      setState(() => _isLoading = true);

      // Load all project data
      final projectData = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      final solution = await _projectService.getProjectSolution(widget.projectSpaceId);
      final codeProject = await _codeService.getCodeProject(widget.projectSpaceId);

      // Get problem data
      Problem? problem;
      if (projectData != null && projectData.containsKey('selectedProblem')) {
        final problemData = projectData['selectedProblem'] as Map<dynamic, dynamic>;
        problem = Problem.fromMap((problemData['id'] as String?) ?? 'default', Map<String, dynamic>.from(problemData));
      }

      setState(() {
        _projectData = projectData;
        _problem = problem;
        _solution = solution;
        _codeProject = codeProject;
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

  Future<void> _generateDocument(DocumentType docType) async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team leaders can generate documents')),
      );
      return;
    }
    
    setState(() => _currentlyGenerating = docType.id);

    try {
      // Generate professional PDF document
      final pdfFilePath = await _documentationService.generateProfessionalPDF(
        projectSpaceId: widget.projectSpaceId,
        projectName: widget.projectName,
        documentType: docType.id,
        projectData: _projectData,
        problem: _problem,
        solution: _solution,
        codeProject: _codeProject,
        templateUrl: _uploadedTemplateUrl,
      );

      // Update current step to 8 (Documentation completed, enable Viva Preparation)
      await _projectService.updateCurrentStep(widget.projectSpaceId, 8);

      setState(() {
        _generatedDocuments[docType.id] = pdfFilePath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Professional ${docType.title} PDF generated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open PDF',
              onPressed: () => _openGeneratedPDF(pdfFilePath),
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to generate ${docType.title}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _currentlyGenerating = null);
      }
    }
  }

  Future<void> _uploadTemplate() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team leaders can upload templates')),
      );
      return;
    }
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'pdf', 'txt'],
      );

      if (result != null) {
        // In a real app, you'd upload this to Firebase Storage
        // For now, we'll just store the file path
        setState(() {
          _uploadedTemplateUrl = result.files.single.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Template uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to upload template: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Loading...',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: Text(
          'Documentation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff2563eb),
          unselectedLabelColor: const Color(0xff6b7280),
          indicatorColor: const Color(0xff2563eb),
          tabs: const [
            Tab(text: '📄 Generate Docs'),
            Tab(text: '🎨 Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentGenerationTab(),
          _buildTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildDocumentGenerationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffeef2ff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 7: Documentation Generation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate professional PDF documents automatically',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: ${widget.projectName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Document Types Grid
          Text(
            'Choose Document Type',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _documentTypes.length,
            itemBuilder: (context, index) {
              final docType = _documentTypes[index];
              return _buildDocumentTypeCard(docType);
            },
          ),

          const SizedBox(height: 24),

          // Generated Documents Section
          if (_generatedDocuments.isNotEmpty) ...[
            Text(
              'Generated Documents',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildGeneratedDocumentsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTypeCard(DocumentType docType) {
    final isThisGenerating = _currentlyGenerating == docType.id;
    final isAnyGenerating = _currentlyGenerating != null;
    final isGenerated = _generatedDocuments.containsKey(docType.id);
    
    return Card(
      child: InkWell(
        onTap: isAnyGenerating ? null : () => _generateDocument(docType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                docType.icon,
                size: 36,
                color: isThisGenerating ? Colors.grey : (isGenerated ? const Color(0xff059669) : const Color(0xff2563eb)),
              ),
              const SizedBox(height: 8),
              Text(
                docType.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isThisGenerating ? Colors.grey : const Color(0xff1f2937),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  docType.description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isThisGenerating ? Colors.grey : const Color(0xff6b7280),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isThisGenerating 
                      ? Colors.grey.shade200 
                      : (isGenerated 
                          ? const Color(0xff059669).withValues(alpha: 0.1) 
                          : const Color(0xff2563eb).withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isGenerated ? 'Generated ✓' : '${docType.estimatedTime} • PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isThisGenerating 
                        ? Colors.grey 
                        : (isGenerated ? const Color(0xff059669) : const Color(0xff2563eb)),
                  ),
                ),
              ),
              if (isThisGenerating) ...[
                const SizedBox(height: 6),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratedDocumentsSection() {
    return Column(
      children: _generatedDocuments.entries.map((entry) {
        final docType = _documentTypes.firstWhere(
          (type) => type.id == entry.key,
          orElse: () => DocumentType(
            id: entry.key,
            title: entry.key,
            description: '',
            icon: Icons.description,
            estimatedTime: '',
          ),
        );
        return _buildGeneratedDocumentCard(
          docType.title,
          entry.value,
          docType.icon,
        );
      }).toList(),
    );
  }

  Widget _buildGeneratedDocumentCard(String title, String filePath, IconData icon) {
    // Extract filename from path for display
    final fileName = filePath.split('/').last;
    final fileSize = _getFileSize(filePath);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffdc2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xffdc2626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      Text(
                        'Professional PDF Document',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16, color: Color(0xff6b7280)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xff6b7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (fileSize != null) const SizedBox(height: 4),
                  if (fileSize != null)
                    Text(
                      'Size: $fileSize',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xff9ca3af),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openGeneratedPDF(filePath),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _shareDocument(title, filePath),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Template Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xfff0f9ff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload College Template',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your college-specific document template to ensure generated documents match your institution\'s format requirements.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xff6b7280),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _uploadTemplate,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_uploadedTemplateUrl != null) const SizedBox(height: 12),
                if (_uploadedTemplateUrl != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xff059669), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Template uploaded successfully',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xff059669),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Default Templates Section
          Text(
            'Default Templates',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Professional templates available when no custom template is uploaded',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 16),

          // Template Preview Cards
          _buildTemplatePreviewCard('Academic Report Template', 'Standard academic format with proper sections'),
          _buildTemplatePreviewCard('Technical Specification Template', 'Architecture and design documentation format'),
          _buildTemplatePreviewCard('Synopsis Template', 'Brief format for project overviews'),
          _buildTemplatePreviewCard('User Manual Template', 'Step-by-step guide format'),
        ],
      ),
    );
  }

  Widget _buildTemplatePreviewCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xff2563eb).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description,
                color: Color(0xff2563eb),
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
                      fontWeight: FontWeight.bold,
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
            TextButton(
              onPressed: () => _previewTemplate(title),
              child: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentPreview(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGeneratedPDF(String pdfPath) async {
    try {
      final result = await OpenFile.open(pdfPath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Could not open PDF: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error opening PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadDocument(String title, String filePath) {
    // For PDF files, the file is already saved to device storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $title PDF saved to device'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _openGeneratedPDF(filePath),
        ),
      ),
    );
  }

  Future<void> _shareDocument(String title, String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sharing $title - Generated by Minix',
        subject: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error sharing PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previewTemplate(String templateName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Template Preview: $templateName'),
        content: const Text('Template preview would be shown here in a real implementation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  String? _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) {
          return '$bytes B';
        } else if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return null;
  }
}

class DocumentType {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String estimatedTime;

  DocumentType({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.estimatedTime,
  });
}