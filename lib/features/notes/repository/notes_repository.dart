import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/verse_note.dart';

class NotesRepository {
  static const _boxName = 'notes';
  Box<VerseNote>? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<VerseNote>(_boxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {}
      _box = await Hive.openBox<VerseNote>(_boxName);
    }
  }

  void save(VerseNote note) {
    _box?.put(note.verseId, note);
  }

  VerseNote? get(String verseId) {
    return _box?.get(verseId);
  }

  List<VerseNote> getAll() {
    return _box?.values.toList() ?? [];
  }

  void delete(String verseId) {
    _box?.delete(verseId);
  }

  /// Reactive listenable — rebuild the UI automatically when notes change.
  ValueListenable<Box<VerseNote>>? get listenable => _box?.listenable();
}
