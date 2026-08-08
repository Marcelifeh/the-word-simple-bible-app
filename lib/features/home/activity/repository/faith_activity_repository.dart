import 'dart:convert';

import '../model/faith_activity_type.dart';

/// Lightweight repository for the three faith activities that have no prior
/// persistence: [FaithActivityType.dailyVerse], [FaithActivityType.promise],
/// and [FaithActivityType.scriptureMemory].
///
/// Stores one `Set<String>` of date-keys (`YYYY-MM-DD`) per activity type.
/// Deduplication is automatic: recording the same type on the same calendar
/// day is a no-op after the first call.
///
/// Persistence is handled externally by [AppState], which calls [encode] /
/// [decode] and owns the Hive write so the save path is the same as every
/// other setting.
class FaithActivityRepository {
  // Only the three genuinely new types need their own storage bucket.
  static const _persistedTypes = [
    FaithActivityType.dailyVerse,
    FaithActivityType.promise,
    FaithActivityType.scriptureMemory,
  ];

  final Map<FaithActivityType, Set<String>> _dates = {
    for (final t in _persistedTypes) t: <String>{},
  };

  // ── Public API ─────────────────────────────────────────────────────────

  /// Records that [type] occurred on the local calendar day of [occurredAt].
  ///
  /// Returns `true` if this is a new date for the given type (i.e. Hive
  /// should be written). Returns `false` if the date was already recorded.
  bool record(FaithActivityType type, DateTime occurredAt) {
    final bucket = _dates[type];
    if (bucket == null) return false; // not a persisted type

    final key = _dateKey(occurredAt);
    return bucket.add(key); // Set.add returns true only when newly inserted
  }

  /// Returns `true` if [type] was recorded on the local calendar day of [date].
  bool hasActivityOn(FaithActivityType type, DateTime date) {
    final bucket = _dates[type];
    if (bucket == null) return false;
    return bucket.contains(_dateKey(date));
  }

  // ── Serialisation ───────────────────────────────────────────────────────

  /// Encodes the repository to a JSON string for Hive storage.
  String encode() {
    return jsonEncode({
      for (final t in _persistedTypes)
        t.name: (_dates[t] ?? <String>{}).toList()..sort(),
    });
  }

  /// Populates the repository from a previously [encode]d string.
  /// Silently ignores malformed input.
  void decode(String? raw) {
    for (final t in _persistedTypes) {
      _dates[t]!.clear();
    }
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final t in _persistedTypes) {
        final list = map[t.name];
        if (list is List) {
          _dates[t]!.addAll(list.whereType<String>());
        }
      }
    } catch (_) {
      // Leave empty — safe default.
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────

  String _dateKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
