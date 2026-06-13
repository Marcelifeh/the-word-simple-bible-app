import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/verse_ref.dart';
import 'book_catalog.dart';
import 'bible_asset_paths.dart';
import 'bible_repository.dart';

class BibleAssetRepository implements BibleRepository {
  final _allCache = <BibleTranslation, List<Verse>>{};
  final _chapterCache = <String, List<Verse>>{};
  static const int _maxCacheEntries = 50;

  void _putCache(String key, List<Verse> verses) {
    if (_chapterCache.length >= _maxCacheEntries) {
      _chapterCache.remove(_chapterCache.keys.first);
    }
    _chapterCache[key] = verses;
  }

  /// Returns true if the given asset path already has a warm cache entry.
  bool isChapterCached(String path) => _chapterCache.containsKey(path);

  Set<String>? _assetKeys;
  final _chapterAssetsCache = <BibleTranslation, Set<String>>{};

  Future<List<Verse>> loadAllVerses(BibleTranslation t) async {
    final cached = _allCache[t];
    if (cached != null) return cached;

    if (t == BibleTranslation.kjv) {
      final verses = await _loadFullKJV();
      if (verses.isNotEmpty) {
        _allCache[t] = verses;
        return verses;
      }
    }

    final chapterAssets = await _chapterAssetsFor(t);
    if (chapterAssets.isNotEmpty) {
      final verses = <Verse>[];
      final keys = chapterAssets.toList()..sort();
      for (final path in keys) {
        final chunk = await _loadChapterAsset(path);
        verses.addAll(chunk);
      }
      final frozen = List<Verse>.unmodifiable(verses);
      _allCache[t] = frozen;
      return frozen;
    }

    final legacy = BibleAssetPaths.legacyAllVersesPath(t);
    if (legacy == null) {
      _allCache[t] = const [];
      return const [];
    }

    final raw = await rootBundle.loadString(legacy);
    final decoded = jsonDecode(raw);
    final list = (decoded as List)
        .cast<Map<String, dynamic>>()
        .map(Verse.fromJson)
        .toList(growable: false);

    _allCache[t] = list;
    return list;
  }

  @override
  Future<List<Verse>> loadChapter({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  }) async {
    final directPath = _chapterPath(
        translation: translation, bookId: bookId, chapter: chapter);
    if (directPath != null) {
      try {
        final verses = await _loadChapterAsset(directPath);
        if (verses.isNotEmpty) {
          if (translation == BibleTranslation.kjv) return verses;
          return await _applyCanonicalBackfill(
              translation, verses, bookId, chapter);
        }
      } catch (_) {
        // fall back
      }
    }

    final all = await loadAllVerses(translation);
    final raw = all
        .where((v) => v.ref.bookId == bookId && v.ref.chapter == chapter)
        .toList(growable: false);
    if (translation == BibleTranslation.kjv) return raw;
    return await _applyCanonicalBackfill(translation, raw, bookId, chapter);
  }

  Future<List<Verse>> _applyCanonicalBackfill(
    BibleTranslation actualTranslation,
    List<Verse> verses,
    String bookId,
    int chapter,
  ) async {
    if (verses.isEmpty) return verses;

    // Use the KJV chapter file directly as the canonical verse-count reference.
    // This avoids recursion and keeps the function safe without additional parameters.
    int maxVerse = 0;
    try {
      final kjvPath = _chapterPath(
        translation: BibleTranslation.kjv,
        bookId: bookId,
        chapter: chapter,
      );
      if (kjvPath != null) {
        final kjvVerses = await _loadChapterAsset(kjvPath);
        if (kjvVerses.isNotEmpty) {
          maxVerse = kjvVerses.last.ref.verse;
        }
      }
    } catch (_) {}

    if (maxVerse == 0) {
      maxVerse = verses.fold<int>(
          0, (max, v) => v.ref.verse > max ? v.ref.verse : max);
    }

    if (verses.length == maxVerse) return verses;

    final sorted = List.of(verses)
      ..sort((a, b) => a.ref.verse.compareTo(b.ref.verse));
    final backfilled = <Verse>[];
    String bookName = verses.first.book;

    for (int i = 1; i <= maxVerse; i++) {
      final existing = sorted.where((v) => v.ref.verse == i).toList();
      if (existing.isNotEmpty) {
        backfilled.add(existing.first);
      } else {
        backfilled.add(Verse(
          ref: VerseRef(bookId: bookId, chapter: chapter, verse: i),
          book: bookName,
          text: 'This verse is not available in this translation.',
          isFallback: true,
        ));
      }
    }
    return backfilled;
  }

  Future<Set<String>> listChapterAssetPaths(BibleTranslation translation) =>
      _chapterAssetsFor(translation);

  Future<List<Verse>> loadChapterByAssetPath(String assetPath) =>
      _loadChapterAsset(assetPath);

