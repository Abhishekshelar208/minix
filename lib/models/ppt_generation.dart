class PPTTemplate {
  final String id;
  final String name;
  final String description;
  final String type; // 'default' or 'custom'
  final String category; // 'academic', 'professional', 'creative'
  final List<SlideTemplate> slides;
  final PPTTheme theme;
  final bool isActive;
  final DateTime createdAt;
  final String? filePath; // For custom uploaded templates
  final String? collegeName; // For college-specific templates
  final Map<String, dynamic>? metadata;

  const PPTTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.slides,
    required this.theme,
    this.isActive = true,
    required this.createdAt,
    this.filePath,
    this.collegeName,
    this.metadata,
  });

  factory PPTTemplate.fromMap(Map<String, dynamic> map) {
    return PPTTemplate(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      type: (map['type'] ?? 'default').toString(),
      category: (map['category'] ?? 'academic').toString(),
      slides: (map['slides'] as List<dynamic>?)
          ?.map((slide) => SlideTemplate.fromMap((slide as Map<dynamic, dynamic>).map(
            (key, value) => MapEntry(key.toString(), value),
          )))
          .toList() ?? [],
      theme: PPTTheme.fromMap((map['theme'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{}),
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num? ?? 0).toInt()),
      filePath: map['filePath']?.toString(),
      collegeName: map['collegeName']?.toString(),
      metadata: map['metadata'] != null 
          ? (map['metadata'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'category': category,
      'slides': slides.map((slide) => slide.toMap()).toList(),
      'theme': theme.toMap(),
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'filePath': filePath,
      'collegeName': collegeName,
      'metadata': metadata,
    };
  }

  PPTTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? category,
    List<SlideTemplate>? slides,
    PPTTheme? theme,
    bool? isActive,
    DateTime? createdAt,
    String? filePath,
    String? collegeName,
    Map<String, dynamic>? metadata,
  }) {
    return PPTTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      slides: slides ?? this.slides,
      theme: theme ?? this.theme,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      collegeName: collegeName ?? this.collegeName,
      metadata: metadata ?? this.metadata,
    );
  }
}

class SlideTemplate {
  final String id;
  final String title;
  final SlideType type;
  final int order;
  final List<SlideElement> elements;
  final Map<String, String> placeholders; // {placeholder: dataField}
  final SlideLayout layout;
  final bool isRequired;

  const SlideTemplate({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
    required this.elements,
    this.placeholders = const {},
    required this.layout,
    this.isRequired = true,
  });

