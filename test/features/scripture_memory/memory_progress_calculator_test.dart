import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_review_event.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_schedule.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_progress_calculator.dart';

void main() {
  const calculator = MemoryProgressCalculator();

  test('established milestone remains while a lapsed verse strengthens', () {
    final summary = calculator.calculate(
      verses: [
        _verse(
          stage: 4,
          hasReachedEstablished: true,
          collectionIds: const ['peace'],
        ),
      ],
      events: const [],
      now: DateTime(2026, 7, 18),
    );

    expect(summary.establishedCount, 1);
    expect(summary.strengtheningCount, 1);
    expect(summary.collectionsStartedCount, 1);
  });

  test('month totals and streak use completed local practice dates', () {
    final summary = calculator.calculate(
      verses: [_verse(stage: 1)],
      events: [
        _event('2026-07-18'),
        _event('2026-07-17', id: 'previous'),
        _event('2026-06-30', id: 'prior-month'),
      ],
      now: DateTime(2026, 7, 18, 23, 30),
    );

    expect(summary.reviewsThisMonth, 2);
    expect(summary.practiceDaysThisMonth, 2);
    expect(summary.streakDays, 2);
  });
}

MemoryVerse _verse({
  required int stage,
  bool hasReachedEstablished = false,
  List<String> collectionIds = const [],
}) {
  return MemoryVerse(
    id: 'verse-$stage',
    dedupeKey: 'KJV|john|3|16|16',
    bookId: 'john',
    bookName: 'John',
    chapter: 3,
    startVerse: 16,
    endVerse: 16,
    translation: BibleTranslation.kjv,
    textSnapshot: 'For God so loved the world.',
    source: MemoryVerseSource.bible,
    categories: const [],
    collectionIds: collectionIds,
    difficulty: MemoryDifficulty.normal,
    schedule: MemorySchedule(
      status: MemoryStatus.reviewing,
      stage: stage,
      dueLocalDate: '2026-07-18',
      hasReachedEstablished: hasReachedEstablished,
    ),
    createdAtUtc: DateTime.utc(2026, 1, 1),
    updatedAtUtc: DateTime.utc(2026, 1, 1),
  );
}

MemoryReviewEvent _event(String date, {String id = 'event'}) {
  return MemoryReviewEvent(
    id: id,
    memoryVerseId: 'verse',
    mode: MemoryExerciseMode.missingWords,
    rating: MemoryReviewRating.remembered,
    completedLocalDate: date,
    completedAtUtc: DateTime.parse('${date}T12:00:00Z'),
    previousStage: 1,
    nextStage: 2,
  );
}