  @override
  Future<List<Verse>> searchKeyword({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final chapterAssets = await _chapterAssetsFor(translation);
    if (chapterAssets.isEmpty) {
      final all = await loadAllVerses(translation);
      return all
          .where((v) => v.text.toLowerCase().contains(q))
          .take(limit)
          .toList(growable: false);
    }

    final hits = <Verse>[];
    final keys = chapterAssets.toList()..sort();
    for (final path in keys) {
      final chunk = await _loadChapterAsset(path);
      for (final v in chunk) {
        if (v.text.toLowerCase().contains(q)) {
          hits.add(v);
          if (hits.length >= limit) return List<Verse>.unmodifiable(hits);
        }
      }
    }

    return List<Verse>.unmodifiable(hits);
  }

  String? _chapterPath({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  }) {
    final root = BibleAssetPaths.chapterRoot(translation);
    if (root == null) return null;

    // WEB folders don't have underscores (e.g. 1samuel instead of 1_samuel)
    // and Song of Solomon is songofsolomon
    var normalizedId = bookId;
    if (translation == BibleTranslation.web) {
      normalizedId = bookId.replaceAll('_', '');
      if (normalizedId == 'songofsongs') normalizedId = 'songofsolomon';
    }

    return '$root/$normalizedId/$chapter.json';
  }

  Future<List<Verse>> _loadChapterAsset(String path) async {
    final cached = _chapterCache[path];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);

    List<Verse> verses;
    if (decoded is List) {
      verses = decoded
          .cast<Map<String, dynamic>>()
          .map(Verse.fromJson)
          .toList(growable: false);
    } else if (decoded is Map) {
      final map = decoded.cast<String, dynamic>();
      final bookId = _normalizeBookId(map['bookId'] as String);
      final book = (map['book'] as String);
      final chapter = map['chapter'] as int;
      final items = (map['verses'] as List).cast<Map<String, dynamic>>();
      verses = items
          .map(
            (v) => Verse.fromJson({
              'bookId': bookId,
              'book': book,
              'chapter': chapter,
              'verse': v['verse'],
              'text': v['text'],
            }),
          )
          .toList(growable: false);
    } else {
      verses = const [];
    }

    final frozen = List<Verse>.unmodifiable(verses);
    _putCache(path, frozen);
    return frozen;
  }

  Future<Set<String>> _chapterAssetsFor(BibleTranslation t) async {
    final cached = _chapterAssetsCache[t];
    if (cached != null) return cached;

    final root = BibleAssetPaths.chapterRoot(t);
    if (root == null) {
      _chapterAssetsCache[t] = const {};
      return const {};
    }

    final keys = (await _loadAssetKeys())
        .where((k) => k.startsWith('$root/') && k.endsWith('.json'))
        .where((k) => !k.endsWith('_sample.json'))
        .toSet();

    _chapterAssetsCache[t] = keys;
    return keys;
  }

  String _normalizeBookId(String id) {
    final s = id.toLowerCase().trim().replaceAll(' ', '').replaceAll('_', '');
    if (s == 'songofsongs' || s == 'songofsolomon') return 'song_of_songs';

    // 1samuel -> 1_samuel
    if (s.isNotEmpty && '123'.contains(s[0]) && s.length > 1) {
      return '${s[0]}_${s.substring(1)}';
    }
    return s;
  }

  Future<List<Verse>> _loadFullKJV() async {
    try {
      final path = 'assets/data/bibles/kjv.json';
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw) as List;

      final allVerses = <Verse>[];

      // Thiagobodruk format: [{ abbrev: "gn", chapters: [ [ "v1", "v2" ], ... ] }, ...]
      // We rely on the order matching BookCatalog as it's standard 66 books.
      for (int bIndex = 0; bIndex < decoded.length; bIndex++) {
        if (bIndex >= BookCatalog.books.length) break;

        final bookData = decoded[bIndex] as Map<String, dynamic>;
        final book = BookCatalog.books[bIndex];
        final chapters = bookData['chapters'] as List;

        for (int cIndex = 0; cIndex < chapters.length; cIndex++) {
          final versesList = chapters[cIndex] as List;
          for (int vIndex = 0; vIndex < versesList.length; vIndex++) {
            allVerses.add(Verse(
              ref: VerseRef(
                bookId: book.id,
                chapter: cIndex + 1,
                verse: vIndex + 1,
              ),
              text: versesList[vIndex] as String,
              book: book.name,
            ));
          }
        }
      }

      return List<Verse>.unmodifiable(allVerses);
    } catch (e) {
      debugPrint('Error loading full KJV: $e');
      return const [];
    }
  }

  Future<Set<String>> _loadAssetKeys() async {
    final existing = _assetKeys;
    if (existing != null) return existing;

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest.listAssets().toSet();
    _assetKeys = keys;
    return keys;
  }
}
