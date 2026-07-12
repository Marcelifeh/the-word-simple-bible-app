import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/verse.dart';
import '../bible/bible_repository.dart';
import '../bible/book_catalog.dart';

class DailyVerseService {
  DailyVerseService(
    this._repo, {
    AssetBundle? assetBundle,
    DateTime Function()? now,
  })  : _assetBundle = assetBundle ?? rootBundle,
        _now = now ?? DateTime.now;

  static const _curatedAssetPath = 'assets/data/daily/devotional_verses.json';
  static final _devotionalYearStart = DateTime(2026, 1, 1);
  static const _builtInFallbackPool = [
    _CuratedDailyVerse(bookId: 'psalms', chapter: 23, verse: 1),
    _CuratedDailyVerse(bookId: 'isaiah', chapter: 41, verse: 10),
    _CuratedDailyVerse(bookId: 'romans', chapter: 8, verse: 28),
    _CuratedDailyVerse(bookId: 'philippians', chapter: 4, verse: 6),
    _CuratedDailyVerse(bookId: 'john', chapter: 15, verse: 5),
    _CuratedDailyVerse(bookId: 'proverbs', chapter: 3, verse: 5),
    _CuratedDailyVerse(bookId: 'matthew', chapter: 11, verse: 28),
    _CuratedDailyVerse(bookId: 'john', chapter: 14, verse: 27),
    _CuratedDailyVerse(bookId: 'psalms', chapter: 46, verse: 1),
    _CuratedDailyVerse(bookId: '2_timothy', chapter: 1, verse: 7),
  ];

  final BibleRepository _repo;
  final AssetBundle _assetBundle;
  final DateTime Function() _now;
  Future<List<_CuratedDailyVerse>>? _curatedVersePoolFuture;

  Future<Verse?> getDailyVerse({required BibleTranslation translation}) async {
    final now = _now();

    try {
      final curatedVerses = await _loadCuratedVersePool();
      if (curatedVerses.isNotEmpty) {
        final verse = await _loadCuratedVerseFromPool(
          curatedVerses,
          translation: translation,
          dayIndex: _dayIndex(now),
        );
        if (verse != null) return verse;
      }
    } catch (e, st) {
      debugPrint('DailyVerseService curated pool error: $e\n$st');
    }

    final builtInVerse = await _loadCuratedVerseFromPool(
      _builtInFallbackPool,
      translation: translation,
      dayIndex: _dayIndex(now),
    );
    if (builtInVerse != null) return builtInVerse;

    return _loadLastResortVerse(
      translation: translation,
      dayIndex: _dayIndex(now),
    );
  }

  Future<List<_CuratedDailyVerse>> _loadCuratedVersePool() {
    return _curatedVersePoolFuture ??= _readCuratedVersePool();
  }

  Future<List<_CuratedDailyVerse>> _readCuratedVersePool() async {
    final raw = await _assetBundle.loadString(_curatedAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    final seen = <String>{};
    final verses = <_CuratedDailyVerse>[];

    for (final rawEntry in decoded.whereType<Map>()) {
      final verse = _CuratedDailyVerse.tryParse(rawEntry);
      if (verse == null || !_isValidCuratedCandidate(verse)) continue;
      if (seen.add(verse.key)) {
        verses.add(verse);
      }
    }

    return List<_CuratedDailyVerse>.unmodifiable(verses);
  }

  bool _isValidCuratedCandidate(_CuratedDailyVerse verse) {
    if (verse.chapter < 1 || verse.verse < 1) return false;

    Book? book;
    for (final candidate in BookCatalog.books) {
      if (candidate.id == verse.bookId) {
        book = candidate;
        break;
      }
    }
    if (book == null) return false;

    return verse.chapter <= book.chapterCount;
  }

  Future<Verse?> _loadCuratedVerseFromPool(
    List<_CuratedDailyVerse> pool, {
    required BibleTranslation translation,
    required int dayIndex,
  }) async {
    if (pool.isEmpty) return null;

    final startIndex = _positiveModulo(dayIndex, pool.length);
    for (var offset = 0; offset < pool.length; offset += 1) {
      final selected = pool[(startIndex + offset) % pool.length];
      final verse = await _loadCuratedVerse(
        selected,
        translation: translation,
      );
      if (verse != null) return verse;
    }

    return null;
  }

  Future<Verse?> _loadCuratedVerse(
    _CuratedDailyVerse selected, {
    required BibleTranslation translation,
  }) async {
    final verses = await _repo.loadChapter(
      translation: translation,
      bookId: selected.bookId,
      chapter: selected.chapter,
    );

    for (final verse in verses) {
      if (verse.ref.verse == selected.verse && !verse.isFallback) {
        return verse;
      }
    }

    debugPrint(
      'DailyVerseService missing curated verse: '
      '${selected.bookId} ${selected.chapter}:${selected.verse}',
    );
    return null;
  }

  Future<Verse?> _loadLastResortVerse({
    required BibleTranslation translation,
    required int dayIndex,
  }) async {
    final translations = [
      translation,
      if (translation != BibleTranslation.kjv) BibleTranslation.kjv,
    ];

    for (final candidateTranslation in translations) {
      final verse = await _loadCuratedVerseFromPool(
        _builtInFallbackPool,
        translation: candidateTranslation,
        dayIndex: dayIndex,
      );
      if (verse != null) return verse;
    }

    return null;
  }

  int _dayIndex(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(_devotionalYearStart).inDays;
  }

  int _positiveModulo(int value, int divisor) =>
      ((value % divisor) + divisor) % divisor;
}

class _CuratedDailyVerse {
  const _CuratedDailyVerse({
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  final String bookId;
  final int chapter;
  final int verse;

  String get key => '$bookId-$chapter-$verse';

  static _CuratedDailyVerse? tryParse(Map<dynamic, dynamic> json) {
    final rawBookId = json['bookId'];
    final rawChapter = json['chapter'];
    final rawVerse = json['verse'];
    if (rawBookId is! String || rawChapter is! num || rawVerse is! num) {
      return null;
    }

    final bookId = rawBookId.trim().toLowerCase();
    if (bookId.isEmpty) return null;

    return _CuratedDailyVerse(
      bookId: bookId,
      chapter: rawChapter.toInt(),
      verse: rawVerse.toInt(),
    );
  }
}
