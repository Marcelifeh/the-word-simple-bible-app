import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse_ref.dart';

class FavoriteItem {
  FavoriteItem(
      {required this.translation,
      required this.ref,
      required this.display,
      this.note});

  final BibleTranslation? translation;
  final VerseRef ref;
  final String display;
  final String? note;

  Map<String, dynamic> toJson() => {
        'translation': translation?.name,
        'bookId': ref.bookId,
        'chapter': ref.chapter,
        'verse': ref.verse,
        'display': display,
        'note': note,
      };

  static FavoriteItem fromJson(Map<String, dynamic> json,
      {BibleTranslation? translation}) {
    final tRaw = json['translation'] as String?;
    final t = translation ?? (tRaw == null ? null : _parseTranslation(tRaw));
    return FavoriteItem(
      translation: t,
      ref: VerseRef(
        bookId: json['bookId'] as String,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
      ),
      display: json['display'] as String,
      note: json['note'] as String?,
    );
  }

  static BibleTranslation? _parseTranslation(String name) {
    for (final t in BibleTranslation.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

class FavoritesRepository {
  static const _boxName = 'favorites';

  Box<dynamic>? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (_) {
      // If the box is corrupted (common after abrupt app kills), recover by
      // deleting and recreating it instead of crashing on startup.
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {
        // ignore
      }
      _box = await Hive.openBox<dynamic>(_boxName);
    }
  }

  // Expose listenable for reactive UI updates
  // Note: Must be called after init()
  ValueListenable<Box<dynamic>> get listenable {
    final box = _box;
    if (box == null) throw StateError('FavoritesRepository not initialized');
    return box.listenable();
  }

  List<FavoriteItem> list() {
    final box = _box;
    if (box == null) throw StateError('FavoritesRepository not initialized');

    final items = <FavoriteItem>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! String) continue;

      BibleTranslation? translation;
      if (key is String) {
        final idx = key.indexOf(':');
        if (idx > 0) {
          final prefix = key.substring(0, idx);
          translation = FavoriteItem._parseTranslation(prefix);
        }
      }

      try {
        final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
        items.add(FavoriteItem.fromJson(json, translation: translation));
      } catch (_) {
        // Ignore corrupt entries.
      }
    }
    return items;
  }

  bool isFavorite(
      {required BibleTranslation translation, required VerseRef ref}) {
    final box = _box;
    if (box == null) throw StateError('FavoritesRepository not initialized');
    final namespaced = _key(translation: translation, ref: ref);
    if (box.containsKey(namespaced)) return true;
    // Back-compat for legacy favorites (no translation prefix)
    return box.containsKey(ref.key);
  }

  Future<void> toggle(
      {required BibleTranslation translation,
      required VerseRef ref,
      required String display}) async {
    final box = _box;
    if (box == null) throw StateError('FavoritesRepository not initialized');

    final namespaced = _key(translation: translation, ref: ref);
    if (box.containsKey(namespaced)) {
      await box.delete(namespaced);
      return;
    }

    // If an old entry exists, remove it (we migrate forward).
    if (box.containsKey(ref.key)) {
      await box.delete(ref.key);
    }

    final item =
        FavoriteItem(translation: translation, ref: ref, display: display);
    await box.put(namespaced, jsonEncode(item.toJson()));
  }

  Future<void> upsertNote(
      {required BibleTranslation translation,
      required VerseRef ref,
      required String display,
      required String note}) async {
    final box = _box;
    if (box == null) throw StateError('FavoritesRepository not initialized');

    final namespaced = _key(translation: translation, ref: ref);
    final item = FavoriteItem(
      translation: translation,
      ref: ref,
      display: display,
      note: note.trim().isEmpty ? null : note.trim(),
    );
    await box.put(namespaced, jsonEncode(item.toJson()));

    // If we had a legacy entry, remove it to avoid confusion.
    if (box.containsKey(ref.key)) {
      await box.delete(ref.key);
    }
  }

  static String _key(
          {required BibleTranslation translation, required VerseRef ref}) =>
      '${translation.name}:${ref.key}';
}
