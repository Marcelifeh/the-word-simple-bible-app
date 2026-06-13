import 'dart:io';

class SermonAudioFileService {
  const SermonAudioFileService();

  Future<int?> sizeBytes(String? path) async {
    final file = _localFile(path);
    if (file == null) return null;
    try {
      if (!await file.exists()) return null;
      return file.length();
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String? path) async {
    final file = _localFile(path);
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Audio cleanup should never block note deletion.
    }
  }

  File? _localFile(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final value = path.trim();
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:')) {
      return null;
    }
    return File(value);
  }
}
