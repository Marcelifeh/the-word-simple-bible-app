import 'dart:typed_data';

abstract interface class WordStudioBackgroundStorage {
  Future<void> init();

  Future<String?> save({
    required String id,
    required String extension,
    required Uint8List bytes,
  });

  Future<Uint8List?> read({
    required String id,
    String? filePath,
  });

  Future<void> delete({
    required String id,
    String? filePath,
  });

  Future<void> close();
}
