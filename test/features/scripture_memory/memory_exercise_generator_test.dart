import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_review_event.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_schedule.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_exercise_generator.dart';

void main() {
  const generator = MemoryExerciseGenerator();

  test('first-letter mode preserves apostrophes, hyphens, and numbers', () {
    final result = generator.firstLetterPrompt(
      "God's well-being in LORD 3:16, O Lord.",
    );

    expect(result, 'G... w...-b... i... L... 3:16, O... L....');
  });

  test('missing-word mode keeps punctuation in place', () {
    final result = generator.missingWordsPrompt(
      'I am the vine; you are the branches.',
      difficulty: MemoryDifficulty.normal,
      stage: 0,
    );

    expect(result, 'I am ___ vine; you ___ the branches.');
  });

  test('new hard verses begin with missing words', () {
    final verse = MemoryVerse(
      id: 'id',
      dedupeKey: 'KJV|john|15|5|5',
      bookId: 'john',
      bookName: 'John',
      chapter: 15,
      startVerse: 5,
      endVerse: 5,
      translation: BibleTranslation.kjv,
      textSnapshot: 'I am the vine; you are the branches.',
      source: MemoryVerseSource.bible,
      categories: const ['Faith'],
      difficulty: MemoryDifficulty.hard,
      schedule: const MemorySchedule(
        status: MemoryStatus.newVerse,
        stage: 0,
        dueLocalDate: '2026-07-18',
      ),
      createdAtUtc: DateTime.utc(2026, 7, 18),
      updatedAtUtc: DateTime.utc(2026, 7, 18),
    );

    expect(
      generator.activeModeFor(verse),
      MemoryExerciseMode.missingWords,
    );
  });

  test('established verses rotate away from recently used modes', () {
    final verse = MemoryVerse(
      id: 'established',
      dedupeKey: 'KJV|john|15|5|5',
      bookId: 'john',
      bookName: 'John',
      chapter: 15,
      startVerse: 5,
      endVerse: 5,
      translation: BibleTranslation.kjv,
      textSnapshot: 'I am the vine; you are the branches.',
      source: MemoryVerseSource.bible,
      categories: const [],
      difficulty: MemoryDifficulty.normal,
      schedule: const MemorySchedule(
        status: MemoryStatus.established,
        stage: 5,
        dueLocalDate: '2026-07-18',
        hasReachedEstablished: true,
      ),
      createdAtUtc: DateTime.utc(2026, 7, 18),
      updatedAtUtc: DateTime.utc(2026, 7, 18),
    );

    expect(
      generator.chooseMode(
        verse: verse,
        recentlyUsedModes: const {MemoryExerciseMode.typeIt},
      ),
      MemoryExerciseMode.firstLetter,
    );
  });
}
