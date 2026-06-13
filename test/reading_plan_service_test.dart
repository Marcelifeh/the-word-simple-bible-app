import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/data/bible/book_catalog.dart';
import 'package:simple_bible_app/domain/entities/book.dart';
import 'package:simple_bible_app/features/reading_plan/reading_plan_service.dart';

void main() {
  test('builds a full 365-day reading plan that covers every chapter once', () {
    final service = ReadingPlanService();
    final plan = service.fullPlan;

    expect(plan, hasLength(365));
    expect(plan.every((day) => day.passages.isNotEmpty), isTrue);

    final coveredChapters = <String>[];
    final chapterPattern = RegExp(r'^(.*?) (\d+)(?:-(\d+))?$');

    for (final day in plan) {
      for (final passage in day.passages) {
        final match = chapterPattern.firstMatch(passage);
        expect(match, isNotNull, reason: 'Unexpected passage format: $passage');

        final bookName = match!.group(1)!;
        final start = int.parse(match.group(2)!);
        final end = int.parse(match.group(3) ?? match.group(2)!);
        final book = BookCatalog.books
            .firstWhere((candidate) => candidate.name == bookName);

        for (var chapter = start; chapter <= end; chapter++) {
          coveredChapters.add('${book.id}-$chapter');
        }
      }
    }

    final expectedChapters = BookCatalog.books
        .expand(
          (book) => List<String>.generate(
            book.chapterCount,
            (index) => '${book.id}-${index + 1}',
          ),
        )
        .toList(growable: false);

    expect(coveredChapters, hasLength(expectedChapters.length));
    expect(coveredChapters.toSet(), expectedChapters.toSet());
  });

  test('maps dates to stable day indexes including leap years', () {
    final service = ReadingPlanService();

    expect(service.getReadingForDate(DateTime(2026, 1, 1)).title, 'Day 1');
    expect(service.getReadingForDate(DateTime(2026, 12, 31)).title, 'Day 365');
    expect(service.getReadingForDate(DateTime(2024, 2, 29)).title, 'Day 59');
    expect(service.getReadingForDate(DateTime(2024, 3, 1)).title, 'Day 60');
  });

  test('pairs old and new testament passages for the first 260 days', () {
    final service = ReadingPlanService();

    for (var dayIndex = 0; dayIndex < 260; dayIndex++) {
      final reading = service.fullPlan[dayIndex];
      final hasOldTestamentPassage = reading.passages.any(
        (passage) => _passageTestament(passage) == Testament.old,
      );
      final hasNewTestamentPassage = reading.passages.any(
        (passage) => _passageTestament(passage) == Testament.newTestament,
      );

      expect(hasOldTestamentPassage, isTrue,
          reason: 'Missing OT on ${reading.title}');
      expect(hasNewTestamentPassage, isTrue,
          reason: 'Missing NT on ${reading.title}');
    }
  });
}

Testament _passageTestament(String passage) {
  final match = RegExp(r'^(.*?) (\d+)(?:-(\d+))?$').firstMatch(passage);
  final bookName = match!.group(1)!;
  return BookCatalog.books
      .firstWhere((candidate) => candidate.name == bookName)
      .testament;
}
