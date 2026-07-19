import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_schedule.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';

void main() {
  test('dedupe key normalizes translation, book, and verse order', () {
    final key = MemoryVerse.buildDedupeKey(
      translation: BibleTranslation.kjv,
      bookId: ' John ',
      chapter: 3,
      startVerse: 18,
      endVerse: 16,
    );

    expect(key, 'KJV|john|3|16|18');
  });

  test('JSON round trip preserves content and schedule separately', () {
    final original = MemoryVerse(
      id: 'record-id',
      dedupeKey: 'YORUBA|john|3|16|16',
      bookId: 'john',
      bookName: 'John',
      chapter: 3,
      startVerse: 16,
      endVerse: 16,
      translation: BibleTranslation.yoruba,
      textSnapshot: 'Nítorí Ọlọ́run fẹ́ aráyé tó bẹ́ẹ̀ gẹ́ẹ́.',
      source: MemoryVerseSource.dailyVerse,
      categories: const ['Love'],
      difficulty: MemoryDifficulty.normal,
      schedule: const MemorySchedule(
        status: MemoryStatus.learning,
        stage: 0,
        dueLocalDate: '2026-07-18',
        reviewCount: 1,
      ),
      createdAtUtc: DateTime.utc(2026, 7, 18),
      updatedAtUtc: DateTime.utc(2026, 7, 18, 1),
    );

    final restored = MemoryVerse.fromJson(original.toJson());

    expect(restored.translation, BibleTranslation.yoruba);
    expect(restored.textSnapshot, original.textSnapshot);
    expect(restored.schedule.status, MemoryStatus.learning);
    expect(restored.schedule.reviewCount, 1);
  });

  test('future schema versions fail without being misread', () {
    final json = <String, dynamic>{
      'schemaVersion': MemoryVerse.currentSchemaVersion + 1,
    };

    expect(
      () => MemoryVerse.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}
