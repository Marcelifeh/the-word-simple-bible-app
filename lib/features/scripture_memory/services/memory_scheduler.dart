import '../model/memory_review_event.dart';
import '../model/memory_schedule.dart';

class MemoryScheduler {
  const MemoryScheduler();

  static const intervalsInDays = <int>[0, 1, 3, 7, 14, 30, 60, 120];

  MemorySchedule newSchedule({DateTime? now}) {
    final today = localDay(now ?? DateTime.now());
    return MemorySchedule(
      status: MemoryStatus.newVerse,
      stage: 0,
      dueLocalDate: formatLocalDate(today),
    );
  }

  MemorySchedule recordActiveRecall({
    required MemorySchedule current,
    required MemoryReviewRating rating,
    DateTime? now,
  }) {
    final today = localDay(now ?? DateTime.now());
    final previousStage =
        current.stage.clamp(0, intervalsInDays.length - 1).toInt();
    late final int nextStage;
    late final int lapseIncrement;

    switch (rating) {
      case MemoryReviewRating.needsPractice:
        nextStage =
            (previousStage - 1).clamp(0, intervalsInDays.length - 1).toInt();
        lapseIncrement = 1;
        break;
      case MemoryReviewRating.almostThere:
        nextStage = previousStage == 0 ? 1 : previousStage;
        lapseIncrement = 0;
        break;
      case MemoryReviewRating.remembered:
        nextStage =
            (previousStage + 1).clamp(1, intervalsInDays.length - 1).toInt();
        lapseIncrement = 0;
        break;
      case MemoryReviewRating.easyToday:
        nextStage =
            (previousStage + 2).clamp(1, intervalsInDays.length - 1).toInt();
        lapseIncrement = 0;
        break;
    }

    final dueOffset = rating == MemoryReviewRating.needsPractice
        ? 0
        : intervalsInDays[nextStage];
    final status = nextStage >= 5
        ? MemoryStatus.established
        : nextStage == 0
            ? MemoryStatus.learning
            : MemoryStatus.reviewing;

    return MemorySchedule(
      status: status,
      stage: nextStage,
      dueLocalDate: formatLocalDate(today.add(Duration(days: dueOffset))),
      lastReviewedLocalDate: formatLocalDate(today),
      reviewCount: current.reviewCount + 1,
      lapseCount: current.lapseCount + lapseIncrement,
      hasReachedEstablished: current.hasReachedEstablished || nextStage >= 5,
    );
  }

  bool isDue(MemorySchedule schedule, {DateTime? now}) {
    if (schedule.status == MemoryStatus.archived) return false;
    final due = tryParseLocalDate(schedule.dueLocalDate);
    if (due == null) return true;
    final today = localDay(now ?? DateTime.now());
    return !due.isAfter(today);
  }

  static DateTime localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String formatLocalDate(DateTime value) {
    final day = localDay(value);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  static DateTime? tryParseLocalDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }
}
