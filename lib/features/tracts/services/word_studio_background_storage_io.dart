import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'word_studio_background_storage_base.dart';

class _IoWordStudioBackgroundStorage implements WordStudioBackgroundStorage {
  Directory? _directory;

  @override
  Future<void> init() async {
    final documents = await getApplicationDocumentsDirectory();
    _directory = Directory(
      '${documents.path}${Platform.pathSeparator}word_studio'
      '${Platform.pathSeparator}backgrounds',
    );
    await _directory!.create(recursive: true);
  }

  @override
  Future<String> save({
    required String id,
    required String extension,
    required Uint8List bytes,
  }) async {
    final directory = _directory;
    if (directory == null) {
      throw StateError('Word Studio background storage is not initialized');
    }
    final normalizedExtension = _safeExtension(extension);
    final file = File(
      '${directory.path}${Platform.pathSeparator}bg_$id.$normalizedExtension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<Uint8List?> read({
    required String id,
    String? filePath,
  }) async {
    if (filePath == null || filePath.isEmpty) return null;
    final file = File(filePath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> delete({
    required String id,
    String? filePath,
  }) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> close() async {}

  String _safeExtension(String value) {
    return switch (value.toLowerCase()) {
      'jpeg' => 'jpg',
      'jpg' || 'png' || 'webp' => value.toLowerCase(),
      _ => 'jpg',
    };
  }
}

WordStudioBackgroundStorage createWordStudioBackgroundStorage() {
  return _IoWordStudioBackgroundStorage();
}