  factory SlideTemplate.fromMap(Map<String, dynamic> map) {
    return SlideTemplate(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      type: SlideType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? '').toString(),
        orElse: () => SlideType.content,
      ),
      order: (map['order'] as num? ?? 0).toInt(),
      elements: (map['elements'] as List<dynamic>?)
          ?.map((element) => SlideElement.fromMap((element as Map<dynamic, dynamic>).map(
            (key, value) => MapEntry(key.toString(), value),
          )))
          .toList() ?? [],
      placeholders: (map['placeholders'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ) ?? <String, String>{},
      layout: SlideLayout.fromMap((map['layout'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{}),
      isRequired: (map['isRequired'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'order': order,
      'elements': elements.map((element) => element.toMap()).toList(),
      'placeholders': placeholders,
      'layout': layout.toMap(),
      'isRequired': isRequired,
    };
  }
}

enum SlideType {
  titleSlide,
  introduction,
  problemStatement,
  objectives,
  literature,
  methodology,
  architecture,
  implementation,
  results,
  conclusion,
  references,
  thankyou,
  content, // Generic content slide
}

class SlideElement {
  final String id;
  final ElementType type;
  final String content;
  final ElementPosition position;
  final ElementStyle style;
  final Map<String, dynamic>? properties;

  const SlideElement({
    required this.id,
    required this.type,
    required this.content,
    required this.position,
    required this.style,
    this.properties,
  });

  factory SlideElement.fromMap(Map<String, dynamic> map) {
    return SlideElement(
      id: (map['id'] ?? '').toString(),
      type: ElementType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? '').toString(),
        orElse: () => ElementType.text,
      ),
      content: (map['content'] ?? '').toString(),
      position: ElementPosition.fromMap((map['position'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{}),
      style: ElementStyle.fromMap((map['style'] as Map<dynamic, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ) ?? <String, dynamic>{}),
      properties: map['properties'] != null 
          ? (map['properties'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'position': position.toMap(),
      'style': style.toMap(),
      'properties': properties,
    };
  }
}

enum ElementType {
  text,
  title,
  subtitle,
  bulletPoints,
  image,
  chart,
  table,
  code,
  diagram,
  logo,
}

class ElementPosition {
  final double x;
  final double y;
  final double width;
  final double height;

  const ElementPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory ElementPosition.fromMap(Map<String, dynamic> map) {
    return ElementPosition(
      x: (map['x'] as num? ?? 0.0).toDouble(),
      y: (map['y'] as num? ?? 0.0).toDouble(),
      width: (map['width'] as num? ?? 100.0).toDouble(),
      height: (map['height'] as num? ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}

class ElementStyle {
  final String fontFamily;
  final double fontSize;
  final String fontColor;
  final String backgroundColor;
  final bool isBold;
  final bool isItalic;
  final String alignment; // 'left', 'center', 'right'
  final Map<String, dynamic>? additional;

  const ElementStyle({
    this.fontFamily = 'Arial',
    this.fontSize = 14.0,
    this.fontColor = '#000000',
    this.backgroundColor = 'transparent',
    this.isBold = false,
    this.isItalic = false,
    this.alignment = 'left',
    this.additional,
  });

  factory ElementStyle.fromMap(Map<String, dynamic> map) {
    return ElementStyle(
      fontFamily: (map['fontFamily'] ?? 'Arial').toString(),
      fontSize: (map['fontSize'] as num? ?? 14.0).toDouble(),
      fontColor: (map['fontColor'] ?? '#000000').toString(),
      backgroundColor: (map['backgroundColor'] ?? 'transparent').toString(),
      isBold: (map['isBold'] as bool?) ?? false,
      isItalic: (map['isItalic'] as bool?) ?? false,
      alignment: (map['alignment'] ?? 'left').toString(),
      additional: map['additional'] != null 
          ? (map['additional'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontColor': fontColor,
      'backgroundColor': backgroundColor,
      'isBold': isBold,
      'isItalic': isItalic,
      'alignment': alignment,
      'additional': additional,
    };
  }
}

class SlideLayout {
  final String name;
  final String backgroundImage;
  final String backgroundColor;
  final Map<String, ElementPosition> regions; // Named regions for content

  const SlideLayout({
    required this.name,
    this.backgroundImage = '',
    this.backgroundColor = '#FFFFFF',
    this.regions = const {},
  });

  factory SlideLayout.fromMap(Map<String, dynamic> map) {
    final regionsMap = map['regions'] as Map<String, dynamic>? ?? {};
    final regions = <String, ElementPosition>{};
    
    regionsMap.forEach((key, value) {
      regions[key.toString()] = ElementPosition.fromMap((value as Map<dynamic, dynamic>).map(
        (k, v) => MapEntry(k.toString(), v),
      ));
    });

    return SlideLayout(
      name: (map['name'] ?? 'default').toString(),
      backgroundImage: (map['backgroundImage'] ?? '').toString(),
      backgroundColor: (map['backgroundColor'] ?? '#FFFFFF').toString(),
      regions: regions,
    );
  }

  Map<String, dynamic> toMap() {
    final regionsMap = <String, dynamic>{};
    regions.forEach((key, position) {
      regionsMap[key] = position.toMap();
    });

    return {
      'name': name,
      'backgroundImage': backgroundImage,
      'backgroundColor': backgroundColor,
      'regions': regionsMap,
    };
  }
}

class PPTTheme {
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String backgroundColor;
  final String textColor;
  final String fontFamily;
  final Map<String, ElementStyle> textStyles; // For different text types

  const PPTTheme({
    required this.name,
    this.primaryColor = '#2563eb',
    this.secondaryColor = '#3b82f6',
    this.accentColor = '#059669',
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#1f2937',
    this.fontFamily = 'Arial',
    this.textStyles = const {},
  });

  factory PPTTheme.fromMap(Map<String, dynamic> map) {
    final stylesMap = map['textStyles'] as Map<String, dynamic>? ?? {};
    final textStyles = <String, ElementStyle>{};
    
    stylesMap.forEach((key, value) {
      textStyles[key.toString()] = ElementStyle.fromMap((value as Map<dynamic, dynamic>).map(
        (k, v) => MapEntry(k.toString(), v),
      ));
    });

    return PPTTheme(
      name: (map['name'] ?? 'default').toString(),
      primaryColor: (map['primaryColor'] ?? '#2563eb').toString(),
      secondaryColor: (map['secondaryColor'] ?? '#3b82f6').toString(),
      accentColor: (map['accentColor'] ?? '#059669').toString(),
      backgroundColor: (map['backgroundColor'] ?? '#FFFFFF').toString(),
      textColor: (map['textColor'] ?? '#1f2937').toString(),
      fontFamily: (map['fontFamily'] ?? 'Arial').toString(),
      textStyles: textStyles,
    );
  }

  Map<String, dynamic> toMap() {
    final stylesMap = <String, dynamic>{};
    textStyles.forEach((key, style) {
      stylesMap[key] = style.toMap();
    });

    return {
      'name': name,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontFamily': fontFamily,
      'textStyles': stylesMap,
    };
  }
}

class PPTGenerationRequest {
  final String projectSpaceId;
  final String templateId;
  final Map<String, String> customizations;
  final List<String> includeSlides;
  final List<String> excludeSlides;
  final Map<String, dynamic> projectData;
  final PPTExportOptions exportOptions;

  const PPTGenerationRequest({
    required this.projectSpaceId,
    required this.templateId,
    this.customizations = const {},
    this.includeSlides = const [],
    this.excludeSlides = const [],
    required this.projectData,
    required this.exportOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectSpaceId': projectSpaceId,
      'templateId': templateId,
      'customizations': customizations,
      'includeSlides': includeSlides,
      'excludeSlides': excludeSlides,
      'projectData': projectData,
      'exportOptions': exportOptions.toMap(),
    };
  }
}

class PPTExportOptions {
  final String format; // 'pdf', 'pptx', 'images'
  final String fileName;
  final bool includeNotes;
  final String quality; // 'low', 'medium', 'high'
  final Map<String, dynamic>? additionalOptions;

  const PPTExportOptions({
    this.format = 'pdf',
    required this.fileName,
    this.includeNotes = false,
    this.quality = 'medium',
    this.additionalOptions,
  });

  factory PPTExportOptions.fromMap(Map<String, dynamic> map) {
    return PPTExportOptions(
      format: (map['format'] ?? 'pdf').toString(),
      fileName: (map['fileName'] ?? 'presentation').toString(),
      includeNotes: (map['includeNotes'] as bool?) ?? false,
      quality: (map['quality'] ?? 'medium').toString(),
      additionalOptions: map['additionalOptions'] != null 
          ? (map['additionalOptions'] as Map<dynamic, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'format': format,
      'fileName': fileName,
      'includeNotes': includeNotes,
      'quality': quality,
      'additionalOptions': additionalOptions,
    };
  }
}

class GeneratedPPT {
  final String id;
  final String projectSpaceId;
  final String templateId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int slideCount;
  final String format;
  final DateTime generatedAt;
  final bool isShared;
  final String? downloadUrl;

  const GeneratedPPT({
    required this.id,
    required this.projectSpaceId,
    required this.templateId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.slideCount,
    required this.format,
    required this.generatedAt,
    this.isShared = false,
    this.downloadUrl,
  });

  factory GeneratedPPT.fromMap(Map<String, dynamic> map) {
    return GeneratedPPT(
      id: (map['id'] ?? '').toString(),
      projectSpaceId: (map['projectSpaceId'] ?? '').toString(),
      templateId: (map['templateId'] ?? '').toString(),
      filePath: (map['filePath'] ?? '').toString(),
      fileName: (map['fileName'] ?? '').toString(),
      fileSize: (map['fileSize'] as num? ?? 0).toInt(),
      slideCount: (map['slideCount'] as num? ?? 0).toInt(),
      format: (map['format'] ?? 'pdf').toString(),
      generatedAt: DateTime.fromMillisecondsSinceEpoch((map['generatedAt'] as num? ?? 0).toInt()),
      isShared: (map['isShared'] as bool?) ?? false,
      downloadUrl: map['downloadUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectSpaceId': projectSpaceId,
      'templateId': templateId,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'slideCount': slideCount,
      'format': format,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'isShared': isShared,
      'downloadUrl': downloadUrl,
    };
  }
}