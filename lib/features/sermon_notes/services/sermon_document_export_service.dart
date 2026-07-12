import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/sermon_note.dart';
import '../utils/scripture_parser.dart';

class SermonDocumentFile {
  const SermonDocumentFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

class SermonDocumentExportService {
  const SermonDocumentExportService();

  Future<SermonDocumentFile> buildPdf(SermonNote note) async {
    final document = _SermonDocument.fromNote(note);
    final pdf = pw.Document();
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    final headingStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(36),
          pageFormat: PdfPageFormat.letter,
        ),
        build: (context) => [
          pw.Text(document.title, style: titleStyle),
          if (document.preacher.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Preacher: ${document.preacher}'),
          ],
          pw.SizedBox(height: 4),
          pw.Text('Date: ${document.dateLabel}'),
          pw.SizedBox(height: 18),
          _pdfTextSection(
              'Main Scripture', document.mainScripture, headingStyle),
          _pdfTextSection('Introduction', document.introduction, headingStyle),
          _pdfListSection(
              'Sermon Outline', document.sermonOutline, headingStyle),
          _pdfListSection('Key Points', document.keyPoints, headingStyle),
          _pdfListSection(
            'Scriptures Mentioned',
            document.scripturesMentioned,
            headingStyle,
          ),
          _pdfTextSection('Summary', document.summary, headingStyle),
          _pdfListOrTextSection(
            'Reflection / Application',
            document.reflectionItems,
            document.reflectionText,
            headingStyle,
          ),
          _pdfListOrTextSection(
            'Closing Prayer',
            document.closingPrayerItems,
            document.closingPrayerText,
            headingStyle,
          ),
        ],
      ),
    );

    return SermonDocumentFile(
      name: '${document.fileBaseName}.pdf',
      mimeType: 'application/pdf',
      bytes: await pdf.save(),
    );
  }

  SermonDocumentFile buildDocx(SermonNote note) {
    final document = _SermonDocument.fromNote(note);
    final body = StringBuffer()
      ..write(_docxParagraph(document.title, style: 'Title'))
      ..write(_docxParagraph('Preacher: ${document.preacher}'))
      ..write(_docxParagraph('Date: ${document.dateLabel}'))
      ..write(_docxHeading('Main Scripture'))
      ..write(_docxParagraph(document.mainScripture))
      ..write(_docxHeading('Introduction'))
      ..write(_docxParagraph(document.introduction))
      ..write(_docxHeading('Sermon Outline'))
      ..writeAll(document.sermonOutline.map(_docxBullet))
      ..write(_docxHeading('Key Points'))
      ..writeAll(document.keyPoints.map(_docxBullet))
      ..write(_docxHeading('Scriptures Mentioned'))
      ..writeAll(document.scripturesMentioned.map(_docxBullet))
      ..write(_docxHeading('Summary'))
      ..write(_docxParagraph(document.summary))
      ..write(_docxHeading('Reflection / Application'));

    if (document.reflectionItems.isEmpty) {
      body.write(_docxParagraph(document.reflectionText));
    } else {
      body.writeAll(document.reflectionItems.map(_docxBullet));
    }

    body.write(_docxHeading('Closing Prayer'));
    if (document.closingPrayerItems.isEmpty) {
      body.write(_docxParagraph(document.closingPrayerText));
    } else {
      body.writeAll(document.closingPrayerItems.map(_docxBullet));
    }

    final archive = Archive()
      ..addFile(_archiveFile(
        '[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''',
      ))
      ..addFile(_archiveFile(
        '_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''',
      ))
      ..addFile(_archiveFile(
        'word/document.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$body<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body></w:document>''',
      ));

    final encoded = ZipEncoder().encode(archive) ?? const <int>[];
    return SermonDocumentFile(
      name: '${document.fileBaseName}.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      bytes: Uint8List.fromList(encoded),
    );
  }

  pw.Widget _pdfTextSection(
    String title,
    String text,
    pw.TextStyle headingStyle,
  ) {
    if (text.trim().isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: headingStyle),
          pw.SizedBox(height: 4),
          pw.Text(text.trim()),
        ],
      ),
    );
  }

  pw.Widget _pdfListSection(
    String title,
    List<String> items,
    pw.TextStyle headingStyle,
  ) {
    if (items.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: headingStyle),
          pw.SizedBox(height: 4),
          for (final item in items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('- '),
                  pw.Expanded(child: pw.Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfListOrTextSection(
    String title,
    List<String> items,
    String text,
    pw.TextStyle headingStyle,
  ) {
    if (items.isNotEmpty) return _pdfListSection(title, items, headingStyle);
    return _pdfTextSection(title, text, headingStyle);
  }

  ArchiveFile _archiveFile(String name, String content) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return ArchiveFile(name, bytes.length, bytes);
  }

  String _docxHeading(String text) {
    return _docxParagraph(text, style: 'Heading1');
  }

  String _docxBullet(String text) {
    return _docxParagraph('- $text');
  }

  String _docxParagraph(String text, {String? style}) {
    final styleXml =
        style == null ? '' : '<w:pPr><w:pStyle w:val="$style"/></w:pPr>';
    final lines =
        text.trim().isEmpty ? [''] : text.trim().split(RegExp(r'\r?\n'));
    final runs = lines
        .map((line) =>
            '<w:r><w:t xml:space="preserve">${_xml(line)}</w:t></w:r>')
        .join('<w:r><w:br/></w:r>');
    return '<w:p>$styleXml$runs</w:p>';
  }

  String _xml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _SermonDocument {
  const _SermonDocument({
    required this.title,
    required this.preacher,
    required this.dateLabel,
    required this.fileBaseName,
    required this.mainScripture,
    required this.introduction,
    required this.sermonOutline,
    required this.keyPoints,
    required this.scripturesMentioned,
    required this.summary,
    required this.reflectionText,
    required this.reflectionItems,
    required this.closingPrayerText,
    required this.closingPrayerItems,
  });

  final String title;
  final String preacher;
  final String dateLabel;
  final String fileBaseName;
  final String mainScripture;
  final String introduction;
  final List<String> sermonOutline;
  final List<String> keyPoints;
  final List<String> scripturesMentioned;
  final String summary;
  final String reflectionText;
  final List<String> reflectionItems;
  final String closingPrayerText;
  final List<String> closingPrayerItems;

  factory _SermonDocument.fromNote(SermonNote note) {
    final insight = note.insight;
    final outline = note.outline;
    final parsedScriptures = ScriptureParser.extractScriptures(
      '${note.content}\n${note.transcript ?? ''}\n${note.summary ?? ''}',
    ).map((scripture) => scripture.displayTitle);
    final scriptures = _unique([
      if (outline?.mainText.trim().isNotEmpty ?? false) outline!.mainText,
      ...?outline?.supportingScriptures,
      ...?insight?.scripturesMentioned,
      ...parsedScriptures,
    ]);
    final title = _firstNonEmpty([
      outline?.title,
      insight?.title,
      note.title,
      'Sermon Document',
    ]);

    return _SermonDocument(
      title: title,
      preacher: note.preacher.trim(),
      dateLabel: DateFormat.yMMMd().format(note.date),
      fileBaseName: _fileBaseName(title),
      mainScripture: _firstNonEmpty([
        outline?.mainText,
        scriptures.isEmpty ? null : scriptures.first,
      ]),
      introduction: outline?.introduction.trim() ?? '',
      sermonOutline: outline?.mainPoints ?? const <String>[],
      keyPoints: insight?.keyLessons ?? const <String>[],
      scripturesMentioned: scriptures,
      summary: _firstNonEmpty([
        note.summary,
        insight?.mainTheme,
        insight?.shortDevotional,
      ]),
      reflectionText: outline?.lifeApplication.trim() ?? '',
      reflectionItems: insight?.actionSteps ?? const <String>[],
      closingPrayerText: outline?.closingPrayer.trim() ?? '',
      closingPrayerItems: insight?.prayerPoints ?? const <String>[],
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final output = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) continue;
      output.add(trimmed);
    }
    return output;
  }

  static String _fileBaseName(String title) {
    final safe = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = safe.isEmpty ? 'sermon-document' : safe;
    return base.length > 48 ? base.substring(0, 48) : base;
  }
}
