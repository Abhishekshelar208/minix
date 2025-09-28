import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/services/gemini_problems_service.dart';
import 'package:minix/services/project_service.dart';

class ProjectNameSuggestionsPage extends StatefulWidget {
  final String projectId;
  final Problem problem;

  const ProjectNameSuggestionsPage({
    super.key,
    required this.projectId,
    required this.problem,
  });

  @override
  State<ProjectNameSuggestionsPage> createState() => _ProjectNameSuggestionsPageState();
}

class _ProjectNameSuggestionsPageState extends State<ProjectNameSuggestionsPage> {
  final _projectService = ProjectService();
  final _gemini = const GeminiProblemsService();
  final _customNameController = TextEditingController();
  
  bool _isGeneratingNames = false;
  List<String> _suggestedNames = [];
  String? _selectedName;
  bool _isSavingName = false;
  bool _isCustomNameSelected = false;

  @override
  void initState() {
    super.initState();
    _generateProjectNames();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _generateProjectNames() async {
    setState(() {
      _isGeneratingNames = true;
      _suggestedNames = [];
    });

    try {
      print('🚀 Generating project names for: ${widget.problem.title}');
      
      final names = await _generateNamesUsingGemini();
      
      setState(() {
        _suggestedNames = names;
      });

      if (names.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Generated ${names.length} creative project names!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error generating project names: $e');
      
      // Fallback to static names if AI fails
      final fallbackNames = _generateFallbackNames();
      setState(() {
        _suggestedNames = fallbackNames;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Using fallback names. AI generation failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingNames = false);
      }
    }
  }

  Future<List<String>> _generateNamesUsingGemini() async {
    final prompt = '''
Generate exactly 6-8 creative, professional project names for this engineering project.

Problem Title: ${widget.problem.title}
Problem Description: ${widget.problem.description}
Domain: ${widget.problem.domain}
Technologies: ${widget.problem.skills.join(', ')}

Requirements:
- Names should be creative but professional
- Include technology/domain hints where appropriate
- Mix of different naming styles (descriptive, branded, technical)
- Each name should be 2-4 words maximum
- No generic names like "Project Management System"

Examples of good names:
- "SmartAttend Pro"
- "CampusTracker Hub" 
- "QR-Attendance Suite"
- "EduFlow Manager"
- "ClassSync Pro"
- "AttendEase"

Return ONLY a JSON array of strings, no other text:
["Name 1", "Name 2", "Name 3", ...]
''';

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _gemini.apiKey,
        generationConfig: GenerationConfig(temperature: 0.8),
      );

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(minutes: 1));

      final text = response.text ?? '';
      print('📥 Raw name generation response: $text');

      if (text.isEmpty) {
        throw StateError('Empty response from AI');
      }

      // Extract JSON array from response
      final jsonString = _extractJsonArray(text);
      if (jsonString.isEmpty) {
        throw StateError('No valid JSON found in response');
      }

      final List<dynamic> namesList = jsonDecode(jsonString);
      final names = namesList
          .map((e) => e.toString().trim())
          .where((name) => name.isNotEmpty)
          .take(8)
          .toList();

      if (names.isEmpty) {
        throw StateError('No valid names extracted from response');
      }

      return names;
    } catch (e) {
      print('❌ Gemini name generation failed: $e');
      rethrow;
    }
  }

  List<String> _generateFallbackNames() {
    final domain = widget.problem.domain.toLowerCase();
    final title = widget.problem.title;
    
    // Generate fallback names based on domain and problem
    final Map<String, List<String>> fallbackTemplates = {
      'college': [
        'EduTracker Pro',
        'CampusFlow Hub',
        'SmartCampus Suite',
        'EduManage Plus',
        'ClassSync Pro',
        'CampusEase'
      ],
      'hospital': [
        'MediFlow Pro',
        'HealthTracker Plus',
        'CareSync Hub',
        'MedManage Suite',
        'HealthEase Pro',
        'CareFlow Manager'
      ],
      'parking': [
        'ParkSmart Pro',
        'SpotFinder Hub',
        'ParkEase Plus',
        'SmartPark Suite',
        'ParkFlow Manager',
        'SpotSync Pro'
      ],
      'library': [
        'BookTracker Pro',
        'LibraryFlow Hub',
        'ReadEase Plus',
        'BookSync Manager',
        'LibManage Suite',
        'BookFlow Pro'
      ],
      'default': [
        'SmartSolution Pro',
        'FlowManager Hub',
        'EaseTracker Plus',
        'SyncSuite Manager',
        'ProFlow System',
        'SmartHub Plus'
      ]
    };

    final templates = fallbackTemplates[domain] ?? fallbackTemplates['default']!;
    
    // Add some variations based on the problem title
    final customNames = <String>[];
    if (title.toLowerCase().contains('attendance')) {
      customNames.addAll(['AttendEase', 'SmartAttend Pro', 'QR-Attendance Hub']);
    } else if (title.toLowerCase().contains('event')) {
      customNames.addAll(['EventFlow Pro', 'EventSync Hub', 'SmartEvent Manager']);
    } else if (title.toLowerCase().contains('book')) {
      customNames.addAll(['BookSync Pro', 'LibraryTracker Plus', 'ReadFlow Hub']);
    }
    
    // Combine and return up to 6 names
    final allNames = [...customNames, ...templates];
    return allNames.take(6).toList();
  }

  String _extractJsonArray(String text) {
    try {
      // Remove markdown code fences if present
      String cleanText = text.trim();
      if (cleanText.contains('```json')) {
        final start = cleanText.indexOf('```json') + 7;
        final end = cleanText.indexOf('```', start);
        if (end != -1) {
          cleanText = cleanText.substring(start, end).trim();
        }
      } else if (cleanText.contains('```')) {
        final start = cleanText.indexOf('```') + 3;
        final end = cleanText.indexOf('```', start);
        if (end != -1) {
          cleanText = cleanText.substring(start, end).trim();
        }
      }
      
      // Find JSON array boundaries
      final start = cleanText.indexOf('[');
      final end = cleanText.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        return cleanText.substring(start, end + 1);
      }
      
      return '[]';
    } catch (e) {
      print('Error extracting JSON: $e');
      return '[]';
    }
  }

  void _submitCustomName() {
    final customName = _customNameController.text.trim();
    if (customName.isNotEmpty && customName.length >= 3) {
      _selectProjectName(customName, isCustom: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a valid project name (at least 3 characters)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _selectProjectName(String name, {bool isCustom = false}) async {
    setState(() {
      _selectedName = name;
      _isSavingName = true;
      _isCustomNameSelected = isCustom;
    });

    try {
      print('💾 Saving project name: $name for project: ${widget.projectId}');
      
      // Update project space with the selected name
      await _projectService.updateProjectSpaceStep(
        projectSpaceId: widget.projectId,
        step: 3,
        additionalData: {
          'projectName': name,
          'status': 'ProjectNamed',
        },
      );
      
      // Also update the draft project if it exists
      try {
        await _projectService.updateDraftProject(
          projectId: widget.projectId,
          updates: {
            'projectName': name,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (e) {
        // Draft project might not exist, which is fine
        print('Note: Draft project not found or couldn\'t be updated: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Project name "$name" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a moment to show success message, then return to project steps page
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          // Return to Project Steps page to show progress and allow sequential navigation
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('❌ Error saving project name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save project name: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Project Name',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xfff8fafc),
      ),
      body: Column(
        children: [
          // Header Section
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
                  'Step 3: Project Name',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff2563eb),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected Problem: ${widget.problem.title}',
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag(widget.problem.domain, const Color(0xff2563eb)),
                    ...widget.problem.skills.take(3).map(
                      (skill) => _buildTag(skill, const Color(0xff059669)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: _isGeneratingNames
                ? _buildLoadingState()
                : _suggestedNames.isEmpty
                    ? _buildEmptyState()
                    : _buildNameSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '🤖 AI is generating creative project names...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff6b7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline, size: 64, color: Color(0xff6b7280)),
            const SizedBox(height: 16),
            Text(
              'No project names generated',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s try generating some creative names for your project',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateProjectNames,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate Names'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Choose your perfect project name',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These AI-generated names are tailored to your project. Pick one that resonates with you!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 24),

          // Name Options
          ...(_suggestedNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            final isSelected = _selectedName == name;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isSelected ? 8 : 2,
                shadowColor: isSelected ? const Color(0xff2563eb).withOpacity(0.3) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? const Color(0xff2563eb) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: _isSavingName ? null : () => _selectProjectName(name),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Option Number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xff2563eb) 
                                : const Color(0xfff3f4f6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xff6b7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Project Name
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? const Color(0xff2563eb) 
                                  : const Color(0xff1f2937),
                            ),
                          ),
                        ),
                        
                        // Selection Indicator
                        if (isSelected) ...[
                          if (_isSavingName)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xff059669),
                              size: 24,
                            ),
                        ] else ...[
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          })),

          const SizedBox(height: 32),

          // Custom Name Section
          _buildCustomNameSection(),

          const SizedBox(height: 24),

          // Regenerate Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _isGeneratingNames || _isSavingName ? null : _generateProjectNames,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate New Names'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCustomNameSection() {
    final isCustomSelected = _isCustomNameSelected && _selectedName == _customNameController.text.trim();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCustomSelected ? const Color(0xff2563eb) : Colors.grey.shade200,
          width: isCustomSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                color: const Color(0xff7c3aed),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Or create your own name',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Have something specific in mind? Enter your custom project name below.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your project name...',
                    prefixIcon: const Icon(Icons.lightbulb_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: GoogleFonts.poppins(),
                  onFieldSubmitted: (_) => _submitCustomName(),
                  enabled: !_isSavingName,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSavingName ? null : _submitCustomName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7c3aed),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSavingName && isCustomSelected
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Use This',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
          if (isCustomSelected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff059669).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xff059669),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: "${_customNameController.text.trim()}"',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
