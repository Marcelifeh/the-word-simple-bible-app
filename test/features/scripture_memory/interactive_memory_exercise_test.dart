import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/scripture_memory/model/interactive_recall_result.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_review_event.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_schedule.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';
import 'package:simple_bible_app/features/scripture_memory/services/interactive_memory_exercise.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_text_comparator.dart';

void main() {
  const generator = InteractiveMemoryExerciseGenerator();

  test('missing words become editable tokens with punctuation outside', () {
    final tokens = generator.build(
      verse: _verse('For God so loved the world, that he gave.'),
      mode: MemoryExerciseMode.missingWords,
    );
    final blanks = tokens.whereType<EditableMemoryBlank>().toList();

    expect(blanks, isNotEmpty);
    expect(blanks.any((blank) => blank.trailingText.contains(',')), isTrue);
  });

  test('first letter keeps its hint and one-letter words visible', () {
    final tokens = generator.build(
      verse: _verse('I am Ọlọ́run.'),
      mode: MemoryExerciseMode.firstLetter,
    );
    final blanks = tokens.whereType<FirstLetterBlank>().toList();

    expect(blanks.any((blank) => blank.firstLetter == 'Ọ'), isTrue);
    expect(
      tokens
          .whereType<VisibleMemoryText>()
          .any((token) => token.text.contains('I')),
      isTrue,
    );
  });

  test('blank comparison ignores case and surrounding punctuation', () {
    expect(isMemoryWordCorrect(' Loved, ', 'loved'), isTrue);
    expect(isMemoryWordCorrect('Gods', 'God\'s'), isFalse);
  });

  test('precomposed and decomposed Yoruba accents compare equally', () {
    expect(isMemoryWordCorrect('Ọlọ́run', 'Ọlo\u0323\u0301run'), isTrue);
  });

  test('full reveal caps the suggested rating at strengthening', () {
    const result = InteractiveRecallResult(
      totalBlanks: 4,
      correctOnFirstCheck: 4,
      correctAfterRetry: 4,
      hintCount: 1,
      fullVerseRevealed: true,
      duration: Duration(seconds: 20),
    );

    expect(result.suggestedRating, MemoryReviewRating.almostThere);
  });
}

MemoryVerse _verse(String text) {
  return MemoryVerse(
    id: 'id',
    dedupeKey: 'WEB|john|3|16|16',
    bookId: 'john',
    bookName: 'John',
    chapter: 3,
    startVerse: 16,
    endVerse: 16,
    translation: BibleTranslation.web,
    textSnapshot: text,
    source: MemoryVerseSource.bible,
    categories: const [],
    difficulty: MemoryDifficulty.normal,
    schedule: const MemorySchedule(
      status: MemoryStatus.reviewing,
      stage: 2,
      dueLocalDate: '2026-07-19',
    ),
    createdAtUtc: DateTime.utc(2026, 7, 19),
    updatedAtUtc: DateTime.utc(2026, 7, 19),
  );
}
