import 'faith_activity_type.dart';

/// Represents one calendar day's worth of spiritual activity.
///
/// Each boolean field indicates whether a meaningful engagement occurred on
/// [date]. Multiple events of the same type on the same day collapse to a
/// single `true` (deduplication happens at the repository level).
///
/// [activityScore] returns a value in [0.0, 1.0] representing how much of
/// an "ideal" day was completed. When this is folded across seven days and
/// divided by 7, **no single day can ever contribute more than 1/7 of the
/// weekly ring**, regardless of how many activities happened on that day.
class DailyFaithActivity {
  const DailyFaithActivity({
    required this.date,
    required this.bibleReading,
    required this.devotional,
    required this.dailyVerse,
    required this.promise,
    required this.scriptureMemory,
    required this.sermon,
    required this.saved,
  });

  /// Weights for each activity type. Values must sum to exactly 1.0.
  ///
  /// Kept as a single public constant so auditing or adjusting weights
  /// requires only one change.
  static const Map<FaithActivityType, double> weights = {
    FaithActivityType.bibleReading: 0.35,
    FaithActivityType.devotional: 0.20,
    FaithActivityType.scriptureMemory: 0.15,
    FaithActivityType.dailyVerse: 0.10,
    FaithActivityType.promise: 0.10,
    FaithActivityType.sermon: 0.05,
    FaithActivityType.saved: 0.05,
  };

  /// The local calendar date this record covers (midnight 00:00).
  final DateTime date;

  final bool bibleReading;
  final bool devotional;
  final bool dailyVerse;
  final bool promise;
  final bool scriptureMemory;
  final bool sermon;
  final bool saved;

  /// Weighted sum of completed activities, clamped to [0.0, 1.0].
  ///
  /// A fully active day returns 1.0. That day's contribution to the weekly
  /// ring is then `1.0 / 7 ≈ 14.29%`.
  double get activityScore {
    var score = 0.0;
    if (bibleReading) score += weights[FaithActivityType.bibleReading]!;
    if (devotional) score += weights[FaithActivityType.devotional]!;
    if (scriptureMemory) score += weights[FaithActivityType.scriptureMemory]!;
    if (dailyVerse) score += weights[FaithActivityType.dailyVerse]!;
    if (promise) score += weights[FaithActivityType.promise]!;
    if (sermon) score += weights[FaithActivityType.sermon]!;
    if (saved) score += weights[FaithActivityType.saved]!;
    return score.clamp(0.0, 1.0);
  }
}
