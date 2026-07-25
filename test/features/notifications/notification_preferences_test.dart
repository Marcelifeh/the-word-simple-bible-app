import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/notifications/model/notification_preferences.dart';
import 'package:simple_bible_app/features/notifications/model/notification_type.dart';
import 'package:simple_bible_app/features/notifications/services/notification_content_service.dart';
import 'package:simple_bible_app/features/notifications/services/notification_scheduler.dart';

void main() {
  group('NotificationPreferences', () {
    test('migrates missing and malformed fields to current defaults', () {
      final preferences = NotificationPreferences.fromJson(
        <String, dynamic>{
          'schemaVersion': 1,
          'masterEnabled': false,
          'dailyVerseMinutes': 5000,
          'prayerEnabled': 'not-a-bool',
        },
      );

      expect(
        preferences.schemaVersion,
        NotificationPreferences.currentSchemaVersion,
      );
      expect(preferences.masterEnabled, isFalse);
      expect(preferences.dailyVerseMinutes, 1439);
      expect(
        preferences.prayerEnabled,
        NotificationPreferences.defaults.prayerEnabled,
      );
      expect(preferences.importantAnnouncementsEnabled, isFalse);
    });

    test('keeps saved category choices when master delivery is disabled', () {
      final preferences = NotificationPreferences.defaults
          .copyWith(masterEnabled: false, prayerEnabled: true);

      expect(preferences.masterEnabled, isFalse);
      expect(preferences.prayerEnabled, isTrue);
      expect(preferences.dailyVerseEnabled, isTrue);
    });

    test('persists explicit quiet-hour category overrides', () {
      final preferences = NotificationPreferences.defaults.withMinutes(
        NotificationType.prayerReminder,
        23 * 60,
        allowDuringQuietHours: true,
      );
      final restored = NotificationPreferences.fromJson(
        preferences.toJson(),
      );

      expect(
        restored.quietHoursOverrides,
        contains(NotificationType.prayerReminder),
      );
      expect(restored.prayerMinutes, 23 * 60);
    });
  });

  group('quiet hours', () {
    test('recognizes a window spanning midnight', () {
      expect(
        isInsideQuietHours(
          minutesAfterMidnight: 23 * 60,
          quietStartMinutes: 22 * 60,
          quietEndMinutes: 6 * 60 + 30,
        ),
        isTrue,
      );
      expect(
        isInsideQuietHours(
          minutesAfterMidnight: 6 * 60,
          quietStartMinutes: 22 * 60,
          quietEndMinutes: 6 * 60 + 30,
        ),
        isTrue,
      );
      expect(
        isInsideQuietHours(
          minutesAfterMidnight: 12 * 60,
          quietStartMinutes: 22 * 60,
          quietEndMinutes: 6 * 60 + 30,
        ),
        isFalse,
      );
    });

    test('moves a late reminder to the next quiet-hours end', () {
      final moved = moveOutsideQuietHours(
        scheduled: DateTime(2026, 7, 24, 23),
        quietStartMinutes: 22 * 60,
        quietEndMinutes: 6 * 60 + 30,
      );

      expect(moved, DateTime(2026, 7, 25, 6, 30));
    });
  });

  test('content selection is stable for a local date', () async {
    final service = NotificationContentService(
      assetLoader: () async => jsonEncode(
        <String, dynamic>{
          'daily_verse': <Map<String, String>>[
            <String, String>{'title': 'One', 'body': 'First'},
            <String, String>{'title': 'Two', 'body': 'Second'},
          ],
        },
      ),
    );
    await service.init();

    final first = service.forType(
      NotificationType.dailyVerse,
      date: DateTime(2026, 7, 24, 1),
    );
    final later = service.forType(
      NotificationType.dailyVerse,
      date: DateTime(2026, 7, 24, 20),
    );

    expect(later.title, first.title);
    expect(later.body, first.body);
  });

  test('recurring and rolling notification IDs are deterministic', () {
    expect(AppNotificationIds.dailyVerse, 1001);
    expect(AppNotificationIds.readingPlanForDay(0), 1100);
    expect(AppNotificationIds.readingPlanForDay(6), 1106);
    expect(AppNotificationIds.scriptureMemoryForDay(0), 1200);
    expect(
      AppNotificationIds.allFaithReminderIds.toSet().length,
      AppNotificationIds.allFaithReminderIds.length,
    );
  });
}
