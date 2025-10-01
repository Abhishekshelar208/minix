import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:minix/models/ppt_generation.dart';
import 'package:minix/services/ppt_generation_service.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/invitation_service.dart';

class PPTGenerationPage extends StatefulWidget {
  final String projectSpaceId;
  final String projectName;

  const PPTGenerationPage({
    super.key,
    required this.projectSpaceId,
    required this.projectName,
  });

  @override
  State<PPTGenerationPage> createState() => _PPTGenerationPageState();
}

class _PPTGenerationPageState extends State<PPTGenerationPage>
    with SingleTickerProviderStateMixin {
  final PPTGenerationService _pptService = PPTGenerationService();
  final ProjectService _projectService = ProjectService();
  final InvitationService _invitationService = InvitationService();
  
  // Permissions
  bool _canEdit = true;
  bool _isCheckingPermissions = true;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isUploading = false;

  List<PPTTemplate> _defaultTemplates = [];
  List<PPTTemplate> _userTemplates = [];
  List<GeneratedPPT> _generatedPPTs = [];
  PPTTemplate? _selectedTemplate;
  Map<String, dynamic>? _projectData;

  // Customization controllers
  final Map<String, TextEditingController> _customControllers = {};
  final List<String> _selectedSlides = [];
  String _selectedFormat = 'pdf';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
    _loadData();
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
    _customControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load project data
      final projectData = await _projectService.getProjectSpaceData(widget.projectSpaceId);
      
      // Load templates
      final defaultTemplates = await _pptService.getDefaultTemplates();
      final userTemplates = await _pptService.getUserTemplates();
      final generatedPPTs = await _pptService.getUserGeneratedPPTs();

      setState(() {
        _projectData = projectData;
        _defaultTemplates = defaultTemplates;
        _userTemplates = userTemplates;
        _generatedPPTs = generatedPPTs;
        _isLoading = false;
      });

      // Select first default template if available
      if (_defaultTemplates.isNotEmpty && _selectedTemplate == null) {
        _selectTemplate(_defaultTemplates.first);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    }
  }

  void _selectTemplate(PPTTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _selectedSlides.clear();
      _selectedSlides.addAll(template.slides.map((slide) => slide.id));
    });
  }

  Future<void> _uploadCustomTemplate() async {
    if (!_canEdit) {
      _showErrorSnackBar('Only team leaders can upload templates');
      return;
    }
    
    setState(() => _isUploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pptx', 'ppt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Create a custom template from uploaded file
        final customTemplate = PPTTemplate(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.name.split('.').first,
          description: 'Custom uploaded template',
          type: 'custom',
          category: 'custom',
          slides: _createBasicSlides(), // Create basic slides for now
          theme: PPTTheme(name: 'Custom'),
          createdAt: DateTime.now(),
          filePath: file.path,
        );

        final savedId = await _pptService.saveCustomTemplate(customTemplate);
        if (savedId != null) {
          await _loadData();
          _showSuccessSnackBar('Custom template uploaded successfully!');
          _tabController.animateTo(1); // Switch to user templates
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upload template: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  List<SlideTemplate> _createBasicSlides() {
    return [
      SlideTemplate(
        id: 'title',
        title: 'Title Slide',
        type: SlideType.titleSlide,
        order: 0,
        elements: [],
        layout: SlideLayout(name: 'standard'),
      ),
      SlideTemplate(
        id: 'introduction',
        title: 'Introduction',
        type: SlideType.introduction,
        order: 1,
        elements: [],
        layout: SlideLayout(name: 'standard'),
      ),
      SlideTemplate(
        id: 'content',
        title: 'Content',
        type: SlideType.content,
        order: 2,
        elements: [],
        layout: SlideLayout(name: 'standard'),
      ),
      SlideTemplate(
        id: 'thankyou',
        title: 'Thank You',
        type: SlideType.thankyou,
        order: 3,
        elements: [],
        layout: SlideLayout(name: 'standard'),
      ),
    ];
  }

  Future<void> _generatePPT() async {
    if (!_canEdit) {
      _showErrorSnackBar('Only team leaders can generate PPT');
      return;
    }
    
    if (_selectedTemplate == null) {
      _showErrorSnackBar('Please select a template first');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final customizations = <String, String>{};
      _customControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          customizations[key] = controller.text;
        }
      });

      final generatedPPT = await _pptService.generatePPT(
        projectSpaceId: widget.projectSpaceId,
        templateId: _selectedTemplate!.id,
        projectData: _projectData ?? {},
        customizations: customizations,
        includeSlides: _selectedSlides,
      );

      // Update current step to 7 (PPT Generation)
      await _projectService.updateCurrentStep(widget.projectSpaceId, 7);

      await _loadData(); // Refresh generated PPTs list
      _showSuccessSnackBar('Presentation generated successfully!');
      _tabController.animateTo(2); // Switch to generated presentations tab
    } catch (e) {
      _showErrorSnackBar('Failed to generate presentation: ${e.toString()}');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _openPPT(GeneratedPPT ppt) async {
    try {
      final file = File(ppt.filePath);
      if (await file.exists()) {
        await OpenFile.open(ppt.filePath);
      } else {
        _showErrorSnackBar('File not found');
      }
    } catch (e) {
      _showErrorSnackBar('Could not open file: ${e.toString()}');
    }
  }

  Future<void> _sharePPT(GeneratedPPT ppt) async {
    try {
      await _pptService.sharePPT(ppt);
      _showSuccessSnackBar('Presentation shared successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to share presentation: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PPT Generation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Default Templates'),
            Tab(text: 'Custom Templates'),
            Tab(text: 'Generated'),
          ],
        ),
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
                  'Step 7: PPT Generation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate professional presentations',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a template and customize your presentation for ${widget.projectName}',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDefaultTemplatesTab(),
                      _buildCustomTemplatesTab(),
                      _buildGeneratedPresentationsTab(),
                    ],
                  ),
          ),

          // Generation Panel
          if (_selectedTemplate != null) _buildGenerationPanel(),
        ],
      ),
    );
  }

  Widget _buildDefaultTemplatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose from professional templates',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),
          if (_defaultTemplates.isEmpty)
            _buildEmptyState('No default templates available')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _defaultTemplates.length,
              itemBuilder: (context, index) {
                final template = _defaultTemplates[index];
                return _buildTemplateCard(template);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomTemplatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your custom templates',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadCustomTemplate,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff059669),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userTemplates.isEmpty)
            _buildEmptyState('No custom templates yet. Upload your college template above!')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _userTemplates.length,
              itemBuilder: (context, index) {
                final template = _userTemplates[index];
                return _buildTemplateCard(template);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPresentationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your presentations',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 16),
          if (_generatedPPTs.isEmpty)
            _buildEmptyState('No presentations generated yet')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedPPTs.length,
              itemBuilder: (context, index) {
                final ppt = _generatedPPTs[index];
                return _buildGeneratedPPTCard(ppt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(PPTTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;
    
    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xff2563eb) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Preview
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getTemplateColor(template),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.slideshow,
                          size: 32,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${template.slides.length} slides',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xff2563eb),
                        ),
                      ),
                    ),
                  if (template.type == 'custom')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xff059669),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CUSTOM',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Template Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xff6b7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(template.category),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        template.category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedPPTCard(GeneratedPPT ppt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff2563eb).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    size: 24,
                    color: Color(0xff2563eb),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ppt.fileName.split('_').first,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ppt.slideCount} slides • ${_formatFileSize(ppt.fileSize)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xff6b7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generated ${_formatDate(ppt.generatedAt)}',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPPT(ppt),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff2563eb),
                      side: const BorderSide(color: Color(0xff2563eb)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sharePPT(ppt),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff059669),
                      foregroundColor: Colors.white,
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

  Widget _buildGenerationPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected: ${_selectedTemplate!.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showCustomizationDialog(),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Customize'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff2563eb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generatePPT,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generating Presentation...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Generate Presentation',
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
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.slideshow,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xff6b7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Presentation',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1f2937),
                ),
              ),
              const SizedBox(height: 20),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slide Selection
                      Text(
                        'Select Slides',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_selectedTemplate!.slides.map((slide) => CheckboxListTile(
                        title: Text(slide.title),
                        subtitle: Text(_getSlideDescription(slide.type)),
                        value: _selectedSlides.contains(slide.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedSlides.add(slide.id);
                            } else {
                              _selectedSlides.remove(slide.id);
                            }
                          });
                        },
                        dense: true,
                      ))),
                      
                      const SizedBox(height: 24),
                      
                      // Custom Text Fields
                      Text(
                        'Customizations',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildCustomField('title', 'Custom Title'),
                      _buildCustomField('subtitle', 'Custom Subtitle'),
                      _buildCustomField('introduction', 'Custom Introduction'),
                      _buildCustomField('conclusion', 'Custom Conclusion'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563eb),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomField(String key, String label) {
    if (!_customControllers.containsKey(key)) {
      _customControllers[key] = TextEditingController();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _customControllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
        ),
        maxLines: key.contains('introduction') || key.contains('conclusion') ? 3 : 1,
      ),
    );
  }

  Color _getTemplateColor(PPTTemplate template) {
    switch (template.category) {
      case 'academic':
        return const Color(0xff2563eb);
      case 'professional':
        return const Color(0xff1f2937);
      case 'creative':
        return const Color(0xff7c3aed);
      default:
        return const Color(0xff059669);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'academic':
        return const Color(0xff2563eb);
      case 'professional':
        return const Color(0xff1f2937);
      case 'creative':
        return const Color(0xff7c3aed);
      default:
        return const Color(0xff059669);
    }
  }

  String _getSlideDescription(SlideType type) {
    switch (type) {
      case SlideType.titleSlide:
        return 'Project title and team information';
      case SlideType.introduction:
        return 'Project overview and highlights';
      case SlideType.problemStatement:
        return 'Problem definition and scope';
      case SlideType.objectives:
        return 'Project goals and objectives';
      case SlideType.methodology:
        return 'Development approach';
      case SlideType.architecture:
        return 'System design and architecture';
      case SlideType.implementation:
        return 'Key features and implementation';
      case SlideType.results:
        return 'Project outcomes and achievements';
      case SlideType.conclusion:
        return 'Summary and takeaways';
      case SlideType.references:
        return 'References and resources';
      case SlideType.thankyou:
        return 'Thank you slide';
      default:
        return 'Additional content';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}