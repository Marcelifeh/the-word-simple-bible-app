import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'word_studio_background_storage_base.dart';

class _WebWordStudioBackgroundStorage implements WordStudioBackgroundStorage {
  static const _boxName = 'word_studio_custom_background_files';

  Box<dynamic>? _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  @override
  Future<String?> save({
    required String id,
    required String extension,
    required Uint8List bytes,
  }) async {
    await _box?.put(id, bytes);
    return null;
  }

  @override
  Future<Uint8List?> read({
    required String id,
    String? filePath,
  }) async {
    final value = _box?.get(id);
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  @override
  Future<void> delete({
    required String id,
    String? filePath,
  }) async {
    await _box?.delete(id);
  }

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

WordStudioBackgroundStorage createWordStudioBackgroundStorage() {
  return _WebWordStudioBackgroundStorage();
}
