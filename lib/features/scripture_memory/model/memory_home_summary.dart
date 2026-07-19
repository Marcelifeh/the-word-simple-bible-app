class MemoryHomeSummary {
  const MemoryHomeSummary({
    this.dueCount = 0,
    this.activeCount = 0,
    this.establishedCount = 0,
    this.streakDays = 0,
    this.reviewedToday = 0,
  });

  final int dueCount;
  final int activeCount;
  final int establishedCount;
  final int streakDays;
  final int reviewedToday;
}
