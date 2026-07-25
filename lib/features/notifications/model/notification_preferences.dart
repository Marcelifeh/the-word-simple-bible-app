import 'notification_type.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.schemaVersion,
    required this.masterEnabled,
    required this.dailyVerseEnabled,
    required this.dailyVerseMinutes,
    required this.devotionalEnabled,
    required this.devotionalMinutes,
    required this.readingPlanEnabled,
    required this.readingPlanMinutes,
    required this.scriptureMemoryEnabled,
    required this.scriptureMemoryMinutes,
    required this.prayerEnabled,
    required this.prayerMinutes,
    required this.eveningReflectionEnabled,
    required this.eveningReflectionMinutes,
    required this.quietHoursEnabled,
    required this.quietStartMinutes,
    required this.quietEndMinutes,
    required this.appUpdatesEnabled,
    required this.importantAnnouncementsEnabled,
    required this.permissionPrompted,
    this.quietHoursOverrides = const <NotificationType>{},
  });

  static const currentSchemaVersion = 2;

  static const defaults = NotificationPreferences(
    schemaVersion: currentSchemaVersion,
    masterEnabled: true,
    dailyVerseEnabled: true,
    dailyVerseMinutes: 7 * 60,
    devotionalEnabled: true,
    devotionalMinutes: 8 * 60,
    readingPlanEnabled: true,
    readingPlanMinutes: 19 * 60 + 30,
    scriptureMemoryEnabled: true,
    scriptureMemoryMinutes: 18 * 60 + 30,
    prayerEnabled: false,
    prayerMinutes: 8 * 60,
    eveningReflectionEnabled: true,
    eveningReflectionMinutes: 21 * 60,
    quietHoursEnabled: true,
    quietStartMinutes: 22 * 60,
    quietEndMinutes: 6 * 60 + 30,
    appUpdatesEnabled: false,
    importantAnnouncementsEnabled: false,
    permissionPrompted: false,
  );

  final int schemaVersion;
  final bool masterEnabled;
  final bool dailyVerseEnabled;
  final int dailyVerseMinutes;
  final bool devotionalEnabled;
  final int devotionalMinutes;
  final bool readingPlanEnabled;
  final int readingPlanMinutes;
  final bool scriptureMemoryEnabled;
  final int scriptureMemoryMinutes;
  final bool prayerEnabled;
  final int prayerMinutes;
  final bool eveningReflectionEnabled;
  final int eveningReflectionMinutes;
  final bool quietHoursEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;
  final bool appUpdatesEnabled;
  final bool importantAnnouncementsEnabled;
  final bool permissionPrompted;

  /// Categories explicitly allowed inside quiet hours by the user.
  final Set<NotificationType> quietHoursOverrides;

  bool get hasAnyEnabledCategory =>
      dailyVerseEnabled ||
      devotionalEnabled ||
      readingPlanEnabled ||
      scriptureMemoryEnabled ||
      prayerEnabled ||
      eveningReflectionEnabled ||
      appUpdatesEnabled ||
      importantAnnouncementsEnabled;

  bool isEnabled(NotificationType type) => switch (type) {
        NotificationType.dailyVerse => dailyVerseEnabled,
        NotificationType.dailyDevotional => devotionalEnabled,
        NotificationType.readingPlan => readingPlanEnabled,
        NotificationType.scriptureMemoryReview => scriptureMemoryEnabled,
        NotificationType.prayerReminder => prayerEnabled,
        NotificationType.eveningReflection => eveningReflectionEnabled,
        NotificationType.appUpdate => appUpdatesEnabled,
        NotificationType.importantAnnouncement => importantAnnouncementsEnabled,
      };

  int? minutesFor(NotificationType type) => switch (type) {
        NotificationType.dailyVerse => dailyVerseMinutes,
        NotificationType.dailyDevotional => devotionalMinutes,
        NotificationType.readingPlan => readingPlanMinutes,
        NotificationType.scriptureMemoryReview => scriptureMemoryMinutes,
        NotificationType.prayerReminder => prayerMinutes,
        NotificationType.eveningReflection => eveningReflectionMinutes,
        NotificationType.appUpdate ||
        NotificationType.importantAnnouncement =>
          null,
      };

  NotificationPreferences copyWith({
    int? schemaVersion,
    bool? masterEnabled,
    bool? dailyVerseEnabled,
    int? dailyVerseMinutes,
    bool? devotionalEnabled,
    int? devotionalMinutes,
    bool? readingPlanEnabled,
    int? readingPlanMinutes,
    bool? scriptureMemoryEnabled,
    int? scriptureMemoryMinutes,
    bool? prayerEnabled,
    int? prayerMinutes,
    bool? eveningReflectionEnabled,
    int? eveningReflectionMinutes,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
    bool? appUpdatesEnabled,
    bool? importantAnnouncementsEnabled,
    bool? permissionPrompted,
    Set<NotificationType>? quietHoursOverrides,
  }) {
    return NotificationPreferences(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      masterEnabled: masterEnabled ?? this.masterEnabled,
      dailyVerseEnabled: dailyVerseEnabled ?? this.dailyVerseEnabled,
      dailyVerseMinutes: _normalizeMinutes(
        dailyVerseMinutes ?? this.dailyVerseMinutes,
      ),
      devotionalEnabled: devotionalEnabled ?? this.devotionalEnabled,
      devotionalMinutes: _normalizeMinutes(
        devotionalMinutes ?? this.devotionalMinutes,
      ),
      readingPlanEnabled: readingPlanEnabled ?? this.readingPlanEnabled,
      readingPlanMinutes: _normalizeMinutes(
        readingPlanMinutes ?? this.readingPlanMinutes,
      ),
      scriptureMemoryEnabled:
          scriptureMemoryEnabled ?? this.scriptureMemoryEnabled,
      scriptureMemoryMinutes: _normalizeMinutes(
        scriptureMemoryMinutes ?? this.scriptureMemoryMinutes,
      ),
      prayerEnabled: prayerEnabled ?? this.prayerEnabled,
      prayerMinutes: _normalizeMinutes(
        prayerMinutes ?? this.prayerMinutes,
      ),
      eveningReflectionEnabled:
          eveningReflectionEnabled ?? this.eveningReflectionEnabled,
      eveningReflectionMinutes: _normalizeMinutes(
        eveningReflectionMinutes ?? this.eveningReflectionMinutes,
      ),
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartMinutes: _normalizeMinutes(
        quietStartMinutes ?? this.quietStartMinutes,
      ),
      quietEndMinutes: _normalizeMinutes(
        quietEndMinutes ?? this.quietEndMinutes,
      ),
      appUpdatesEnabled: appUpdatesEnabled ?? this.appUpdatesEnabled,
      importantAnnouncementsEnabled:
          importantAnnouncementsEnabled ?? this.importantAnnouncementsEnabled,
      permissionPrompted: permissionPrompted ?? this.permissionPrompted,
      quietHoursOverrides: Set<NotificationType>.unmodifiable(
        quietHoursOverrides ?? this.quietHoursOverrides,
      ),
    );
  }

  NotificationPreferences withEnabled(
    NotificationType type,
    bool enabled,
  ) {
    return switch (type) {
      NotificationType.dailyVerse => copyWith(dailyVerseEnabled: enabled),
      NotificationType.dailyDevotional => copyWith(devotionalEnabled: enabled),
      NotificationType.readingPlan => copyWith(readingPlanEnabled: enabled),
      NotificationType.scriptureMemoryReview =>
        copyWith(scriptureMemoryEnabled: enabled),
      NotificationType.prayerReminder => copyWith(prayerEnabled: enabled),
      NotificationType.eveningReflection =>
        copyWith(eveningReflectionEnabled: enabled),
      NotificationType.appUpdate => copyWith(appUpdatesEnabled: enabled),
      NotificationType.importantAnnouncement =>
        copyWith(importantAnnouncementsEnabled: enabled),
    };
  }

  NotificationPreferences withMinutes(
    NotificationType type,
    int minutes, {
    bool allowDuringQuietHours = false,
  }) {
    final normalized = _normalizeMinutes(minutes);
    final overrides = Set<NotificationType>.of(quietHoursOverrides);
    if (allowDuringQuietHours) {
      overrides.add(type);
    } else {
      overrides.remove(type);
    }

    final updated = switch (type) {
      NotificationType.dailyVerse => copyWith(dailyVerseMinutes: normalized),
      NotificationType.dailyDevotional =>
        copyWith(devotionalMinutes: normalized),
      NotificationType.readingPlan => copyWith(readingPlanMinutes: normalized),
      NotificationType.scriptureMemoryReview =>
        copyWith(scriptureMemoryMinutes: normalized),
      NotificationType.prayerReminder => copyWith(prayerMinutes: normalized),
      NotificationType.eveningReflection =>
        copyWith(eveningReflectionMinutes: normalized),
      NotificationType.appUpdate ||
      NotificationType.importantAnnouncement =>
        this,
    };
    return updated.copyWith(quietHoursOverrides: overrides);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': currentSchemaVersion,
        'masterEnabled': masterEnabled,
        'dailyVerseEnabled': dailyVerseEnabled,
        'dailyVerseMinutes': dailyVerseMinutes,
        'devotionalEnabled': devotionalEnabled,
        'devotionalMinutes': devotionalMinutes,
        'readingPlanEnabled': readingPlanEnabled,
        'readingPlanMinutes': readingPlanMinutes,
        'scriptureMemoryEnabled': scriptureMemoryEnabled,
        'scriptureMemoryMinutes': scriptureMemoryMinutes,
        'prayerEnabled': prayerEnabled,
        'prayerMinutes': prayerMinutes,
        'eveningReflectionEnabled': eveningReflectionEnabled,
        'eveningReflectionMinutes': eveningReflectionMinutes,
        'quietHoursEnabled': quietHoursEnabled,
        'quietStartMinutes': quietStartMinutes,
        'quietEndMinutes': quietEndMinutes,
        'appUpdatesEnabled': appUpdatesEnabled,
        'importantAnnouncementsEnabled': importantAnnouncementsEnabled,
        'permissionPrompted': permissionPrompted,
        'quietHoursOverrides': quietHoursOverrides
            .map((type) => type.wireName)
            .toList(growable: false),
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final fallback = defaults;
    final overrides = (json['quietHoursOverrides'] as List<dynamic>?)
            ?.map((value) => NotificationTypeX.fromWireName(value as String?))
            .whereType<NotificationType>()
            .toSet() ??
        const <NotificationType>{};

    return NotificationPreferences(
      schemaVersion: currentSchemaVersion,
      masterEnabled: _readBool(
        json,
        'masterEnabled',
        fallback.masterEnabled,
      ),
      dailyVerseEnabled: _readBool(
        json,
        'dailyVerseEnabled',
        fallback.dailyVerseEnabled,
      ),
      dailyVerseMinutes: _readMinutes(
        json,
        'dailyVerseMinutes',
        fallback.dailyVerseMinutes,
      ),
      devotionalEnabled: _readBool(
        json,
        'devotionalEnabled',
        fallback.devotionalEnabled,
      ),
      devotionalMinutes: _readMinutes(
        json,
        'devotionalMinutes',
        fallback.devotionalMinutes,
      ),
      readingPlanEnabled: _readBool(
        json,
        'readingPlanEnabled',
        fallback.readingPlanEnabled,
      ),
      readingPlanMinutes: _readMinutes(
        json,
        'readingPlanMinutes',
        fallback.readingPlanMinutes,
      ),
      scriptureMemoryEnabled: _readBool(
        json,
        'scriptureMemoryEnabled',
        fallback.scriptureMemoryEnabled,
      ),
      scriptureMemoryMinutes: _readMinutes(
        json,
        'scriptureMemoryMinutes',
        fallback.scriptureMemoryMinutes,
      ),
      prayerEnabled: _readBool(
        json,
        'prayerEnabled',
        fallback.prayerEnabled,
      ),
      prayerMinutes: _readMinutes(
        json,
        'prayerMinutes',
        fallback.prayerMinutes,
      ),
      eveningReflectionEnabled: _readBool(
        json,
        'eveningReflectionEnabled',
        fallback.eveningReflectionEnabled,
      ),
      eveningReflectionMinutes: _readMinutes(
        json,
        'eveningReflectionMinutes',
        fallback.eveningReflectionMinutes,
      ),
      quietHoursEnabled: _readBool(
        json,
        'quietHoursEnabled',
        fallback.quietHoursEnabled,
      ),
      quietStartMinutes: _readMinutes(
        json,
        'quietStartMinutes',
        fallback.quietStartMinutes,
      ),
      quietEndMinutes: _readMinutes(
        json,
        'quietEndMinutes',
        fallback.quietEndMinutes,
      ),
      appUpdatesEnabled: _readBool(
        json,
        'appUpdatesEnabled',
        fallback.appUpdatesEnabled,
      ),
      importantAnnouncementsEnabled: _readBool(
        json,
        'importantAnnouncementsEnabled',
        fallback.importantAnnouncementsEnabled,
      ),
      permissionPrompted: _readBool(
        json,
        'permissionPrompted',
        fallback.permissionPrompted,
      ),
      quietHoursOverrides: Set<NotificationType>.unmodifiable(overrides),
    );
  }

  static bool _readBool(
    Map<String, dynamic> json,
    String key,
    bool fallback,
  ) {
    final value = json[key];
    return value is bool ? value : fallback;
  }

  static int _readMinutes(
    Map<String, dynamic> json,
    String key,
    int fallback,
  ) {
    final value = json[key];
    return value is num ? _normalizeMinutes(value.toInt()) : fallback;
  }

  static int _normalizeMinutes(int value) => value.clamp(0, 1439).toInt();
}
