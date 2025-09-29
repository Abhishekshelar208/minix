import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:minix/models/citation.dart';

class CitationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = const Uuid();

  // Add citation to project
  Future<void> addCitation({
    required String projectSpaceId,
    required Citation citation,
  }) async {
    try {
      await _database
          .child('ProjectCitations')
          .child(projectSpaceId)
          .child(citation.id)
          .set(citation.toMap());
    } catch (e) {
      debugPrint('Failed to add citation: $e');
      rethrow;
    }
  }

  // Remove citation from project
  Future<void> removeCitation({
    required String projectSpaceId,
    required String citationId,
  }) async {
    try {
      await _database
          .child('ProjectCitations')
          .child(projectSpaceId)
          .child(citationId)
          .remove();
    } catch (e) {
      debugPrint('Failed to remove citation: $e');
      rethrow;
    }
  }

  // Get all citations for a project
  Future<List<Citation>> getProjectCitations(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectCitations')
          .child(projectSpaceId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries
            .map((entry) => Citation.fromMap(Map<String, dynamic>.from(entry.value as Map)))
            .toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Failed to get project citations: $e');
      return [];
    }
  }

  // Create or update bibliography for project
  Future<void> saveBibliography({
    required String projectSpaceId,
    required Bibliography bibliography,
  }) async {
    try {
      await _database
          .child('ProjectBibliographies')
          .child(projectSpaceId)
          .set(bibliography.toMap());
    } catch (e) {
      debugPrint('Failed to save bibliography: $e');
      rethrow;
    }
  }

  // Get bibliography for project
  Future<Bibliography?> getProjectBibliography(String projectSpaceId) async {
    try {
      final snapshot = await _database
          .child('ProjectBibliographies')
          .child(projectSpaceId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        return Bibliography.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get project bibliography: $e');
      return null;
    }
  }

  // Generate bibliography from project citations
  Future<Bibliography> generateBibliography({
    required String projectSpaceId,
    String style = 'APA',
  }) async {
    try {
      final citations = await getProjectCitations(projectSpaceId);
      final now = DateTime.now();
      
      final bibliography = Bibliography(
        id: _uuid.v4(),
        projectSpaceId: projectSpaceId,
        citations: citations,
        style: style,
        createdAt: now,
        updatedAt: now,
      );
      
      await saveBibliography(
        projectSpaceId: projectSpaceId,
        bibliography: bibliography,
      );
      
      return bibliography;
    } catch (e) {
      debugPrint('Failed to generate bibliography: $e');
      rethrow;
    }
  }

  // Create citation from URL (basic web scraping simulation)
  Future<Citation> createCitationFromUrl(String url) async {
    try {
      // In a real implementation, you would scrape the webpage for metadata
      // For now, we'll create a basic citation structure
      final now = DateTime.now();
      
      return Citation(
        id: _uuid.v4(),
        type: 'website',
        title: 'Web Page Title', // Would be scraped
        authors: ['Unknown Author'], // Would be scraped
        url: url,
        accessDate: now,
        year: now.year.toString(),
      );
    } catch (e) {
      debugPrint('Failed to create citation from URL: $e');
      rethrow;
    }
  }

  // Create citation manually
  Citation createManualCitation({
    required String type,
    required String title,
    required List<String> authors,
    String? journal,
    String? year,
    String? volume,
    String? pages,
    String? publisher,
    String? url,
    String? doi,
    DateTime? accessDate,
    Map<String, String> additionalFields = const {},
  }) {
    return Citation(
      id: _uuid.v4(),
      type: type,
      title: title,
      authors: authors,
      journal: journal,
      year: year,
      volume: volume,
      pages: pages,
      publisher: publisher,
      url: url,
      doi: doi,
      accessDate: accessDate,
      additionalFields: additionalFields,
    );
  }

  // Get predefined citations for common technologies
  List<Citation> getCommonTechCitations() {
    return [
      Citation(
        id: 'flutter_citation',
        type: 'misc',
        title: 'Flutter - Google\'s UI toolkit for building natively compiled applications',
        authors: ['Google LLC'],
        year: '2024',
        url: 'https://flutter.dev',
        accessDate: DateTime.now(),
      ),
      Citation(
        id: 'firebase_citation',
        type: 'misc',
        title: 'Firebase - Google\'s mobile and web application development platform',
        authors: ['Google LLC'],
        year: '2024',
        url: 'https://firebase.google.com',
        accessDate: DateTime.now(),
      ),
      Citation(
        id: 'dart_citation',
        type: 'misc',
        title: 'Dart programming language',
        authors: ['Google LLC'],
        year: '2024',
        url: 'https://dart.dev',
        accessDate: DateTime.now(),
      ),
      Citation(
        id: 'gemini_citation',
        type: 'misc',
        title: 'Gemini AI - Google\'s most capable AI model',
        authors: ['Google LLC'],
        year: '2024',
        url: 'https://deepmind.google/technologies/gemini',
        accessDate: DateTime.now(),
      ),
    ];
  }

  // Import citations from BibTeX format
  Future<List<Citation>> importFromBibTeX(String bibtexContent) async {
    try {
      final citations = <Citation>[];
      // This is a simplified BibTeX parser
      // In a real implementation, you would use a proper BibTeX parsing library
      
      final entries = bibtexContent.split('@').where((entry) => entry.trim().isNotEmpty);
      
      for (final entry in entries) {
        final lines = entry.split('\n');
        if (lines.isEmpty) continue;
        
        final firstLine = lines[0];
        final typeAndId = firstLine.split('{');
        if (typeAndId.length < 2) continue;
        
        final type = typeAndId[0].toLowerCase();
        final id = typeAndId[1].replaceAll(',', '').trim();
        
        final fields = <String, String>{};
        
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.contains('=')) {
            final parts = line.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=')
                  .replaceAll('{', '')
                  .replaceAll('}', '')
                  .replaceAll(',', '')
                  .trim();
              fields[key] = value;
            }
          }
        }
        
        final citation = Citation(
          id: id,
          type: type,
          title: fields['title'] ?? '',
          authors: fields['author']?.split(' and ') ?? [],
          journal: fields['journal'],
          year: fields['year'],
          volume: fields['volume'],
          pages: fields['pages'],
          publisher: fields['publisher'],
          url: fields['url'],
          doi: fields['doi'],
          additionalFields: fields,
        );
        
        citations.add(citation);
      }
      
      return citations;
    } catch (e) {
      debugPrint('Failed to import from BibTeX: $e');
      return [];
    }
  }

  // Export citations to BibTeX format
  String exportToBibTeX(List<Citation> citations) {
    final StringBuffer bibtex = StringBuffer();
    
    for (final citation in citations) {
      bibtex.write(citation.toBibTeX());
      bibtex.writeln();
    }
    
    return bibtex.toString();
  }

  // Format citations for in-text references
  String formatInTextCitation(Citation citation, String style) {
    switch (style.toUpperCase()) {
      case 'APA':
        if (citation.authors.isNotEmpty && citation.year != null) {
          final firstAuthor = citation.authors.first;
          final lastName = firstAuthor.split(' ').last;
          return '($lastName, ${citation.year})';
        }
        return '(Unknown, n.d.)';
      
      case 'IEEE':
        // For IEEE, you would typically use numbers like [1], [2], etc.
        // This would need to be managed at the document level
        return '[${citation.id}]';
      
      default:
        return formatInTextCitation(citation, 'APA');
    }
  }
}