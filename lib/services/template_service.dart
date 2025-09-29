import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:minix/models/document_template.dart';

class TemplateService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = const Uuid();

  // Get all available templates
  Future<List<DocumentTemplate>> getAllTemplates() async {
    try {
      final snapshot = await _database
          .child('DocumentTemplates')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        return data.entries
            .map((entry) => DocumentTemplate.fromMap(Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>)))
            .toList();
      }
      
      return getDefaultTemplates();
    } catch (e) {
      debugPrint('Failed to get templates: $e');
      return getDefaultTemplates();
    }
  }

  // Get templates by type
  Future<List<DocumentTemplate>> getTemplatesByType(String type) async {
    final allTemplates = await getAllTemplates();
    return allTemplates.where((template) => template.type == type).toList();
  }

  // Save custom template
  Future<void> saveTemplate(DocumentTemplate template) async {
    try {
      await _database
          .child('DocumentTemplates')
          .child(template.id)
          .set(template.toMap());
    } catch (e) {
      debugPrint('Failed to save template: $e');
      rethrow;
    }
  }

  // Get default templates
  List<DocumentTemplate> getDefaultTemplates() {
    final now = DateTime.now();
    
    return [
      // Academic Report Template
      DocumentTemplate(
        id: 'academic_report_template',
        name: 'Academic Report Template',
        type: 'report',
        description: 'Standard academic project report format',
        college: 'Default',
        structure: {
          'pageNumbering': true,
          'tableOfContents': true,
          'bibliography': true,
          'appendices': true,
        },
        sections: [
          DocumentSection(
            id: 'title_page',
            title: 'Title Page',
            type: 'title',
            order: 1,
            isRequired: true,
            placeholder: 'Project title, team members, college details',
          ),
          DocumentSection(
            id: 'abstract',
            title: 'Abstract',
            type: 'paragraph',
            order: 2,
            isRequired: true,
            placeholder: 'Brief summary of the project (150-200 words)',
            properties: {'maxWords': 200},
          ),
          DocumentSection(
            id: 'table_of_contents',
            title: 'Table of Contents',
            type: 'toc',
            order: 3,
            isRequired: true,
          ),
          DocumentSection(
            id: 'introduction',
            title: 'Introduction',
            type: 'heading',
            order: 4,
            isRequired: true,
            subsections: [
              DocumentSection(
                id: 'background',
                title: 'Background and Motivation',
                type: 'paragraph',
                order: 1,
                placeholder: 'Project background and motivation',
              ),
              DocumentSection(
                id: 'problem_statement',
                title: 'Problem Statement',
                type: 'paragraph',
                order: 2,
                placeholder: 'Clear problem statement',
              ),
              DocumentSection(
                id: 'objectives',
                title: 'Objectives and Scope',
                type: 'paragraph',
                order: 3,
                placeholder: 'Project objectives and scope',
              ),
            ],
          ),
          DocumentSection(
            id: 'literature_review',
            title: 'Literature Review',
            type: 'heading',
            order: 5,
            isRequired: true,
            placeholder: 'Existing systems analysis and technology research',
          ),
          DocumentSection(
            id: 'system_design',
            title: 'System Analysis and Design',
            type: 'heading',
            order: 6,
            isRequired: true,
            subsections: [
              DocumentSection(
                id: 'requirements',
                title: 'Requirements Analysis',
                type: 'paragraph',
                order: 1,
                placeholder: 'Functional and non-functional requirements',
              ),
              DocumentSection(
                id: 'architecture',
                title: 'System Architecture',
                type: 'paragraph',
                order: 2,
                placeholder: 'System architecture and design',
              ),
              DocumentSection(
                id: 'database_design',
                title: 'Database Design',
                type: 'paragraph',
                order: 3,
                placeholder: 'Database schema and design',
              ),
            ],
          ),
          DocumentSection(
            id: 'implementation',
            title: 'Implementation',
            type: 'heading',
            order: 7,
            isRequired: true,
            placeholder: 'Technology stack and implementation details',
          ),
          DocumentSection(
            id: 'testing',
            title: 'Testing and Validation',
            type: 'heading',
            order: 8,
            isRequired: true,
            placeholder: 'Testing strategies and results',
          ),
          DocumentSection(
            id: 'results',
            title: 'Results and Discussion',
            type: 'heading',
            order: 9,
            isRequired: true,
            placeholder: 'Project deliverables and results',
          ),
          DocumentSection(
            id: 'conclusion',
            title: 'Conclusion and Future Work',
            type: 'heading',
            order: 10,
            isRequired: true,
            placeholder: 'Summary and future enhancements',
          ),
          DocumentSection(
            id: 'references',
            title: 'References',
            type: 'bibliography',
            order: 11,
            isRequired: true,
          ),
          DocumentSection(
            id: 'appendices',
            title: 'Appendices',
            type: 'appendix',
            order: 12,
            isRequired: false,
            placeholder: 'Additional code, diagrams, or documentation',
          ),
        ],
        formatting: DocumentFormatting(
          fontFamily: 'Times New Roman',
          fontSize: 12.0,
          lineHeight: 1.5,
          margins: {'top': 1.0, 'bottom': 1.0, 'left': 1.0, 'right': 1.0},
          pageSize: 'A4',
          citationStyle: 'APA',
          headingStyles: {
            'h1': {'fontSize': 16.0, 'bold': true, 'spacing': 12.0},
            'h2': {'fontSize': 14.0, 'bold': true, 'spacing': 10.0},
            'h3': {'fontSize': 13.0, 'bold': true, 'spacing': 8.0},
          },
        ),
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Presentation Template
      DocumentTemplate(
        id: 'presentation_template',
        name: 'Professional Presentation Template',
        type: 'presentation',
        description: 'Professional presentation slides for project demo',
        college: 'Default',
        structure: {
          'slideCount': 20,
          'masterSlide': true,
          'animations': false,
        },
        sections: [
          DocumentSection(
            id: 'title_slide',
            title: 'Title Slide',
            type: 'slide',
            order: 1,
            isRequired: true,
            placeholder: 'Project title, team members, college, date',
          ),
          DocumentSection(
            id: 'agenda_slide',
            title: 'Agenda/Outline',
            type: 'slide',
            order: 2,
            isRequired: true,
            placeholder: 'Presentation flow overview',
          ),
          DocumentSection(
            id: 'intro_slides',
            title: 'Introduction & Problem Statement',
            type: 'slide_group',
            order: 3,
            properties: {'slideCount': 2},
            placeholder: 'Background, problem identification',
          ),
          DocumentSection(
            id: 'objectives_slides',
            title: 'Objectives & Scope',
            type: 'slide_group',
            order: 4,
            properties: {'slideCount': 2},
            placeholder: 'Project objectives and scope',
          ),
          DocumentSection(
            id: 'literature_slides',
            title: 'Literature Review',
            type: 'slide_group',
            order: 5,
            properties: {'slideCount': 2},
            placeholder: 'Existing solutions analysis',
          ),
          DocumentSection(
            id: 'solution_slides',
            title: 'Proposed Solution',
            type: 'slide_group',
            order: 6,
            properties: {'slideCount': 2},
            placeholder: 'Solution overview and key features',
          ),
          DocumentSection(
            id: 'implementation_slides',
            title: 'Implementation Approach',
            type: 'slide_group',
            order: 7,
            properties: {'slideCount': 2},
            placeholder: 'Development methodology and phases',
          ),
          DocumentSection(
            id: 'design_slides',
            title: 'System Design',
            type: 'slide_group',
            order: 8,
            properties: {'slideCount': 2},
            placeholder: 'Architecture and database design',
          ),
          DocumentSection(
            id: 'results_slides',
            title: 'Results & Demonstrations',
            type: 'slide_group',
            order: 9,
            properties: {'slideCount': 2},
            placeholder: 'Key achievements and screenshots',
          ),
          DocumentSection(
            id: 'challenges_slide',
            title: 'Challenges & Solutions',
            type: 'slide',
            order: 10,
            placeholder: 'Major challenges and solutions',
          ),
          DocumentSection(
            id: 'future_slide',
            title: 'Future Enhancements',
            type: 'slide',
            order: 11,
            placeholder: 'Planned improvements',
          ),
          DocumentSection(
            id: 'conclusion_slide',
            title: 'Conclusion',
            type: 'slide',
            order: 12,
            placeholder: 'Project summary and key takeaways',
          ),
          DocumentSection(
            id: 'qa_slide',
            title: 'Q&A',
            type: 'slide',
            order: 13,
            placeholder: 'Thank you and questions',
          ),
        ],
        formatting: DocumentFormatting(
          fontFamily: 'Arial',
          fontSize: 24.0,
          colors: {
            'primary': '#2563eb',
            'secondary': '#1f2937',
            'accent': '#059669',
            'background': '#ffffff',
          },
        ),
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Synopsis Template
      DocumentTemplate(
        id: 'synopsis_template',
        name: 'Project Synopsis Template',
        type: 'synopsis',
        description: 'Brief overview document for submission',
        college: 'Default',
        structure: {
          'maxPages': 4,
          'singleSpacing': false,
        },
        sections: [
          DocumentSection(
            id: 'title_section',
            title: 'Project Title and Details',
            type: 'title',
            order: 1,
            isRequired: true,
          ),
          DocumentSection(
            id: 'abstract_section',
            title: 'Abstract',
            type: 'paragraph',
            order: 2,
            isRequired: true,
            properties: {'maxWords': 250},
            placeholder: 'Project overview, objectives, methodology, outcomes (200-250 words)',
          ),
          DocumentSection(
            id: 'introduction_section',
            title: 'Introduction',
            type: 'paragraph',
            order: 3,
            isRequired: true,
            properties: {'maxWords': 400},
            placeholder: 'Background, motivation, problem statement (300-400 words)',
          ),
          DocumentSection(
            id: 'objectives_section',
            title: 'Objectives',
            type: 'list',
            order: 4,
            isRequired: true,
            placeholder: 'Primary and secondary objectives, success criteria',
          ),
          DocumentSection(
            id: 'methodology_section',
            title: 'Methodology',
            type: 'paragraph',
            order: 5,
            isRequired: true,
            properties: {'maxWords': 500},
            placeholder: 'Approach, technology stack, development phases (400-500 words)',
          ),
          DocumentSection(
            id: 'outcomes_section',
            title: 'Expected Outcomes',
            type: 'paragraph',
            order: 6,
            isRequired: true,
            placeholder: 'Deliverables, benefits, performance expectations',
          ),
          DocumentSection(
            id: 'timeline_section',
            title: 'Timeline',
            type: 'table',
            order: 7,
            isRequired: true,
            placeholder: 'Project phases, milestone schedule',
          ),
          DocumentSection(
            id: 'conclusion_section',
            title: 'Conclusion',
            type: 'paragraph',
            order: 8,
            isRequired: true,
            placeholder: 'Project significance, expected contribution',
          ),
        ],
        formatting: DocumentFormatting(
          fontFamily: 'Times New Roman',
          fontSize: 12.0,
          lineHeight: 1.5,
          pageSize: 'A4',
          citationStyle: 'APA',
        ),
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),

      // User Manual Template
      DocumentTemplate(
        id: 'user_manual_template',
        name: 'User Manual Template',
        type: 'user_manual',
        description: 'Step-by-step guide for using the application',
        college: 'Default',
        structure: {
          'illustrations': true,
          'stepByStep': true,
          'troubleshooting': true,
        },
        sections: [
          DocumentSection(
            id: 'welcome_section',
            title: 'Introduction',
            type: 'heading',
            order: 1,
            isRequired: true,
            placeholder: 'Welcome message, purpose, target audience',
          ),
          DocumentSection(
            id: 'requirements_section',
            title: 'System Requirements',
            type: 'heading',
            order: 2,
            isRequired: true,
            placeholder: 'Hardware and software requirements',
          ),
          DocumentSection(
            id: 'installation_section',
            title: 'Installation Guide',
            type: 'heading',
            order: 3,
            isRequired: true,
            placeholder: 'Download and installation steps',
          ),
          DocumentSection(
            id: 'getting_started_section',
            title: 'Getting Started',
            type: 'heading',
            order: 4,
            isRequired: true,
            placeholder: 'First login, interface overview, navigation',
          ),
          DocumentSection(
            id: 'features_section',
            title: 'Core Features Guide',
            type: 'heading',
            order: 5,
            isRequired: true,
            placeholder: 'Feature-by-feature instructions',
          ),
          DocumentSection(
            id: 'advanced_section',
            title: 'Advanced Features',
            type: 'heading',
            order: 6,
            isRequired: false,
            placeholder: 'Advanced functionality and customization',
          ),
          DocumentSection(
            id: 'troubleshooting_section',
            title: 'Troubleshooting',
            type: 'heading',
            order: 7,
            isRequired: true,
            placeholder: 'Common issues, error messages, FAQ',
          ),
          DocumentSection(
            id: 'security_section',
            title: 'Security and Privacy',
            type: 'heading',
            order: 8,
            isRequired: true,
            placeholder: 'Data protection, privacy settings, security',
          ),
          DocumentSection(
            id: 'support_section',
            title: 'Support and Contact',
            type: 'heading',
            order: 9,
            isRequired: true,
            placeholder: 'Help resources, contact information',
          ),
          DocumentSection(
            id: 'appendices_section',
            title: 'Appendices',
            type: 'heading',
            order: 10,
            isRequired: false,
            placeholder: 'Glossary, shortcuts, version history',
          ),
        ],
        formatting: DocumentFormatting(
          fontFamily: 'Arial',
          fontSize: 11.0,
          lineHeight: 1.4,
          pageSize: 'A4',
          colors: {
            'primary': '#2563eb',
            'secondary': '#6b7280',
            'warning': '#f59e0b',
            'success': '#059669',
          },
        ),
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Create template for specific college
  Future<DocumentTemplate> createCollegeTemplate({
    required String collegeName,
    required String baseTemplateId,
    required Map<String, dynamic> customizations,
  }) async {
    try {
      final baseTemplate = (await getAllTemplates())
          .firstWhere((t) => t.id == baseTemplateId);
      
      final customTemplate = DocumentTemplate(
        id: _uuid.v4(),
        name: '${baseTemplate.name} - $collegeName',
        type: baseTemplate.type,
        description: '${baseTemplate.description} - Customized for $collegeName',
        college: collegeName,
        structure: {
          ...baseTemplate.structure,
          ...(customizations['structure'] as Map<String, dynamic>? ?? <String, dynamic>{})
        },
        sections: baseTemplate.sections, // Could be customized further
        formatting: DocumentFormatting.fromMap({
          ...baseTemplate.formatting.toMap(),
          ...(customizations['formatting'] as Map<String, dynamic>? ?? <String, dynamic>{})
        }),
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await saveTemplate(customTemplate);
      return customTemplate;
    } catch (e) {
      debugPrint('Failed to create college template: $e');
      rethrow;
    }
  }
}