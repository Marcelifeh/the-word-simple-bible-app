import '../data/devotional_topics.dart';
import '../model/devotional_model.dart';

/// Selects and serves [DevotionalModel] objects.
///
/// Today's devotional is chosen by the sequential calendar-day index
/// (days since Unix epoch), advancing by exactly one devotional every
/// 24 hours at midnight — no API required.
class DevotionalService {
  const DevotionalService();

  static final DateTime contentStartDate = DateTime(2024, 1, 1);

  /// Returns today's devotional.
  ///
  /// Uses the number of days since the Unix epoch so it advances precisely
  /// at midnight on every device, regardless of time-zone offset.
  DevotionalModel getTodaysDevotional({DateTime? now}) {
    final dayIndex = _todayIndex(now ?? DateTime.now());
    return DevotionalTopics.all[dayIndex];
  }

  DevotionalModel getDevotionalForDate(DateTime date) {
    final dayIndex = _todayIndex(date);
    return DevotionalTopics.all[dayIndex];
  }

  /// Returns devotionals the user has already opened, newest first.
  List<DevotionalModel> getHistoryDevotionals({
    Map<String, DateTime> readHistory = const {},
    DateTime? now,
  }) {
    if (readHistory.isEmpty) {
      return const <DevotionalModel>[];
    }

    final historyEntries = readHistory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final devotionals = <DevotionalModel>[];
    final seenIds = <String>{};
    for (final entry in historyEntries) {
      final devotional = getById(entry.key);
      if (devotional != null && seenIds.add(devotional.id)) {
        devotionals.add(devotional);
      }
    }

    if (devotionals.length < DevotionalTopics.all.length) {
      return List<DevotionalModel>.unmodifiable(devotionals);
    }

    final todayIndex = _todayIndex(now ?? DateTime.now());
    return List<DevotionalModel>.unmodifiable(
      List<DevotionalModel>.generate(
        devotionals.length,
        (offset) => DevotionalTopics.all[
            (todayIndex - offset + DevotionalTopics.all.length) %
                DevotionalTopics.all.length],
      ),
    );
  }

  /// The index into [DevotionalTopics.all] that is active today.
  int _todayIndex(DateTime now) {
    final devotionalCount = DevotionalTopics.all.length;
    if (devotionalCount == 0) return 0;
    final daysSinceEpoch = _daysSinceEpoch(now);
    return daysSinceEpoch.abs() % devotionalCount;
  }

  int _daysSinceEpoch(DateTime now) {
    // Count calendar days, not elapsed 24-hour periods. Local elapsed time can
    // be 23 or 25 hours across daylight-saving boundaries, which would delay
    // the rollover at midnight in DST months.
    final start = DateTime.utc(
      contentStartDate.year,
      contentStartDate.month,
      contentStartDate.day,
    );
    final current = DateTime.utc(now.year, now.month, now.day);
    return current.difference(start).inDays;
  }

  /// Milliseconds until the next midnight (when the devotional will change).
  Duration get timeUntilNextDevotional {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Returns the devotional for a specific topic ID (e.g. "peace").
  DevotionalModel? getById(String id) {
    try {
      return DevotionalTopics.all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All available devotionals.
  List<DevotionalModel> get all => DevotionalTopics.all;
}
