import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';
import '../bible/bible_repository.dart';
import '../bible/book_catalog.dart';

class DailyVerseService {
  DailyVerseService(this._repo);

  final BibleRepository _repo;

  Future<Verse?> getDailyVerse({required BibleTranslation translation}) async {
    // Pick a deterministic book+chapter based on today's date — never loads
    // the full Bible, so startup is instant regardless of translation size.
    final now = DateTime.now();
    final seed = int.parse(
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
    );
    final rng = Random(seed);

    final books = BookCatalog.books;
    // Pick book weighted toward NT (skip Psalms-heavy weighting) — just random.
    final book = books[rng.nextInt(books.length)];
    final chapter = rng.nextInt(book.chapterCount) + 1;

    try {
      final verses = await _repo.loadChapter(
        translation: translation,
        bookId: book.id,
        chapter: chapter,
      );
      if (verses.isEmpty) return null;
      // Pick a non-fallback verse if possible.
      final real = verses.where((v) => !v.isFallback).toList();
      final pool = real.isNotEmpty ? real : verses;
      return pool[rng.nextInt(pool.length)];
    } catch (e, st) {
      debugPrint('DailyVerseService error: $e\n$st');
      return null;
    }
  }
}
