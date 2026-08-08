import '../activity/model/daily_faith_activity.dart';

DateTime normalizeLocalDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime startOfSundayWeek(DateTime value) {
  final date = normalizeLocalDate(value);
  return date.subtract(Duration(days: date.weekday % DateTime.daysPerWeek));
}

DateTime endOfSundayWeek(DateTime value) {
  return startOfSundayWeek(value).add(
    const Duration(days: DateTime.daysPerWeek),
  );
}

bool isWithinSundayWeek(DateTime eventDate, DateTime now) {
  final start = startOfSundayWeek(now);
  final endExclusive = endOfSundayWeek(now);
  final date = normalizeLocalDate(eventDate);
  return !date.isBefore(start) && date.isBefore(endExclusive);
}

int countUniqueDaysInSundayWeek({
  required Iterable<DateTime> dates,
  required DateTime now,
}) {
  final uniqueDays = <DateTime>{
    for (final value in dates)
      if (isWithinSundayWeek(value, now)) normalizeLocalDate(value),
  };
  return uniqueDays.length.clamp(0, DateTime.daysPerWeek);
}

DateTime _localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _localDateKey(DateTime value) {
  final date = _localDateOnly(value);

  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int calculateBibleReadingDays({
  required Iterable<DateTime> completedAtDates,
  required DateTime now,
}) {
  final weekStart = startOfSundayWeek(now);
  final nextWeekStart = weekStart.add(
    const Duration(days: 7),
  );

  final uniqueReadingDates = <String>{};

  for (final completedAt in completedAtDates) {
    final localDate = _localDateOnly(completedAt);

    if (localDate.isBefore(weekStart) || !localDate.isBefore(nextWeekStart)) {
      continue;
    }

    uniqueReadingDates.add(_localDateKey(localDate));
  }

  return uniqueReadingDates.length.clamp(0, 7);
}

int countWeeklyReadingDays({
  required Iterable<DateTime> completedReadingDates,
  required DateTime now,
}) {
  return calculateBibleReadingDays(
    completedAtDates: completedReadingDates,
    now: now,
  );
}

int countWeeklyDevotionalDays({
  required Iterable<DateTime> completedDevotionalDates,
  required DateTime now,
}) {
  return countUniqueDaysInSundayWeek(
    dates: completedDevotionalDates,
    now: now,
  );
}

/// Returns the ordinal position of [now] within the current Sunday-start week.
///
/// Sunday = 1, Monday = 2, …, Saturday = 7.
///
/// Dart's [DateTime.weekday] uses Monday = 1 … Sunday = 7.
/// The mapping (weekday % 7) + 1 converts that to the Sunday-anchored scale:
///   Monday   1 % 7 = 1  → 2
///   Tuesday  2 % 7 = 2  → 3
///   …
///   Saturday 6 % 7 = 6  → 7
///   Sunday   7 % 7 = 0  → 1  ✓
int calendarDayOfSundayWeek(DateTime now) {
  final local = now.toLocal();
  return (local.weekday % 7) + 1;
}

/// Fraction of the current Sunday–Saturday week that has elapsed.
///
/// Sunday  → ~0.143 (1/7)
/// Saturday → 1.0   (7/7)
double calendarWeekProgress(DateTime now) {
  return (calendarDayOfSundayWeek(now) / 7.0).clamp(0.0, 1.0);
}

/// Computes the weekly rhythm ring value from a list of [DailyFaithActivity]
/// objects — one per day of the current Sun–Sat week (7 entries).
///
/// Each day's [DailyFaithActivity.activityScore] is summed and then divided
/// by 7. This guarantees that **no single day can ever contribute more than
/// 1/7 (≈ 14.29%) of the weekly total**, regardless of how many activities
/// occurred on that day.
///
/// Pass exactly 7 entries (one per week-day, future days with all-false
/// values) to keep the denominator constant and the ring deterministic.
double calculateWeeklyRhythm(Iterable<DailyFaithActivity> days) {
  final total = days.fold<double>(
    0.0,
    (sum, day) => sum + day.activityScore,
  );
  return (total / 7.0).clamp(0.0, 1.0);
}
