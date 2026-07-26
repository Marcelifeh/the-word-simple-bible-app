import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../data/bible/bible_repository.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse.dart';
import '../model/promise_history_entry.dart';
import '../model/promise_verse.dart';
import 'promise_rotation.dart';

class PromiseVerseService {
  final BibleRepository bibleRepository;

  const PromiseVerseService({
    required this.bibleRepository,
  });

  Future<PromiseVerse> getTodayPromise({
    required BibleTranslation translation,
    DateTime? now,
    List<PromiseHistoryEntry> history = const <PromiseHistoryEntry>[],
  }) async {
    final results = await Future.wait([
      rootBundle.loadString('assets/data/daily/devotional_verses.json'),
      rootBundle.loadString('assets/data/daily/promise_verses.json'),
    ]);

    final curatedDetails =
        (jsonDecode(results[1]) as List).cast<Map<String, dynamic>>();
    final curatedByReference = {
      for (final item in curatedDetails) _key(item): item,
    };
    final items = (jsonDecode(results[0]) as List)
        .cast<Map<String, dynamic>>()
        .map((item) {
      final enriched = <String, dynamic>{
        ...item,
        'tag': item['theme'],
        if (curatedByReference[_key(item)] case final details?) ...details,
      };
      enriched.putIfAbsent('id', () => _stableId(enriched));
      return enriched;
    }).toList(growable: false);

    final enriched = items[PromiseRotation.selectIndex(
      items,
      date: now ?? DateTime.now(),
      history: history,
    )];
    final theme = enriched['tag'].toString();
    enriched.putIfAbsent('commentary', () => _commentaryFor(theme));
    enriched.putIfAbsent('prayer', () => _prayerFor(theme));
    enriched.putIfAbsent('reflection', () => _reflectionFor(theme));

    var effectiveTranslation = translation;
    var verses = await bibleRepository.loadChapter(
      translation: translation,
      bookId: enriched['bookId'].toString(),
      chapter: int.parse(enriched['chapter'].toString()),
    );
    final verseNumber = int.parse(enriched['verse'].toString());
    var verse = _findUsableVerse(verses, verseNumber);
    if (verse == null && translation != BibleTranslation.kjv) {
      effectiveTranslation = BibleTranslation.kjv;
      verses = await bibleRepository.loadChapter(
        translation: effectiveTranslation,
        bookId: enriched['bookId'].toString(),
        chapter: int.parse(enriched['chapter'].toString()),
      );
      verse = _findUsableVerse(verses, verseNumber);
    }
    if (verse == null) {
      throw StateError('Promise verse text is unavailable');
    }

    return PromiseVerse.fromJson(
      enriched,
      text: BibleTextSanitizer.clean(verse.text),
      translation: effectiveTranslation,
    );
  }

  Verse? _findUsableVerse(List<Verse> verses, int verseNumber) {
    for (final verse in verses) {
      if (verse.ref.verse == verseNumber && !verse.isFallback) return verse;
    }
    return null;
  }

  String _key(Map<String, dynamic> item) {
    return '${item['bookId']}:${item['chapter']}:${item['verse']}';
  }

  String _stableId(Map<String, dynamic> item) {
    final theme = (item['tag'] ?? item['theme'] ?? 'promise')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return '${item['bookId']}-${item['chapter']}-${item['verse']}-$theme-01';
  }

  String _commentaryFor(String theme) {
    final subject = theme.toLowerCase();
    return 'This passage anchors $subject in the character of God. His Word '
        'invites you to receive what He gives, trust what He has spoken, and '
        'carry that truth into the choices before you today.';
  }

  String _prayerFor(String theme) {
    return 'Lord, make the truth of Your $theme real in me today. Help me trust '
        'Your Word, follow Your leading, and rest in Your faithful care. Amen.';
  }

  String _reflectionFor(String theme) {
    return 'Where do I most need to receive God\'s $theme and respond to His '
        'promise with trust today?';
  }
}
