import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/core/utils/scripture_reference_parser.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/domain/entities/verse.dart';
import 'package:simple_bible_app/domain/entities/verse_ref.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_range_selection.dart';

void main() {
  const parser = ScriptureReferenceParser();
  const selection = MemoryRangeSelection();

  test('parser handles single verses, ranges, and malformed input', () {
    expect(parser.tryParse('John 3:16')?.isSingleVerse, isTrue);
    final range = parser.tryParse('Philippians 4:6–7');
    expect(range?.startVerse, 6);
    expect(range?.endVerse, 7);
    expect(parser.tryParse('not a reference'), isNull);
  });

  test('complete and contiguous selections create one entry', () {
    final reference = parser.tryParse('Philippians 4:6-8')!;
    final verses = _verses(6, 8);

    final complete = selection.buildDrafts(
      reference: reference,
      verses: verses,
      selectedVerseNumbers: const {6, 7, 8},
      translation: BibleTranslation.yoruba,
      source: MemoryVerseSource.devotional,
    );
    final subrange = selection.buildDrafts(
      reference: reference,
      verses: verses,
      selectedVerseNumbers: const {6, 7},
      translation: BibleTranslation.yoruba,
      source: MemoryVerseSource.devotional,
    );

    expect(complete, hasLength(1));
    expect(complete.single.endVerse, 8);
    expect(subrange.single.endVerse, 7);
    expect(subrange.single.translation, BibleTranslation.yoruba);
  });

  test('non-contiguous selection creates separate entries', () {
    final reference = parser.tryParse('Philippians 4:6-8')!;
    final drafts = selection.buildDrafts(
      reference: reference,
      verses: _verses(6, 8),
      selectedVerseNumbers: const {6, 8},
      translation: BibleTranslation.hausa,
      source: MemoryVerseSource.devotional,
    );

    expect(drafts, hasLength(2));
    expect(drafts.map((draft) => draft.startVerse), [6, 8]);
    expect(
      drafts.every((draft) => draft.translation == BibleTranslation.hausa),
      isTrue,
    );
  });
}

List<Verse> _verses(int start, int end) {
  return [
    for (var number = start; number <= end; number++)
      Verse(
        ref: VerseRef(
          bookId: 'philippians',
          chapter: 4,
          verse: number,
        ),
        book: 'Philippians',
        text: 'Verse $number text.',
      ),
  ];
}
