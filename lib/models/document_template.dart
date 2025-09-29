class DocumentTemplate {
  final String id;
  final String name;
  final String type; // report, presentation, synopsis, manual
  final String description;
  final String college;
  final Map<String, dynamic> structure;
  final List<DocumentSection> sections;
  final DocumentFormatting formatting;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.college = 'Default',
    required this.structure,
    required this.sections,
    required this.formatting,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentTemplate.fromMap(Map<String, dynamic> map) {
    return DocumentTemplate(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'report').toString(),
      description: (map['description'] ?? '').toString(),
      college: (map['college'] ?? 'Default').toString(),
      structure: (map['structure'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{},
      sections: (map['sections'] as List<dynamic>?)
          ?.map((section) => DocumentSection.fromMap((section as Map<dynamic, dynamic>).map(
            (key, value) => MapEntry(key.toString(), value),
          )))
          .toList() ?? [],
      formatting: DocumentFormatting.fromMap(
        (map['formatting'] as Map<dynamic, dynamic>?)?.map(
          (key, value) => MapEntry(key.toString(), value),
        ) ?? <String, dynamic>{},
      ),
      isDefault: (map['isDefault'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num? ?? 0).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as num? ?? 0).toInt()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'college': college,
      'structure': structure,
      'sections': sections.map((section) => section.toMap()).toList(),
      'formatting': formatting.toMap(),
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class DocumentSection {
  final String id;
  final String title;
  final String type; // heading, paragraph, list, image, table, code
  final int order;
  final bool isRequired;
  final String? placeholder;
  final Map<String, dynamic> properties;
  final List<DocumentSection> subsections;

  DocumentSection({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
    this.isRequired = true,
    this.placeholder,
    this.properties = const {},
    this.subsections = const [],
  });

  factory DocumentSection.fromMap(Map<String, dynamic> map) {
    return DocumentSection(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      type: (map['type'] ?? 'paragraph').toString(),
      order: (map['order'] as num? ?? 0).toInt(),
      isRequired: (map['isRequired'] as bool?) ?? true,
      placeholder: map['placeholder']?.toString(),
      properties: (map['properties'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{},
      subsections: (map['subsections'] as List<dynamic>?)
          ?.map((section) => DocumentSection.fromMap((section as Map<dynamic, dynamic>).map(
            (key, value) => MapEntry(key.toString(), value),
          )))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'order': order,
      'isRequired': isRequired,
      'placeholder': placeholder,
      'properties': properties,
      'subsections': subsections.map((section) => section.toMap()).toList(),
    };
  }
}

class DocumentFormatting {
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final Map<String, dynamic> margins; // top, bottom, left, right
  final Map<String, dynamic> headingStyles; // h1, h2, h3 styles
  final Map<String, dynamic> colors; // primary, secondary, accent colors
  final String pageSize; // A4, Letter, etc.
  final String citationStyle; // APA, IEEE, MLA

  DocumentFormatting({
    this.fontFamily = 'Times New Roman',
    this.fontSize = 12.0,
    this.lineHeight = 1.5,
    this.margins = const {'top': 1.0, 'bottom': 1.0, 'left': 1.0, 'right': 1.0},
    this.headingStyles = const {},
    this.colors = const {},
    this.pageSize = 'A4',
    this.citationStyle = 'APA',
  });

  factory DocumentFormatting.fromMap(Map<String, dynamic> map) {
    return DocumentFormatting(
      fontFamily: (map['fontFamily'] ?? 'Times New Roman').toString(),
      fontSize: (map['fontSize'] as num? ?? 12.0).toDouble(),
      lineHeight: (map['lineHeight'] as num? ?? 1.5).toDouble(),
      margins: (map['margins'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{'top': 1.0, 'bottom': 1.0, 'left': 1.0, 'right': 1.0},
      headingStyles: (map['headingStyles'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{},
      colors: (map['colors'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{},
      pageSize: (map['pageSize'] ?? 'A4').toString(),
      citationStyle: (map['citationStyle'] ?? 'APA').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'margins': margins,
      'headingStyles': headingStyles,
      'colors': colors,
      'pageSize': pageSize,
      'citationStyle': citationStyle,
    };
  }
}

class DocumentVersion {
  final String id;
  final String projectSpaceId;
  final String documentType;
  final String content;
  final int version;
  final String? changes;
  final DateTime createdAt;
  final String createdBy;

  DocumentVersion({
    required this.id,
    required this.projectSpaceId,
    required this.documentType,
    required this.content,
    required this.version,
    this.changes,
    required this.createdAt,
    required this.createdBy,
  });

  factory DocumentVersion.fromMap(Map<String, dynamic> map) {
    return DocumentVersion(
      id: (map['id'] ?? '').toString(),
      projectSpaceId: (map['projectSpaceId'] ?? '').toString(),
      documentType: (map['documentType'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      version: (map['version'] as num? ?? 0).toInt(),
      changes: map['changes']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num? ?? 0).toInt()),
      createdBy: (map['createdBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectSpaceId': projectSpaceId,
      'documentType': documentType,
      'content': content,
      'version': version,
      'changes': changes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }
}