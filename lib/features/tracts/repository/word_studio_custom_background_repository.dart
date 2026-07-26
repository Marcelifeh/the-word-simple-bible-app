import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../model/word_studio_custom_background.dart';
import '../services/word_studio_background_storage.dart';

class WordStudioBackgroundException implements Exception {
  const WordStudioBackgroundException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WordStudioCustomBackgroundRepository extends ChangeNotifier {
  WordStudioCustomBackgroundRepository({
    WordStudioBackgroundStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ?? createWordStudioBackgroundStorage(),
        _uuid = uuid ?? const Uuid();

  static const boxName = 'word_studio_custom_backgrounds';
  static const maxBackgrounds = 20;
  static const maxFileBytes = 10 * 1024 * 1024;
  static const _privacyKey = '__privacy_acknowledged';

  final WordStudioBackgroundStorage _storage;
  final Uuid _uuid;
  final List<WordStudioCustomBackground> _backgrounds =
      <WordStudioCustomBackground>[];

  Box<dynamic>? _box;

  List<WordStudioCustomBackground> get backgrounds =>
      List<WordStudioCustomBackground>.unmodifiable(_backgrounds);

  bool get privacyAcknowledged => _box?.get(_privacyKey) == true;

  Future<void> init() async {
    _box = await _openRecovering(boxName);
    await _storage.init();
    await _load();
  }

  Future<void> acknowledgePrivacy() async {
    await _box?.put(_privacyKey, true);
  }

  Future<WordStudioCustomBackground> importImage({
    required Uint8List bytes,
    required String originalName,
    String? mimeType,
  }) async {
    if (_backgrounds.length >= maxBackgrounds) {
      throw const WordStudioBackgroundException(
        'You can save up to 20 custom backgrounds.',
      );
    }
    if (bytes.isEmpty) {
      throw const WordStudioBackgroundException(
        'The selected image could not be read.',
      );
    }
    if (bytes.length > maxFileBytes) {
      throw const WordStudioBackgroundException(
        'Choose an image smaller than 10 MB.',
      );
    }

    final id = _uuid.v4();
    final filePath = await _storage.save(
      id: id,
      extension: _extensionFor(originalName, mimeType),
      bytes: bytes,
    );
    final background = WordStudioCustomBackground(
      id: id,
      createdAtUtc: DateTime.now().toUtc(),
      displayName: _displayNameFor(originalName),
      filePath: filePath,
      bytes: bytes,
      mimeType: mimeType,
    );
    _backgrounds.add(background);
    await _persist(background);
    notifyListeners();
    return background;
  }

  Future<void> update(WordStudioCustomBackground background) async {
    final index = _backgrounds.indexWhere((item) => item.id == background.id);
    if (index < 0) return;
    _backgrounds[index] = background;
    await _persist(background);
    notifyListeners();
  }

  Future<void> rename(String id, String displayName) async {
    final normalized = displayName.trim();
    if (normalized.isEmpty) return;
    final background = _find(id);
    if (background == null) return;
    await update(
      background.copyWith(
        displayName:
            normalized.length > 50 ? normalized.substring(0, 50) : normalized,
      ),
    );
  }

  Future<WordStudioCustomBackground?> duplicate(String id) async {
    final source = _find(id);
    if (source == null || source.bytes == null) return null;
    final duplicate = await importImage(
      bytes: source.bytes!,
      originalName: '${source.displayName} copy.${_extensionFor(
        source.filePath ?? '',
        source.mimeType,
      )}',
      mimeType: source.mimeType,
    );
    final customized = duplicate.copyWith(
      overlayOpacity: source.overlayOpacity,
      scale: source.scale,
      fit: source.fit,
      alignmentX: source.alignmentX,
      alignmentY: source.alignmentY,
    );
    await update(customized);
    return customized;
  }

  Future<void> remove(String id) async {
    final background = _find(id);
    if (background == null) return;
    await _storage.delete(id: id, filePath: background.filePath);
    await _box?.delete(id);
    _backgrounds.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> close() async {
    await _storage.close();
    await _box?.close();
    _box = null;
  }

  WordStudioCustomBackground? _find(String id) {
    for (final background in _backgrounds) {
      if (background.id == id) return background;
    }
    return null;
  }

  Future<void> _load() async {
    _backgrounds.clear();
    final staleIds = <String>[];
    for (final key in _box?.keys ?? const <dynamic>[]) {
      if (key == _privacyKey) continue;
      final raw = _box?.get(key);
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final metadata = WordStudioCustomBackground.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        final bytes = await _storage.read(
          id: metadata.id,
          filePath: metadata.filePath,
        );
        if (bytes == null || bytes.isEmpty) {
          staleIds.add(metadata.id);
          continue;
        }
        _backgrounds.add(metadata.copyWith(bytes: bytes));
      } catch (_) {
        staleIds.add(key.toString());
      }
    }
    for (final id in staleIds) {
      await _box?.delete(id);
    }
    _backgrounds.sort(
      (a, b) => a.createdAtUtc.compareTo(b.createdAtUtc),
    );
    notifyListeners();
  }

  Future<void> _persist(WordStudioCustomBackground background) async {
    await _box?.put(background.id, jsonEncode(background.toJson()));
  }

  Future<Box<dynamic>> _openRecovering(String name) async {
    try {
      return await Hive.openBox<dynamic>(name);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // Let the second open report the storage failure.
      }
      return Hive.openBox<dynamic>(name);
    }
  }

  String _displayNameFor(String originalName) {
    final normalized = originalName.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final dot = fileName.lastIndexOf('.');
    final withoutExtension = dot > 0 ? fileName.substring(0, dot) : fileName;
    final displayName = withoutExtension.trim();
    if (displayName.isEmpty) {
      return 'My background ${_backgrounds.length + 1}';
    }
    return displayName.length > 50 ? displayName.substring(0, 50) : displayName;
  }

  String _extensionFor(String originalName, String? mimeType) {
    final mimeExtension = switch (mimeType?.toLowerCase()) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/jpeg' || 'image/jpg' => 'jpg',
      _ => null,
    };
    if (mimeExtension != null) return mimeExtension;

    final normalized = originalName.replaceAll('\\', '/').split('/').last;
    final dot = normalized.lastIndexOf('.');
    if (dot < 0) return 'jpg';
    return switch (normalized.substring(dot + 1).toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      'jpeg' || 'jpg' => 'jpg',
      _ => 'jpg',
    };
  }
}
