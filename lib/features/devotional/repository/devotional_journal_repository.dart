import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/devotional_journal_entry.dart';

class DevotionalJournalRepository {
  static const _boxName = 'devotional_journal';
  Box<DevotionalJournalEntry>? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<DevotionalJournalEntry>(_boxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {}
      _box = await Hive.openBox<DevotionalJournalEntry>(_boxName);
    }
  }

  /// All saved entries, newest first.
  List<DevotionalJournalEntry> getAll() {
    final list = _box?.values.toList() ?? [];
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  void save(DevotionalJournalEntry entry) {
    _box?.put(entry.id, entry);
  }

  void delete(String id) {
    _box?.delete(id);
  }

  /// Returns a [ValueListenable] so the UI can rebuild reactively.
  ValueListenable<Box<DevotionalJournalEntry>>? get listenable =>
      _box?.listenable();
}
