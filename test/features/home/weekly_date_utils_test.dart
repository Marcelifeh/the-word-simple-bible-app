import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/home/activity/model/daily_faith_activity.dart';
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

  // ── calendarDayOfSundayWeek ─────────────────────────────────────────────

  test('calendarDayOfSundayWeek Sunday = 1', () {
    // 2026-08-02 is a Sunday.
    expect(calendarDayOfSundayWeek(DateTime(2026, 8, 2)), 1);
  });

  test('calendarDayOfSundayWeek Monday = 2', () {
    // 2026-08-03 is a Monday.
    expect(calendarDayOfSundayWeek(DateTime(2026, 8, 3)), 2);
  });

  test('calendarDayOfSundayWeek Saturday = 7', () {
    // 2026-08-08 is a Saturday.
    expect(calendarDayOfSundayWeek(DateTime(2026, 8, 8)), 7);
  });

  // ── calendarWeekProgress ────────────────────────────────────────────────

  test('calendarWeekProgress Sunday = one seventh', () {
    expect(
      calendarWeekProgress(DateTime(2026, 8, 2)),
      closeTo(1 / 7, 0.000001),
    );
  });

  test('calendarWeekProgress Saturday = 1.0', () {
    expect(calendarWeekProgress(DateTime(2026, 8, 8)), 1.0);
  });

  // ── DailyFaithActivity ──────────────────────────────────────────────────

  group('DailyFaithActivity.activityScore', () {
    test('all activities completed returns 1.0', () {
      final day = DailyFaithActivity(
        date: DateTime(2026, 8, 8),
        bibleReading: true,
        devotional: true,
        dailyVerse: true,
        promise: true,
        scriptureMemory: true,
        sermon: true,
        saved: true,
      );
      expect(day.activityScore, closeTo(1.0, 0.000001));
    });

    test('only bibleReading returns 0.35', () {
      final day = DailyFaithActivity(
        date: DateTime(2026, 8, 8),
        bibleReading: true,
        devotional: false,
        dailyVerse: false,
        promise: false,
        scriptureMemory: false,
        sermon: false,
        saved: false,
      );
      expect(day.activityScore, closeTo(0.35, 0.000001));
    });

    test('no activities returns 0.0', () {
      final day = DailyFaithActivity(
        date: DateTime(2026, 8, 8),
        bibleReading: false,
        devotional: false,
        dailyVerse: false,
        promise: false,
        scriptureMemory: false,
        sermon: false,
        saved: false,
      );
      expect(day.activityScore, 0.0);
    });

    test('weights sum to 1.0', () {
      final total = DailyFaithActivity.weights.values
          .fold<double>(0.0, (sum, w) => sum + w);
      expect(total, closeTo(1.0, 0.000001));
    });
  });

  // ── calculateWeeklyRhythm ───────────────────────────────────────────────

  DailyFaithActivity fullDay(DateTime date) => DailyFaithActivity(
        date: date,
        bibleReading: true,
        devotional: true,
        dailyVerse: true,
        promise: true,
        scriptureMemory: true,
        sermon: true,
        saved: true,
      );

  DailyFaithActivity emptyDay(DateTime date) => DailyFaithActivity(
        date: date,
        bibleReading: false,
        devotional: false,
        dailyVerse: false,
        promise: false,
        scriptureMemory: false,
        sermon: false,
        saved: false,
      );

  group('calculateWeeklyRhythm', () {
    test('one fully active day contributes exactly 1/7', () {
      final days = [
        fullDay(DateTime(2026, 8, 8)),
        ...List.generate(6, (i) => emptyDay(DateTime(2026, 8, 9 + i))),
      ];
      expect(calculateWeeklyRhythm(days), closeTo(1 / 7, 0.000001));
    });

    test('seven fully active days returns 1.0', () {
      final days = List.generate(
        7,
        (i) => fullDay(DateTime(2026, 8, 2 + i)),
      );
      expect(calculateWeeklyRhythm(days), closeTo(1.0, 0.000001));
    });

    test('one half-active day contributes approximately 0.5/7', () {
      // bibleReading (0.35) + devotional (0.20) = 0.55 — close enough to "half"
      final half = DailyFaithActivity(
        date: DateTime(2026, 8, 8),
        bibleReading: true,
        devotional: true,
        dailyVerse: false,
        promise: false,
        scriptureMemory: false,
        sermon: false,
        saved: false,
      );
      final days = [
        half,
        ...List.generate(6, (i) => emptyDay(DateTime(2026, 8, 9 + i))),
      ];
      // score = 0.55 / 7
      expect(calculateWeeklyRhythm(days), closeTo(0.55 / 7, 0.000001));
    });

    test('empty week returns 0.0', () {
      final days = List.generate(7, (i) => emptyDay(DateTime(2026, 8, 2 + i)));
      expect(calculateWeeklyRhythm(days), 0.0);
    });

    // User-specified edge-case test: one extremely active day ≤ 1/7
    test('multiple activities on one day never exceed one seventh', () {
      final day = DailyFaithActivity(
        date: DateTime(2026, 8, 8),
        bibleReading: true,
        devotional: true,
        dailyVerse: true,
        promise: true,
        scriptureMemory: true,
        sermon: true,
        saved: true,
      );
      expect(
        calculateWeeklyRhythm([day]),
        closeTo(1 / 7, 0.000001),
      );
    });
  });
}
