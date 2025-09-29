class Citation {
  final String id;
  final String type; // article, book, website, inproceedings, etc.
  final String title;
  final List<String> authors;
  final String? journal;
  final String? year;
  final String? volume;
  final String? pages;
  final String? publisher;
  final String? url;
  final String? doi;
  final DateTime? accessDate;
  final Map<String, String> additionalFields;

  Citation({
    required this.id,
    required this.type,
    required this.title,
    required this.authors,
    this.journal,
    this.year,
    this.volume,
    this.pages,
    this.publisher,
    this.url,
    this.doi,
    this.accessDate,
    this.additionalFields = const {},
  });

  factory Citation.fromMap(Map<String, dynamic> map) {
    return Citation(
      id: ((map['id'] ?? '').toString()).toString(),
      type: (map['type'] ?? 'article').toString(),
      title: ((map['title'] ?? '').toString()).toString(),
      authors: (map['authors'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      journal: map['journal']?.toString(),
      year: map['year']?.toString(),
      volume: map['volume']?.toString(),
      pages: map['pages']?.toString(),
      publisher: map['publisher']?.toString(),
      url: map['url']?.toString(),
      doi: map['doi']?.toString(),
      accessDate: map['accessDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((map['accessDate'] as num).toInt())
          : null,
      additionalFields: (map['additionalFields'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ) ?? <String, String>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'authors': authors,
      'journal': journal,
      'year': year,
      'volume': volume,
      'pages': pages,
      'publisher': publisher,
      'url': url,
      'doi': doi,
      'accessDate': accessDate?.millisecondsSinceEpoch,
      'additionalFields': additionalFields,
    };
  }

  // Generate APA format citation
  String toAPA() {
    final StringBuffer citation = StringBuffer();
    
    // Authors
    if (authors.isNotEmpty) {
      if (authors.length == 1) {
        citation.write(authors[0]);
      } else if (authors.length == 2) {
        citation.write('${authors[0]} & ${authors[1]}');
      } else {
        citation.write(authors.first);
        citation.write(' et al.');
      }
    }
    
    // Year
    if (year != null) {
      citation.write(' ($year).');
    } else {
      citation.write(' (n.d.).');
    }
    
    // Title
    citation.write(' $title.');
    
    // Journal/Publisher
    if (journal != null) {
      citation.write(' *$journal*');
      if (volume != null) {
        citation.write(', $volume');
        if (pages != null) {
          citation.write(', $pages');
        }
      }
      citation.write('.');
    } else if (publisher != null) {
      citation.write(' $publisher.');
    }
    
    // URL and access date
    if (url != null) {
      citation.write(' Retrieved from $url');
      if (accessDate != null) {
        final dateFormat = '${accessDate!.day}/${accessDate!.month}/${accessDate!.year}';
        citation.write(' (accessed $dateFormat)');
      }
    }
    
    return citation.toString();
  }

  // Generate IEEE format citation
  String toIEEE() {
    final StringBuffer citation = StringBuffer();
    
    // Authors
    if (authors.isNotEmpty) {
      for (int i = 0; i < authors.length; i++) {
        if (i == 0) {
          citation.write(authors[i]);
        } else if (i == authors.length - 1) {
          citation.write(' and ${authors[i]}');
        } else {
          citation.write(', ${authors[i]}');
        }
      }
    }
    
    // Title
    citation.write(', "$title,"');
    
    // Journal/Publisher
    if (journal != null) {
      citation.write(' *$journal*');
      if (volume != null) {
        citation.write(', vol. $volume');
        if (pages != null) {
          citation.write(', pp. $pages');
        }
      }
    } else if (publisher != null) {
      citation.write(' $publisher');
    }
    
    // Year
    if (year != null) {
      citation.write(', $year.');
    } else {
      citation.write('.');
    }
    
    // URL
    if (url != null) {
      citation.write(' [Online]. Available: $url');
      if (accessDate != null) {
        final dateFormat = '${accessDate!.day}/${accessDate!.month}/${accessDate!.year}';
        citation.write(' [Accessed: $dateFormat]');
      }
    }
    
    return citation.toString();
  }

  // Generate BibTeX entry
  String toBibTeX() {
    final StringBuffer bibtex = StringBuffer();
    
    bibtex.writeln('@$type{$id,');
    bibtex.writeln('  title = {$title},');
    
    if (authors.isNotEmpty) {
      bibtex.writeln('  author = {${authors.join(' and ')}},');
    }
    
    if (year != null) {
      bibtex.writeln('  year = {$year},');
    }
    
    if (journal != null) {
      bibtex.writeln('  journal = {$journal},');
    }
    
    if (volume != null) {
      bibtex.writeln('  volume = {$volume},');
    }
    
    if (pages != null) {
      bibtex.writeln('  pages = {$pages},');
    }
    
    if (publisher != null) {
      bibtex.writeln('  publisher = {$publisher},');
    }
    
    if (url != null) {
      bibtex.writeln('  url = {$url},');
    }
    
    if (doi != null) {
      bibtex.writeln('  doi = {$doi},');
    }
    
    // Add additional fields
    for (final entry in additionalFields.entries) {
      bibtex.writeln('  ${entry.key} = {${entry.value}},');
    }
    
    bibtex.writeln('}');
    
    return bibtex.toString();
  }
}

class Bibliography {
  final String id;
  final String projectSpaceId;
  final List<Citation> citations;
  final String style; // APA, IEEE, MLA, etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  Bibliography({
    required this.id,
    required this.projectSpaceId,
    required this.citations,
    this.style = 'APA',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bibliography.fromMap(Map<String, dynamic> map) {
    return Bibliography(
      id: ((map['id'] ?? '').toString()).toString(),
      projectSpaceId: ((map['projectSpaceId'] ?? '').toString()).toString(),
      citations: (map['citations'] as List<dynamic>?)
          ?.map((citation) => Citation.fromMap((citation as Map<dynamic, dynamic>).map(
            (key, value) => MapEntry(key.toString(), value),
          )))
          .toList() ?? [],
      style: (map['style'] ?? 'APA').toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num? ?? 0).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as num? ?? 0).toInt()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectSpaceId': projectSpaceId,
      'citations': citations.map((citation) => citation.toMap()).toList(),
      'style': style,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Generate formatted bibliography
  String generateBibliography() {
    final StringBuffer bibliography = StringBuffer();
    bibliography.writeln('## References\n');
    
    // Sort citations alphabetically by first author's last name
    final sortedCitations = List<Citation>.from(citations);
    sortedCitations.sort((a, b) {
      final aFirstAuthor = a.authors.isNotEmpty ? a.authors.first : '';
      final bFirstAuthor = b.authors.isNotEmpty ? b.authors.first : '';
      return aFirstAuthor.compareTo(bFirstAuthor);
    });
    
    for (int i = 0; i < sortedCitations.length; i++) {
      final citation = sortedCitations[i];
      switch (style.toUpperCase()) {
        case 'APA':
          bibliography.writeln('${i + 1}. ${citation.toAPA()}\n');
          break;
        case 'IEEE':
          bibliography.writeln('[${i + 1}] ${citation.toIEEE()}\n');
          break;
        default:
          bibliography.writeln('${i + 1}. ${citation.toAPA()}\n');
      }
    }
    
    return bibliography.toString();
  }

  // Generate BibTeX file content
  String generateBibTeX() {
    final StringBuffer bibtex = StringBuffer();
    
    for (final citation in citations) {
      bibtex.write(citation.toBibTeX());
      bibtex.writeln();
    }
    
    return bibtex.toString();
  }
}