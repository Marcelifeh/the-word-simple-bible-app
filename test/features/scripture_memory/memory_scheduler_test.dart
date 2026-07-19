import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_review_event.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_schedule.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_scheduler.dart';

void main() {
  const scheduler = MemoryScheduler();
  final now = DateTime(2026, 7, 18, 23, 45);

  test('new verses enter the learn queue without entering review', () {
    final schedule = scheduler.newSchedule(now: now);

    expect(schedule.status, MemoryStatus.newVerse);
    expect(schedule.stage, 0);
    expect(schedule.dueLocalDate, '2026-07-18');
  });

  test('first successful recall starts the one-day interval', () {
    final schedule = scheduler.recordActiveRecall(
      current: scheduler.newSchedule(now: now),
      rating: MemoryReviewRating.remembered,
      now: now,
    );

    expect(schedule.status, MemoryStatus.reviewing);
    expect(schedule.stage, 1);
    expect(schedule.dueLocalDate, '2026-07-19');
    expect(schedule.lastReviewedLocalDate, '2026-07-18');
  });

  test('30-day stage is established', () {
    const current = MemorySchedule(
      status: MemoryStatus.reviewing,
      stage: 4,
      dueLocalDate: '2026-07-18',
    );

    final schedule = scheduler.recordActiveRecall(
      current: current,
      rating: MemoryReviewRating.remembered,
      now: now,
    );

    expect(schedule.status, MemoryStatus.established);
    expect(schedule.stage, 5);
    expect(schedule.dueLocalDate, '2026-08-17');
    expect(schedule.hasReachedEstablished, isTrue);
  });

  test('a lapse keeps the historical established milestone', () {
    const established = MemorySchedule(
      status: MemoryStatus.established,
      stage: 5,
      dueLocalDate: '2026-07-18',
      hasReachedEstablished: true,
    );

    final schedule = scheduler.recordActiveRecall(
      current: established,
      rating: MemoryReviewRating.needsPractice,
      now: now,
    );

    expect(schedule.stage, 4);
    expect(schedule.hasReachedEstablished, isTrue);
  });

  test('date-only scheduling is stable around a DST-style boundary', () {
    final beforeMidnight = DateTime(2026, 11, 1, 23, 55);
    final schedule = scheduler.newSchedule(now: beforeMidnight);

    expect(schedule.dueLocalDate, '2026-11-01');
    expect(
      scheduler.isDue(schedule, now: DateTime(2026, 11, 2, 0, 5)),
      isTrue,
    );
  });
}
