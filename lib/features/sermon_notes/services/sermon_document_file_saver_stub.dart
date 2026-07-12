import 'sermon_document_export_service.dart';

Future<List<String>> saveSermonDocumentFiles(
  List<SermonDocumentFile> files,
) async {
  throw UnsupportedError(
    'Saving sermon documents is not supported on this platform. Use Share Sermon Document instead.',
  );
}
