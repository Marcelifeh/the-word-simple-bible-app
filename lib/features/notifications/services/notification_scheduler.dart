import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../model/notification_preferences.dart';
import '../model/notification_type.dart';
import '../model/scheduled_notification_record.dart';
import '../repository/scheduled_notification_repository.dart';
import 'app_notification_service.dart';
import 'notification_content_service.dart';

typedef NotificationCountForDate = int Function(DateTime date);
typedef NotificationCompletionForDate = bool Function(DateTime date);

class NotificationScheduler {
  NotificationScheduler({
    required AppNotificationService notificationService,
    required NotificationContentService contentService,
    required ScheduledNotificationRepository scheduleRepository,
    required NotificationCountForDate readingPlanRemainingCount,
    required NotificationCountForDate scriptureMemoryDueCount,
    required NotificationCompletionForDate devotionalCompleted,
  })  : _notificationService = notificationService,
        _contentService = contentService,
        _scheduleRepository = scheduleRepository,
        _readingPlanRemainingCount = readingPlanRemainingCount,
        _scriptureMemoryDueCount = scriptureMemoryDueCount,
        _devotionalCompleted = devotionalCompleted;

  static const rollingDays = 7;

  final AppNotificationService _notificationService;
  final NotificationContentService _contentService;
  final ScheduledNotificationRepository _scheduleRepository;
  final NotificationCountForDate _readingPlanRemainingCount;
  final NotificationCountForDate _scriptureMemoryDueCount;
  final NotificationCompletionForDate _devotionalCompleted;

  Future<void> synchronize(
    NotificationPreferences preferences, {
    DateTime? now,
    bool deliver = true,
  }) async {
    if (!preferences.masterEnabled) {
      if (deliver) {
        await cancelAllFaithReminders();
      }
      await _scheduleRepository.replaceAll(
        const <ScheduledNotificationRecord>[],
      );
      return;
    }

    final localNow = _asLocalTz(now ?? DateTime.now());
    final records = <ScheduledNotificationRecord>[];
    final occupiedStaticMinutes = <int>{};

    await _scheduleStatic(
      type: NotificationType.dailyVerse,
      id: AppNotificationIds.dailyVerse,
      preferences: preferences,
      now: localNow,
      occupiedMinutes: occupiedStaticMinutes,
      records: records,
      deliver: deliver,
    );
    await _scheduleStatic(
      type: NotificationType.dailyDevotional,
      id: AppNotificationIds.dailyDevotional,
      preferences: preferences,
      now: localNow,
      occupiedMinutes: occupiedStaticMinutes,
      records: records,
      deliver: deliver,
    );
    await _scheduleStatic(
      type: NotificationType.prayerReminder,
      id: AppNotificationIds.prayerReminder,
      preferences: preferences,
      now: localNow,
      occupiedMinutes: occupiedStaticMinutes,
      records: records,
      deliver: deliver,
    );
    await _scheduleStatic(
      type: NotificationType.eveningReflection,
      id: AppNotificationIds.eveningReflection,
      preferences: preferences,
      now: localNow,
      occupiedMinutes: occupiedStaticMinutes,
      records: records,
      deliver: deliver,
    );

    for (var dayOffset = 0; dayOffset < rollingDays; dayOffset += 1) {
      final date = DateTime(
        localNow.year,
        localNow.month,
        localNow.day + dayOffset,
      );
      final occupiedMinutes = Set<int>.of(occupiedStaticMinutes);

      await _scheduleDynamic(
        type: NotificationType.readingPlan,
        id: AppNotificationIds.readingPlanForDay(dayOffset),
        count: _readingPlanRemainingCount(date),
        date: date,
        preferences: preferences,
        now: localNow,
        occupiedMinutes: occupiedMinutes,
        records: records,
        deliver: deliver,
      );
      await _scheduleDynamic(
        type: NotificationType.scriptureMemoryReview,
        id: AppNotificationIds.scriptureMemoryForDay(dayOffset),
        count: _scriptureMemoryDueCount(date),
        date: date,
        preferences: preferences,
        now: localNow,
        occupiedMinutes: occupiedMinutes,
        records: records,
        deliver: deliver,
      );
    }

    if (deliver) {
      await _cancelObsoleteReminders(records);
    }
    await _scheduleRepository.replaceAll(records);
  }

