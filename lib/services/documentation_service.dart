import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:minix/config/secrets.dart';
import 'package:minix/models/problem.dart';
import 'package:minix/models/solution.dart';
import 'package:minix/models/code_generation.dart';
import 'package:minix/models/document_template.dart';
import 'package:minix/models/citation.dart';
import 'package:minix/services/template_service.dart';
import 'package:minix/services/citation_service.dart';
import 'package:minix/services/export_service.dart';

class DocumentationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _apiKey = Secrets.geminiApiKey;
  final Uuid _uuid = const Uuid();
  final TemplateService _templateService = TemplateService();
  final CitationService _citationService = CitationService();
  final ExportService _exportService = ExportService();

  /// Generate professional PDF document
  Future<String> generateProfessionalPDF({
    required String projectSpaceId,
    required String projectName,
    required String documentType,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
    required CodeGenerationProject? codeProject,
    String? templateUrl,
  }) async {
    try {
      debugPrint('📝 Starting professional PDF generation for: $documentType');
      
      // Generate document content using AI
      final content = await generateDocument(
        projectSpaceId: projectSpaceId,
        projectName: projectName,
        documentType: documentType,
        projectData: projectData,
        problem: problem,
        solution: solution,
        codeProject: codeProject,
        templateUrl: templateUrl,
      );
      
      // Create professional PDF from content
      final pdfFilePath = await _createProfessionalPDF(
        projectName: projectName,
        documentType: documentType,
        content: content,
        projectData: projectData,
        problem: problem,
        solution: solution,
      );
      
      debugPrint('✅ Professional PDF generated successfully: $pdfFilePath');
      return pdfFilePath;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating professional PDF: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      throw Exception('Failed to generate professional PDF: $e');
    }
  }

  Future<String> generateDocument({
    required String projectSpaceId,
    required String projectName,
    required String documentType,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
    required CodeGenerationProject? codeProject,
    String? templateUrl,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Please configure your API key.');
    }

    try {
      debugPrint('🚀 Starting document generation for: $documentType');
      
      // Use same model as topic selection page (proven to work)
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.6),
      );

      debugPrint('📝 Building project context...');
      final projectContext = _buildProjectContext(
        projectName: projectName,
        projectData: projectData,
        problem: problem,
        solution: solution,
        codeProject: codeProject,
      );
      debugPrint('✅ Project context built successfully');

      debugPrint('📄 Generating document prompt...');
      final prompt = _generateDocumentPrompt(
        documentType: documentType,
        projectContext: projectContext,
        templateUrl: templateUrl,
      );
      debugPrint('✅ Document prompt generated successfully');

      // Retry with exponential backoff (same as topic selection)
      const maxAttempts = 3;
      late String generatedContent;
      
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          debugPrint('🔄 Calling Gemini API - Attempt $attempt/$maxAttempts');
          final response = await model
              .generateContent([Content.text(prompt)])
              .timeout(const Duration(minutes: 3)); // Longer timeout for documents

          generatedContent = response.text ?? '';
          debugPrint('📥 Received response (${generatedContent.length} chars)');
          
          if (generatedContent.isNotEmpty) break; // Success
          
          if (attempt < maxAttempts) {
            debugPrint('⚠️ Empty response, retrying...');
            await Future<void>.delayed(Duration(seconds: attempt * 2));
          }
        } catch (e) {
          debugPrint('⚠️ Attempt $attempt failed: $e');
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }

      if (generatedContent.isEmpty) {
        throw StateError('Gemini returned empty response after $maxAttempts attempts');
      }

      debugPrint('🎉 Document generated successfully');

      // Save generated document to Firebase
      await _saveGeneratedDocument(
        projectSpaceId: projectSpaceId,
        documentType: documentType,
        content: generatedContent,
      );

      return generatedContent;

    } catch (e, stackTrace) {
      debugPrint('❌ Error in generateDocument: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      throw Exception('Failed to generate document: $e');
    }
  }

  String _buildProjectContext({
    required String projectName,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
    required CodeGenerationProject? codeProject,
  }) {
    final context = StringBuffer();
    
    context.writeln('PROJECT INFORMATION:');
    context.writeln('Project Name: $projectName');
    
    if (projectData != null) {
      context.writeln('Team Name: ${projectData['teamName'] ?? 'Unknown'}');
      context.writeln('Target Platform: ${projectData['targetPlatform'] ?? 'Unknown'}');
      context.writeln('Year of Study: ${projectData['yearOfStudy'] ?? 'Unknown'}');
      context.writeln('Difficulty Level: ${projectData['difficulty'] ?? 'Unknown'}');
      
      try {
        final teamMembers = projectData['teamMembers'] as List<dynamic>?;
        if (teamMembers != null && teamMembers.isNotEmpty) {
          final memberNames = teamMembers.map((m) {
            if (m is Map) {
              return m['name']?.toString() ?? 'Unknown Member';
            } else {
              return m.toString();
            }
          }).join(', ');
          context.writeln('Team Members: $memberNames');
        }
      } catch (e) {
        context.writeln('Team Members: Unable to retrieve team member details');
      }
      
      try {
        final skills = projectData['skills'] as List<dynamic>?;
        if (skills != null && skills.isNotEmpty) {
          context.writeln('Team Skills: ${skills.join(', ')}');
        }
      } catch (e) {
        context.writeln('Team Skills: Unable to retrieve skills');
      }
    }

    if (problem != null) {
      try {
        context.writeln('\nPROBLEM STATEMENT:');
        context.writeln('Title: ${problem.title}');
        context.writeln('Description: ${problem.description}');
        context.writeln('Domain: ${problem.domain}');
        context.writeln('Platform: ${problem.platform.join(', ')}');
        context.writeln('Difficulty: ${problem.difficulty}');
        context.writeln('Scope: ${problem.scope}');
        context.writeln('Beneficiaries: ${problem.beneficiaries.join(', ')}');
        context.writeln('Key Features: ${problem.features.join(', ')}');
        context.writeln('Data Sources: ${problem.dataSources.join(', ')}');
      } catch (e) {
        context.writeln('\nPROBLEM STATEMENT: Error retrieving problem details');
      }
    }

    if (solution != null) {
      try {
        context.writeln('\nSOLUTION APPROACH:');
        context.writeln('Solution Title: ${solution.title}');
        context.writeln('Type: ${solution.type}');
        context.writeln('Description: ${solution.description}');
        context.writeln('Key Features: ${solution.keyFeatures.join(', ')}');
        context.writeln('Technologies: ${solution.techStack.join(', ')}');
        if (solution.timeline != null) {
          context.writeln('Timeline: ${solution.timeline}');
        }
        context.writeln('Difficulty: ${solution.difficulty}');
        if (solution.implementationSteps != null && solution.implementationSteps!.isNotEmpty) {
          context.writeln('Implementation Steps: ${solution.implementationSteps!.join(', ')}');
        }
        if (solution.benefits != null && solution.benefits!.isNotEmpty) {
          context.writeln('Benefits: ${solution.benefits!.join(', ')}');
        }
      } catch (e) {
        context.writeln('\nSOLUTION APPROACH: Error retrieving solution details');
      }
    }

    if (codeProject != null) {
      try {
        context.writeln('\nDEVELOPMENT PROGRESS:');
        context.writeln('Overall Progress: ${(codeProject.overallProgress * 100).toInt()}%');
        context.writeln('Modules Completed: ${codeProject.modules.where((m) => m.steps.every((s) => s.isCompleted)).length}/${codeProject.modules.length}');
        context.writeln('Total Steps: ${codeProject.modules.fold(0, (sum, m) => sum + m.steps.length)}');
        context.writeln('Completed Steps: ${codeProject.modules.fold(0, (sum, m) => sum + m.steps.where((s) => s.isCompleted).length)}');
        
        if (codeProject.isCompleted) {
          context.writeln('Project Status: COMPLETED');
          if (codeProject.completedAt != null) {
            context.writeln('Completed On: ${codeProject.completedAt!.toLocal().toString().split(' ')[0]}');
          }
        } else {
          context.writeln('Project Status: IN PROGRESS');
        }

        // Include module details
        context.writeln('\nDEVELOPMENT MODULES:');
        for (var module in codeProject.modules) {
          final moduleProgress = module.steps.where((s) => s.isCompleted).length / module.steps.length;
          context.writeln('- ${module.title}: ${(moduleProgress * 100).toInt()}% complete');
          context.writeln('  Description: ${module.description}');
        }
      } catch (e) {
        context.writeln('\nDEVELOPMENT PROGRESS: Error retrieving development progress details');
      }
    }

    return context.toString();
  }

  String _generateDocumentPrompt({
    required String documentType,
    required String projectContext,
    String? templateUrl,
  }) {
    switch (documentType) {
      case 'project_report':
        return _generateProjectReportPrompt(projectContext, templateUrl);
      case 'presentation':
        return _generatePresentationPrompt(projectContext, templateUrl);
      case 'synopsis':
        return _generateSynopsisPrompt(projectContext, templateUrl);
      case 'user_manual':
        return _generateUserManualPrompt(projectContext, templateUrl);
      default:
        throw Exception('Unknown document type: $documentType');
    }
  }

  String _generateProjectReportPrompt(String projectContext, String? templateUrl) {
    return '''
Generate a comprehensive technical project report based on the following project information:

$projectContext

${templateUrl != null ? 'Please follow the format and structure from the uploaded template.' : 'Use standard academic project report format.'}

REPORT REQUIREMENTS:
1. **Title Page**: Project title, team members, college/university details
2. **Abstract**: Brief summary of the project (150-200 words)
3. **Table of Contents**: Organized section listing with page numbers
4. **Introduction**: 
   - Background and motivation
   - Problem statement
   - Objectives and scope
   - Project overview
5. **Literature Review**: 
   - Existing systems analysis
   - Technology research
   - Comparative study
6. **System Analysis and Design**:
   - Requirements analysis (functional and non-functional)
   - System architecture
   - Database design
   - UI/UX design
7. **Implementation**:
   - Technology stack details
   - Development methodology
   - Module-wise implementation
   - Code snippets and explanations
8. **Testing and Validation**:
   - Testing strategies
   - Test cases and results
   - Performance analysis
9. **Results and Discussion**:
   - Project deliverables
   - Screenshots and demonstrations
   - Performance metrics
   - Challenges faced and solutions
10. **Conclusion and Future Work**:
    - Summary of achievements
    - Future enhancements
    - Lessons learned
11. **References**: Academic and technical references
12. **Appendices**: Additional code, diagrams, or documentation

FORMAT REQUIREMENTS:
- Professional academic writing style
- Proper headings and subheadings
- Technical diagrams and flowcharts descriptions
- Code snippets with explanations
- Screenshots placement suggestions
- Minimum 15-20 pages content
- IEEE or standard academic format

Generate the complete report content with detailed sections. Focus on technical accuracy and professional presentation.
''';
  }

  String _generatePresentationPrompt(String projectContext, String? templateUrl) {
    return '''
Generate a professional PowerPoint presentation content for the following project:

$projectContext

${templateUrl != null ? 'Please adapt the content to match the uploaded presentation template format.' : 'Create content for a standard professional presentation template.'}

PRESENTATION STRUCTURE (15-20 slides):

**Slide 1: Title Slide**
- Project title
- Team members names
- College/University
- Date
- Course/Subject details

**Slide 2: Agenda/Outline**
- Presentation flow overview
- Key topics to be covered

**Slide 3-4: Introduction & Problem Statement**
- Background and context
- Problem identification
- Why this project matters
- Target audience/beneficiaries

**Slide 5-6: Objectives & Scope**
- Project objectives
- Scope and limitations
- Success criteria

**Slide 7-8: Literature Review**
- Existing solutions analysis
- Technology research
- Gap identification

**Slide 9-10: Proposed Solution**
- Solution overview
- Key features and benefits
- Technology stack
- System architecture

**Slide 11-12: Implementation Approach**
- Development methodology
- Project phases
- Timeline and milestones
- Team responsibilities

**Slide 13-14: System Design**
- Architecture diagram
- Database design
- User interface mockups
- System workflow

**Slide 15-16: Results & Demonstrations**
- Key achievements
- Screenshots/demo descriptions
- Performance metrics
- User feedback

**Slide 17: Challenges & Solutions**
- Major challenges faced
- How they were resolved
- Lessons learned

**Slide 18: Future Enhancements**
- Planned improvements
- Scalability considerations
- Additional features

**Slide 19: Conclusion**
- Project summary
- Key takeaways
- Impact and benefits

**Slide 20: Q&A**
- Thank you message
- Contact information
- Questions invitation

CONTENT REQUIREMENTS:
- Clear, concise bullet points
- Professional language
- Technical accuracy
- Engaging and informative
- Suitable for academic presentation
- Include slide notes for presenter guidance

Generate detailed content for each slide with speaker notes and visual element suggestions.
''';
  }

  String _generateSynopsisPrompt(String projectContext, String? templateUrl) {
    return '''
Generate a concise project synopsis based on the following project information:

$projectContext

${templateUrl != null ? 'Follow the format structure from the uploaded template.' : 'Use standard academic synopsis format.'}

SYNOPSIS REQUIREMENTS (3-4 pages):

**1. Project Title and Details**
- Complete project title
- Team information
- Academic details

**2. Abstract (200-250 words)**
- Project overview
- Key objectives
- Methodology
- Expected outcomes

**3. Introduction (300-400 words)**
- Background and motivation
- Problem statement
- Significance of the project
- Target users/beneficiaries

**4. Objectives**
- Primary objectives
- Secondary objectives
- Success criteria

**5. Methodology (400-500 words)**
- Approach and methodology
- Technology stack
- Development phases
- Testing strategy

**6. Expected Outcomes**
- Deliverables
- Benefits to stakeholders
- Performance expectations
- Impact assessment

**7. Timeline**
- Project phases
- Milestone schedule
- Resource requirements

**8. Conclusion**
- Project significance
- Expected contribution
- Future scope

FORMAT REQUIREMENTS:
- Formal academic writing
- Clear and concise language
- Proper citations if applicable
- Professional formatting
- Maximum 4 pages
- Standard margins and fonts

Generate a comprehensive yet concise synopsis that clearly communicates the project's value and technical approach.
''';
  }

  String _generateUserManualPrompt(String projectContext, String? templateUrl) {
    return '''
Generate a comprehensive user manual based on the following project information:

$projectContext

${templateUrl != null ? 'Adapt the content structure to match the uploaded template format.' : 'Create a standard user manual format.'}

USER MANUAL STRUCTURE:

**1. Introduction**
- Welcome message
- Purpose of the application
- Target audience
- What this manual covers

**2. System Requirements**
- Hardware requirements
- Software requirements
- Browser compatibility (if web-based)
- Mobile device specifications (if mobile app)

**3. Installation Guide**
- Download instructions
- Installation steps
- Initial setup
- Account creation

**4. Getting Started**
- First login process
- Interface overview
- Navigation basics
- User dashboard tour

**5. Core Features Guide**
- Feature-by-feature instructions
- Step-by-step procedures
- Screenshots descriptions
- Tips and best practices

**6. Advanced Features**
- Advanced functionality
- Customization options
- Settings and preferences
- Integration capabilities

**7. Troubleshooting**
- Common issues and solutions
- Error messages and fixes
- Performance optimization
- FAQ section

**8. Security and Privacy**
- Data protection measures
- User privacy settings
- Security best practices
- Account security

**9. Support and Contact**
- Help resources
- Contact information
- Feedback channels
- Update notifications

**10. Appendices**
- Glossary of terms
- Keyboard shortcuts
- Version history
- Additional resources

WRITING REQUIREMENTS:
- Clear, simple language
- Step-by-step instructions
- User-friendly tone
- Logical organization
- Visual element placeholders
- Comprehensive coverage
- Practical examples

Generate detailed user manual content that helps users effectively use the application from basic to advanced levels.
''';
  }

  Future<void> _saveGeneratedDocument({
    required String projectSpaceId,
    required String documentType,
    required String content,
  }) async {
    try {
      await _database
          .child('GeneratedDocuments')
          .child(projectSpaceId)
          .child(documentType)
          .set({
        'content': content,
        'generatedAt': DateTime.now().millisecondsSinceEpoch,
        'documentType': documentType,
      });
    } catch (e) {
      debugPrint('Failed to save generated document: $e');
      // Don't throw error here to avoid breaking the main flow
    }
  }

  Future<Map<String, String>?> getGeneratedDocuments(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('GeneratedDocuments')
          .child(projectSpaceId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final documents = <String, String>{};
        
        for (final entry in data.entries) {
          final docData = Map<String, dynamic>.from(entry.value as Map);
          documents[entry.key] = (docData['content'] as String?) ?? '';
        }
        
        return documents;
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get generated documents: $e');
      return null;
    }
  }

  // Enhanced document generation with template support
  Future<String> generateEnhancedDocument({
    required String projectSpaceId,
    required String projectName,
    required String documentType,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
    required CodeGenerationProject? codeProject,
    String? templateId,
    String? citationStyle,
  }) async {
    try {
      debugPrint('🚀 Starting enhanced document generation for: $documentType');
      
      // Get template
      final templates = await _templateService.getTemplatesByType(documentType == 'project_report' ? 'report' : documentType);
      DocumentTemplate? template;
      
      if (templateId != null) {
        template = templates.firstWhere((t) => t.id == templateId, orElse: () => templates.first);
      } else {
        template = templates.isNotEmpty ? templates.first : null;
      }
      
      // Get project citations
      final bibliography = await _citationService.getProjectBibliography(projectSpaceId);
      
      // Build enhanced project context
      final projectContext = _buildEnhancedProjectContext(
        projectName: projectName,
        projectData: projectData,
        problem: problem,
        solution: solution,
        codeProject: codeProject,
        template: template,
        bibliography: bibliography,
      );
      
      // Generate document with template structure
      final prompt = _generateEnhancedDocumentPrompt(
        documentType: documentType,
        projectContext: projectContext,
        template: template,
        citationStyle: citationStyle ?? bibliography?.style ?? 'APA',
      );
      
      // Use same model as before
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.6),
      );
      
      // Generate content with retry logic
      const maxAttempts = 3;
      late String generatedContent;
      
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          debugPrint('🔄 Calling Gemini API - Attempt $attempt/$maxAttempts');
          final response = await model
              .generateContent([Content.text(prompt)])
              .timeout(const Duration(minutes: 3));

          generatedContent = response.text ?? '';
          debugPrint('📥 Received response (${generatedContent.length} chars)');
          
          if (generatedContent.isNotEmpty) break;
          
          if (attempt < maxAttempts) {
            debugPrint('⚠️ Empty response, retrying...');
            await Future<void>.delayed(Duration(seconds: attempt * 2));
          }
        } catch (e) {
          debugPrint('⚠️ Attempt $attempt failed: $e');
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
      
      if (generatedContent.isEmpty) {
        throw StateError('Gemini returned empty response after $maxAttempts attempts');
      }
      
      // Post-process generated content
      final processedContent = _postProcessContent(
        content: generatedContent,
        template: template,
        bibliography: bibliography,
      );
      
      // Save generated document with version
      await _saveDocumentVersion(
        projectSpaceId: projectSpaceId,
        documentType: documentType,
        content: processedContent,
        templateId: template?.id,
      );
      
      // Save to existing format for compatibility
      await _saveGeneratedDocument(
        projectSpaceId: projectSpaceId,
        documentType: documentType,
        content: processedContent,
      );
      
      debugPrint('🎉 Enhanced document generated successfully');
      return processedContent;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error in generateEnhancedDocument: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      throw Exception('Failed to generate enhanced document: $e');
    }
  }
  
  // Export document to PDF
  Future<String> exportDocumentToPdf({
    required String projectSpaceId,
    required String documentType,
    required String fileName,
  }) async {
    try {
      final documents = await getGeneratedDocuments(projectSpaceId);
      final content = documents?[documentType];
      
      if (content == null) {
        throw Exception('Document not found. Please generate the document first.');
      }
      
      // Get template for formatting
      final templates = await _templateService.getTemplatesByType(
        documentType == 'project_report' ? 'report' : documentType,
      );
      final template = templates.isNotEmpty ? templates.first : null;
      
      // Get bibliography
      final bibliography = await _citationService.getProjectBibliography(projectSpaceId);
      
      final filePath = await _exportService.exportToPdf(
        content: content,
        fileName: fileName,
        template: template,
        bibliography: bibliography,
      );
      
      return filePath;
    } catch (e) {
      debugPrint('Failed to export to PDF: $e');
      rethrow;
    }
  }
  
  // Export document to Word
  Future<String> exportDocumentToWord({
    required String projectSpaceId,
    required String documentType,
    required String fileName,
  }) async {
    try {
      final documents = await getGeneratedDocuments(projectSpaceId);
      final content = documents?[documentType];
      
      if (content == null) {
        throw Exception('Document not found. Please generate the document first.');
      }
      
      // Get template for formatting
      final templates = await _templateService.getTemplatesByType(
        documentType == 'project_report' ? 'report' : documentType,
      );
      final template = templates.isNotEmpty ? templates.first : null;
      
      // Get bibliography
      final bibliography = await _citationService.getProjectBibliography(projectSpaceId);
      
      final filePath = await _exportService.exportToWord(
        content: content,
        fileName: fileName,
        template: template,
        bibliography: bibliography,
      );
      
      return filePath;
    } catch (e) {
      debugPrint('Failed to export to Word: $e');
      rethrow;
    }
  }
  
  // Add citations to project
  Future<void> addProjectCitations({
    required String projectSpaceId,
    required List<Citation> citations,
  }) async {
    try {
      for (final citation in citations) {
        await _citationService.addCitation(
          projectSpaceId: projectSpaceId,
          citation: citation,
        );
      }
      
      // Generate updated bibliography
      await _citationService.generateBibliography(
        projectSpaceId: projectSpaceId,
      );
    } catch (e) {
      debugPrint('Failed to add project citations: $e');
      rethrow;
    }
  }
  
  // Get document versions
  Future<List<DocumentVersion>> getDocumentVersions({
    required String projectSpaceId,
    required String documentType,
  }) async {
    try {
      final snapshot = await _database
          .child('DocumentVersions')
          .child(projectSpaceId)
          .child(documentType)
          .orderByChild('version')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries
            .map((entry) => DocumentVersion.fromMap(Map<String, dynamic>.from(entry.value as Map)))
            .toList()
          ..sort((a, b) => b.version.compareTo(a.version)); // Latest first
      }
      
      return [];
    } catch (e) {
      debugPrint('Failed to get document versions: $e');
      return [];
    }
  }
  
  // Build enhanced project context with template structure
  String _buildEnhancedProjectContext({
    required String projectName,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
    required CodeGenerationProject? codeProject,
    DocumentTemplate? template,
    Bibliography? bibliography,
  }) {
    final context = StringBuffer();
    
    // Add basic project context from existing method
    context.writeln(_buildProjectContext(
      projectName: projectName,
      projectData: projectData,
      problem: problem,
      solution: solution,
      codeProject: codeProject,
    ));
    
    // Add template structure information
    if (template != null) {
      context.writeln('\nTEMPLATE STRUCTURE:');
      context.writeln('Template: ${template.name}');
      context.writeln('Type: ${template.type}');
      context.writeln('College: ${template.college}');
      
      context.writeln('\nREQUIRED SECTIONS:');
      for (final section in template.sections.where((s) => s.isRequired)) {
        context.writeln('- ${section.title}: ${section.placeholder ?? "No placeholder"}');
        if (section.subsections.isNotEmpty) {
          for (final subsection in section.subsections) {
            context.writeln('  - ${subsection.title}: ${subsection.placeholder ?? "No placeholder"}');
          }
        }
      }
      
      context.writeln('\nFORMATTING REQUIREMENTS:');
      context.writeln('Font: ${template.formatting.fontFamily}');
      context.writeln('Font Size: ${template.formatting.fontSize}pt');
      context.writeln('Line Height: ${template.formatting.lineHeight}');
      context.writeln('Page Size: ${template.formatting.pageSize}');
      context.writeln('Citation Style: ${template.formatting.citationStyle}');
    }
    
    // Add bibliography information
    if (bibliography != null && bibliography.citations.isNotEmpty) {
      context.writeln('\nAVAILABLE CITATIONS:');
      context.writeln('Total Citations: ${bibliography.citations.length}');
      context.writeln('Citation Style: ${bibliography.style}');
      
      context.writeln('\nCITATIONS LIST:');
      for (final citation in bibliography.citations.take(5)) { // Show first 5
        context.writeln('- ${citation.title} by ${citation.authors.join(", ")} (${citation.year ?? "n.d."})');
      }
      if (bibliography.citations.length > 5) {
        context.writeln('... and ${bibliography.citations.length - 5} more citations');
      }
    }
    
    return context.toString();
  }
  
  // Generate enhanced document prompt with template support
  String _generateEnhancedDocumentPrompt({
    required String documentType,
    required String projectContext,
    DocumentTemplate? template,
    String citationStyle = 'APA',
  }) {
    final basePrompt = _generateDocumentPrompt(
      documentType: documentType,
      projectContext: projectContext,
    );
    
    if (template == null) {
      return '$basePrompt\n\nCitation Style: Use $citationStyle format for all references.';
    }
    
    return '''
$basePrompt

ENHANCED REQUIREMENTS:

**Template Compliance:**
You MUST follow the exact structure and formatting specified in the template information above.

**Required Sections (in order):**
${template.sections.map((s) => '${s.order}. ${s.title}${s.isRequired ? " (Required)" : " (Optional)"}').join('\n')}

**Section Guidelines:**
${template.sections.map((s) => '- **${s.title}**: ${s.placeholder ?? "Standard content for this section"}').join('\n')}

**Formatting Requirements:**
- Use ${template.formatting.fontFamily} font equivalent
- Base font size: ${template.formatting.fontSize}pt
- Line spacing: ${template.formatting.lineHeight}
- Page size: ${template.formatting.pageSize}
- Citation style: ${template.formatting.citationStyle}

**Content Structure:**
- Include proper headings hierarchy (H1, H2, H3)
- Add table of contents markers where appropriate
- Include placeholder text for diagrams and images
- Format code snippets with proper syntax highlighting indicators
- Use bullet points and numbered lists as specified in template

**Citations and References:**
- Use $citationStyle citation style throughout
- Include in-text citations where appropriate
- Add a complete bibliography/references section
- Reference the provided citations when relevant

**Professional Standards:**
- Academic writing tone and style
- Clear section transitions
- Comprehensive yet concise content
- Proper technical terminology
- Consistent formatting throughout

Generate the complete document following ALL template requirements and formatting guidelines.
''';
  }
  
  
  
  // Add bibliography to content
  String _addBibliographyToContent(String content, Bibliography bibliography) {
    final bibContent = bibliography.generateBibliography();
    return '$content\n\n$bibContent';
  }
  
  // Add page numbering markers
  String _addPageNumberingMarkers(String content) {
    // Add markers for page breaks and numbering
    return content.replaceAllMapped(
    RegExp(r'^#{1}\s+(.+)$', multiLine: true),
      (match) => '\n<!-- PAGE_BREAK -->\n${match.group(0)}',
    );
  }
  

  /// Post-process content to ensure quality and compliance
  String _postProcessContent({
    required String content,
    DocumentTemplate? template,
    Bibliography? bibliography,
  }) {
    // Add table of contents if template requires it
    if (template?.structure['tableOfContents'] == true) {
      content = _addTableOfContents(content);
    }
    
    // Ensure proper section formatting
    content = _formatSections(content);
    
    // Add page breaks where needed
    if (template != null) {
      content = _addPageBreaks(content, template);
    }
    
    // Add bibliography if available and template requires it
    if (bibliography != null && 
        bibliography.citations.isNotEmpty && 
        template?.structure['bibliography'] == true) {
      content = _addBibliographyToContent(content, bibliography);
    }
    
    // Add page numbering markers if required
    if (template?.structure['pageNumbering'] == true) {
      content = _addPageNumberingMarkers(content);
    }
    
    return content;
  }

  String _addTableOfContents(String content) {
    final lines = content.split('\n');
    final tocLines = <String>['## Table of Contents\n'];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('# ') && !line.contains('Table of Contents')) {
        final title = line.substring(2).trim();
        tocLines.add('- $title');
      } else if (line.startsWith('## ')) {
        final title = line.substring(3).trim();
        tocLines.add('  - $title');
      }
    }
    
    tocLines.add('');
    
    // Insert TOC after first heading
    final firstHeadingIndex = lines.indexWhere((line) => line.startsWith('# '));
    if (firstHeadingIndex != -1) {
      lines.insertAll(firstHeadingIndex + 1, tocLines);
    }
    
    return lines.join('\n');
  }

  String _formatSections(String content) {
    // Ensure proper spacing between sections
    content = content.replaceAll(RegExp(r'\n#{1,6}\s'), '\n\n# ');
    content = content.replaceAll(RegExp(r'\n\n\n+'), '\n\n');
    return content;
  }

  String _addPageBreaks(String content, DocumentTemplate template) {
    // Add page breaks before major sections if template specifies
    final sections = template.sections.where((s) => s.properties['pageBreakBefore'] == true).toList();
    for (final section in sections) {
      content = content.replaceAll(
        '# ${section.title}',
        '\n---\nNEW PAGE\n---\n\n# ${section.title}'
      );
    }
    return content;
  }

  /// Save document version for history tracking
  Future<void> _saveDocumentVersion({
    required String projectSpaceId,
    required String documentType,
    required String content,
    String? templateId,
  }) async {
    try {
      // Get current version number
      final versions = await getDocumentVersions(
        projectSpaceId: projectSpaceId,
        documentType: documentType,
      );
      final nextVersion = versions.isNotEmpty ? versions.first.version + 1 : 1;
      
      final version = DocumentVersion(
        id: _uuid.v4(),
        projectSpaceId: projectSpaceId,
        documentType: documentType,
        content: content,
        version: nextVersion,
        changes: templateId != null ? 'Generated with template: $templateId' : 'Generated document',
        createdAt: DateTime.now(),
        createdBy: 'system',
      );
      
      await _database
          .child('DocumentVersions')
          .child(projectSpaceId)
          .child(documentType)
          .child(version.id)
          .set(version.toMap());
    } catch (e) {
      debugPrint('Failed to save document version: $e');
      // Don't throw error to avoid breaking main flow
    }
  }
  
  /// Create professional PDF from generated content
  Future<String> _createProfessionalPDF({
    required String projectName,
    required String documentType,
    required String content,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
  }) async {
    try {
      debugPrint('🎨 Creating professional PDF layout...');
      
      final pdf = pw.Document();
      
      // Load custom fonts for professional appearance
      final regularFont = await PdfGoogleFonts.openSansRegular();
      final boldFont = await PdfGoogleFonts.openSansBold();
      final titleFont = await PdfGoogleFonts.playfairDisplayBold();
      
      
      // Parse content into sections
      final sections = _parseContentSections(content);
      
      // Create cover page
      pdf.addPage(_createCoverPage(
        projectName: projectName,
        documentType: documentType,
        projectData: projectData,
        problem: problem,
        solution: solution,
        titleFont: titleFont,
        regularFont: regularFont,
      ));
      
      // Add table of contents
      pdf.addPage(_createTableOfContents(
        sections: sections,
        titleFont: titleFont,
        regularFont: regularFont,
      ));
      
      // Add content pages
      for (int i = 0; i < sections.length; i++) {
        final section = sections[i];
        pdf.addPage(_createContentPage(
          section: section,
          pageNumber: i + 3, // After cover and TOC
          totalSections: sections.length,
          titleFont: titleFont,
          regularFont: regularFont,
          boldFont: boldFont,
        ));
      }
      
      // Save PDF to device
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${projectName.replaceAll(' ', '_')}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('✅ Professional PDF saved: ${file.path}');
      return file.path;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating professional PDF: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Parse content into structured sections
  List<DocumentSection> _parseContentSections(String content) {
    final sections = <DocumentSection>[];
    final lines = content.split('\n');
    
    String currentTitle = '';
    List<String> currentContent = [];
    
    for (final line in lines) {
      if (line.startsWith('# ')) {
        // Save previous section
        if (currentTitle.isNotEmpty) {
          sections.add(DocumentSection(
            title: currentTitle,
            content: currentContent.join('\n').trim(),
          ));
        }
        
        // Start new section
        currentTitle = line.substring(2).trim();
        currentContent = [];
      } else {
        currentContent.add(line);
      }
    }
    
    // Add final section
    if (currentTitle.isNotEmpty) {
      sections.add(DocumentSection(
        title: currentTitle,
        content: currentContent.join('\n').trim(),
      ));
    }
    
    return sections;
  }
  
  /// Create professional cover page
  pw.Page _createCoverPage({
    required String projectName,
    required String documentType,
    required Map<String, dynamic>? projectData,
    required Problem? problem,
    required ProjectSolution? solution,
    required pw.Font titleFont,
    required pw.Font regularFont,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Spacer(flex: 2),
              
              // Title
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  projectName,
                  style: pw.TextStyle(
                    font: titleFont,
                    fontSize: 32,
                    color: PdfColors.blue800,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Document type
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  _getDocumentTypeTitle(documentType),
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 18,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              
              pw.Spacer(flex: 1),
              
              // Project details box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(30),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue300, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  color: PdfColors.blue50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (projectData != null) ..._buildProjectDetails(projectData, regularFont),
                    if (problem != null) ..._buildProblemSummary(problem, regularFont),
                    if (solution != null) ..._buildSolutionSummary(solution, regularFont),
                  ],
                ),
              ),
              
              pw.Spacer(flex: 2),
              
              // Footer
              pw.Container(
                width: double.infinity,
                child: pw.Text(
                  'Generated on ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Create table of contents
  pw.Page _createTableOfContents({
    required List<DocumentSection> sections,
    required pw.Font titleFont,
    required pw.Font regularFont,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Table of Contents',
                style: pw.TextStyle(
                  font: titleFont,
                  fontSize: 24,
                  color: PdfColors.blue800,
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              ...sections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        '${index + 1}. ${section.title}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 14,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                          child: pw.Divider(
                            color: PdfColors.grey400,
                            thickness: 1,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${index + 3}', // Page number (after cover and TOC)
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
  
  /// Create content page
  pw.Page _createContentPage({
    required DocumentSection section,
    required int pageNumber,
    required int totalSections,
    required pw.Font titleFont,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue300, width: 2),
                  ),
                ),
                child: pw.Text(
                  section.title,
                  style: pw.TextStyle(
                    font: titleFont,
                    fontSize: 20,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Content
              pw.Expanded(
                child: pw.Text(
                  section.content,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 12,
                    lineSpacing: 1.5,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
              
              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(top: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by Minix',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Page $pageNumber',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Helper methods for cover page content
  List<pw.Widget> _buildProjectDetails(Map<String, dynamic> projectData, pw.Font font) {
    return [
      pw.Text('Project Details', style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Text('Team: ${projectData['teamName'] ?? 'Unknown'}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.Text('Platform: ${projectData['targetPlatform'] ?? 'Unknown'}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.Text('Year of Study: ${projectData['yearOfStudy'] ?? 'Unknown'}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.SizedBox(height: 15),
    ];
  }
  
  List<pw.Widget> _buildProblemSummary(Problem problem, pw.Font font) {
    return [
      pw.Text('Problem Statement', style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Text('Domain: ${problem.domain}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.Text('Difficulty: ${problem.difficulty}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.Text('Scope: ${problem.scope}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.SizedBox(height: 15),
    ];
  }
  
  List<pw.Widget> _buildSolutionSummary(ProjectSolution solution, pw.Font font) {
    return [
      pw.Text('Solution Approach', style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Text('Type: ${solution.type}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.Text('Technologies: ${solution.techStack.take(3).join(', ')}', style: pw.TextStyle(font: font, fontSize: 12)),
      pw.Text('Difficulty: ${solution.difficulty}', style: pw.TextStyle(font: font, fontSize: 12)),
    ];
  }
  
  String _getDocumentTypeTitle(String documentType) {
    switch (documentType) {
      case 'project_report':
        return 'Technical Project Report';
      case 'presentation':
        return 'Project Presentation';
      case 'synopsis':
        return 'Project Synopsis';
      case 'user_manual':
        return 'User Manual';
      default:
        return 'Project Document';
    }
  }
}

/// Helper class for document sections
class DocumentSection {
  final String title;
  final String content;
  
  DocumentSection({
    required this.title,
    required this.content,
  });
}
