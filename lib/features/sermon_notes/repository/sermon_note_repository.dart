import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/sermon_note.dart';
import '../services/sermon_audio_file_service.dart';

class SermonNoteRepository {
  static const _boxName = 'sermon_notes';

  final SermonAudioFileService _audioFileService =
      const SermonAudioFileService();
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

  ValueListenable<Box<dynamic>> get listenable {
    final box = _box;
    if (box == null) throw StateError('SermonNoteRepository not initialized');
    return box.listenable();
  }

  List<SermonNote> list() {
    final box = _box;
    if (box == null) throw StateError('SermonNoteRepository not initialized');

    final notes = <SermonNote>[];
    for (final raw in box.values) {
      if (raw is! String) continue;
      try {
        final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
        notes.add(SermonNote.fromJson(json));
      } catch (_) {
        // Ignore corrupt entries.
      }
    }

    notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return notes;
  }

  Future<void> saveNote(SermonNote note) async {
    final box = _box;
    if (box == null) throw StateError('SermonNoteRepository not initialized');
    await box.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> updateNote(SermonNote note) => saveNote(note);

  Future<void> deleteNote(String id) async {
    final box = _box;
    if (box == null) throw StateError('SermonNoteRepository not initialized');
    final raw = box.get(id);
    if (raw is String) {
      try {
        final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
        final note = SermonNote.fromJson(json);
        await _audioFileService.delete(note.audioPath);
      } catch (_) {
        // Note deletion should still proceed even if cleanup metadata is stale.
      }
    }
    await box.delete(id);
  }
}
