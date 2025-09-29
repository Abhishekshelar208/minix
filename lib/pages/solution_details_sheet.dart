import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/solution.dart';

class SolutionDetailsSheet extends StatefulWidget {
  final ProjectSolution solution;
  final bool canEdit;
  final Function(ProjectSolution)? onSolutionEdited;

  const SolutionDetailsSheet({
    super.key,
    required this.solution,
    this.canEdit = false,
    this.onSolutionEdited,
  });

  @override
  State<SolutionDetailsSheet> createState() => _SolutionDetailsSheetState();
}

class _SolutionDetailsSheetState extends State<SolutionDetailsSheet> {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Solution' : 'Solution Details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1f2937),
                    ),
                  ),
                ),
                if (!_isEditing && widget.canEdit)
                  IconButton(
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit, color: Color(0xff2563eb)),
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
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              fontSize: 20,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff1f2937),
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

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
                        _buildChipsList(
                          _isEditing ? _editedFeatures : widget.solution.keyFeatures,
                          _isEditing ? _removeFeature : null,
                          const Color(0xfff3f4f6),
                          const Color(0xff6b7280),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

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
                        _buildChipsList(
                          _isEditing ? _editedTechStack : widget.solution.techStack,
                          _isEditing ? _removeTech : null,
                          const Color(0xffeef2ff),
                          const Color(0xff2563eb),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Architecture (if available)
                  if (widget.solution.architecture.isNotEmpty)
                    _buildDetailSection(
                      'Technical Architecture',
                      _buildArchitectureView(widget.solution.architecture),
                    ),

                  const SizedBox(height: 20),

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
          ),
        ],
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1f2937),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildChipsList(
    List<String> items,
    Function(int)? onRemove,
    Color backgroundColor,
    Color textColor,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onRemove(index),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: textColor.withValues(alpha: 0.7),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        children: architecture.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${entry.key.capitalize()}:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff6b7280),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
        borderRadius: BorderRadius.circular(12),
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