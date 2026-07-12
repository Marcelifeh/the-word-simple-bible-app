import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/data/bible/bible_repository.dart';
import 'package:simple_bible_app/data/daily_verse/daily_verse_service.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/domain/entities/verse.dart';
import 'package:simple_bible_app/domain/entities/verse_ref.dart';

void main() {
  test('walks forward through curated verses when the daily pick is missing',
      () async {
    final service = DailyVerseService(
      _FakeBibleRepository({
        _chapterKey('john', 3): [
          _verse(bookId: 'john', book: 'John', chapter: 3, verse: 16),
        ],
      }),
      assetBundle: _StringAssetBundle({
        'assets/data/daily/devotional_verses.json': jsonEncode([
          {'bookId': 'psalms', 'chapter': 23, 'verse': 1},
          {'bookId': 'john', 'chapter': 3, 'verse': 16},
        ]),
      }),
      now: () => DateTime(2026, 1, 1),
    );

    final verse = await service.getDailyVerse(
      translation: BibleTranslation.kjv,
    );

    expect(verse?.ref.bookId, 'john');
    expect(verse?.ref.chapter, 3);
    expect(verse?.ref.verse, 16);
  });

  test('does not return placeholder fallback verses from curated picks',
      () async {
    final service = DailyVerseService(
      _FakeBibleRepository({
        _chapterKey('psalms', 23): [
          _verse(
            bookId: 'psalms',
            book: 'Psalms',
            chapter: 23,
            verse: 1,
            isFallback: true,
          ),
        ],
        _chapterKey('john', 3): [
          _verse(bookId: 'john', book: 'John', chapter: 3, verse: 16),
        ],
      }),
      assetBundle: _StringAssetBundle({
        'assets/data/daily/devotional_verses.json': jsonEncode([
          {'bookId': 'psalms', 'chapter': 23, 'verse': 1},
          {'bookId': 'john', 'chapter': 3, 'verse': 16},
        ]),
      }),
      now: () => DateTime(2026, 1, 1),
    );

    final verse = await service.getDailyVerse(
      translation: BibleTranslation.kjv,
    );

    expect(verse?.ref.bookId, 'john');
    expect(verse?.isFallback, isFalse);
  });

  test('uses built-in devotional fallbacks when curated asset is unreadable',
      () async {
    final service = DailyVerseService(
      _FakeBibleRepository({
        _chapterKey('psalms', 23): [
          _verse(bookId: 'psalms', book: 'Psalms', chapter: 23, verse: 1),
        ],
      }),
      assetBundle: _StringAssetBundle({
        'assets/data/daily/devotional_verses.json': 'not json',
      }),
      now: () => DateTime(2026, 1, 1),
    );

    final verse = await service.getDailyVerse(
      translation: BibleTranslation.kjv,
    );

    expect(verse?.ref.bookId, 'psalms');
    expect(verse?.ref.chapter, 23);
    expect(verse?.ref.verse, 1);
  });
}

String _chapterKey(String bookId, int chapter) => '$bookId-$chapter';

Verse _verse({
  required String bookId,
  required String book,
  required int chapter,
  required int verse,
  bool isFallback = false,
}) {
  return Verse(
    ref: VerseRef(bookId: bookId, chapter: chapter, verse: verse),
    book: book,
    text: 'Curated devotional verse text.',
    isFallback: isFallback,
  );
}

class _FakeBibleRepository implements BibleRepository {
  const _FakeBibleRepository(this.chapters);

  final Map<String, List<Verse>> chapters;

  @override
  Future<List<Verse>> loadChapter({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  }) async {
    return chapters[_chapterKey(bookId, chapter)] ?? const [];
  }

  @override
  Future<List<Verse>> searchKeyword({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  }) async {
    return const [];
  }
}

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }

    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.view(bytes.buffer);
  }
}
