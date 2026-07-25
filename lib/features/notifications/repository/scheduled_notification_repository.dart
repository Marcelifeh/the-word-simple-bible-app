import 'dart:convert';

import 'package:hive/hive.dart';

import '../model/scheduled_notification_record.dart';

class ScheduledNotificationRepository {
  static const boxName = 'scheduled_notifications';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box = await _openRecovering(boxName);
  }

  List<ScheduledNotificationRecord> list() {
    final records = <ScheduledNotificationRecord>[];
    for (final raw in _box?.values ?? const <dynamic>[]) {
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        records.add(
          ScheduledNotificationRecord.fromJson(
            Map<String, dynamic>.from(decoded),
          ),
        );
      } catch (_) {
        // Preserve valid schedule records when one entry is malformed.
      }
    }
    records.sort((a, b) => a.scheduledAtUtc.compareTo(b.scheduledAtUtc));
    return List<ScheduledNotificationRecord>.unmodifiable(records);
  }

  Future<void> replaceAll(
    Iterable<ScheduledNotificationRecord> records,
  ) async {
    final box = _box;
    if (box == null) return;
    await box.clear();
    await box.putAll(
      <dynamic, dynamic>{
        for (final record in records) record.id: jsonEncode(record.toJson()),
      },
    );
  }

  Future<Box<dynamic>> _openRecovering(String name) async {
    try {
      return await Hive.openBox<dynamic>(name);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // Let the second open surface a useful storage error.
      }
      return Hive.openBox<dynamic>(name);
    }
  }
}
