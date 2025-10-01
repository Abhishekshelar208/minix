import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/models/code_generation.dart';
import 'package:minix/models/document_template.dart';
import 'package:minix/models/citation.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/code_generation_service.dart';
import 'package:minix/services/documentation_service.dart';
import 'package:minix/services/template_service.dart';
import 'package:minix/services/citation_service.dart';
import 'package:share_plus/share_plus.dart';

class EnhancedDocumentationPage extends StatefulWidget {
  final String projectSpaceId;
  final String projectName;

  const EnhancedDocumentationPage({
    super.key,
    required this.projectSpaceId,
    required this.projectName,
  });

  @override
  State<EnhancedDocumentationPage> createState() => _EnhancedDocumentationPageState();
}

class _EnhancedDocumentationPageState extends State<EnhancedDocumentationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Services
  final ProjectService _projectService = ProjectService();
  final CodeGenerationService _codeService = CodeGenerationService();
  final DocumentationService _documentationService = DocumentationService();
  final TemplateService _templateService = TemplateService();
  final CitationService _citationService = CitationService();

  // State variables
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isExporting = false;
  String _currentlyGeneratingType = '';
  
  // Project data
  Map<String, dynamic>? _projectData;
  Problem? _problem;
  ProjectSolution? _solution;
  CodeGenerationProject? _codeProject;
  
  // Documentation data
  List<DocumentTemplate> _availableTemplates = [];
  List<Citation> _projectCitations = [];
  Bibliography? _bibliography;
  Map<String, String> _generatedDocuments = {};
  List<DocumentVersion> _documentVersions = [];
  
  // UI state
  String _selectedDocumentType = 'project_report';
  DocumentTemplate? _selectedTemplate;
  String _selectedCitationStyle = 'APA';
  QuillController _quillController = QuillController.basic();
  String _currentDocumentContent = '';

  final List<String> _documentTypes = [
    'project_report',
    'technical_specification', 
    'synopsis',
    'user_manual',
  ];

  final Map<String, String> _documentTypeNames = {
    'project_report': 'Project Report',
    'technical_specification': 'Technical Specification',
    'synopsis': 'Project Synopsis',
    'user_manual': 'User Manual',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      setState(() => _isLoading = true);

      // Load project data
      final projectData = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      final solution = await _projectService.getProjectSolution(widget.projectSpaceId);
      final codeProject = await _codeService.getCodeProject(widget.projectSpaceId);

      // Get problem data
      Problem? problem;
      if (projectData != null && projectData.containsKey('selectedProblem')) {
        final problemData = projectData['selectedProblem'] as Map<dynamic, dynamic>;
        problem = Problem.fromMap(problemData['id']?.toString() ?? 'default', Map<String, dynamic>.from(problemData));
      }

      // Load templates
      final templates = await _templateService.getAllTemplates();
      
      // Load citations and bibliography
      final citations = await _citationService.getProjectCitations(widget.projectSpaceId);
      final bibliography = await _citationService.getProjectBibliography(widget.projectSpaceId);
      
      // Load generated documents
      final generatedDocs = await _documentationService.getGeneratedDocuments(widget.projectSpaceId);

      setState(() {
        _projectData = projectData;
        _problem = problem;
        _solution = solution;
        _codeProject = codeProject;
        _availableTemplates = templates;
        _projectCitations = citations;
        _bibliography = bibliography;
        _generatedDocuments = generatedDocs ?? {};
        _selectedTemplate = templates.where((t) => t.type == 'report').isNotEmpty 
            ? templates.where((t) => t.type == 'report').first 
            : null;
        _isLoading = false;
      });

      // Load document versions for current type
      _loadDocumentVersions();

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

  Future<void> _loadDocumentVersions() async {
    try {
      final versions = await _documentationService.getDocumentVersions(
        projectSpaceId: widget.projectSpaceId,
        documentType: _selectedDocumentType,
      );
      setState(() {
        _documentVersions = versions;
      });
    } catch (e) {
      // Failed to load document versions - this is not critical for the UI
      debugPrint('Failed to load document versions: $e');
    }
  }

  Future<void> _generateDocument() async {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _generateSpecificDocument(_selectedDocumentType);
  }

  Future<void> _generateSpecificDocument(String documentType) async {
    // Auto-select appropriate template for the document type
    DocumentTemplate? templateToUse = _selectedTemplate;
    if (templateToUse == null || templateToUse.type != _getTemplateTypeForDocument(documentType)) {
      final availableTemplates = _availableTemplates
          .where((t) => t.type == _getTemplateTypeForDocument(documentType))
          .toList();
      
      if (availableTemplates.isNotEmpty) {
        templateToUse = availableTemplates.first;
      }
    }

    if (templateToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No template available for ${_documentTypeNames[documentType]}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _currentlyGeneratingType = documentType;
    });

    try {
      final documentContent = await _documentationService.generateEnhancedDocument(
        projectSpaceId: widget.projectSpaceId,
        projectName: widget.projectName,
        documentType: documentType,
        projectData: _projectData,
        problem: _problem,
        solution: _solution,
        codeProject: _codeProject,
        templateId: templateToUse.id,
        citationStyle: _selectedCitationStyle,
      );

      // Update current step to 8 (Documentation completed)
      await _projectService.updateCurrentStep(widget.projectSpaceId, 8);

      setState(() {
        _generatedDocuments[documentType] = documentContent;
        // Update current document content if this is the selected type
        if (documentType == _selectedDocumentType) {
          _currentDocumentContent = documentContent;
          _updateEditorContent(documentContent);
        }
      });

      // Reload document versions
      if (documentType == _selectedDocumentType) {
        _loadDocumentVersions();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_documentTypeNames[documentType]} generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to generate ${_documentTypeNames[documentType]}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
        _currentlyGeneratingType = '';
      });
    }
  }

  String _getTemplateTypeForDocument(String documentType) {
    switch (documentType) {
      case 'project_report':
        return 'report';
      case 'technical_specification':
        return 'specification';
      case 'synopsis':
        return 'synopsis';
      case 'user_manual':
        return 'manual';
      default:
        return 'report';
    }
  }

  Future<void> _exportToPdf() async {
    if (!_generatedDocuments.containsKey(_selectedDocumentType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate the document first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final fileName = '${widget.projectName}_${_documentTypeNames[_selectedDocumentType]?.replaceAll(' ', '_')}';
      final filePath = await _documentationService.exportDocumentToPdf(
        projectSpaceId: widget.projectSpaceId,
        documentType: _selectedDocumentType,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF exported successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(filePath)]),
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to export PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToWord() async {
    if (!_generatedDocuments.containsKey(_selectedDocumentType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate the document first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final fileName = '${widget.projectName}_${_documentTypeNames[_selectedDocumentType]?.replaceAll(' ', '_')}';
      final filePath = await _documentationService.exportDocumentToWord(
        projectSpaceId: widget.projectSpaceId,
        documentType: _selectedDocumentType,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Word document exported successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(filePath)]),
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to export Word: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _addCommonCitations() async {
    try {
      final commonCitations = _citationService.getCommonTechCitations();
      await _documentationService.addProjectCitations(
        projectSpaceId: widget.projectSpaceId,
        citations: commonCitations,
      );

      // Reload citations
      final citations = await _citationService.getProjectCitations(widget.projectSpaceId);
      final bibliography = await _citationService.getProjectBibliography(widget.projectSpaceId);

      setState(() {
        _projectCitations = citations;
        _bibliography = bibliography;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Common technology citations added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add citations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateEditorContent(String content) {
    // Convert content to Quill format (simplified)
    try {
      _quillController = QuillController.basic();
      _quillController.document.insert(0, content);
    } catch (e) {
      // Error updating editor content - this is not critical for the UI
      debugPrint('Error updating editor content: $e');
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
          'Enhanced Documentation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff2563eb),
          unselectedLabelColor: const Color(0xff6b7280),
          indicatorColor: const Color(0xff2563eb),
          isScrollable: true,
          tabs: const [
            Tab(text: '📄 Generate'),
            Tab(text: '🎨 Templates'),
            Tab(text: '📚 Citations'),
            Tab(text: '✏️ Editor'),
            Tab(text: '📤 Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildTemplatesTab(),
          _buildCitationsTab(),
          _buildEditorTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  'Step 8: Enhanced Documentation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate professional documentation with templates and citations',
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

          // Document Type Selection
          Text(
            'Document Type',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd1d5db)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedDocumentType,
              isExpanded: true,
              underline: Container(),
              items: _documentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_documentTypeNames[type] ?? type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDocumentType = value;
                    _selectedTemplate = _availableTemplates
                        .where((t) => t.type == (value == 'project_report' ? 'report' : value))
                        .isNotEmpty
                        ? _availableTemplates
                            .where((t) => t.type == (value == 'project_report' ? 'report' : value))
                            .first
                        : null;
                  });
                  _loadDocumentVersions();
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Template Selection
          Text(
            'Template',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd1d5db)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<DocumentTemplate?>(
              value: _selectedTemplate,
              isExpanded: true,
              underline: Container(),
              items: _availableTemplates
                  .where((t) => t.type == (_selectedDocumentType == 'project_report' ? 'report' : _selectedDocumentType))
                  .map((template) {
                return DropdownMenuItem(
                  value: template,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        template.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        template.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (template) {
                setState(() {
                  _selectedTemplate = template;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // Citation Style
          Text(
            'Citation Style',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd1d5db)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedCitationStyle,
              isExpanded: true,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'APA', child: Text('APA Style')),
                DropdownMenuItem(value: 'IEEE', child: Text('IEEE Style')),
                DropdownMenuItem(value: 'MLA', child: Text('MLA Style')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCitationStyle = value;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Generate ${_documentTypeNames[_selectedDocumentType]}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Document Versions
          if (_documentVersions.isNotEmpty) ...[
            Text(
              'Document Versions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 12),
            ..._documentVersions.take(3).map((version) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xff2563eb),
                  child: Text(
                    'v${version.version}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Version ${version.version}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  version.changes ?? 'No changes specified',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: Text(
                  _formatDate(version.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xff6b7280),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentDocumentContent = version.content;
                  });
                  _updateEditorContent(version.content);
                  _tabController.animateTo(3); // Switch to editor tab
                },
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final relevantTemplates = _availableTemplates
        .where((t) => t.type == (_selectedDocumentType == 'project_report' ? 'report' : _selectedDocumentType))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Templates',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),

          ...relevantTemplates.map((template) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1f2937),
                          ),
                        ),
                      ),
                      if (_selectedTemplate?.id == template.id)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Selected',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'College: ${template.college}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sections:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...template.sections.take(5).map((section) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          section.isRequired ? Icons.circle : Icons.circle_outlined,
                          size: 8,
                          color: section.isRequired 
                              ? const Color(0xff2563eb) 
                              : const Color(0xff6b7280),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            section.title,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xff374151),
                            ),
                          ),
                        ),
                        if (section.isRequired)
                          Text(
                            'Required',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xff2563eb),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  )),
                  if (template.sections.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '... and ${template.sections.length - 5} more sections',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xff6b7280),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTemplate = template;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTemplate?.id == template.id
                              ? const Color(0xff059669)
                              : const Color(0xff2563eb),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _selectedTemplate?.id == template.id ? 'Selected' : 'Select',
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => _showTemplatePreview(template),
                        child: const Text('Preview'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCitationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Project Citations',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCommonCitations,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Common'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_projectCitations.isEmpty) 
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 48,
                      color: const Color(0xff6b7280),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Citations Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add common technology citations to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._projectCitations.map((citation) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      citation.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Authors: ${citation.authors.join(", ")}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                    if (citation.year != null)
                      Text(
                        'Year: ${citation.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    if (citation.journal != null)
                      Text(
                        'Journal: ${citation.journal}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xff2563eb).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        citation.type.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xff2563eb),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),

          const SizedBox(height: 24),

          // Bibliography Preview
          if (_bibliography != null && _bibliography!.citations.isNotEmpty) ...[
            Text(
              'Bibliography Preview (${_bibliography!.style} Style)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1f2937),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bibliography!.generateBibliography(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: const Color(0xff374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xfff9fafb),
            border: Border(bottom: BorderSide(color: Color(0xffe5e7eb))),
          ),
          child: QuillSimpleToolbar(
            controller: _quillController,
          ),
        ),
        
        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _currentDocumentContent.isEmpty
                ? Center(
                    child: Text(
                      'Generate a document first to start editing...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xff6b7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : QuillEditor.basic(
                    controller: _quillController,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Options',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),

          // Export Cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: const Color(0xffdc2626),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export to PDF',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff1f2937),
                              ),
                            ),
                            Text(
                              'Professional PDF with proper formatting, citations, and page numbering',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xff6b7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isExporting ? null : _exportToPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffdc2626),
                        foregroundColor: Colors.white,
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Export PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: const Color(0xff2563eb),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export to Word',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff1f2937),
                              ),
                            ),
                            Text(
                              'Editable Word document with proper styling and formatting',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xff6b7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isExporting ? null : _exportToWord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563eb),
                        foregroundColor: Colors.white,
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Export Word'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Generated Documents Status
          Text(
            'Document Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 12),

          ..._documentTypes.map((type) {
            final typeName = _documentTypeNames[type] ?? type;
            final isGenerated = _generatedDocuments.containsKey(type);
            final isGenerating = _isGenerating && _currentlyGeneratingType == type;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: isGenerating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xff2563eb),
                        ),
                      )
                    : Icon(
                        isGenerated ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isGenerated ? const Color(0xff059669) : const Color(0xff6b7280),
                      ),
                title: Text(
                  typeName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  isGenerating 
                      ? 'Generating...' 
                      : isGenerated 
                          ? 'Generated and ready for export' 
                          : 'Not generated yet',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: isGenerated 
                    ? PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'pdf') {
                            // Export specific document type to PDF
                            setState(() => _selectedDocumentType = type);
                            _exportToPdf();
                          } else if (action == 'word') {
                            // Export specific document type to Word
                            setState(() => _selectedDocumentType = type);
                            _exportToWord();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf, size: 16, color: Color(0xffdc2626)),
                                SizedBox(width: 8),
                                Text('Export PDF'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'word',
                            child: Row(
                              children: [
                                Icon(Icons.description, size: 16, color: Color(0xff2563eb)),
                                SizedBox(width: 8),
                                Text('Export Word'),
                              ],
                            ),
                          ),
                        ],
                      )
                    : isGenerating
                        ? null
                        : ElevatedButton(
                            onPressed: () => _generateSpecificDocument(type),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2563eb),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 32),
                            ),
                            child: const Text(
                              'Generate',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showTemplatePreview(DocumentTemplate template) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Template: ${template.name}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(template.description),
                const SizedBox(height: 16),
                Text(
                  'College: ${template.college}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sections:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...template.sections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${section.order}. '),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                            if (section.placeholder != null)
                              Text(
                                section.placeholder!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xff6b7280),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedTemplate = template;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template "${template.name}" selected'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
            ),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}