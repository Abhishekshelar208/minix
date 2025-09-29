import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;
import 'dart:ui';
import 'package:minix/models/document_template.dart';
import 'package:minix/models/citation.dart';

class ExportService {
  
  // Export document to PDF
  Future<String> exportToPdf({
    required String content,
    required String fileName,
    DocumentTemplate? template,
    Bibliography? bibliography,
  }) async {
    try {
      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      
      // Set document properties
      document.documentInformation.title = fileName;
      document.documentInformation.creator = 'MINIX Documentation Generator';
      document.documentInformation.creationDate = DateTime.now();
      
      // Get formatting from template or use defaults
      final formatting = template?.formatting ?? DocumentFormatting();
      
      // Create font styles
      final PdfStandardFont titleFont = PdfStandardFont(
        PdfFontFamily.timesRoman,
        formatting.fontSize + 4,
        style: PdfFontStyle.bold,
      );
      
      final PdfStandardFont headingFont = PdfStandardFont(
        PdfFontFamily.timesRoman,
        formatting.fontSize + 2,
        style: PdfFontStyle.bold,
      );
      
      final PdfStandardFont bodyFont = PdfStandardFont(
        PdfFontFamily.timesRoman,
        formatting.fontSize,
      );
      
      // Parse HTML content to extract structured text
      final parsedContent = _parseHtmlContent(content);
      
      // Create pages and add content
      double yPosition = 50;
      PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;
      
      // Set page margins
      final double leftMargin = ((formatting.margins['left'] as num?) ?? 1.0).toDouble() * 72; // Convert inches to points
      final double rightMargin = ((formatting.margins['right'] as num?) ?? 1.0).toDouble() * 72;
      final double topMargin = ((formatting.margins['top'] as num?) ?? 1.0).toDouble() * 72;
      final double bottomMargin = ((formatting.margins['bottom'] as num?) ?? 1.0).toDouble() * 72;
      
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;
      final double contentWidth = pageWidth - leftMargin - rightMargin;
      
      // Add content to PDF
      for (final section in parsedContent) {
        // Check if we need a new page
        if (yPosition > pageHeight - bottomMargin - 100) {
          page = document.pages.add();
          graphics = page.graphics;
          yPosition = topMargin;
        }
        
        switch (section.type) {
          case 'title':
            yPosition = _addTitle(graphics, section.text, leftMargin, yPosition, contentWidth, titleFont);
            break;
          case 'heading':
            yPosition = _addHeading(graphics, section.text, leftMargin, yPosition, contentWidth, headingFont);
            break;
          case 'paragraph':
            yPosition = _addParagraph(graphics, section.text, leftMargin, yPosition, contentWidth, bodyFont, formatting.lineHeight);
            break;
          case 'list':
            yPosition = _addList(graphics, section.items ?? [], leftMargin, yPosition, contentWidth, bodyFont, formatting.lineHeight);
            break;
        }
        
        yPosition += 20; // Add spacing between sections
      }
      
      // Add bibliography if provided
      if (bibliography != null && bibliography.citations.isNotEmpty) {
        // Check if we need a new page for bibliography
        if (yPosition > pageHeight - bottomMargin - 200) {
          page = document.pages.add();
          graphics = page.graphics;
          yPosition = topMargin;
        }
        
        yPosition = _addHeading(graphics, 'References', leftMargin, yPosition, contentWidth, headingFont);
        yPosition += 20;
        
        final bibText = bibliography.generateBibliography();
        yPosition = _addParagraph(graphics, bibText, leftMargin, yPosition, contentWidth, bodyFont, formatting.lineHeight);
      }
      
      // Add page numbers
      _addPageNumbers(document);
      
      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();
      
      // Save to file
      final String filePath = await _saveToFile(bytes, '$fileName.pdf');
      
      return filePath;
    } catch (e) {
      debugPrint('Failed to export to PDF: $e');
      rethrow;
    }
  }
  
  // Export document to Word format (simplified HTML-based approach)
  Future<String> exportToWord({
    required String content,
    required String fileName,
    DocumentTemplate? template,
    Bibliography? bibliography,
  }) async {
    try {
      final formatting = template?.formatting ?? DocumentFormatting();
      
      // Create Word-compatible HTML document
      final StringBuffer wordHtml = StringBuffer();
      
      // Add HTML header with styles
      wordHtml.writeln('<!DOCTYPE html>');
      wordHtml.writeln('<html>');
      wordHtml.writeln('<head>');
      wordHtml.writeln('<meta charset="UTF-8">');
      wordHtml.writeln('<title>$fileName</title>');
      wordHtml.writeln('<style>');
      wordHtml.writeln(_generateWordStyles(formatting));
      wordHtml.writeln('</style>');
      wordHtml.writeln('</head>');
      wordHtml.writeln('<body>');
      
      // Add content
      wordHtml.writeln(_processContentForWord(content));
      
      // Add bibliography if provided
      if (bibliography != null && bibliography.citations.isNotEmpty) {
        wordHtml.writeln('<div class="page-break"></div>');
        wordHtml.writeln('<h2>References</h2>');
        wordHtml.writeln('<div class="bibliography">');
        
        final bibText = bibliography.generateBibliography();
        final bibLines = bibText.split('\n');
        for (final line in bibLines) {
          if (line.trim().isNotEmpty) {
            wordHtml.writeln('<p class="reference">$line</p>');
          }
        }
        
        wordHtml.writeln('</div>');
      }
      
      wordHtml.writeln('</body>');
      wordHtml.writeln('</html>');
      
      // Save as HTML file that Word can open
      final String filePath = await _saveToFile(
        wordHtml.toString().codeUnits,
        '$fileName.html',
      );
      
      return filePath;
    } catch (e) {
      debugPrint('Failed to export to Word: $e');
      rethrow;
    }
  }
  
