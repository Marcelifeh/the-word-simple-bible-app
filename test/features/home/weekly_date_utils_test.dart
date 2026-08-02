import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/home/services/weekly_date_utils.dart';

void main() {
  test('week starts on Sunday', () {
    expect(
      startOfSundayWeek(DateTime(2026, 8, 3)),
      DateTime(2026, 8, 2),
    );
  });

  test('Sunday belongs to the new week', () {
    expect(
      startOfSundayWeek(DateTime(2026, 8, 2, 18)),
      DateTime(2026, 8, 2),
    );
  });

  test('multiple completions on one day count as one active day', () {
    expect(
      countWeeklyDevotionalDays(
        completedDevotionalDates: [
          DateTime(2026, 7, 30, 8),
          DateTime(2026, 7, 30, 12),
          DateTime(2026, 7, 30, 20),
        ],
        now: DateTime(2026, 8, 1),
      ),
      1,
    );
  });

  test('previous Saturday is excluded after Sunday reset', () {
    expect(
      countWeeklyReadingDays(
        completedReadingDates: [
          DateTime(2026, 8, 1),
          DateTime(2026, 8, 2),
        ],
        now: DateTime(2026, 8, 2),
      ),
      1,
    );
  });

  test('installation date does not affect the calendar week', () {
    final installedOn = DateTime(2026, 8, 5);
    final now = DateTime(2026, 8, 5);

    expect(startOfSundayWeek(now), DateTime(2026, 8, 2));
    expect(installedOn.weekday, DateTime.wednesday);
  });
}
