import 'dart:async';

import '../model/app_notification_inbox_item.dart';
import '../model/notification_type.dart';
import '../repository/notification_inbox_repository.dart';
import '../repository/notification_preferences_repository.dart';
import '../repository/scheduled_notification_repository.dart';
import 'notification_scheduler.dart';

class NotificationCoordinator {
  NotificationCoordinator({
    required NotificationPreferencesRepository preferencesRepository,
    required ScheduledNotificationRepository scheduleRepository,
    required NotificationInboxRepository inboxRepository,
    required NotificationScheduler scheduler,
  })  : _preferencesRepository = preferencesRepository,
        _scheduleRepository = scheduleRepository,
        _inboxRepository = inboxRepository,
        _scheduler = scheduler;

  final NotificationPreferencesRepository _preferencesRepository;
  final ScheduledNotificationRepository _scheduleRepository;
  final NotificationInboxRepository _inboxRepository;
  final NotificationScheduler _scheduler;

  bool _refreshing = false;
  bool _refreshAgain = false;
  bool _foreground = true;
  Timer? _foregroundRefreshTimer;

  void setForeground(bool value) {
    _foreground = value;
    if (!value) {
      _foregroundRefreshTimer?.cancel();
      _foregroundRefreshTimer = null;
    }
  }

  Future<void> refresh({DateTime? now}) async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        await _scheduler.synchronize(
          _preferencesRepository.preferences,
          now: now,
          deliver: true,
        );
      } while (_refreshAgain);
    } finally {
      _refreshing = false;
      _scheduleForegroundRefresh();
    }
  }

  Future<void> recordNotificationTap(String payload) async {
    ScheduledNotificationRecordMatch? match;
    for (final record in _scheduleRepository.list()) {
      if (record.payload == payload) {
        match = ScheduledNotificationRecordMatch(
          id: record.id,
          type: record.type,
          title: record.title,
          body: record.body,
        );
      }
    }
    if (match == null) return;
    final now = DateTime.now().toUtc();
    await _inboxRepository.add(
      AppNotificationInboxItem(
        id: 'tap_${match.id}_${now.millisecondsSinceEpoch}',
        type: match.type,
        title: match.title,
        body: match.body,
        receivedAtUtc: now,
        payload: payload,
        isRead: true,
      ),
    );
  }

  void dispose() {
    _foregroundRefreshTimer?.cancel();
  }

  void _scheduleForegroundRefresh() {
    _foregroundRefreshTimer?.cancel();
    _foregroundRefreshTimer = null;
    if (!_foreground) return;

    final now = DateTime.now().toUtc();
    DateTime? next;
    for (final record in _scheduleRepository.list()) {
      if (!record.scheduledAtUtc.isAfter(now)) continue;
      if (next == null || record.scheduledAtUtc.isBefore(next)) {
        next = record.scheduledAtUtc;
      }
    }
    if (next == null) return;

    final delay = next.difference(now) + const Duration(seconds: 1);
    _foregroundRefreshTimer = Timer(delay, () {
      unawaited(_deliverForegroundNotifications());
    });
  }

  Future<void> _deliverForegroundNotifications() async {
    if (!_foreground) return;
    await _inboxRepository.materializeDue(_scheduleRepository.list());
    await refresh();
  }
}

class ScheduledNotificationRecordMatch {
  const ScheduledNotificationRecordMatch({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
  });

  final int id;
  final NotificationType type;
  final String title;
  final String body;
}