  // Share exported document
  Future<void> shareDocument(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint('Failed to share document: $e');
      rethrow;
    }
  }
  
  // Parse HTML content into structured sections
  List<ContentSection> _parseHtmlContent(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final sections = <ContentSection>[];
    
    // Extract title
    final title = document.querySelector('h1')?.text;
    if (title != null && title.isNotEmpty) {
      sections.add(ContentSection(type: 'title', text: title));
    }
    
    // Extract headings and paragraphs
    final elements = document.querySelectorAll('h1, h2, h3, h4, h5, h6, p, ul, ol');
    
    for (final element in elements) {
      switch (element.localName) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          if (element.text != title) { // Skip title if already added
            sections.add(ContentSection(type: 'heading', text: element.text));
          }
          break;
        case 'p':
          if (element.text.isNotEmpty) {
            sections.add(ContentSection(type: 'paragraph', text: element.text));
          }
          break;
        case 'ul':
        case 'ol':
          final items = element.querySelectorAll('li').map((li) => li.text).toList();
          sections.add(ContentSection(type: 'list', items: items));
          break;
      }
    }
    
    return sections;
  }
  
  // Add title to PDF
  double _addTitle(PdfGraphics graphics, String text, double x, double y, double width, PdfFont font) {
    graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(x, y, width, 50),
    );
    
    return y + 50; // Estimate title height
  }
  
  // Add heading to PDF
  double _addHeading(PdfGraphics graphics, String text, double x, double y, double width, PdfFont font) {
    graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(x, y, width, 30),
    );
    
    return y + 30; // Estimate heading height
  }
  
  // Add paragraph to PDF
  double _addParagraph(PdfGraphics graphics, String text, double x, double y, double width, PdfFont font, double lineHeight) {
    graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(x, y, width, 100),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.justify,
        lineAlignment: PdfVerticalAlignment.top,
        lineSpacing: lineHeight,
      ),
    );
    
    return y + (text.length / 80 * 15).round() + 10; // Estimate paragraph height
  }
  
  // Add list to PDF
  double _addList(PdfGraphics graphics, List<String> items, double x, double y, double width, PdfFont font, double lineHeight) {
    double currentY = y;
    
    for (int i = 0; i < items.length; i++) {
      final bulletText = '• ${items[i]}';
      graphics.drawString(
        bulletText,
        font,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(x, currentY, width, 50),
      );
      
      currentY += 20; // Estimate line height
    }
    
    return currentY;
  }
  
  // Add page numbers to PDF
  void _addPageNumbers(PdfDocument document) {
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 10);
    
    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final pageNumber = '${i + 1}';
      
      page.graphics.drawString(
        pageNumber,
        font,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(
          page.getClientSize().width - 50,
          page.getClientSize().height - 30,
          40,
          20,
        ),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }
  }
  
  // Generate CSS styles for Word export
  String _generateWordStyles(DocumentFormatting formatting) {
    return '''
      @page {
        margin: ${formatting.margins['top']}in ${formatting.margins['right']}in ${formatting.margins['bottom']}in ${formatting.margins['left']}in;
      }
      
      body {
        font-family: "${formatting.fontFamily}";
        font-size: ${formatting.fontSize}pt;
        line-height: ${formatting.lineHeight};
        color: #000000;
      }
      
      h1 {
        font-size: ${formatting.fontSize + 4}pt;
        font-weight: bold;
        text-align: center;
        margin-bottom: 24pt;
      }
      
      h2 {
        font-size: ${formatting.fontSize + 2}pt;
        font-weight: bold;
        margin-top: 18pt;
        margin-bottom: 12pt;
      }
      
      h3 {
        font-size: ${formatting.fontSize + 1}pt;
        font-weight: bold;
        margin-top: 14pt;
        margin-bottom: 8pt;
      }
      
      p {
        text-align: justify;
        margin-bottom: 12pt;
      }
      
      .bibliography {
        margin-top: 24pt;
      }
      
      .reference {
        margin-bottom: 6pt;
        padding-left: 22pt;
        text-indent: -22pt;
      }
      
      .page-break {
        page-break-before: always;
      }
      
      ul, ol {
        margin-bottom: 12pt;
      }
      
      li {
        margin-bottom: 6pt;
      }
    ''';
  }
  
  // Process content for Word export
  String _processContentForWord(String content) {
    // Clean up content for Word compatibility
    String processedContent = content;
    
    // Convert markdown-style headers to HTML
    processedContent = processedContent.replaceAllMapped(
      RegExp(r'^#{1}\s+(.+)$', multiLine: true),
      (match) => '<h1>${match.group(1)}</h1>',
    );
    
    processedContent = processedContent.replaceAllMapped(
      RegExp(r'^#{2}\s+(.+)$', multiLine: true),
      (match) => '<h2>${match.group(1)}</h2>',
    );
    
    processedContent = processedContent.replaceAllMapped(
      RegExp(r'^#{3}\s+(.+)$', multiLine: true),
      (match) => '<h3>${match.group(1)}</h3>',
    );
    
    // Convert line breaks to paragraphs
    final lines = processedContent.split('\n');
    final processedLines = <String>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('<')) {
        processedLines.add('<p>$trimmedLine</p>');
      } else if (trimmedLine.startsWith('<')) {
        processedLines.add(trimmedLine);
      }
    }
    
    return processedLines.join('\n');
  }
  
  // Save bytes to file
  Future<String> _saveToFile(List<int> bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Failed to save file: $e');
      rethrow;
    }
  }
}

// Helper class for content sections
class ContentSection {
  final String type;
  final String text;
  final List<String>? items;
  
  ContentSection({
    required this.type,
    this.text = '',
    this.items,
  });
}