enum NotificationType {
  dailyVerse,
  dailyDevotional,
  readingPlan,
  scriptureMemoryReview,
  prayerReminder,
  eveningReflection,
  appUpdate,
  importantAnnouncement,
}

extension NotificationTypeX on NotificationType {
  String get wireName => switch (this) {
        NotificationType.dailyVerse => 'daily_verse',
        NotificationType.dailyDevotional => 'daily_devotional',
        NotificationType.readingPlan => 'reading_plan',
        NotificationType.scriptureMemoryReview => 'scripture_memory_review',
        NotificationType.prayerReminder => 'prayer_reminder',
        NotificationType.eveningReflection => 'evening_reflection',
        NotificationType.appUpdate => 'app_update',
        NotificationType.importantAnnouncement => 'important_announcement',
      };

  String get displayName => switch (this) {
        NotificationType.dailyVerse => 'Daily Verse',
        NotificationType.dailyDevotional => 'Daily Devotional',
        NotificationType.readingPlan => 'Bible Reading Plan',
        NotificationType.scriptureMemoryReview => 'Scripture Memory Reviews',
        NotificationType.prayerReminder => 'Prayer Reminder',
        NotificationType.eveningReflection => 'Evening Reflection',
        NotificationType.appUpdate => 'New devotionals and features',
        NotificationType.importantAnnouncement => 'Important announcements',
      };

  static NotificationType? fromWireName(String? value) {
    for (final type in NotificationType.values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}

abstract final class AppNotificationIds {
  static const dailyVerse = 1001;
  static const dailyDevotional = 1002;
  static const readingPlan = 1003;
  static const scriptureMemory = 1004;
  static const prayerReminder = 1005;
  static const eveningReflection = 1006;

  static const _readingPlanRollingBase = 1100;
  static const _scriptureMemoryRollingBase = 1200;

  static int readingPlanForDay(int dayOffset) =>
      _readingPlanRollingBase + dayOffset;

  static int scriptureMemoryForDay(int dayOffset) =>
      _scriptureMemoryRollingBase + dayOffset;

  static List<int> get allFaithReminderIds => <int>[
        dailyVerse,
        dailyDevotional,
        readingPlan,
        scriptureMemory,
        prayerReminder,
        eveningReflection,
        ...List<int>.generate(7, readingPlanForDay),
        ...List<int>.generate(7, scriptureMemoryForDay),
      ];
}
