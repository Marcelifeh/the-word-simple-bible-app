import '../model/promise_history_entry.dart';

class PromiseRotation {
  const PromiseRotation._();

  static const int minimumRepeatGap = 60;
  static final DateTime _rotationEpoch = DateTime(2026, 1, 1);

  static int selectIndex(
    List<Map<String, dynamic>> items, {
    required DateTime date,
    List<PromiseHistoryEntry> history = const <PromiseHistoryEntry>[],
  }) {
    if (items.isEmpty) {
      throw StateError('Promise catalog cannot be empty.');
    }

    final target = PromiseHistoryEntry.localDay(date);
    final sameDayEntry = _latestHistoryEntry(
      history,
      target,
      minimumAge: 0,
      maximumAge: 0,
    );
    if (sameDayEntry != null) {
      final existingIndex = items.indexWhere(
        (item) => _id(item) == sameDayEntry.promiseId,
      );
      if (existingIndex >= 0) return existingIndex;
    }

    final persistedRecentIds = history
        .where((entry) {
          final age = PromiseHistoryEntry.calendarDaysBetween(
            target,
            entry.shownOn,
          );
          return age >= 1 && age <= minimumRepeatGap;
        })
        .map((entry) => entry.promiseId)
        .toSet();
    final previousActualTheme = _latestHistoryEntry(
      history,
      target,
      minimumAge: 1,
    )?.theme.toLowerCase();

    final start = target.isBefore(_rotationEpoch) ? target : _rotationEpoch;
    final generatedRecentIds = <String>[];
    String? previousGeneratedTheme;
    var selectedIndex = 0;
    var cursor = start;
    var dayIndex = 0;

    while (!cursor.isAfter(target)) {
      final seasonalThemes = _seasonalThemes(cursor);
      final startIndex = _positiveModulo(dayIndex * 37 + 11, items.length);
      final baseRanking = List<int>.generate(items.length, (offset) {
        return (startIndex + offset) % items.length;
      });
      final ranked = seasonalThemes.isEmpty
          ? baseRanking
          : <int>[
              ...baseRanking.where(
                (index) => seasonalThemes.contains(_theme(items[index])),
              ),
              ...baseRanking.where(
                (index) => !seasonalThemes.contains(_theme(items[index])),
              ),
            ];

      final isTarget = _sameLocalDate(cursor, target);
      final blockedIds = <String>{...generatedRecentIds};
      if (isTarget) blockedIds.addAll(persistedRecentIds);
      final themeToAvoid = isTarget && previousActualTheme != null
          ? previousActualTheme
          : previousGeneratedTheme;

      selectedIndex = ranked.firstWhere(
        (index) {
          final item = items[index];
          return !blockedIds.contains(_id(item)) &&
              _theme(item) != themeToAvoid;
        },
        orElse: () => ranked.firstWhere(
          (index) => !blockedIds.contains(_id(items[index])),
          orElse: () => ranked.firstWhere(
            (index) => _theme(items[index]) != themeToAvoid,
            orElse: () => ranked.first,
          ),
        ),
      );

      final selected = items[selectedIndex];
      generatedRecentIds.add(_id(selected));
      if (generatedRecentIds.length > minimumRepeatGap) {
        generatedRecentIds.removeAt(0);
      }
      previousGeneratedTheme = _theme(selected);
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      dayIndex += 1;
    }

    return selectedIndex;
  }

  static PromiseHistoryEntry? _latestHistoryEntry(
    List<PromiseHistoryEntry> history,
    DateTime target, {
    required int minimumAge,
    int? maximumAge,
  }) {
    PromiseHistoryEntry? latest;
    var latestAge = 1 << 30;
    for (final entry in history) {
      final age = PromiseHistoryEntry.calendarDaysBetween(
        target,
        entry.shownOn,
      );
      if (age < minimumAge || (maximumAge != null && age > maximumAge)) {
        continue;
      }
      if (age < latestAge) {
        latest = entry;
        latestAge = age;
      }
    }
    return latest;
  }

  static Set<String> _seasonalThemes(DateTime date) {
    if ((date.month == 12 && date.day == 31) ||
        (date.month == 1 && date.day <= 3)) {
      return const {'renewal', 'purpose', 'hope'};
    }
    if (date.month == 12 && date.day >= 20 && date.day <= 26) {
      return const {'salvation', "god's love", 'joy', 'peace'};
    }

    final easter = _easterSunday(date.year);
    final daysFromEaster = PromiseHistoryEntry.calendarDaysBetween(
      date,
      easter,
    );
    if (daysFromEaster >= -7 && daysFromEaster <= 1) {
      return const {'victory', 'salvation', 'hope', 'renewal'};
    }
    return const <String>{};
  }

  static DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static String _id(Map<String, dynamic> item) {
    final id = item['id']?.toString().trim() ?? '';
    return id.isNotEmpty ? id : _referenceKey(item);
  }

  static String _referenceKey(Map<String, dynamic> item) {
    return '${item['bookId']}:${item['chapter']}:${item['verse']}';
  }

  static String _theme(Map<String, dynamic> item) {
    return (item['tag'] ?? item['theme'] ?? '').toString().trim().toLowerCase();
  }

  static bool _sameLocalDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int _positiveModulo(int value, int divisor) {
    return ((value % divisor) + divisor) % divisor;
  }
}
