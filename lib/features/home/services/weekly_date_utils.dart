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