  Future<void> cancelAllFaithReminders() async {
    for (final id in AppNotificationIds.allFaithReminderIds) {
      await _notificationService.cancel(id);
    }
  }

  Future<void> _cancelObsoleteReminders(
    Iterable<ScheduledNotificationRecord> desiredRecords,
  ) async {
    final desiredIds = desiredRecords.map((record) => record.id).toSet();
    for (final id in AppNotificationIds.allFaithReminderIds) {
      if (!desiredIds.contains(id)) {
        await _notificationService.cancel(id);
      }
    }
  }

  Future<void> _scheduleStatic({
    required NotificationType type,
    required int id,
    required NotificationPreferences preferences,
    required tz.TZDateTime now,
    required Set<int> occupiedMinutes,
    required List<ScheduledNotificationRecord> records,
    required bool deliver,
  }) async {
    if (!preferences.isEnabled(type)) return;
    final preferredMinutes = preferences.minutesFor(type);
    if (preferredMinutes == null) return;

    final date = DateTime(now.year, now.month, now.day);
    var scheduled = _resolvedDateTime(
      type: type,
      date: date,
      minutesAfterMidnight: preferredMinutes,
      preferences: preferences,
    );
    if (type == NotificationType.dailyDevotional &&
        _devotionalCompleted(date)) {
      scheduled = tz.TZDateTime(
        scheduled.location,
        scheduled.year,
        scheduled.month,
        scheduled.day + 1,
        scheduled.hour,
        scheduled.minute,
      );
    }
    scheduled = _movePast(
      scheduled: scheduled,
      now: now,
      repeatingDaily: true,
    );
    scheduled = _avoidCollision(scheduled, occupiedMinutes);
    final content = _contentService.forType(type, date: scheduled);
    final payload = _payloadFor(type, scheduled);

    if (deliver) {
      await _notificationService.schedule(
        id: id,
        title: content.title,
        body: content.body,
        scheduledDate: scheduled,
        type: type,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    records.add(
      _record(
        id: id,
        type: type,
        content: content,
        scheduled: scheduled,
        payload: payload,
      ),
    );
  }

  Future<void> _scheduleDynamic({
    required NotificationType type,
    required int id,
    required int count,
    required DateTime date,
    required NotificationPreferences preferences,
    required tz.TZDateTime now,
    required Set<int> occupiedMinutes,
    required List<ScheduledNotificationRecord> records,
    required bool deliver,
  }) async {
    if (!preferences.isEnabled(type) || count <= 0) return;
    final preferredMinutes = preferences.minutesFor(type);
    if (preferredMinutes == null) return;

    var scheduled = _resolvedDateTime(
      type: type,
      date: date,
      minutesAfterMidnight: preferredMinutes,
      preferences: preferences,
    );
    scheduled = _avoidCollision(scheduled, occupiedMinutes);
    if (!scheduled.isAfter(now)) return;

    final content = _contentService.forType(
      type,
      date: date,
      count: count,
    );
    final payload = _payloadFor(type, date);
    if (deliver) {
      await _notificationService.schedule(
        id: id,
        title: content.title,
        body: content.body,
        scheduledDate: scheduled,
        type: type,
        payload: payload,
      );
    }
    records.add(
      _record(
        id: id,
        type: type,
        content: content,
        scheduled: scheduled,
        payload: payload,
      ),
    );
  }

  tz.TZDateTime _resolvedDateTime({
    required NotificationType type,
    required DateTime date,
    required int minutesAfterMidnight,
    required NotificationPreferences preferences,
  }) {
    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      minutesAfterMidnight ~/ 60,
      minutesAfterMidnight % 60,
    );
    if (!preferences.quietHoursEnabled ||
        preferences.quietHoursOverrides.contains(type)) {
      return scheduled;
    }

    return moveOutsideQuietHours(
      scheduled: scheduled,
      quietStartMinutes: preferences.quietStartMinutes,
      quietEndMinutes: preferences.quietEndMinutes,
    );
  }

  tz.TZDateTime _movePast({
    required tz.TZDateTime scheduled,
    required tz.TZDateTime now,
    required bool repeatingDaily,
  }) {
    if (scheduled.isAfter(now) || !repeatingDaily) return scheduled;
    return tz.TZDateTime(
      scheduled.location,
      scheduled.year,
      scheduled.month,
      scheduled.day + 1,
      scheduled.hour,
      scheduled.minute,
    );
  }

  tz.TZDateTime _avoidCollision(
    tz.TZDateTime scheduled,
    Set<int> occupiedMinutes,
  ) {
    var candidate = scheduled;
    var minute = candidate.hour * 60 + candidate.minute;
    while (occupiedMinutes.contains(minute)) {
      candidate = candidate.add(const Duration(minutes: 5));
      minute = candidate.hour * 60 + candidate.minute;
    }
    occupiedMinutes.add(minute);
    return candidate;
  }

  String _payloadFor(NotificationType type, DateTime date) {
    final route = switch (type) {
      NotificationType.dailyVerse => '/daily-verse',
      NotificationType.dailyDevotional => '/devotional',
      NotificationType.readingPlan => '/reading-plan',
      NotificationType.scriptureMemoryReview => '/scripture-memory',
      NotificationType.prayerReminder => '/prayer',
      NotificationType.eveningReflection => '/journal',
      NotificationType.appUpdate ||
      NotificationType.importantAnnouncement =>
        '/notifications',
    };
    return jsonEncode(<String, dynamic>{
      'type': type.wireName,
      'route': route,
      'date': _dateKey(date),
      if (type == NotificationType.scriptureMemoryReview) 'tab': 'today',
    });
  }

  ScheduledNotificationRecord _record({
    required int id,
    required NotificationType type,
    required NotificationContent content,
    required tz.TZDateTime scheduled,
    required String payload,
  }) {
    return ScheduledNotificationRecord(
      id: id,
      type: type,
      title: content.title,
      body: content.body,
      scheduledAtUtc: scheduled.toUtc(),
      payload: payload,
    );
  }

  tz.TZDateTime _asLocalTz(DateTime value) {
    if (value is tz.TZDateTime && value.location == tz.local) return value;
    return tz.TZDateTime.from(value, tz.local);
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

bool isInsideQuietHours({
  required int minutesAfterMidnight,
  required int quietStartMinutes,
  required int quietEndMinutes,
}) {
  if (quietStartMinutes == quietEndMinutes) return false;
  if (quietStartMinutes < quietEndMinutes) {
    return minutesAfterMidnight >= quietStartMinutes &&
        minutesAfterMidnight < quietEndMinutes;
  }
  return minutesAfterMidnight >= quietStartMinutes ||
      minutesAfterMidnight < quietEndMinutes;
}

T moveOutsideQuietHours<T extends DateTime>({
  required T scheduled,
  required int quietStartMinutes,
  required int quietEndMinutes,
}) {
  final minute = scheduled.hour * 60 + scheduled.minute;
  if (!isInsideQuietHours(
    minutesAfterMidnight: minute,
    quietStartMinutes: quietStartMinutes,
    quietEndMinutes: quietEndMinutes,
  )) {
    return scheduled;
  }

  final movesToNextDay =
      quietStartMinutes > quietEndMinutes && minute >= quietStartMinutes;
  final dayOffset = movesToNextDay ? 1 : 0;
  if (scheduled is tz.TZDateTime) {
    return tz.TZDateTime(
      scheduled.location,
      scheduled.year,
      scheduled.month,
      scheduled.day + dayOffset,
      quietEndMinutes ~/ 60,
      quietEndMinutes % 60,
    ) as T;
  }
  return DateTime(
    scheduled.year,
    scheduled.month,
    scheduled.day + dayOffset,
    quietEndMinutes ~/ 60,
    quietEndMinutes % 60,
  ) as T;
}
