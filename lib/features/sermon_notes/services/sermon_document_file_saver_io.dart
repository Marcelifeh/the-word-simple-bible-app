import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'sermon_document_export_service.dart';

Future<List<String>> saveSermonDocumentFiles(
  List<SermonDocumentFile> files,
) async {
  Directory directory;
  try {
    directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
  } catch (_) {
    directory = await getApplicationDocumentsDirectory();
  }

  final outputDirectory = Directory(
    '${directory.path}${Platform.pathSeparator}The Word Sermons',
  );
  await outputDirectory.create(recursive: true);

  final paths = <String>[];
  for (final file in files) {
    final outputFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}${file.name}',
    );
    await outputFile.writeAsBytes(file.bytes, flush: true);
    paths.add(outputFile.path);
  }
  return paths;
}
