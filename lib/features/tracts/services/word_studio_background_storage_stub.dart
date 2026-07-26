import 'dart:typed_data';

import 'word_studio_background_storage_base.dart';

class _MemoryWordStudioBackgroundStorage
    implements WordStudioBackgroundStorage {
  final Map<String, Uint8List> _bytesById = <String, Uint8List>{};

  @override
  Future<void> init() async {}

  @override
  Future<String?> save({
    required String id,
    required String extension,
    required Uint8List bytes,
  }) async {
    _bytesById[id] = bytes;
    return null;
  }

  @override
  Future<Uint8List?> read({
    required String id,
    String? filePath,
  }) async {
    return _bytesById[id];
  }

  @override
  Future<void> delete({
    required String id,
    String? filePath,
  }) async {
    _bytesById.remove(id);
  }

  @override
  Future<void> close() async {
    _bytesById.clear();
  }
}

WordStudioBackgroundStorage createWordStudioBackgroundStorage() {
  return _MemoryWordStudioBackgroundStorage();
}
