import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/solution.dart';

class SolutionDetailsPage extends StatefulWidget {
  final ProjectSolution solution;
  final bool canEdit;
  final Function(ProjectSolution)? onSolutionEdited;

  const SolutionDetailsPage({
    super.key,
    required this.solution,
    this.canEdit = false,
    this.onSolutionEdited,
  });

  @override
  State<SolutionDetailsPage> createState() => _SolutionDetailsPageState();
}

class _SolutionDetailsPageState extends State<SolutionDetailsPage> {
  bool _isEditing = false;
  
  // Edit controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featureController = TextEditingController();
  final _techController = TextEditingController();
  
  List<String> _editedFeatures = [];
  List<String> _editedTechStack = [];
  Map<String, dynamic> _editedArchitecture = {};
  
  @override
  void initState() {
    super.initState();
    _initializeEditFields();
  }
  
  void _initializeEditFields() {
    _titleController.text = widget.solution.title;
    _descriptionController.text = widget.solution.description;
    _editedFeatures = List.from(widget.solution.keyFeatures);
    _editedTechStack = List.from(widget.solution.techStack);
    _editedArchitecture = Map.from(widget.solution.architecture);
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _featureController.dispose();
    _techController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _initializeEditFields();
  }

  void _saveChanges() {
    final editedSolution = widget.solution.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      keyFeatures: _editedFeatures,
      techStack: _editedTechStack,
      architecture: _editedArchitecture,
    );
    
    widget.onSolutionEdited?.call(editedSolution);
    
    setState(() {
      _isEditing = false;
    });
    
    Navigator.pop(context, editedSolution);
  }

  void _addFeature() {
    final feature = _featureController.text.trim();
    if (feature.isNotEmpty && !_editedFeatures.contains(feature)) {
      setState(() {
        _editedFeatures.add(feature);
        _featureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _editedFeatures.removeAt(index);
    });
  }

  void _addTech() {
    final tech = _techController.text.trim();
    if (tech.isNotEmpty && !_editedTechStack.contains(tech)) {
      setState(() {
        _editedTechStack.add(tech);
        _techController.clear();
      });
    }
  }

  void _removeTech(int index) {
    setState(() {
      _editedTechStack.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Solution' : 'Solution Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isEditing && widget.canEdit)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Solution',
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2563eb),
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solution Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.solution.type == 'app_suggested'
                    ? const Color(0xffeef2ff)
                    : const Color(0xfff0fdf4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.solution.type == 'app_suggested' 
                        ? Icons.auto_awesome 
                        : Icons.person,
                    size: 16,
                    color: widget.solution.type == 'app_suggested'
                        ? const Color(0xff2563eb)
                        : const Color(0xff059669),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.solution.type == 'app_suggested' 
                        ? 'AI Generated' 
                        : 'Custom Solution',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.solution.type == 'app_suggested'
                          ? const Color(0xff2563eb)
                          : const Color(0xff059669),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title
            _buildDetailSection(
              'Solution Title',
              _isEditing
                  ? TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    )
                  : Text(
                      widget.solution.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1f2937),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Description
            _buildDetailSection(
              'Description',
              _isEditing
                  ? TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xff374151),
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    )
                  : Text(
                      widget.solution.description,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xff374151),
                        height: 1.5,
                      ),
                    ),
            ),

            // Detailed Description (if available)
            if (widget.solution.detailedDescription != null && widget.solution.detailedDescription!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Detailed Description',
                Text(
                  widget.solution.detailedDescription!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xff374151),
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Key Features
            _buildDetailSection(
              'Key Features',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _featureController,
                            decoration: const InputDecoration(
                              hintText: 'Add a feature',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (_) => _addFeature(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addFeature,
                          icon: const Icon(Icons.add, color: Color(0xff2563eb)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildBulletPoints(
                    _isEditing ? _editedFeatures : widget.solution.keyFeatures,
                    _isEditing ? _removeFeature : null,
                    Icons.check_circle_outline,
                    const Color(0xff059669),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tech Stack
            _buildDetailSection(
              'Technology Stack',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _techController,
                            decoration: const InputDecoration(
                              hintText: 'Add a technology',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (_) => _addTech(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addTech,
                          icon: const Icon(Icons.add, color: Color(0xff2563eb)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildWrappedChips(
                    _isEditing ? _editedTechStack : widget.solution.techStack,
                    _isEditing ? _removeTech : null,
                    const Color(0xffeef2ff),
                    const Color(0xff2563eb),
                  ),
                ],
              ),
            ),

            // Implementation Steps (if available)
            if (widget.solution.implementationSteps != null && widget.solution.implementationSteps!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Implementation Steps',
                _buildNumberedList(widget.solution.implementationSteps!),
              ),
            ],

            // Real Life Examples (if available)
            if (widget.solution.realLifeExamples != null && widget.solution.realLifeExamples!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Real-life Examples',
                _buildBulletPoints(
                  widget.solution.realLifeExamples!,
                  null,
                  Icons.lightbulb_outline,
                  const Color(0xfff59e0b),
                ),
              ),
            ],

            // Challenges (if available)
            if (widget.solution.challenges != null && widget.solution.challenges!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Potential Challenges',
                _buildBulletPoints(
                  widget.solution.challenges!,
                  null,
                  Icons.warning_amber_outlined,
                  const Color(0xffef4444),
                ),
              ),
            ],

            // Benefits (if available)
            if (widget.solution.benefits != null && widget.solution.benefits!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Benefits',
                _buildBulletPoints(
                  widget.solution.benefits!,
                  null,
                  Icons.thumb_up_outlined,
                  const Color(0xff10b981),
                ),
              ),
            ],

            // Learning Outcomes (if available)
            if (widget.solution.learningOutcomes != null && widget.solution.learningOutcomes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Learning Outcomes',
                _buildBulletPoints(
                  widget.solution.learningOutcomes!,
                  null,
                  Icons.school_outlined,
                  const Color(0xff8b5cf6),
                ),
              ),
            ],

            // Timeline (if available)
            if (widget.solution.timeline != null && widget.solution.timeline!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailSection(
                'Project Timeline',
                _buildTimelineView(widget.solution.timeline!),
              ),
            ],

            const SizedBox(height: 24),

            // Architecture (if available)
            if (widget.solution.architecture.isNotEmpty)
              _buildDetailSection(
                'Technical Architecture',
                _buildArchitectureView(widget.solution.architecture),
              ),

            const SizedBox(height: 24),

            // Difficulty & Metadata
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Difficulty',
                    widget.solution.difficulty,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Created',
                    _formatDate(widget.solution.createdAt),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1f2937),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildBulletPoints(
    List<String> items,
    Function(int)? onRemove,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xff374151),
                    height: 1.5,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.close, size: 16),
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberedList(List<String> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xff2563eb),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
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
      }).toList(),
    );
  }

  Widget _buildTimelineView(Map<String, dynamic> timeline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        children: timeline.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xff2563eb),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1f2937),
                        ),
                      ),
                      Text(
                        entry.value.toString(),
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWrappedChips(
    List<String> items,
    Function(int)? onRemove,
    Color backgroundColor,
    Color textColor,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: textColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onRemove(index),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArchitectureView(Map<String, dynamic> architecture) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        children: architecture.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${entry.key.capitalize()}:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    entry.value is List 
                        ? (entry.value as List).join(', ')
                        : entry.value is Map
                            ? (entry.value as Map).entries.map((e) => '${e.key}: ${e.value}').join(', ')
                            : entry.value.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xff374151),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xff6b7280)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff6b7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}