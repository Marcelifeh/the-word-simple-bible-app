import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../model/sermon_note.dart';

class SermonDraftRepository {
  static const _boxName = 'sermon_note_drafts';
  static const _activeDraftKey = 'active_sermon_draft';

  Box<dynamic>? _box;
  Future<void>? _initFuture;

  bool get isInitialized => _box != null;

  Future<void> init() async {
    if (_box != null) return;
    final existing = _initFuture;
    if (existing != null) return existing;

    final future = _openBox();
    _initFuture = future;
    try {
      await future;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> ensureInitialized() => init();

  Future<void> _openBox() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {
        // ignore
      }
      _box = await Hive.openBox<dynamic>(_boxName);
    }
  }

  SermonNote? getActiveDraft() {
    final box = _box;
    if (box == null) throw StateError('SermonDraftRepository not initialized');

    final raw = box.get(_activeDraftKey);
    if (raw is! String) return null;

    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return SermonNote.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveDraft(SermonNote note) async {
    final box = _box;
    if (box == null) throw StateError('SermonDraftRepository not initialized');
    await box.put(_activeDraftKey, jsonEncode(note.toJson()));
  }

  Future<void> clearActiveDraft() async {
    final box = _box;
    if (box == null) throw StateError('SermonDraftRepository not initialized');
    await box.delete(_activeDraftKey);
  }
}
