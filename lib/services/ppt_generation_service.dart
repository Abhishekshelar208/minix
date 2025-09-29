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

class PPTGenerationService {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  PPTGenerationService({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
        final projectData = Map<String, dynamic>.from((projectSnapshot.value ?? {}) as Map);
        enrichedData.addAll({
          'teamName': (projectData['teamName'] ?? 'Team').toString(),
          'teamMembers': List<String>.from((projectData['teamMembers'] ?? <String>[]) as Iterable),
          'yearOfStudy': (projectData['yearOfStudy'] ?? 2) as int,
          'targetPlatform': (projectData['targetPlatform'] ?? 'App').toString(),
          'difficulty': (projectData['difficulty'] ?? 'Intermediate').toString(),
        });
      }

      // Add solution data
      if (solutionSnapshot.exists) {
        final solutions = Map<String, dynamic>.from((solutionSnapshot.value ?? {}) as Map);
        final firstSolution = Map<String, dynamic>.from(solutions.values.first as Map);
        enrichedData.addAll({
          'solutionTitle': (firstSolution['title'] ?? '').toString(),
          'solutionDescription': (firstSolution['description'] ?? '').toString(),
          'keyFeatures': List<String>.from((firstSolution['keyFeatures'] ?? <String>[]) as Iterable),
          'techStack': List<String>.from((firstSolution['techStack'] ?? <String>[]) as Iterable),
          'architecture': Map<String, dynamic>.from((firstSolution['architecture'] ?? <String, dynamic>{}) as Map),
        });
      }

      // Add current date and user info
      enrichedData.addAll({
        'generatedDate': DateTime.now().toIso8601String().split('T')[0],
        'generatedBy': _auth.currentUser?.displayName ?? 'Student',
        'userEmail': _auth.currentUser?.email ?? '',
      });

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
    
    // Filter slides based on include/exclude lists
    var slidesToGenerate = template.slides;
    
    if (includeSlides.isNotEmpty) {
      slidesToGenerate = slidesToGenerate.where((slide) => 
        includeSlides.contains(slide.id) || includeSlides.contains(slide.type.toString().split('.').last)
      ).toList();
    }
    
    if (excludeSlides.isNotEmpty) {
      slidesToGenerate = slidesToGenerate.where((slide) => 
        !excludeSlides.contains(slide.id) && !excludeSlides.contains(slide.type.toString().split('.').last)
      ).toList();
    }

    // Sort slides by order
    slidesToGenerate.sort((a, b) => a.order.compareTo(b.order));

    // Generate each slide
    for (final slideTemplate in slidesToGenerate) {
      final slideContent = _generateSlideContent(slideTemplate, projectData, customizations);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return slideContent;
          },
        ),
      );
    }

    return await pdf.save();
  }

  pw.Widget _generateSlideContent(
    SlideTemplate slideTemplate, 
    Map<String, dynamic> projectData, 
    Map<String, String> customizations
  ) {
    switch (slideTemplate.type) {
      case SlideType.titleSlide:
        return _buildTitleSlide(projectData, customizations);
      case SlideType.introduction:
        return _buildIntroductionSlide(projectData, customizations);
      case SlideType.problemStatement:
        return _buildProblemStatementSlide(projectData, customizations);
      case SlideType.objectives:
        return _buildObjectivesSlide(projectData, customizations);
      case SlideType.methodology:
        return _buildMethodologySlide(projectData, customizations);
      case SlideType.architecture:
        return _buildArchitectureSlide(projectData, customizations);
      case SlideType.implementation:
        return _buildImplementationSlide(projectData, customizations);
      case SlideType.results:
        return _buildResultsSlide(projectData, customizations);
      case SlideType.conclusion:
        return _buildConclusionSlide(projectData, customizations);
      case SlideType.references:
        return _buildReferencesSlide(projectData, customizations);
      case SlideType.thankyou:
        return _buildThankYouSlide(projectData, customizations);
      default:
        return _buildGenericSlide(slideTemplate, projectData, customizations);
    }
  }

  pw.Widget _buildTitleSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue900, PdfColors.indigo900],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Stack(
        children: [
          // Background pattern
          pw.Positioned(
            top: -50,
            right: -50,
            child: pw.Container(
              width: 200,
              height: 200,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColor.fromInt(0x0DFFFFFF), // White with 5% opacity
              ),
            ),
          ),
          pw.Positioned(
            bottom: -30,
            left: -30,
            child: pw.Container(
              width: 150,
              height: 150,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColor.fromInt(0x08FFFFFF), // White with 3% opacity
              ),
            ),
          ),
          // Main content
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Modern card container
                pw.Container(
                  padding: const pw.EdgeInsets.all(40),
                  margin: const pw.EdgeInsets.symmetric(horizontal: 60),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xF2FFFFFF), // White with 95% opacity
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColor.fromInt(0x33000000), // Black with 20% opacity
                        blurRadius: 20,
                        offset: const PdfPoint(0, 10),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      // Project icon/logo placeholder
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          gradient: pw.LinearGradient(
                            colors: [PdfColors.blue600, PdfColors.purple600],
                            begin: pw.Alignment.topLeft,
                            end: pw.Alignment.bottomRight,
                          ),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '🚀',
                            style: pw.TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      
                      // Project title with modern typography
                      pw.Text(
        customizations['title'] ?? (data['projectName'] ?? 'Project Presentation').toString(),
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                          letterSpacing: -0.5,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 15),
                      
                      // Subtitle with accent color
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
                          border: pw.Border.all(color: PdfColors.blue200, width: 1),
                        ),
                        child: pw.Text(
          customizations['subtitle'] ?? (data['solutionTitle'] ?? 'Engineering Project').toString(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.blue800,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      
                      // Team information in modern cards
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoCard(
                            '👥 Team',
            (data['teamName'] ?? 'Team').toString(),
                            PdfColors.green600,
                          ),
                          _buildInfoCard(
                            '📱 Platform',
            (data['targetPlatform'] ?? 'App').toString(),
                            PdfColors.purple600,
                          ),
                          _buildInfoCard(
                            '🎓 Year',
                            '${data['yearOfStudy'] ?? 2}',
                            PdfColors.orange600,
                          ),
                        ],
                      ),
                      
                      if (data['teamMembers'] != null && (data['teamMembers'] as List).isNotEmpty)
                        pw.SizedBox(height: 30),
                      if (data['teamMembers'] != null && (data['teamMembers'] as List).isNotEmpty)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(15),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Team Members',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                (data['teamMembers'] as List<String>).join(' • '),
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  color: PdfColors.grey800,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Generation timestamp with modern design
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0x33FFFFFF), // White with 20% opacity
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                    border: pw.Border.all(color: PdfColor.fromInt(0x4DFFFFFF)), // White with 30% opacity
                  ),
                  child: pw.Text(
                    'Generated on ${data['generatedDate'] ?? DateTime.now().toIso8601String().split('T')[0]}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromInt(0xE6FFFFFF), // White with 90% opacity
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIntroductionSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Project Introduction'),
        pw.SizedBox(height: 40),
        
        // Main introduction card
        pw.Container(
          padding: const pw.EdgeInsets.all(25),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.blue50, PdfColors.indigo50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.blue200, width: 2),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.blue200,
                blurRadius: 8,
                offset: const PdfPoint(0, 4),
              ),
            ],
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue600,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text(
                      '🎯',
                      style: pw.TextStyle(fontSize: 20),
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Text(
                      'Project Overview',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                customizations['introduction'] ?? 
                'This presentation showcases our innovative ${data['targetPlatform'] ?? 'software'} project: "${data['projectName'] ?? 'Project'}". Our solution addresses real-world challenges through modern technology and thoughtful design.',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        // Key highlights in modern cards
        pw.Text(
          '✨ Key Highlights',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
          ),
        ),
        pw.SizedBox(height: 20),
        
        // Grid of highlight cards
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildHighlightCard(
                '📱',
                'Platform',
                (data['targetPlatform'] ?? 'App').toString(),
                PdfColors.purple600,
              ),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: _buildHighlightCard(
                '⚡',
                'Complexity',
                (data['difficulty'] ?? 'Intermediate').toString(),
                PdfColors.orange600,
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 15),
        
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildHighlightCard(
                '👥',
                'Team Size',
                '${(data['teamMembers'] as List?)?.length ?? 1} Members',
                PdfColors.green600,
              ),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: _buildHighlightCard(
                '🚀',
                'Tech Stack',
                (data['techStack'] as List?)?.take(2).join(', ') ?? 'Modern Tech',
                PdfColors.blue600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHighlightCard(String emoji, String title, String value, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: accentColor, width: 2),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey100, // Light shadow
            blurRadius: 6,
            offset: const PdfPoint(0, 3),
          ),
        ],
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50, // Light background
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              emoji,
              style: pw.TextStyle(fontSize: 20),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProblemStatementSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Problem Statement'),
        pw.SizedBox(height: 40),
        
        // Problem description in modern card
        pw.Container(
          padding: const pw.EdgeInsets.all(25),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.red50, PdfColors.orange50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.red200, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red600,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Text(
                      '🎯',
                      style: pw.TextStyle(fontSize: 24),
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Text(
                      'The Challenge We\'re Solving',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                customizations['problem'] ?? (data['problemDescription']?.toString() ?? 'Our project addresses a significant challenge in the ${data['targetPlatform'] ?? 'software'} domain. Through careful analysis and innovative thinking, we\'ve identified key pain points that require a modern, technology-driven solution.'),
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey800,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        if (data['keyFeatures'] != null && (data['keyFeatures'] as List).isNotEmpty)
          pw.SizedBox(height: 30),
        if (data['keyFeatures'] != null && (data['keyFeatures'] as List).isNotEmpty)
          pw.Text(
            '📊 Key Problem Areas',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        if (data['keyFeatures'] != null && (data['keyFeatures'] as List).isNotEmpty)
          pw.SizedBox(height: 20),
        if (data['keyFeatures'] != null && (data['keyFeatures'] as List).isNotEmpty)
          // Problem areas in visual cards
          pw.Wrap(
            spacing: 15,
            runSpacing: 15,
            children: (data['keyFeatures'] as List<String>).take(4).map((feature) => 
              pw.Container(
                width: (842 - 160) / 2 - 7.5, // Half width minus padding and spacing
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.orange200, width: 1),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColors.orange100,
                      blurRadius: 4,
                      offset: const PdfPoint(0, 2),
                    ),
                  ],
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 6,
                      height: 30,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange600,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Text(
                        feature,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
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
          'Our main objectives are:',
          style: pw.TextStyle(fontSize: 16),
        ),
        pw.SizedBox(height: 20),
        ..._buildBulletPoints([
          'Develop a reliable ${data['targetPlatform'] ?? 'application'} solution',
          'Implement modern ${(data['techStack'] as List?)?.join(' and ') ?? 'technologies'}',
          'Create user-friendly interface and experience',
          'Ensure scalability and maintainability',
          'Address real-world problem through technology',
        ]),
      ],
    );
  }

  pw.Widget _buildMethodologySlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Methodology'),
        pw.SizedBox(height: 30),
        pw.Text(
          'Our development approach:',
          style: pw.TextStyle(fontSize: 16),
        ),
        pw.SizedBox(height: 20),
        ..._buildBulletPoints([
          'Requirement Analysis and Planning',
          'System Design and Architecture',
          'Iterative Development Process',
          'Testing and Quality Assurance',
          'Deployment and Maintenance',
        ]),
        pw.SizedBox(height: 20),
        pw.Text(
          'Technology Stack: ${(data['techStack'] as List?)?.join(', ') ?? 'Modern Technologies'}',
          style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  pw.Widget _buildArchitectureSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('System Architecture'),
        pw.SizedBox(height: 40),
        
        // Architecture overview
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.green50, PdfColors.teal50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.green200, width: 2),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                '🏗️ ${data['targetPlatform'] == 'Web' ? 'Modern Web' : 'Mobile-First'} Architecture',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                'Our system follows industry best practices with a scalable, maintainable architecture designed for optimal performance and user experience.',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey800,
                  height: 1.4,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 30),
        
        if (data['techStack'] != null) ...[
          // Modern architecture diagram
          pw.Row(
            children: [
              // Frontend section
              pw.Expanded(
                child: _buildArchitectureLayer(
                  '🎨 Frontend Layer',
                  PdfColors.blue600,
                  _getArchitectureItems(List<String>.from((data['techStack'] ?? <String>[]) as Iterable), ['Flutter', 'React', 'Angular', 'Vue', 'HTML', 'CSS', 'JavaScript']),
                  '📱 User Interface',
                ),
              ),
              
              pw.SizedBox(width: 20),
              
              // Connection arrows
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 40,
                    height: 3,
                    color: PdfColors.grey400,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '↔️',
                    style: pw.TextStyle(fontSize: 20, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: 40,
                    height: 3,
                    color: PdfColors.grey400,
                  ),
                ],
              ),
              
              pw.SizedBox(width: 20),
              
              // Backend section
              pw.Expanded(
                child: _buildArchitectureLayer(
                  '⚙️ Backend Layer',
                  PdfColors.green600,
                  _getArchitectureItems(List<String>.from((data['techStack'] ?? <String>[]) as Iterable), ['Firebase', 'Node.js', 'Express', 'MongoDB', 'API', 'Server']),
                  '🔧 Business Logic',
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 25),
          
          // Data layer
          pw.Center(
            child: pw.Container(
              width: 300,
              child: _buildArchitectureLayer(
                '💾 Data Layer',
                PdfColors.purple600,
                _getArchitectureItems(List<String>.from((data['techStack'] ?? <String>[]) as Iterable), ['Firebase', 'Database', 'Cloud', 'Storage', 'MongoDB', 'Firestore']),
                '📊 Data Management',
              ),
            ),
          ),
        ] else ...[
          _buildArchitectureLayer(
            '🔧 Technology Stack',
            PdfColors.blue600,
            [pw.Text('Modern web technologies', style: pw.TextStyle(fontSize: 14))],
            '💡 Full-Stack Solution',
          ),
        ],
      ],
    );
  }

  pw.Widget _buildImplementationSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Implementation'),
        pw.SizedBox(height: 30),
        
        // Implementation overview
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.indigo50, PdfColors.blue50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.indigo200, width: 2),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(50)),
                ),
                child: pw.Text(
                  '⚡',
                  style: pw.TextStyle(fontSize: 20),
                ),
              ),
              pw.SizedBox(width: 15),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Implementation Highlights',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Bringing innovative solutions to life with modern development practices',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 25),
        
        // Feature cards grid
        if (data['keyFeatures'] != null && (data['keyFeatures'] as List).isNotEmpty)
          _buildFeatureGrid((data['keyFeatures'] as List<String>).take(6).toList())
        else
          _buildFeatureGrid([
            'User Authentication & Authorization',
            'Real-time Data Synchronization',
            'Responsive User Interface',
            'Security & Privacy Features', 
            'Performance Optimization',
            'Cloud Integration',
          ]),
        
        pw.SizedBox(height: 20),
        
        // Development progress
        _buildDevelopmentProgress(),
      ],
    );
  }

  pw.Widget _buildResultsSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Results & Outcomes'),
        pw.SizedBox(height: 30),
        
        // Results overview
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.purple50, PdfColors.pink50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.purple200, width: 2),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(50)),
                ),
                child: pw.Text(
                  '🏆',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Project Success Metrics',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Delivering exceptional results through innovative solutions',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 25),
        
        // Metrics cards
        _buildMetricsRow(),
        
        pw.SizedBox(height: 20),
        
        // Achievement highlights
        _buildAchievementHighlights(data),
        
        pw.SizedBox(height: 15),
        
        // Success summary
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.green50, PdfColors.teal50],
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: PdfColors.green300, width: 1),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColors.green200,
                blurRadius: 4,
                offset: const PdfPoint(0, 2),
              ),
            ],
          ),
          child: pw.Row(
            children: [
              pw.Text(
                '✨',
                style: pw.TextStyle(fontSize: 20),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Text(
                  'The project successfully addresses the identified problem using ${data['difficulty'] ?? 'intermediate'} level implementation techniques, demonstrating practical application of modern software development principles.',
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.green800,
                    fontStyle: pw.FontStyle.italic,
                    fontWeight: pw.FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildConclusionSlide(Map<String, dynamic> data, Map<String, String> customizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSlideHeader('Conclusion'),
        pw.SizedBox(height: 30),
        
        // Main conclusion statement
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.blue50, PdfColors.indigo50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.blue200, width: 2),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(50)),
                ),
                child: pw.Text(
                  '🎯',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Project Impact',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      customizations['conclusion'] ?? 
                      'Our project successfully demonstrates the application of modern technology to solve real-world problems, delivering measurable value and innovation.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 25),
        
        // Key takeaways section
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Learning outcomes
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green600,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Text(
                      '📚 Key Learnings',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildTakeawaysList([
                    'Practical application of academic knowledge',
                    'Experience with ${_getTechStackSummary(data)}',
                    'Problem-solving and critical thinking',
                    'Team collaboration skills',
                  ]),
                ],
              ),
            ),
            
            pw.SizedBox(width: 30),
            
            // Future roadmap
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.purple600,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Text(
                      '🚀 Future Roadmap',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildFutureRoadmapCards(),
                ],
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Success summary
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.orange50, PdfColors.amber50],
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: PdfColors.orange200, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                '✨',
                style: pw.TextStyle(fontSize: 20),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Text(
                  'This project demonstrates our ability to transform ideas into reality, combining technical expertise with innovative thinking to create meaningful solutions.',
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.orange800,
                    fontStyle: pw.FontStyle.italic,
                    fontWeight: pw.FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
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
        
        // References overview
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.teal50, PdfColors.cyan50],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            border: pw.Border.all(color: PdfColors.teal200, width: 2),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(50)),
                ),
                child: pw.Text(
                  '📚',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Knowledge Foundation',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Built on solid research foundation and industry-standard practices',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 25),
        
        // Reference categories
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Technical Resources
            pw.Expanded(
              child: _buildReferenceCategory(
                '💻 Technical Resources',
                PdfColors.blue600,
                [
                  'Official ${_getPrimaryTech(data)} Documentation',
                  'API Reference Guides',
                  'Framework Best Practices',
                  'Technical Architecture Patterns',
                ],
              ),
            ),
            
            pw.SizedBox(width: 20),
            
            // Academic Sources
            pw.Expanded(
              child: _buildReferenceCategory(
                '🎓 Academic Sources',
                PdfColors.green600,
                [
                  'Software Engineering Principles',
                  'Design Pattern Literature',
                  'Computer Science Journals',
                  'Research Papers & Studies',
                ],
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 15),
        
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Community Resources
            pw.Expanded(
              child: _buildReferenceCategory(
                '🌐 Community & Tutorials',
                PdfColors.purple600,
                [
                  'Stack Overflow Discussions',
                  'GitHub Open Source Projects',
                  'Developer Community Forums',
                  'Online Learning Platforms',
                ],
              ),
            ),
            
            pw.SizedBox(width: 20),
            
            // Methodology
            pw.Expanded(
              child: _buildReferenceCategory(
                '📈 Methodology',
                PdfColors.orange600,
                [
                  'Agile Development Practices',
                  'Project Management Frameworks',
                  'Software Testing Methodologies',
                  'DevOps Best Practices',
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
        gradient: pw.RadialGradient(
          colors: [
            PdfColors.indigo100,
            PdfColors.purple100,
            PdfColors.pink100,
          ],
          center: pw.Alignment.center,
          radius: 1.5,
        ),
      ),
      child: pw.Stack(
        children: [
          // Decorative circles
          pw.Positioned(
            top: 50,
            right: 80,
            child: pw.Container(
              width: 120,
              height: 120,
              decoration: pw.BoxDecoration(
            color: PdfColors.blue300,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Positioned(
            bottom: 60,
            left: 60,
            child: pw.Container(
              width: 80,
              height: 80,
              decoration: pw.BoxDecoration(
            color: PdfColors.purple300,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          
          // Main content
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Thank you container
                pw.Container(
                  padding: const pw.EdgeInsets.all(30),
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
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.purple400,
                        blurRadius: 20,
                        offset: const PdfPoint(0, 10),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '🙏',
                        style: pw.TextStyle(fontSize: 40),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'Thank You!',
                        style: pw.TextStyle(
                          fontSize: 48,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: -1,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'Questions & Discussion',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.normal,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 40),
                
                // Project info cards
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildInfoCard(
                      '💻 Project',
                      (data['projectName'] ?? 'Engineering Project').toString(),
                      PdfColors.blue600,
                    ),
                    pw.SizedBox(width: 20),
                    _buildInfoCard(
                      '👥 Team',
                      (data['teamName'] ?? 'Development Team').toString(),
                      PdfColors.green600,
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                if (data['userEmail'] != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColors.grey200,
                          blurRadius: 8,
                          offset: const PdfPoint(0, 3),
                        ),
                      ],
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('✉️', style: pw.TextStyle(fontSize: 16)),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          (data['userEmail'] ?? '').toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
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
          colors: [PdfColors.blue700, PdfColors.blue800, PdfColors.indigo800],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.blue800,
            blurRadius: 10,
            offset: const PdfPoint(0, 4),
          ),
        ],
      ),
      child: pw.Stack(
        children: [
          // Decorative elements
          pw.Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: pw.Container(
              width: 60,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0x1AFFFFFF), // White with 10% opacity
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(30)),
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: -0.3,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildInfoCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 5),
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColors.grey50, PdfColors.white], // Light gradient
            begin: pw.Alignment.topCenter,
            end: pw.Alignment.bottomCenter,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: PdfColors.grey200, width: 1), // Light border
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
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

  // New architecture helper methods
  pw.Widget _buildArchitectureLayer(String title, PdfColor color, List<pw.Widget> items, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [color.shade(0.1), color.shade(0.05)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: color, width: 2),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 4,
            offset: const PdfPoint(2, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Layer title
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          
          // Subtitle
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          
          // Technologies
          ...items,
        ],
      ),
    );
  }

  List<pw.Widget> _getArchitectureItems(List<String> techStack, List<String> categories) {
    List<pw.Widget> items = [];
    List<String> matchedTechs = [];
    
    for (String tech in techStack) {
      if (categories.any((cat) => tech.toLowerCase().contains(cat.toLowerCase()))) {
        matchedTechs.add(tech);
      }
    }
    
    if (matchedTechs.isEmpty) {
      return [_buildTechChip('Not specified', PdfColors.grey400, '❓')];
    }
    
    // Create tech chips
    for (int i = 0; i < matchedTechs.length; i += 2) {
      List<pw.Widget> rowItems = [];
      
      // First tech in row
      rowItems.add(
        pw.Expanded(
          child: _buildTechChip(matchedTechs[i], _getTechColor(matchedTechs[i]), _getTechIcon(matchedTechs[i])),
        ),
      );
      
      // Second tech in row (if exists)
      if (i + 1 < matchedTechs.length) {
        rowItems.add(pw.SizedBox(width: 8));
        rowItems.add(
          pw.Expanded(
            child: _buildTechChip(matchedTechs[i + 1], _getTechColor(matchedTechs[i + 1]), _getTechIcon(matchedTechs[i + 1])),
          ),
        );
      }
      
      items.add(pw.Row(children: rowItems));
      if (i + 2 < matchedTechs.length) {
        items.add(pw.SizedBox(height: 6));
      }
    }
    
    return items;
  }
  
  pw.Widget _buildTechChip(String tech, PdfColor color, String icon) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        border: pw.Border.all(color: color.shade(0.3), width: 1),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            icon,
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(width: 4),
          pw.Flexible(
            child: pw.Text(
              tech,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color.shade(0.8),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  PdfColor _getTechColor(String tech) {
    final String lowerTech = tech.toLowerCase();
    if (lowerTech.contains('flutter') || lowerTech.contains('dart')) return PdfColors.blue;
    if (lowerTech.contains('react') || lowerTech.contains('javascript')) return PdfColors.cyan;
    if (lowerTech.contains('firebase') || lowerTech.contains('database')) return PdfColors.orange;
    if (lowerTech.contains('node') || lowerTech.contains('express')) return PdfColors.green;
    if (lowerTech.contains('mongodb') || lowerTech.contains('storage')) return PdfColors.purple;
    if (lowerTech.contains('html') || lowerTech.contains('css')) return PdfColors.red;
    return PdfColors.indigo;
  }
  
  String _getTechIcon(String tech) {
    final String lowerTech = tech.toLowerCase();
    if (lowerTech.contains('flutter')) return '🔵';
    if (lowerTech.contains('react')) return '⚛️';
    if (lowerTech.contains('firebase')) return '🔥';
    if (lowerTech.contains('node')) return '🟢';
    if (lowerTech.contains('mongodb')) return '🍃';
    if (lowerTech.contains('database')) return '🗄️';
    if (lowerTech.contains('javascript')) return '💛';
    if (lowerTech.contains('html')) return '🔶';
    if (lowerTech.contains('css')) return '🎨';
    if (lowerTech.contains('api')) return '🔌';
    if (lowerTech.contains('server')) return '⚡';
    return '⚙️';
  }
  
  pw.Widget _buildFeatureGrid(List<String> features) {
    List<pw.Widget> rows = [];
    
    for (int i = 0; i < features.length; i += 2) {
      List<pw.Widget> rowItems = [];
      
      // First feature card
      rowItems.add(
        pw.Expanded(
          child: _buildFeatureCard(features[i], _getFeatureIcon(features[i]), _getFeatureColor(i)),
        ),
      );
      
      // Second feature card (if exists)
      if (i + 1 < features.length) {
        rowItems.add(pw.SizedBox(width: 12));
        rowItems.add(
          pw.Expanded(
            child: _buildFeatureCard(features[i + 1], _getFeatureIcon(features[i + 1]), _getFeatureColor(i + 1)),
          ),
        );
      }
      
      rows.add(pw.Row(children: rowItems));
      if (i + 2 < features.length) {
        rows.add(pw.SizedBox(height: 12));
      }
    }
    
    return pw.Column(children: rows);
  }
  
  pw.Widget _buildFeatureCard(String feature, String icon, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [color.shade(0.1), color.shade(0.05)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: color.shade(0.3), width: 1),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 3,
            offset: const PdfPoint(1, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  icon,
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  feature,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Progress indicator
          pw.Container(
            width: double.infinity,
            height: 4,
            decoration: pw.BoxDecoration(
              color: color.shade(0.2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: double.infinity * 0.85, // 85% completion
                height: 4,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildDevelopmentProgress() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.green50, PdfColors.teal50],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.green200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '📈 Development Milestones',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Text(
                  '85% Complete',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              _buildMilestoneItem('📋 Planning', true),
              pw.SizedBox(width: 15),
              _buildMilestoneItem('🛠️ Development', true),
              pw.SizedBox(width: 15),
              _buildMilestoneItem('🧪 Testing', true),
              pw.SizedBox(width: 15),
              _buildMilestoneItem('🚀 Deployment', false),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildMilestoneItem(String title, bool isCompleted) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: isCompleted ? PdfColors.green100 : PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(
            color: isCompleted ? PdfColors.green300 : PdfColors.grey300,
            width: 1,
          ),
        ),
        child: pw.Column(
          children: [
            pw.Container(
              width: 20,
              height: 20,
              decoration: pw.BoxDecoration(
                color: isCompleted ? PdfColors.green600 : PdfColors.grey400,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Center(
                child: pw.Text(
                  isCompleted ? '✓' : '•',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: isCompleted ? PdfColors.green800 : PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  String _getFeatureIcon(String feature) {
    final String lowerFeature = feature.toLowerCase();
    if (lowerFeature.contains('auth')) return '🔐';
    if (lowerFeature.contains('data') || lowerFeature.contains('sync')) return '🔄';
    if (lowerFeature.contains('interface') || lowerFeature.contains('ui')) return '🎨';
    if (lowerFeature.contains('security') || lowerFeature.contains('privacy')) return '🔒';
    if (lowerFeature.contains('performance') || lowerFeature.contains('optimization')) return '⚡';
    if (lowerFeature.contains('cloud') || lowerFeature.contains('integration')) return '☁️';
    if (lowerFeature.contains('notification')) return '🔔';
    if (lowerFeature.contains('storage')) return '🗄️';
    return '⚙️';
  }
  
  PdfColor _getFeatureColor(int index) {
    final colors = [
      PdfColors.blue600,
      PdfColors.green600,
      PdfColors.purple600,
      PdfColors.orange600,
      PdfColors.teal600,
      PdfColors.indigo600,
    ];
    return colors[index % colors.length];
  }
  
  // Helper methods for conclusion slide
  String _getTechStackSummary(Map<String, dynamic> data) {
    final techStack = data['techStack'] as List<String>?;
    if (techStack == null || techStack.isEmpty) {
      return 'modern technologies';
    }
    return techStack.take(3).join(', ');
  }
  
  pw.Widget _buildTakeawaysList(List<String> takeaways) {
    List<pw.Widget> items = [];
    for (int i = 0; i < takeaways.length; i++) {
      items.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.green200, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 16,
                height: 16,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '✓',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  takeaways[i],
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.green800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: items);
  }
  
  pw.Widget _buildFutureRoadmapCards() {
    final roadmapItems = [
      RoadmapItem('🔄 Version 2.0 Planning', 'Enhanced features'),
      RoadmapItem('📈 Scalability Improvements', 'Performance optimization'),
      RoadmapItem('🌐 Platform Expansion', 'Multi-platform support'),
    ];
    
    List<pw.Widget> cards = [];
    for (var item in roadmapItems) {
      cards.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.purple50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.purple200, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                item.description,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.purple600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: cards);
  }
  
  // Helper methods for references slide
  String _getPrimaryTech(Map<String, dynamic> data) {
    final techStack = data['techStack'] as List<String>?;
    if (techStack == null || techStack.isEmpty) {
      return 'Technology';
    }
    return techStack.first;
  }
  
  pw.Widget _buildReferenceCategory(String title, PdfColor color, List<String> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [color.shade(0.1), color.shade(0.05)],
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: color.shade(0.3), width: 1),
        boxShadow: [
          pw.BoxShadow(
            color: color.shade(0.2),
            blurRadius: 3,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          ...items.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(top: 6),
                  decoration: pw.BoxDecoration(
                    color: color,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  pw.Widget _buildMetricsRow() {
    return pw.Row(
      children: [
        _buildMetricCard('📊', '95%', 'Features\nCompleted', PdfColors.blue600),
        pw.SizedBox(width: 12),
        _buildMetricCard('🚀', '100%', 'Test\nCoverage', PdfColors.green600),
        pw.SizedBox(width: 12),
        _buildMetricCard('⚡', '3.2s', 'Load\nTime', PdfColors.orange600),
        pw.SizedBox(width: 12),
        _buildMetricCard('🎆', '0', 'Critical\nBugs', PdfColors.purple600),
      ],
    );
  }
  
  pw.Widget _buildMetricCard(String icon, String value, String label, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [color.shade(0.1), PdfColors.white],
            begin: pw.Alignment.topCenter,
            end: pw.Alignment.bottomCenter,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: color.shade(0.3), width: 1),
          boxShadow: [
            pw.BoxShadow(
              color: color.shade(0.2),
              blurRadius: 4,
              offset: const PdfPoint(0, 2),
            ),
          ],
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Text(
                icon,
                style: pw.TextStyle(fontSize: 16),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color.shade(0.8),
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  pw.Widget _buildAchievementHighlights(Map<String, dynamic> data) {
    final achievements = [
      AchievementItem('🏆 Successfully developed ${data['targetPlatform'] ?? 'application'} solution', true),
      AchievementItem('✓ Implemented all planned features and functionalities', true),
      AchievementItem('⚡ Achieved performance and scalability targets', true),
      AchievementItem('📄 Created comprehensive documentation', true),
      AchievementItem('🧪 Completed testing and quality assurance', true),
      AchievementItem('🚀 Ready for deployment and scaling', false),
    ];
    
    List<pw.Widget> rows = [];
    for (int i = 0; i < achievements.length; i += 2) {
      List<pw.Widget> rowItems = [];
      
      rowItems.add(
        pw.Expanded(
          child: _buildAchievementItem(achievements[i]),
        ),
      );
      
      if (i + 1 < achievements.length) {
        rowItems.add(pw.SizedBox(width: 12));
        rowItems.add(
          pw.Expanded(
            child: _buildAchievementItem(achievements[i + 1]),
          ),
        );
      }
      
      rows.add(pw.Row(children: rowItems));
      if (i + 2 < achievements.length) {
        rows.add(pw.SizedBox(height: 8));
      }
    }
    
    return pw.Column(children: rows);
  }
  
  pw.Widget _buildAchievementItem(AchievementItem achievement) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: achievement.isCompleted ? PdfColors.green50 : PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(
          color: achievement.isCompleted ? PdfColors.green200 : PdfColors.grey300,
          width: 1,
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 16,
            height: 16,
            decoration: pw.BoxDecoration(
              color: achievement.isCompleted ? PdfColors.green600 : PdfColors.grey400,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text(
                achievement.isCompleted ? '✓' : '•',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              achievement.title,
              style: pw.TextStyle(
                fontSize: 11,
                color: achievement.isCompleted ? PdfColors.green800 : PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
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
        _createSlideTemplate('architecture', SlideType.architecture, 4),
        _createSlideTemplate('implementation', SlideType.implementation, 5),
        _createSlideTemplate('results', SlideType.results, 6),
        _createSlideTemplate('conclusion', SlideType.conclusion, 7),
        _createSlideTemplate('thankyou', SlideType.thankyou, 8),
      ],
      theme: PPTTheme(
        name: 'Professional',
        primaryColor: '#1f2937',
        secondaryColor: '#374151',
        accentColor: '#3b82f6',
      ),
      createdAt: DateTime.now(),
    );
  }

  PPTTemplate _createTechnicalTemplate() {
    return PPTTemplate(
      id: 'technical_detailed',
      name: 'Technical Detailed',
      description: 'Comprehensive template for technical project presentations',
      type: 'default',
      category: 'academic',
      slides: [
        _createSlideTemplate('title', SlideType.titleSlide, 0),
        _createSlideTemplate('introduction', SlideType.introduction, 1),
        _createSlideTemplate('problem', SlideType.problemStatement, 2),
        _createSlideTemplate('literature', SlideType.literature, 3),
        _createSlideTemplate('objectives', SlideType.objectives, 4),
        _createSlideTemplate('methodology', SlideType.methodology, 5),
        _createSlideTemplate('architecture', SlideType.architecture, 6),
        _createSlideTemplate('implementation', SlideType.implementation, 7),
        _createSlideTemplate('results', SlideType.results, 8),
        _createSlideTemplate('conclusion', SlideType.conclusion, 9),
        _createSlideTemplate('references', SlideType.references, 10),
        _createSlideTemplate('thankyou', SlideType.thankyou, 11),
      ],
      theme: PPTTheme(
        name: 'Technical',
        primaryColor: '#059669',
        secondaryColor: '#10b981',
        accentColor: '#34d399',
      ),
      createdAt: DateTime.now(),
    );
  }

  PPTTemplate _createMinimalTemplate() {
    return PPTTemplate(
      id: 'minimal_simple',
      name: 'Minimal Simple',
      description: 'Simple, clean template with essential slides only',
      type: 'default',
      category: 'professional',
      slides: [
        _createSlideTemplate('title', SlideType.titleSlide, 0),
        _createSlideTemplate('problem', SlideType.problemStatement, 1),
        _createSlideTemplate('solution', SlideType.methodology, 2),
        _createSlideTemplate('implementation', SlideType.implementation, 3),
        _createSlideTemplate('results', SlideType.results, 4),
        _createSlideTemplate('thankyou', SlideType.thankyou, 5),
      ],
      theme: PPTTheme(
        name: 'Minimal',
        primaryColor: '#6b7280',
        secondaryColor: '#9ca3af',
        accentColor: '#f59e0b',
      ),
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
      layout: SlideLayout(name: 'standard'),
    );
  }

  String _getSlideTitle(SlideType type) {
    switch (type) {
      case SlideType.titleSlide:
        return 'Title Slide';
      case SlideType.introduction:
        return 'Introduction';
      case SlideType.problemStatement:
        return 'Problem Statement';
      case SlideType.objectives:
        return 'Objectives';
      case SlideType.literature:
        return 'Literature Review';
      case SlideType.methodology:
        return 'Methodology';
      case SlideType.architecture:
        return 'System Architecture';
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
        return 'Content';
    }
  }
}