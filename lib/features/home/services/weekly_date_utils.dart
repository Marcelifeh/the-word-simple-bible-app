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

int countWeeklyReadingDays({
  required Iterable<DateTime> completedReadingDates,
  required DateTime now,
}) {
  return countUniqueDaysInSundayWeek(
    dates: completedReadingDates,
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
