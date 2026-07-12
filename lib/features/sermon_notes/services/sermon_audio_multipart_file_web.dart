import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

Future<http.MultipartFile> sermonAudioMultipartFile(String audioPath) async {
  try {
    final response = await web.window.fetch(audioPath.toJS).toDart;
    if (!response.ok) {
      throw Exception('status ${response.status}');
    }

    final contentType = response.headers.get('content-type') ?? '';
    final arrayBuffer = await response.arrayBuffer().toDart;
    final bytes = arrayBuffer.toDart.asUint8List();

    if (bytes.isEmpty) {
      throw Exception('audio blob is empty');
    }

    return http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: _filenameFor(audioPath, contentType),
    );
  } catch (e) {
    throw Exception('Could not read web audio blob for upload: $e');
  }
}

String _filenameFor(String audioPath, String contentType) {
  final path = Uri.tryParse(audioPath)?.path;
  if (path != null && path.contains('.')) {
    final name = path.split('/').last;
    if (name.trim().isNotEmpty) return name;
  }

  final normalizedType = contentType.toLowerCase();
  if (normalizedType.contains('mp4')) return 'sermon.mp4';
  if (normalizedType.contains('mpeg')) return 'sermon.mp3';
  if (normalizedType.contains('wav')) return 'sermon.wav';
  if (normalizedType.contains('ogg')) return 'sermon.ogg';
  if (normalizedType.contains('webm')) return 'sermon.webm';
  return 'sermon.m4a';
}
