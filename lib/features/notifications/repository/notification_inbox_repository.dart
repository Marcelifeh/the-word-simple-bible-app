import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../model/app_notification_inbox_item.dart';
import '../model/scheduled_notification_record.dart';

class NotificationInboxRepository extends ChangeNotifier {
  static const boxName = 'notification_inbox';
  static const maxItems = 100;

  Box<dynamic>? _box;
  final Map<String, AppNotificationInboxItem> _itemsById = {};

  List<AppNotificationInboxItem> get items {
    final values = _itemsById.values.toList(growable: false)
      ..sort((a, b) => b.receivedAtUtc.compareTo(a.receivedAtUtc));
    return List<AppNotificationInboxItem>.unmodifiable(values);
  }

  int get unreadCount => _itemsById.values.where((item) => !item.isRead).length;

  Future<void> init() async {
    _box = await _openRecovering(boxName);
    _load();
  }

  Future<void> add(AppNotificationInboxItem item) async {
    if (_itemsById.containsKey(item.id)) return;
    _itemsById[item.id] = item;
    await _box?.put(item.id, jsonEncode(item.toJson()));
    await _trim();
    notifyListeners();
  }

  Future<void> materializeDue(
    Iterable<ScheduledNotificationRecord> records, {
    DateTime? now,
  }) async {
    final nowUtc = (now ?? DateTime.now()).toUtc();
    var changed = false;
    for (final record in records) {
      if (record.scheduledAtUtc.isAfter(nowUtc)) continue;
      final itemId =
          'local_${record.id}_${record.scheduledAtUtc.millisecondsSinceEpoch}';
      if (_itemsById.containsKey(itemId)) continue;
      final item = AppNotificationInboxItem(
        id: itemId,
        type: record.type,
        title: record.title,
        body: record.body,
        receivedAtUtc: record.scheduledAtUtc,
        payload: record.payload,
        isRead: false,
      );
      _itemsById[item.id] = item;
      await _box?.put(item.id, jsonEncode(item.toJson()));
      changed = true;
    }
    if (!changed) return;
    await _trim();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final item = _itemsById[id];
    if (item == null || item.isRead) return;
    final updated = item.copyWith(isRead: true);
    _itemsById[id] = updated;
    await _box?.put(id, jsonEncode(updated.toJson()));
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final unread =
        _itemsById.values.where((item) => !item.isRead).toList(growable: false);
    if (unread.isEmpty) return;
    for (final item in unread) {
      final updated = item.copyWith(isRead: true);
      _itemsById[item.id] = updated;
      await _box?.put(item.id, jsonEncode(updated.toJson()));
    }
    notifyListeners();
  }

  void _load() {
    _itemsById.clear();
    for (final raw in _box?.values ?? const <dynamic>[]) {
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final item = AppNotificationInboxItem.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        _itemsById[item.id] = item;
      } catch (_) {
        // Skip a malformed inbox item without discarding the rest.
      }
    }
  }

  Future<void> _trim() async {
    final sorted = items;
    if (sorted.length <= maxItems) return;
    final expired = sorted.skip(maxItems).toList(growable: false);
    for (final item in expired) {
      _itemsById.remove(item.id);
    }
    await _box?.deleteAll(expired.map((item) => item.id));
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
