import '../model/memory_progress_summary.dart';
import '../model/memory_review_event.dart';
import '../model/memory_verse.dart';
import 'memory_scheduler.dart';

class MemoryProgressCalculator {
  const MemoryProgressCalculator();

  MemoryProgressSummary calculate({
    required Iterable<MemoryVerse> verses,
    required Iterable<MemoryReviewEvent> events,
    DateTime? now,
  }) {
    final active = verses.where((verse) => !verse.isArchived).toList();
    final allEvents = events.toList()
      ..sort((a, b) => b.completedAtUtc.compareTo(a.completedAtUtc));
    final today = MemoryScheduler.formatLocalDate(now ?? DateTime.now());
    final monthPrefix = today.substring(0, 7);
    final monthEvents = allEvents
        .where((event) => event.completedLocalDate.startsWith(monthPrefix))
        .toList(growable: false);
    final established = active
        .where((verse) => verse.schedule.hasReachedEstablished)
        .toList(growable: false);

    return MemoryProgressSummary(
      learningCount:
          active.where((verse) => !verse.schedule.hasReachedEstablished).length,
      establishedCount: established.length,
      strengtheningCount:
          established.where((verse) => verse.schedule.stage < 5).length,
      reviewsThisMonth: monthEvents.length,
      practiceDaysThisMonth:
          monthEvents.map((event) => event.completedLocalDate).toSet().length,
      streakDays: _streakDays(allEvents, now ?? DateTime.now()),
      collectionsStartedCount:
          active.expand((verse) => verse.collectionIds).toSet().length,
      recentActivity: List<MemoryReviewEvent>.unmodifiable(
        allEvents.take(8),
      ),
    );
  }

  int _streakDays(List<MemoryReviewEvent> events, DateTime now) {
    if (events.isEmpty) return 0;
    final reviewedDates =
        events.map((event) => event.completedLocalDate).toSet();
    var cursor = MemoryScheduler.localDay(now);
    if (!reviewedDates.contains(MemoryScheduler.formatLocalDate(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (reviewedDates.contains(MemoryScheduler.formatLocalDate(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
