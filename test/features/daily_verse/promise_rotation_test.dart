import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_verse/model/promise_history_entry.dart';
import 'package:simple_bible_app/features/daily_verse/services/promise_rotation.dart';

void main() {
  List<Map<String, dynamic>> catalog([int count = 105]) {
    return List<Map<String, dynamic>>.generate(
      count,
      (index) => {
        'id': 'promise-$index',
        'bookId': 'book_$index',
        'chapter': 1,
        'verse': index + 1,
        'theme': 'theme_${index % 12}',
      },
    );
  }

  test('same local calendar date returns the persisted promise', () {
    final items = catalog();
    const persistedId = 'promise-42';
    final history = [
      PromiseHistoryEntry(
        promiseId: persistedId,
        theme: 'theme_6',
        shownOn: DateTime(2026, 7, 16),
      ),
    ];

    final morning = PromiseRotation.selectIndex(
      items,
      date: DateTime(2026, 7, 16, 1),
      history: history,
    );
    final evening = PromiseRotation.selectIndex(
      items,
      date: DateTime(2026, 7, 16, 23, 59),
      history: history,
    );

    expect(items[morning]['id'], persistedId);
    expect(evening, morning);
  });

  test('next date selects the next eligible promise', () {
    final items = catalog();
    final firstIndex = PromiseRotation.selectIndex(
      items,
      date: DateTime(2026, 7, 16),
    );
    final first = items[firstIndex];
    final history = [
      PromiseHistoryEntry(
        promiseId: first['id'] as String,
        theme: first['theme'] as String,
        shownOn: DateTime(2026, 7, 16),
      ),
    ];

    final nextIndex = PromiseRotation.selectIndex(
      items,
      date: DateTime(2026, 7, 17),
      history: history,
    );

    expect(items[nextIndex]['id'], isNot(first['id']));
    expect(items[nextIndex]['theme'], isNot(first['theme']));
  });

  test('avoids repeats for 60 days and consecutive themes', () {
    final items = catalog();
    final history = <PromiseHistoryEntry>[];

    for (var day = 0; day < 365; day += 1) {
      final date = DateTime(2026, 1, 1 + day);
      final selectedIndex = PromiseRotation.selectIndex(
        items,
        date: date,
        history: history,
      );
      final selected = items[selectedIndex];
      final recent = history.where((entry) {
        final age = PromiseHistoryEntry.calendarDaysBetween(
          date,
          entry.shownOn,
        );
        return age >= 1 && age <= PromiseRotation.minimumRepeatGap;
      });

      expect(
        recent.map((entry) => entry.promiseId),
        isNot(contains(selected['id'])),
      );
      if (history.isNotEmpty) {
        expect(selected['theme'], isNot(history.last.theme));
      }

      history.add(
        PromiseHistoryEntry(
          promiseId: selected['id'] as String,
          theme: selected['theme'] as String,
          shownOn: date,
        ),
      );
      history.removeWhere((entry) {
        return PromiseHistoryEntry.calendarDaysBetween(date, entry.shownOn) >
            90;
      });
    }
  });

  test('New Year window prefers a seasonal theme', () {
    final items = catalog()
      ..[0] = {
        'id': 'new-year-hope',
        'bookId': 'isaiah',
        'chapter': 43,
        'verse': 19,
        'theme': 'Hope',
      };

    final selected = PromiseRotation.selectIndex(
      items,
      date: DateTime(2026, 1, 1),
    );

    expect(items[selected]['theme'], 'Hope');
  });

  test('history serialization survives restart and corrupt data is safe', () {
    final original = [
      PromiseHistoryEntry(
        promiseId: 'isaiah-41-10-strength-01',
        theme: 'Strength',
        shownOn: DateTime(2026, 7, 16, 22),
      ),
    ];

    final restored = PromiseHistoryEntry.decodeList(
      PromiseHistoryEntry.encodeList(original),
    );

    expect(restored, hasLength(1));
    expect(restored.single.promiseId, original.single.promiseId);
    expect(restored.single.theme, original.single.theme);
    expect(restored.single.shownOn, DateTime(2026, 7, 16));
    expect(PromiseHistoryEntry.decodeList('{broken'), isEmpty);
    expect(PromiseHistoryEntry.decodeList('[]'), isEmpty);
  });

  test('calendar arithmetic is stable across leap year and DST dates', () {
    expect(
      PromiseHistoryEntry.calendarDaysBetween(
        DateTime(2028, 3, 1),
        DateTime(2028, 2, 28),
      ),
      2,
    );
    expect(
      PromiseHistoryEntry.calendarDaysBetween(
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 8),
      ),
      1,
    );
    expect(
      PromiseHistoryEntry.calendarDaysBetween(
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 1),
      ),
      1,
    );
  });
}
