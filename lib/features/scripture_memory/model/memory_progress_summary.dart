import 'memory_review_event.dart';

class MemoryProgressSummary {
  const MemoryProgressSummary({
    this.learningCount = 0,
    this.establishedCount = 0,
    this.strengtheningCount = 0,
    this.reviewsThisMonth = 0,
    this.practiceDaysThisMonth = 0,
    this.streakDays = 0,
    this.collectionsStartedCount = 0,
    this.recentActivity = const <MemoryReviewEvent>[],
  });

  final int learningCount;
  final int establishedCount;
  final int strengtheningCount;
  final int reviewsThisMonth;
  final int practiceDaysThisMonth;
  final int streakDays;
  final int collectionsStartedCount;
  final List<MemoryReviewEvent> recentActivity;
}
