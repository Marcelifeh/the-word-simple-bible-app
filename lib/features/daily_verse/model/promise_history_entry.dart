import 'dart:convert';

class PromiseHistoryEntry {
  const PromiseHistoryEntry({
    required this.promiseId,
    required this.theme,
    required this.shownOn,
  });

  final String promiseId;
  final String theme;
  final DateTime shownOn;

  Map<String, dynamic> toJson() {
    return {
      'promiseId': promiseId,
      'theme': theme,
      'shownOn': _dateKey(shownOn),
    };
  }

  static PromiseHistoryEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final promiseId = value['promiseId']?.toString().trim() ?? '';
    final theme = value['theme']?.toString().trim() ?? '';
    final shownOn = DateTime.tryParse(value['shownOn']?.toString() ?? '');
    if (promiseId.isEmpty || theme.isEmpty || shownOn == null) return null;

    return PromiseHistoryEntry(
      promiseId: promiseId,
      theme: theme,
      shownOn: localDay(shownOn),
    );
  }

  static List<PromiseHistoryEntry> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <PromiseHistoryEntry>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PromiseHistoryEntry>[];
      return decoded
          .map(fromJson)
          .whereType<PromiseHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const <PromiseHistoryEntry>[];
    }
  }

  static String encodeList(Iterable<PromiseHistoryEntry> entries) {
    return jsonEncode(entries.map((entry) => entry.toJson()).toList());
  }

  static DateTime localDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static int calendarDaysBetween(DateTime later, DateTime earlier) {
    final laterUtc = DateTime.utc(later.year, later.month, later.day);
    final earlierUtc = DateTime.utc(earlier.year, earlier.month, earlier.day);
    return laterUtc.difference(earlierUtc).inDays;
  }

  static String _dateKey(DateTime value) {
    final day = localDay(value);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }
}
