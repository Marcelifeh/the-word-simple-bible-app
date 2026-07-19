import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/core/utils/scripture_reference_parser.dart';
import 'package:simple_bible_app/data/bible/bible_repository.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/domain/entities/verse.dart';
import 'package:simple_bible_app/domain/entities/verse_ref.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_passage_resolver.dart';

void main() {
  const reference = ScriptureReferenceRange(
    bookId: 'philippians',
    bookName: 'Philippians',
    chapter: 4,
    startVerse: 6,
    endVerse: 7,
  );

  test('incomplete or fallback translation is unavailable', () async {
    final resolver = MemoryPassageResolver(
      _FakeBibleRepository(
        verses: const [
          Verse(
            ref: VerseRef(
              bookId: 'philippians',
              chapter: 4,
              verse: 6,
            ),
            book: 'Philippians',
            text: 'Fallback text',
            isFallback: true,
          ),
        ],
      ),
    );

    final result = await resolver.resolve(
      reference: reference,
      translation: BibleTranslation.hausa,
    );

    expect(result.isAvailable, isFalse);
    expect(result.verses, isEmpty);
    expect(result.translation, BibleTranslation.hausa);
  });

  test('complete selected translation remains correctly identified', () async {
    final resolver = MemoryPassageResolver(
      _FakeBibleRepository(
        verses: const [
          Verse(
            ref: VerseRef(
              bookId: 'philippians',
              chapter: 4,
              verse: 6,
            ),
            book: 'Philippians',
            text: 'Ẹ má ṣe ṣe aniyan.',
          ),
          Verse(
            ref: VerseRef(
              bookId: 'philippians',
              chapter: 4,
              verse: 7,
            ),
            book: 'Philippians',
            text: 'Àlàáfíà Ọlọ́run yóò ṣọ́ ọkàn yín.',
          ),
        ],
      ),
    );

    final result = await resolver.resolve(
      reference: reference,
      translation: BibleTranslation.yoruba,
    );

    expect(result.isAvailable, isTrue);
    expect(result.translation, BibleTranslation.yoruba);
    expect(result.text, contains('Ọlọ́run'));
  });
}

class _FakeBibleRepository implements BibleRepository {
  const _FakeBibleRepository({required this.verses});

  final List<Verse> verses;

  @override
  Future<List<Verse>> loadChapter({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  }) async {
    return verses;
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
