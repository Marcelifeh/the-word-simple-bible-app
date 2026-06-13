import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

Future<http.MultipartFile> sermonAudioMultipartFile(String audioPath) async {
  final response = await web.window.fetch(audioPath.toJS).toDart;
  if (!response.ok) {
    throw Exception('Could not read sermon audio for upload.');
  }

  final arrayBuffer = await response.arrayBuffer().toDart;
  final bytes = arrayBuffer.toDart.asUint8List();

  return http.MultipartFile.fromBytes(
    'file',
    bytes,
    filename: _filenameFor(audioPath),
  );
}

String _filenameFor(String audioPath) {
  final path = Uri.tryParse(audioPath)?.path;
  if (path != null && path.contains('.')) {
    final name = path.split('/').last;
    if (name.trim().isNotEmpty) return name;
  }
  return 'sermon.webm';
}
