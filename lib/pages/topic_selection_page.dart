import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/pages/problem_details_page.dart';
import 'package:minix/services/project_service.dart';
import 'package:minix/services/gemini_problems_service.dart';

class TopicSelectionPage extends StatefulWidget {
  final String? projectSpaceId;
  final int? yearOfStudy;
  final String? targetPlatform;
  final int? teamSize;
  
  const TopicSelectionPage({
    super.key,
    this.projectSpaceId,
    this.yearOfStudy,
    this.targetPlatform,
    this.teamSize,
  });

  @override
  State<TopicSelectionPage> createState() => _TopicSelectionPageState();
}

class _TopicSelectionPageState extends State<TopicSelectionPage> {
  final _projectService = ProjectService();
  final _gemini = const GeminiProblemsService();
  final _yearController = TextEditingController();
  final _customTechController = TextEditingController();
  final _customDomainController = TextEditingController();

  // Form state
  String? _selectedDomain;
  final Set<String> _selectedTechs = {};
  bool _hasSearched = false;

  // Results state
  bool _isSearching = false;
  List<Problem> _searchResults = [];
  Set<String> _bookmarks = {};
  bool _isGeneratingDetails = false;
  String? _generatingDetailsForId;
  

  // UI Constants
  final List<String> _domains = const [
    'College','Hospital','Parking','Library','Hotels','Cafés','E-commerce','Govt Services','Custom'
  ];
  final List<String> _availableTechs = const [
    'Flutter','React','Firebase','Node.js','Python','Django','Express','MongoDB','MySQL',
    'Java','Spring Boot','Angular','Vue.js','PostgreSQL','Redis','Docker'
  ];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _initializeFromProjectSpace();
  }
  
  void _initializeFromProjectSpace() {
    if (widget.yearOfStudy != null) {
      _yearController.text = widget.yearOfStudy.toString();
    }
    if (widget.targetPlatform != null) {
      // Platform is already selected during project space creation
      // We could pre-filter based on this if needed
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _customTechController.dispose();
    _customDomainController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final set = await _projectService.fetchBookmarks();
    setState(() {
      _bookmarks = set;
    });
  }

  void _addCustomTech() {
    final tech = _customTechController.text.trim();
    if (tech.isNotEmpty && !_selectedTechs.contains(tech)) {
      setState(() {
        _selectedTechs.add(tech);
        _customTechController.clear();
      });
    }
  }

  bool _isFormValid() {
    return _selectedDomain != null &&
           _yearController.text.trim().isNotEmpty &&
           _selectedTechs.isNotEmpty &&
           // If "Custom" is selected, ensure custom domain is entered
           (_selectedDomain != 'Custom' || _customDomainController.text.trim().isNotEmpty);
  }

  Future<void> _generateDetailedProblem(Problem baseProblem) async {
    setState(() {
      _isGeneratingDetails = true;
      _generatingDetailsForId = baseProblem.id;
    });

    try {
      debugPrint('🔍 Generating detailed problem for: ${baseProblem.title}');
      
      final detailedProblem = await _gemini.generateDetailedProblem(baseProblem);
      
      // Update the problem in search results
      final index = _searchResults.indexWhere((p) => p.id == baseProblem.id);
      if (index != -1) {
        setState(() {
          _searchResults[index] = detailedProblem;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Detailed problem information generated!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      debugPrint('⚠️ Error generating detailed problem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Failed to generate details: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingDetails = false;
          _generatingDetailsForId = null;
        });
      }
    }
  }
  
  Future<void> _searchTopics() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final year = int.tryParse(_yearController.text.trim()) ?? 2;
    if (year < 1 || year > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid year (1-4)')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // Use custom domain if "Custom" is selected
      final domainToSearch = _selectedDomain == 'Custom' 
          ? _customDomainController.text.trim() 
          : _selectedDomain!;
      
      debugPrint('🚀 Starting AI search for domain: $domainToSearch, year: $year, techs: ${_selectedTechs.toList()}');
      
      final problems = await _gemini.fetchProblems(
        domain: domainToSearch,
        year: year,
        platforms: ['App', 'Web'], // Default platforms
        skills: _selectedTechs.toList(),
        difficulty: 'Intermediate', // Default difficulty
        count: 8,
      );
      
      debugPrint('✅ Got ${problems.length} problems from AI');
      
      setState(() {
        _searchResults = problems;
        _hasSearched = true;
      });

      if (problems.isNotEmpty) {
        final firstProblem = problems.first;
        final isAiGenerated = firstProblem.id.startsWith('ai_');
        debugPrint('🔍 First problem ID: ${firstProblem.id} (AI-generated: $isAiGenerated)');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Found ${problems.length} AI-generated topics!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No topics generated. Try different criteria.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _searchTopics: $e');
      if (mounted) {
        String message = 'Failed to generate AI topics: ${e.toString()}';
        if (e.toString().contains('TimeoutException')) {
          message = 'AI request timed out. Check your connection and try again.';
        } else if (e.toString().contains('GEMINI_API_KEY')) {
          message = 'API key missing. Please restart with --dart-define=GEMINI_API_KEY=...';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _searchTopics,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }


  void _openProblemDetails(Problem p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProblemDetailsPage(
          problem: p,
          isBookmarked: _bookmarks.contains(p.id),
          onSelect: () async {
            Navigator.of(context).pop();
            await _selectTopic(p);
          },
          onBookmarkChanged: (val) async {
            await _projectService.setBookmark(p.id, val);
            await _loadBookmarks();
          },
        ),
      ),
    );
  }

  Future<void> _selectTopic(Problem p) async {
    if (widget.projectSpaceId != null) {
      // Update existing project space with selected problem
      try {
      // Prepare problem data with detailed information if available
      final problemData = {
        'problemId': p.id,
        'problemTitle': p.title,
        'problemDescription': p.description,
        'problemDomain': p.domain,
        'problemSkills': p.skills,
        'problemPlatform': p.platform,
        'problemDifficulty': p.difficulty,
        'problemScope': p.scope,
        'selectedProblemTitle': p.title,
        'status': 'TopicSelected',
        // Add detailed information if available
        if (p.hasDetailedInfo) ...{
          'detailedDescription': p.detailedDescription,
          'realLifeExample': p.realLifeExample,
          'detailedFeatures': p.detailedFeatures,
          'implementationSteps': p.implementationSteps,
          'challenges': p.challenges,
          'learningOutcomes': p.learningOutcomes,
          'hasDetailedInfo': true,
        },
        // Store the complete problem object for future use
        'selectedProblem': p.toMap(),
      };
      
      await _projectService.updateProjectSpaceStep(
        projectSpaceId: widget.projectSpaceId!,
        step: 2,
        additionalData: problemData,
      );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Topic selected! Proceeding to project name suggestions...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back to Project Steps page to show progress
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(); // Go back to Project Steps page
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to select topic: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Fallback: create draft project (for backward compatibility)
      final projectId = await _projectService.createDraftProject(problemId: p.id);
      if (!mounted) return;
      if (projectId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Draft created! Proceeding to project name suggestions...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to previous page
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(); // Go back to previous page
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Sign in required to create a project draft.'),
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
          'Find Project Topics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: _hasSearched ? [
          IconButton(
            onPressed: () => setState(() => _hasSearched = false),
            icon: const Icon(Icons.search),
            tooltip: 'New Search',
          )
        ] : null,
      ),
      body: _hasSearched ? _buildResultsView() : _buildSearchForm(),
    );
  }

  Widget _buildSearchForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Tell us about your project preferences',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll find the perfect project topics for you based on your inputs',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 32),

          // Domain Selection
          _buildSectionTitle('1. Select Domain *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _domains.map((domain) {
              final isSelected = _selectedDomain == domain;
              return ChoiceChip(
                label: Text(domain),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedDomain = selected ? domain : null;
                    // Clear custom domain when switching to non-custom domain
                    if (domain != 'Custom' && selected) {
                      _customDomainController.clear();
                    }
                  });
                },
                selectedColor: const Color(0xff2563eb).withValues(alpha: 0.2),
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? const Color(0xff2563eb) : const Color(0xff374151),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          
          // Custom Domain Input (shown when "Custom" is selected)
          if (_selectedDomain == 'Custom') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _customDomainController,
              decoration: InputDecoration(
                labelText: 'Enter Custom Domain *',
                hintText: 'e.g., Banking, Agriculture, Real Estate',
                prefixIcon: const Icon(Icons.domain),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xff2563eb), width: 2),
                ),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (_) => setState(() {}), // Trigger validation update
            ),
          ],
          
          const SizedBox(height: 24),

          // Year Input
          _buildSectionTitle('2. Enter Your Year of Study *'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g., 2',
              helperText: 'Enter 1, 2, 3, or 4',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 24),

          // Tech Selection
          _buildSectionTitle('3. Select Technologies *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTechs.map((tech) {
              final isSelected = _selectedTechs.contains(tech);
              return FilterChip(
                label: Text(tech),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTechs.add(tech);
                    } else {
                      _selectedTechs.remove(tech);
                    }
                  });
                },
                selectedColor: const Color(0xff059669).withValues(alpha: 0.2),
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? const Color(0xff059669) : const Color(0xff374151),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Tech Input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customTechController,
                  decoration: InputDecoration(
                    hintText: 'Add custom technology',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  onFieldSubmitted: (_) => _addCustomTech(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustomTech,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6366f1),
                ),
                child: const Text('Add'),
              ),
            ],
          ),

          if (_selectedTechs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Selected Technologies:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: const Color(0xff374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTechs.map((tech) {
                return Chip(
                  label: Text(tech),
                  onDeleted: () => setState(() => _selectedTechs.remove(tech)),
                  backgroundColor: const Color(0xff059669).withValues(alpha: 0.1),
                  labelStyle: GoogleFonts.poppins(
                    color: const Color(0xff059669),
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 40),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchTopics,
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isSearching ? 'Searching Topics...' : 'Search Topics',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid() ? const Color(0xff2563eb) : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Search Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffeef2ff),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Results for ${_selectedDomain == 'Custom' ? _customDomainController.text.trim() : (_selectedDomain ?? "")} Projects',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff2563eb),
                ),
              ),
              Text(
                'Technologies: ${_selectedTechs.join(", ")}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ),

        // Results List
        Expanded(
          child: _isSearching
              ? Column(
                  children: [
                    const Spacer(),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'AI is generating topics for you...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xff6b7280),
                      ),
                    ),
                    const Spacer(),
                  ],
                )
              : _searchResults.isEmpty
                  ? _buildEmptyResults()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final problem = _searchResults[index];
                        final isBookmarked = _bookmarks.contains(problem.id);
                        return _buildProblemCard(problem, isBookmarked);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Color(0xff6b7280)),
            const SizedBox(height: 16),
            Text(
              'No topics found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or search again',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff6b7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _hasSearched = false),
              child: const Text('New Search'),
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
        color: const Color(0xff1f2937),
      ),
    );
  }

  Widget _buildProblemCard(Problem p, bool bookmarked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0,2)),
        ],
      ),
      child: InkWell(
        onTap: () => _openProblemDetails(p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.title,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await _projectService.setBookmark(p.id, !bookmarked);
                      await _loadBookmarks();
                    },
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_outline, 
                      color: const Color(0xff2563eb),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xff6b7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(p.domain, const Color(0xff2563eb)),
                  _buildTag(p.scope, const Color(0xff059669)),
                  ...p.skills.take(3).map((skill) => _buildTag(skill, const Color(0xff7c3aed))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: p.hasDetailedInfo || (_isGeneratingDetails && _generatingDetailsForId == p.id)
                          ? null
                          : () => _generateDetailedProblem(p),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xff059669).withValues(alpha: 0.5)),
                      ),
                      child: _isGeneratingDetails && _generatingDetailsForId == p.id
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              p.hasDetailedInfo ? 'AI Enhanced ✓' : 'Enhance with AI',
                              style: TextStyle(
                                color: p.hasDetailedInfo ? const Color(0xff059669) : const Color(0xff059669),
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTopic(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563eb),
                      ),
                      child: const Text('Select Topic'),
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
