import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../model/notification_preferences.dart';

class NotificationPreferencesRepository extends ChangeNotifier {
  static const boxName = 'notification_preferences';
  static const _preferencesKey = 'preferences';

  Box<dynamic>? _box;
  NotificationPreferences _preferences = NotificationPreferences.defaults;

  NotificationPreferences get preferences => _preferences;

  Future<void> init() async {
    _box = await _openRecovering(boxName);
    final raw = _box?.get(_preferencesKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _preferences = NotificationPreferences.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        _preferences = NotificationPreferences.defaults;
      }
    }

    // Re-save migrated or recovered values in the current schema.
    await _box?.put(_preferencesKey, jsonEncode(_preferences.toJson()));
  }

  Future<void> save(NotificationPreferences preferences) async {
    _preferences = preferences.copyWith(
      schemaVersion: NotificationPreferences.currentSchemaVersion,
    );
    await _box?.put(_preferencesKey, jsonEncode(_preferences.toJson()));
    notifyListeners();
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
