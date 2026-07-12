import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../data/bible/bible_repository.dart';
import '../../../domain/entities/bible_translation.dart';
import '../model/promise_verse.dart';

class PromiseVerseService {
  final BibleRepository bibleRepository;

  const PromiseVerseService({
    required this.bibleRepository,
  });

  Future<PromiseVerse> getTodayPromise({
    required BibleTranslation translation,
  }) async {
    final raw = await rootBundle.loadString(
      'assets/data/daily/promise_verses.json',
    );

    final items = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    final dayIndex = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;

    final selected = items[dayIndex % items.length];

    final verses = await bibleRepository.loadChapter(
      translation: translation,
      bookId: selected['bookId'].toString(),
      chapter: int.parse(selected['chapter'].toString()),
    );

    final verseNumber = int.parse(selected['verse'].toString());

    final verse = verses.firstWhere(
      (v) => v.ref.verse == verseNumber,
    );

    return PromiseVerse.fromJson(
      selected,
      text: verse.text,
    );
  }
}
