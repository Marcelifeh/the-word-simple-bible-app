import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/notifications/model/notification_preferences.dart';
import 'package:simple_bible_app/features/notifications/model/notification_type.dart';
import 'package:simple_bible_app/features/notifications/model/scheduled_notification_record.dart';
import 'package:simple_bible_app/features/notifications/repository/notification_inbox_repository.dart';
import 'package:simple_bible_app/features/notifications/repository/notification_preferences_repository.dart';
import 'package:simple_bible_app/features/notifications/repository/scheduled_notification_repository.dart';
import 'package:simple_bible_app/features/notifications/services/app_notification_service.dart';
import 'package:simple_bible_app/features/notifications/services/notification_content_service.dart';
import 'package:simple_bible_app/features/notifications/services/notification_coordinator.dart';
import 'package:simple_bible_app/features/notifications/services/notification_scheduler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late _FakeNotificationService notificationService;
  late _MemoryScheduleRepository scheduleRepository;
  late NotificationContentService contentService;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    tz.setLocalLocation(tz.getLocation('America/Toronto'));
    notificationService = _FakeNotificationService();
    scheduleRepository = _MemoryScheduleRepository();
    contentService = NotificationContentService(
      assetLoader: () async => jsonEncode(
        <String, dynamic>{
          for (final type in NotificationType.values)
            type.wireName: <Map<String, String>>[
              <String, String>{
                'title': type.displayName,
                'bodyTemplate': '{count} {passages} {verses}',
                'body': 'Reminder body',
              },
            ],
        },
      ),
    );
    await contentService.init();
  });

  NotificationScheduler buildScheduler({
    int Function(DateTime)? readingCount,
    int Function(DateTime)? memoryCount,
  }) {
    return NotificationScheduler(
      notificationService: notificationService,
      contentService: contentService,
      scheduleRepository: scheduleRepository,
      readingPlanRemainingCount: readingCount ?? (_) => 0,
      scriptureMemoryDueCount: memoryCount ?? (_) => 0,
      devotionalCompleted: (_) => false,
    );
  }

  NotificationPreferences dailyVerseOnly() {
    return NotificationPreferences.defaults.copyWith(
      devotionalEnabled: false,
      readingPlanEnabled: false,
      scriptureMemoryEnabled: false,
      prayerEnabled: false,
      eveningReflectionEnabled: false,
    );
  }

  NotificationPreferences dynamicOnly() {
    return NotificationPreferences.defaults.copyWith(
      dailyVerseEnabled: false,
      devotionalEnabled: false,
      prayerEnabled: false,
      eveningReflectionEnabled: false,
    );
  }

  test('master switch cancels delivery without changing preferences', () async {
    final scheduler = buildScheduler();
    final preferences =
        NotificationPreferences.defaults.copyWith(masterEnabled: false);

    await scheduler.synchronize(preferences);

    expect(
      notificationService.cancelledIds.toSet(),
      AppNotificationIds.allFaithReminderIds.toSet(),
    );
    expect(notificationService.scheduledById, isEmpty);
    expect(scheduleRepository.records, isEmpty);
    expect(preferences.dailyVerseEnabled, isTrue);
  });

  test('a time change replaces the deterministic schedule', () async {
    final scheduler = buildScheduler();
    final initial = dailyVerseOnly().copyWith(dailyVerseMinutes: 7 * 60);
    await scheduler.synchronize(
      initial,
      now: DateTime(2026, 7, 24, 6),
    );
    final first =
        notificationService.scheduledById[AppNotificationIds.dailyVerse]!;

    await scheduler.synchronize(
      initial.copyWith(dailyVerseMinutes: 9 * 60),
      now: DateTime(2026, 7, 24, 6),
    );
    final replacement =
        notificationService.scheduledById[AppNotificationIds.dailyVerse]!;

    expect(notificationService.scheduledById.length, 1);
    expect(first.scheduledDate.hour, 7);
    expect(replacement.scheduledDate.hour, 9);
    expect(
      notificationService.cancelledIds
          .where((id) => id == AppNotificationIds.dailyVerse)
          .length,
      2,
    );
  });

  test('does not schedule completed reading or empty memory reviews', () async {
    final scheduler = buildScheduler(
      readingCount: (_) => 0,
      memoryCount: (_) => 0,
    );
    final preferences = dynamicOnly();

    await scheduler.synchronize(
      preferences,
      now: DateTime(2026, 7, 24, 8),
    );

    expect(
      scheduleRepository.records.where(
        (record) =>
            record.type == NotificationType.readingPlan ||
            record.type == NotificationType.scriptureMemoryReview,
      ),
      isEmpty,
    );
  });

  test('rolling reminders use unique deterministic IDs', () async {
    final scheduler = buildScheduler(
      readingCount: (_) => 2,
      memoryCount: (_) => 3,
    );

    await scheduler.synchronize(
      dynamicOnly().copyWith(
        readingPlanMinutes: 19 * 60,
        scriptureMemoryMinutes: 19 * 60,
      ),
      now: DateTime(2026, 7, 24, 8),
    );

    final records = scheduleRepository.records;
    expect(records.length, 14);
    expect(records.map((record) => record.id).toSet().length, 14);

    for (var offset = 0; offset < 7; offset += 1) {
      expect(
        records.map((record) => record.id),
        contains(AppNotificationIds.readingPlanForDay(offset)),
      );
      expect(
        records.map((record) => record.id),
        contains(AppNotificationIds.scriptureMemoryForDay(offset)),
      );
    }

    final groupedByDay = <String, Set<String>>{};
    for (final record in records) {
      final local = tz.TZDateTime.from(record.scheduledAtUtc, tz.local);
      final dayKey = '${local.year}-${local.month}-${local.day}';
      final timeKey = '${local.hour}:${local.minute}';
      groupedByDay.putIfAbsent(dayKey, () => <String>{}).add(timeKey);
    }
    expect(groupedByDay.values.every((times) => times.length == 2), isTrue);
  });

  test('keeps wall-clock time after a local timezone change', () async {
    final scheduler = buildScheduler();
    final preferences = dailyVerseOnly().copyWith(dailyVerseMinutes: 7 * 60);

    await scheduler.synchronize(
      preferences,
      now: DateTime(2026, 7, 24, 6),
      deliver: false,
    );
    final torontoRecord = scheduleRepository.records.single;
    final torontoLocal = tz.TZDateTime.from(
      torontoRecord.scheduledAtUtc,
      tz.getLocation('America/Toronto'),
    );

    tz.setLocalLocation(tz.getLocation('Europe/London'));
    await scheduler.synchronize(
      preferences,
      now: DateTime(2026, 7, 24, 6),
      deliver: false,
    );
    final londonRecord = scheduleRepository.records.single;
    final londonLocal = tz.TZDateTime.from(
      londonRecord.scheduledAtUtc,
      tz.getLocation('Europe/London'),
    );

    expect(torontoLocal.hour, 7);
    expect(londonLocal.hour, 7);
    expect(
      torontoRecord.scheduledAtUtc,
      isNot(londonRecord.scheduledAtUtc),
    );
  });

  test('produces a valid next occurrence across a DST boundary', () async {
    final scheduler = buildScheduler();
    final preferences = dailyVerseOnly().copyWith(
      dailyVerseMinutes: 2 * 60 + 30,
      quietHoursEnabled: false,
    );

    await scheduler.synchronize(
      preferences,
      now: DateTime(2026, 3, 7, 12),
      deliver: false,
    );
    final record = scheduleRepository.records.single;
    final local = tz.TZDateTime.from(record.scheduledAtUtc, tz.local);

    expect(record.scheduledAtUtc.isAfter(DateTime(2026, 3, 7, 12).toUtc()),
        isTrue);
    expect(local.day, 8);
    expect(local.hour, anyOf(2, 3));
  });

  test('ordinary refresh does not count an elapsed schedule as unread',
      () async {
    final now = DateTime.utc(2026, 7, 24, 12);
    scheduleRepository.records = <ScheduledNotificationRecord>[
      ScheduledNotificationRecord(
        id: AppNotificationIds.dailyVerse,
        type: NotificationType.dailyVerse,
        title: 'Daily verse',
        body: 'Today\'s verse is ready.',
        scheduledAtUtc: now.subtract(const Duration(minutes: 1)),
        payload: '{"type":"daily_verse"}',
      ),
    ];
    final inboxRepository = _TrackingInboxRepository();
    final coordinator = NotificationCoordinator(
      preferencesRepository: NotificationPreferencesRepository(),
      scheduleRepository: scheduleRepository,
      inboxRepository: inboxRepository,
      scheduler: buildScheduler(),
    );

    await coordinator.refresh(now: now);

    expect(inboxRepository.materializeCalls, 0);
    expect(inboxRepository.unreadCount, 0);
    coordinator.dispose();
  });
}

class _FakeNotificationService extends AppNotificationService {
  final List<int> cancelledIds = <int>[];
  final Map<int, _ScheduledCall> scheduledById = <int, _ScheduledCall>{};

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
    scheduledById.remove(id);
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationType type,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduledById[id] = _ScheduledCall(
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }
}

class _ScheduledCall {
  const _ScheduledCall({
    required this.scheduledDate,
    required this.payload,
  });

  final tz.TZDateTime scheduledDate;
  final String payload;
}

class _MemoryScheduleRepository extends ScheduledNotificationRepository {
  List<ScheduledNotificationRecord> records = <ScheduledNotificationRecord>[];

  @override
  List<ScheduledNotificationRecord> list() =>
      List<ScheduledNotificationRecord>.unmodifiable(records);

  @override
  Future<void> replaceAll(
    Iterable<ScheduledNotificationRecord> nextRecords,
  ) async {
    records = nextRecords.toList(growable: false);
  }
}

class _TrackingInboxRepository extends NotificationInboxRepository {
  int materializeCalls = 0;

  @override
  Future<void> materializeDue(
    Iterable<ScheduledNotificationRecord> records, {
    DateTime? now,
  }) async {
    materializeCalls += 1;
    await super.materializeDue(records, now: now);
  }
}
