import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:minix/models/ppt_generation.dart';

// Helper class for achievement tracking
class AchievementItem {
  final String title;
  final bool isCompleted;
  
  AchievementItem(this.title, this.isCompleted);
}

// Helper class for roadmap items
class RoadmapItem {
  final String title;
  final String description;
  
  RoadmapItem(this.title, this.description);
}

class PPTGenerationServiceSimple {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  PPTGenerationServiceSimple({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Helper method to safely parse string lists from dynamic values
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  // Template Management
  Future<List<PPTTemplate>> getDefaultTemplates() async {
    try {
      final snapshot = await _db.ref('PPTTemplates/default').get();
      final List<PPTTemplate> templates = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          templates.add(PPTTemplate.fromMap(Map<String, dynamic>.from(value as Map)));
        });
      }

      // If no default templates exist, create them
      if (templates.isEmpty) {
        await _initializeDefaultTemplates();
        return await getDefaultTemplates();
      }

      return templates..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('Error loading default templates: $e');
      return _createBuiltInTemplates();
    }
  }

  Future<List<PPTTemplate>> getUserTemplates() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await _db.ref('PPTTemplates/users/$uid').get();
      final List<PPTTemplate> templates = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          templates.add(PPTTemplate.fromMap(Map<String, dynamic>.from(value as Map)));
        });
      }

      return templates..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('Error loading user templates: $e');
      return [];
    }
  }

  Future<PPTTemplate?> getTemplate(String templateId) async {
    try {
      // Try default templates first
      final defaultSnapshot = await _db.ref('PPTTemplates/default/$templateId').get();
      if (defaultSnapshot.exists) {
        return PPTTemplate.fromMap(Map<String, dynamic>.from(defaultSnapshot.value as Map));
      }

      // Try user templates
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final userSnapshot = await _db.ref('PPTTemplates/users/$uid/$templateId').get();
        if (userSnapshot.exists) {
          return PPTTemplate.fromMap(Map<String, dynamic>.from(userSnapshot.value as Map));
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting template: $e');
      return null;
    }
  }

  Future<String?> saveCustomTemplate(PPTTemplate template) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final ref = _db.ref('PPTTemplates/users/$uid').push();
      final templateWithId = template.copyWith(
        id: ref.key!,
        type: 'custom',
        createdAt: DateTime.now(),
      );

      await ref.set(templateWithId.toMap());
      return ref.key;
    } catch (e) {
      debugPrint('Error saving custom template: $e');
      return null;
    }
  }

  // PPT Generation
  Future<GeneratedPPT> generatePPT({
    required String projectSpaceId,
    required String templateId,
    required Map<String, dynamic> projectData,
    Map<String, String> customizations = const {},
    List<String> includeSlides = const [],
    List<String> excludeSlides = const [],
  }) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found');
      }

      // Prepare project data for slides
      final enrichedData = await _prepareProjectData(projectSpaceId, projectData);
      
      // Generate PDF
      final pdfBytes = await _generatePDF(
        template: template,
        projectData: enrichedData,
        customizations: customizations,
        includeSlides: includeSlides,
        excludeSlides: excludeSlides,
      );

      // Save to device
      final fileName = '${enrichedData['projectName'] ?? 'presentation'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await _savePDFToDevice(pdfBytes, fileName);

      // Create generated PPT record
      final generatedPPT = GeneratedPPT(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectSpaceId: projectSpaceId,
        templateId: templateId,
        filePath: filePath,
        fileName: fileName,
        fileSize: pdfBytes.length,
        slideCount: template.slides.length,
        format: 'pdf',
        generatedAt: DateTime.now(),
      );

      // Save record to Firebase
      await _saveGeneratedPPTRecord(generatedPPT);

      return generatedPPT;
    } catch (e) {
      debugPrint('Error generating PPT: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _prepareProjectData(String projectSpaceId, Map<String, dynamic> baseData) async {
    try {
      // Get additional project data from Firebase
      final projectSnapshot = await _db.ref('ProjectSpaces/$projectSpaceId').get();
      final solutionSnapshot = await _db.ref('Solutions').orderByChild('projectSpaceId').equalTo(projectSpaceId).get();

      final enrichedData = Map<String, dynamic>.from(baseData);

      // Add project space data
      if (projectSnapshot.exists) {
        final projectData = projectSnapshot.value as Map<dynamic, dynamic>;
        enrichedData.addAll({
          'teamName': projectData['teamName'] ?? 'Team',
          'teamMembers': _parseStringList(projectData['teamMembers']),
          'yearOfStudy': projectData['yearOfStudy'] ?? 2,
          'targetPlatform': projectData['targetPlatform'] ?? 'App',
          'difficulty': projectData['difficulty'] ?? 'Intermediate',
        });
      }

      // Add solution data
      if (solutionSnapshot.exists) {
        final solutions = solutionSnapshot.value as Map<dynamic, dynamic>;
        final firstSolution = solutions.values.first as Map<dynamic, dynamic>;
        enrichedData.addAll({
          'solutionTitle': firstSolution['title'] ?? '',
          'solutionDescription': firstSolution['description'] ?? '',
          'keyFeatures': _parseStringList(firstSolution['keyFeatures']),
          'techStack': _parseStringList(firstSolution['techStack']),
          'architecture': Map<String, dynamic>.from(firstSolution['architecture'] as Map? ?? {}),
        });
      }

      return enrichedData;
    } catch (e) {
      debugPrint('Error preparing project data: $e');
      return baseData;
    }
  }

  Future<Uint8List> _generatePDF({
    required PPTTemplate template,
    required Map<String, dynamic> projectData,
    Map<String, String> customizations = const {},
    List<String> includeSlides = const [],
    List<String> excludeSlides = const [],
  }) async {
    final pdf = pw.Document();

    for (final slideTemplate in template.slides) {
      // Skip excluded slides
      if (excludeSlides.contains(slideTemplate.id)) continue;
      
      // Include only specified slides if list is provided
      if (includeSlides.isNotEmpty && !includeSlides.contains(slideTemplate.id)) continue;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.standard,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return _buildSlideContent(slideTemplate, projectData, customizations);
          },
        ),
      );
    }

    return await pdf.save();
  }

  pw.Widget _buildSlideContent(SlideTemplate slideTemplate, Map<String, dynamic> data, Map<String, String> customizations) {
    switch (slideTemplate.type) {
      case SlideType.titleSlide:
        return _buildTitleSlide(data, customizations);
      case SlideType.introduction:
        return _buildIntroductionSlide(data, customizations);
      case SlideType.problemStatement:
        return _buildProblemStatementSlide(data, customizations);
      case SlideType.objectives:
        return _buildObjectivesSlide(data, customizations);
      case SlideType.methodology:
        return _buildMethodologySlide(data, customizations);
      case SlideType.architecture:
        return _buildArchitectureSlide(data, customizations);
      case SlideType.implementation:
        return _buildImplementationSlide(data, customizations);
      case SlideType.results:
        return _buildResultsSlide(data, customizations);
      case SlideType.conclusion:
        return _buildConclusionSlide(data, customizations);
      case SlideType.references:
        return _buildReferencesSlide(data, customizations);
      case SlideType.thankyou:
        return _buildThankYouSlide(data, customizations);
      default:
        return _buildGenericSlide(slideTemplate, data, customizations);
    }
  }

  // Modern Title Slide
  pw.Widget _buildTitleSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColors.blue800,
            PdfColors.indigo800,
            PdfColors.purple800,
          ],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Stack(
        children: [
          // Decorative circles
          pw.Positioned(
            top: -50,
            right: -50,
            child: pw.Container(
              width: 200,
              height: 200,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Positioned(
            bottom: -30,
            left: -30,
            child: pw.Container(
              width: 120,
              height: 120,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue600,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          
          // Main content
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(40),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.black,
                    blurRadius: 20,
                    offset: const PdfPoint(0, 10),
                  ),
                ],
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    (data['projectName'] as String?) ?? 'Project Title',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    width: 100,
                    height: 4,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [PdfColors.blue600, PdfColors.purple600],
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    (data['solutionTitle'] as String?) ?? 'Innovative Technology Solution',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 30),
                  
                  // Project info cards
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimpleInfoCard('Platform', (data['targetPlatform'] as String?) ?? 'App'),
                      _buildSimpleInfoCard('Team', (data['teamName'] as String?) ?? 'Development Team'),
                      _buildSimpleInfoCard('Year', data['yearOfStudy']?.toString() ?? '2024'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSimpleInfoCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  // Standard slide implementations
  pw.Widget _buildIntroductionSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Introduction'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Project Overview',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          customizations['introduction'] ?? 
          (data['solutionDescription'] as String?) ?? 
          'This project represents an innovative approach to solving real-world challenges through modern technology solutions.',
          style: pw.TextStyle(fontSize: 14, height: 1.4),
        ),
        pw.SizedBox(height: 25),
        pw.Text(
          'Key Highlights',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ..._buildBulletPoints([
          'Modern ${data['targetPlatform'] ?? 'technology'} implementation',
          'User-centered design approach',
          'Scalable and maintainable architecture',
          'Industry best practices integration',
        ]),
      ],
    );
  }

  pw.Widget _buildProblemStatementSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Problem Statement'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Challenge Identification',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          customizations['problem'] ?? 
          'The current system faces significant challenges in meeting user requirements and delivering optimal performance.',
          style: pw.TextStyle(fontSize: 14, height: 1.4),
        ),
        pw.SizedBox(height: 25),
        pw.Text(
          'Key Issues',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ..._buildBulletPoints([
          'Inefficient user experience design',
          'Limited scalability and performance',
          'Integration challenges with existing systems',
          'Lack of modern technology implementation',
        ]),
      ],
    );
  }

  pw.Widget _buildObjectivesSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Project Objectives'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Primary Goals',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        ..._buildBulletPoints([
          'Develop a comprehensive ${data['targetPlatform'] ?? 'application'} solution',
          'Implement modern user interface and experience design',
          'Ensure scalable and maintainable architecture',
          'Integrate advanced features and functionalities',
          'Optimize performance and reliability',
        ]),
        pw.SizedBox(height: 25),
        pw.Text(
          'Success Metrics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ..._buildBulletPoints([
          'User satisfaction and engagement improvement',
          'Performance benchmarks achievement',
          'Code quality and maintainability standards',
          'Successful deployment and adoption',
        ]),
      ],
    );
  }

  pw.Widget _buildMethodologySlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Development Methodology'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Approach',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Our development follows industry-standard practices with an iterative approach to ensure quality and efficiency.',
          style: pw.TextStyle(fontSize: 14, height: 1.4),
        ),
        pw.SizedBox(height: 25),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Planning Phase', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Requirement analysis',
                    'Technology selection',
                    'Architecture design',
                  ]),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Implementation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Iterative development',
                    'Continuous testing',
                    'Quality assurance',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildArchitectureSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('System Architecture'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Architecture Overview',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Our system follows a ${data['targetPlatform'] == 'Web' ? 'web-based' : 'mobile-first'} architecture with modern design patterns.',
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 25),
        if (data['techStack'] != null) ...{
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Frontend Technologies:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    ..._getArchitectureItems(data['techStack'] as List, ['Flutter', 'React', 'Angular', 'Vue', 'HTML', 'CSS', 'JavaScript']),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Backend Technologies:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    ..._getArchitectureItems(data['techStack'] as List, ['Firebase', 'Node.js', 'Express', 'MongoDB', 'API', 'Server']),
                  ],
                ),
              ),
            ],
          ),
        } else ...{
          ..._buildBulletPoints([
            'Modern frontend framework implementation',
            'Scalable backend architecture',
            'Efficient data management system',
            'Security and authentication layers',
          ]),
        }
      ],
    );
  }

  pw.Widget _buildImplementationSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Implementation'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Key Features Implemented',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        if (data['keyFeatures'] != null && (data['keyFeatures'] as List).isNotEmpty)
          ..._buildBulletPoints((data['keyFeatures'] as List<String>).take(6).toList())
        else
          ..._buildBulletPoints([
            'User Authentication and Authorization',
            'Data Management and Storage',
            'Real-time Updates and Notifications',
            'Responsive User Interface',
            'Security and Privacy Features',
            'Performance Optimization',
          ]),
        pw.SizedBox(height: 20),
        pw.Text(
          'Development Progress: 85% Complete',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
        ),
      ],
    );
  }

  pw.Widget _buildResultsSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Results & Outcomes'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Project Achievements',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        ..._buildBulletPoints([
          'Successfully developed ${data['targetPlatform'] ?? 'application'} solution',
          'Implemented all planned features and functionalities',
          'Achieved performance and scalability targets',
          'Created comprehensive documentation',
          'Completed testing and quality assurance',
        ]),
        pw.SizedBox(height: 25),
        pw.Text(
          'Success Metrics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _buildMetricCard('95%', 'Features Complete'),
            pw.SizedBox(width: 20),
            _buildMetricCard('100%', 'Test Coverage'),
            pw.SizedBox(width: 20),
            _buildMetricCard('0', 'Critical Bugs'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            'The project successfully addresses the identified problem using ${data['difficulty'] ?? 'intermediate'} level implementation techniques.',
            style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMetricCard(String value, String label) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          border: pw.Border.all(color: PdfColors.green200),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildConclusionSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Conclusion'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Project Impact',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          customizations['conclusion'] ?? 
          'Our project successfully demonstrates the application of modern technology to solve real-world problems.',
          style: pw.TextStyle(fontSize: 14, height: 1.4),
        ),
        pw.SizedBox(height: 25),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Key Learnings:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Practical application of academic knowledge',
                    'Experience with modern technologies',
                    'Problem-solving and critical thinking',
                    'Team collaboration and project management',
                  ]),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Future Enhancements:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Version 2.0 feature planning',
                    'Performance optimizations',
                    'Platform expansion opportunities',
                    'Advanced functionality integration',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReferencesSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('References'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Knowledge Sources',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Technical Resources:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Official ${_getPrimaryTech(data)} Documentation',
                    'API Reference Guides',
                    'Framework Best Practices',
                    'Technical Architecture Patterns',
                  ]),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Academic Sources:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Software Engineering Principles',
                    'Design Pattern Literature',
                    'Computer Science Journals',
                    'Research Papers & Studies',
                  ]),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Community Resources:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Stack Overflow Discussions',
                    'GitHub Open Source Projects',
                    'Developer Community Forums',
                    'Online Learning Platforms',
                  ]),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Methodology:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ..._buildBulletPoints([
                    'Agile Development Practices',
                    'Project Management Frameworks',
                    'Software Testing Methodologies',
                    'DevOps Best Practices',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildThankYouSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColors.indigo600,
            PdfColors.purple600,
            PdfColors.pink600,
          ],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(40),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.black,
                    blurRadius: 20,
                    offset: const PdfPoint(0, 10),
                  ),
                ],
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank You!',
                    style: pw.TextStyle(
                      fontSize: 48,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Questions & Discussion',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildSimpleInfoCard('Project', (data['projectName'] as String?) ?? 'Engineering Project'),
                pw.SizedBox(width: 20),
                _buildSimpleInfoCard('Team', (data['teamName'] as String?) ?? 'Development Team'),
              ],
            ),
            if (data['userEmail'] != null) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'Contact: ${data['userEmail']}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildGenericSlide(SlideTemplate slideTemplate, Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader(slideTemplate.title),
        pw.SizedBox(height: 30),
        pw.Text(
          customizations[slideTemplate.id] ?? 'Content for ${slideTemplate.title}',
          style: pw.TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  pw.Widget _buildSlideHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue700, PdfColors.indigo800],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  List<pw.Widget> _buildBulletPoints(List<String> points) {
    return points.map((point) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(point, style: pw.TextStyle(fontSize: 14)),
          ),
        ],
      ),
    )).toList();
  }

  List<pw.Widget> _getArchitectureItems(List<dynamic> techStack, List<String> filter) {
    final items = techStack.where((tech) => filter.any((f) => tech.toString().contains(f))).toList();
    if (items.isEmpty) return [pw.Text('To be determined', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey500))];
    
    return items.map((item) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text('• $item', style: pw.TextStyle(fontSize: 12)),
    )).toList();
  }

  String _getPrimaryTech(Map<String, dynamic> data) {
    final techStack = data['techStack'] as List<String>?;
    if (techStack == null || techStack.isEmpty) {
      return 'Technology';
    }
    return techStack.first;
  }

  Future<String> _savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF to device: $e');
      rethrow;
    }
  }

  Future<void> _saveGeneratedPPTRecord(GeneratedPPT generatedPPT) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.ref('GeneratedPPTs/$uid/${generatedPPT.id}').set(generatedPPT.toMap());
    } catch (e) {
      debugPrint('Error saving generated PPT record: $e');
    }
  }

  Future<List<GeneratedPPT>> getUserGeneratedPPTs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await _db.ref('GeneratedPPTs/$uid').get();
      final List<GeneratedPPT> presentations = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          presentations.add(GeneratedPPT.fromMap(Map<String, dynamic>.from(value as Map)));
        });
      }

      return presentations..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    } catch (e) {
      debugPrint('Error loading generated PPTs: $e');
      return [];
    }
  }

  Future<void> sharePPT(GeneratedPPT ppt) async {
    try {
      final file = File(ppt.filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(ppt.filePath)], text: 'Project Presentation: ${ppt.fileName}');
      } else {
        throw Exception('File not found');
      }
    } catch (e) {
      debugPrint('Error sharing PPT: $e');
      rethrow;
    }
  }

  // Initialize default templates
  Future<void> _initializeDefaultTemplates() async {
    final defaultTemplates = _createBuiltInTemplates();
    
    try {
      final updates = <String, dynamic>{};
      for (final template in defaultTemplates) {
        updates['PPTTemplates/default/${template.id}'] = template.toMap();
      }
      await _db.ref().update(updates);
    } catch (e) {
      debugPrint('Error initializing default templates: $e');
    }
  }

  List<PPTTemplate> _createBuiltInTemplates() {
    return [
      _createAcademicTemplate(),
      _createProfessionalTemplate(),
      _createTechnicalTemplate(),
      _createMinimalTemplate(),
    ];
  }

  PPTTemplate _createAcademicTemplate() {
    return PPTTemplate(
      id: 'academic_standard',
      name: 'Academic Standard',
      description: 'Standard academic presentation format for college projects',
      type: 'default',
      category: 'academic',
      slides: [
        _createSlideTemplate('title', SlideType.titleSlide, 0),
        _createSlideTemplate('introduction', SlideType.introduction, 1),
        _createSlideTemplate('problem', SlideType.problemStatement, 2),
        _createSlideTemplate('objectives', SlideType.objectives, 3),
        _createSlideTemplate('methodology', SlideType.methodology, 4),
        _createSlideTemplate('architecture', SlideType.architecture, 5),
        _createSlideTemplate('implementation', SlideType.implementation, 6),
        _createSlideTemplate('results', SlideType.results, 7),
        _createSlideTemplate('conclusion', SlideType.conclusion, 8),
        _createSlideTemplate('references', SlideType.references, 9),
        _createSlideTemplate('thankyou', SlideType.thankyou, 10),
      ],
      theme: PPTTheme(name: 'Academic Blue'),
      createdAt: DateTime.now(),
    );
  }

  PPTTemplate _createProfessionalTemplate() {
    return PPTTemplate(
      id: 'professional_clean',
      name: 'Professional Clean',
      description: 'Clean professional template for business presentations',
      type: 'default',
      category: 'professional',
      slides: [
        _createSlideTemplate('title', SlideType.titleSlide, 0),
        _createSlideTemplate('introduction', SlideType.introduction, 1),
        _createSlideTemplate('problem', SlideType.problemStatement, 2),
        _createSlideTemplate('objectives', SlideType.objectives, 3),
        _createSlideTemplate('methodology', SlideType.methodology, 4),
        _createSlideTemplate('architecture', SlideType.architecture, 5),
        _createSlideTemplate('implementation', SlideType.implementation, 6),
        _createSlideTemplate('results', SlideType.results, 7),
        _createSlideTemplate('conclusion', SlideType.conclusion, 8),
        _createSlideTemplate('references', SlideType.references, 9),
        _createSlideTemplate('thankyou', SlideType.thankyou, 10),
      ],
      theme: PPTTheme(name: 'Professional Grey'),
      createdAt: DateTime.now(),
    );
  }

  PPTTemplate _createTechnicalTemplate() {
    return PPTTemplate(
      id: 'technical_detailed',
      name: 'Technical Detailed',
      description: 'Detailed technical template for engineering presentations',
      type: 'default',
      category: 'technical',
      slides: [
        _createSlideTemplate('title', SlideType.titleSlide, 0),
        _createSlideTemplate('introduction', SlideType.introduction, 1),
        _createSlideTemplate('problem', SlideType.problemStatement, 2),
        _createSlideTemplate('objectives', SlideType.objectives, 3),
        _createSlideTemplate('methodology', SlideType.methodology, 4),
        _createSlideTemplate('architecture', SlideType.architecture, 5),
        _createSlideTemplate('implementation', SlideType.implementation, 6),
        _createSlideTemplate('results', SlideType.results, 7),
        _createSlideTemplate('conclusion', SlideType.conclusion, 8),
        _createSlideTemplate('references', SlideType.references, 9),
        _createSlideTemplate('thankyou', SlideType.thankyou, 10),
      ],
      theme: PPTTheme(name: 'Technical Dark'),
      createdAt: DateTime.now(),
    );
  }

  PPTTemplate _createMinimalTemplate() {
    return PPTTemplate(
      id: 'minimal_simple',
      name: 'Minimal Simple',
      description: 'Simple minimal template for clean presentations',
      type: 'default',
      category: 'minimal',
      slides: [
        _createSlideTemplate('title', SlideType.titleSlide, 0),
        _createSlideTemplate('introduction', SlideType.introduction, 1),
        _createSlideTemplate('problem', SlideType.problemStatement, 2),
        _createSlideTemplate('objectives', SlideType.objectives, 3),
        _createSlideTemplate('implementation', SlideType.implementation, 4),
        _createSlideTemplate('results', SlideType.results, 5),
        _createSlideTemplate('conclusion', SlideType.conclusion, 6),
        _createSlideTemplate('thankyou', SlideType.thankyou, 7),
      ],
      theme: PPTTheme(name: 'Minimal White'),
      createdAt: DateTime.now(),
    );
  }

  SlideTemplate _createSlideTemplate(String id, SlideType type, int order) {
    return SlideTemplate(
      id: id,
      title: _getSlideTitle(type),
      type: type,
      order: order,
      elements: [],
      layout: const SlideLayout(name: 'standard'),
    );
  }

  String _getSlideTitle(SlideType type) {
    switch (type) {
      case SlideType.titleSlide:
        return 'Title';
      case SlideType.introduction:
        return 'Introduction';
      case SlideType.problemStatement:
        return 'Problem Statement';
      case SlideType.objectives:
        return 'Objectives';
      case SlideType.methodology:
        return 'Methodology';
      case SlideType.architecture:
        return 'Architecture';
      case SlideType.implementation:
        return 'Implementation';
      case SlideType.results:
        return 'Results';
      case SlideType.conclusion:
        return 'Conclusion';
      case SlideType.references:
        return 'References';
      case SlideType.thankyou:
        return 'Thank You';
      default:
        return 'Slide';
    }
  }
}