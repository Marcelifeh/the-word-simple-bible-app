import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/data/bible/bible_repository.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/domain/entities/verse.dart';
import 'package:simple_bible_app/domain/entities/verse_ref.dart';
import 'package:simple_bible_app/features/home/view/home_screen.dart';
import 'package:simple_bible_app/features/reading_plan/view/daily_plan_reader_screen.dart';
import 'package:simple_bible_app/shared/state/app_state.dart';

class _Bible extends BibleRepository {
  @override
  Future<List<Verse>> loadChapter(
          {required BibleTranslation translation,
          required String bookId,
          required int chapter}) async =>
      [
        Verse(
            ref: VerseRef(bookId: bookId, chapter: chapter, verse: 1),
            book: bookId,
            text: 'Reading for the selected day.')
      ];
  @override
  Future<List<Verse>> searchKeyword(
          {required BibleTranslation translation,
          required String query,
          int limit = 50}) async =>
      [];
}

class _State extends AppState {
  final _bible = _Bible();
  DateTime? openedDate;
  DateTime? completedDate;
  @override
  BibleRepository get bibleRepo => _bible;
  @override
  Future<void> markReadingPlanPassageOpened(String passage,
      {DateTime? openedAt}) async {
    openedDate = openedAt;
  }

  @override
  Future<void> markReadingPlanCompleted(
      {DateTime? planDate,
      DateTime? completedAt,
      Iterable<String>? passages}) async {
    completedDate = planDate;
  }
}

void main() {
  testWidgets('Missed D1 opens its Bible reading and completes the missed date',
      (tester) async {
    final state = _State();
    await tester.pumpWidget(
        AppScope(state: state, child: const MaterialApp(home: HomeScreen())));
    await tester.pumpAndSettle();
    final pager = find.byType(PageView).first;
    await tester.ensureVisible(pager);
    tester.widget<PageView>(pager).controller!.jumpToPage(1);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Missed D1'));
    await tester.tap(find.text('Missed D1'));
    await tester.pumpAndSettle();

    final reader = tester
        .widget<DailyPlanReaderScreen>(find.byType(DailyPlanReaderScreen));
    expect(reader.passages.first.bookName, 'Genesis');
    expect(reader.passages.first.chapter, 1);
    final missedDate = DateTime(DateTime.now().year, 1, 1);
    expect(reader.readingDate, missedDate);
    expect(find.text("Today's Reading"), findsNothing);
    expect(state.openedDate, missedDate);
    await reader.onMarkComplete!();
    expect(state.completedDate, missedDate);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: DateTime.now().month == 1 && DateTime.now().day == 1);
}
