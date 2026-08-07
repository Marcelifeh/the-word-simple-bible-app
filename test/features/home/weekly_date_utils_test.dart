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

  test('previous week readings are excluded', () {
    final events = [
      DateTime(2026, 8, 1), // Saturday, previous week
      DateTime(2026, 8, 2), // Sunday, current week
    ];

    expect(
      calculateBibleReadingDays(
        completedAtDates: events,
        now: DateTime(2026, 8, 4),
      ),
      1,
    );
  });

  test('multiple readings on one date count as one reading day', () {
    final events = [
      DateTime(2026, 8, 2, 8),
      DateTime(2026, 8, 2, 12),
      DateTime(2026, 8, 2, 20),
    ];

    expect(
      calculateBibleReadingDays(
        completedAtDates: events,
        now: DateTime(2026, 8, 4),
      ),
      1,
    );
  });

  test('readings on two dates count as two days', () {
    final events = [
      DateTime(2026, 8, 2, 8),
      DateTime(2026, 8, 3, 9),
    ];

    expect(
      calculateBibleReadingDays(
        completedAtDates: events,
        now: DateTime(2026, 8, 4),
      ),
      2,
    );
  });

  test('reading plan and normal Bible reading on same date count once', () {
    final events = [
      DateTime(2026, 8, 3, 8),
      DateTime(2026, 8, 3, 19),
    ];

    expect(
      calculateBibleReadingDays(
        completedAtDates: events,
        now: DateTime(2026, 8, 4),
      ),
      1,
    );
  });

  test('Sunday starts a new week', () {
    final events = [
      DateTime(2026, 8, 1, 18), // Saturday
      DateTime(2026, 8, 2, 8), // Sunday
    ];

    expect(
      calculateBibleReadingDays(
        completedAtDates: events,
        now: DateTime(2026, 8, 2, 12),
      ),
      1,
    );
  });

  test('same date from multiple sources counts once', () {
    final events = [
      DateTime(2026, 8, 3, 8),
      DateTime(2026, 8, 3, 20),
      DateTime(2026, 8, 3, 21),
    ];

    expect(
      calculateBibleReadingDays(
        completedAtDates: events,
        now: DateTime(2026, 8, 4),
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
