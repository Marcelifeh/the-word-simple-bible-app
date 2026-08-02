import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../model/notification_type.dart';

enum AppNotificationPermissionStatus {
  notDetermined,
  granted,
  denied,
  unsupported,
}

AppNotificationPermissionStatus resolveNotificationPermissionStatus({
  required bool supported,
  required bool enabled,
  required bool hasPrompted,
}) {
  if (!supported) return AppNotificationPermissionStatus.unsupported;
  if (enabled) return AppNotificationPermissionStatus.granted;
  return hasPrompted
      ? AppNotificationPermissionStatus.denied
      : AppNotificationPermissionStatus.notDetermined;
}

typedef NotificationPayloadHandler = Future<void> Function(String payload);

class AppNotificationService {
  AppNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const androidNotificationIcon = 'ic_stat_word_app';
  static const testNotificationId = 9901;
  static const testNotificationChannelId = 'general_reminders_v2';
  static const dailyFaithChannelId = 'daily_faith';
  static const habitRemindersChannelId = 'habit_reminders';
  static const prayerRemindersChannelId = 'prayer_reminders';
  static const appUpdatesChannelId = 'app_updates';
  static const notificationCentrePayload =
      '{"type":"notification_centre","route":"/notification-settings"}';
  static const _settingsChannel =
      MethodChannel('the_word/notification_settings');

  final FlutterLocalNotificationsPlugin _plugin;
  NotificationPayloadHandler? _payloadHandler;
  bool _initialized = false;

  bool get supportsLocalScheduling =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize({
    required NotificationPayloadHandler onPayload,
  }) async {
    _payloadHandler = onPayload;
    await refreshTimezone();
    if (!supportsLocalScheduling) {
      _initialized = true;
      return;
    }

    const android = AndroidInitializationSettings(androidNotificationIcon);
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: false,
      defaultPresentBadge: false,
      defaultPresentSound: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;
        await _payloadHandler?.call(payload);
      },
    );
    _initialized = true;
    await _createAndroidChannels();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    final payload = response?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.trim().isNotEmpty) {
      await _payloadHandler?.call(payload);
    }
  }

  Future<AppNotificationPermissionStatus> permissionStatus({
    required bool hasPrompted,
  }) async {
    if (!supportsLocalScheduling) {
      return resolveNotificationPermissionStatus(
        supported: false,
        enabled: false,
        hasPrompted: hasPrompted,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return resolveNotificationPermissionStatus(
        supported: true,
        enabled: enabled == true,
        hasPrompted: hasPrompted,
      );
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final options = await ios?.checkPermissions();
    return resolveNotificationPermissionStatus(
      supported: true,
      enabled: options?.isEnabled == true,
      hasPrompted: hasPrompted,
    );
  }

  Future<bool> requestPermission() async {
    if (!supportsLocalScheduling) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
        false;
  }

  Future<bool> areAndroidNotificationsEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<int?> pendingNotificationRequestCount() async {
    if (!supportsLocalScheduling) return null;
    return (await _plugin.pendingNotificationRequests()).length;
  }

  Future<List<String>> blockedAndroidReminderChannelNames() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const <String>[];
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final channels = await android?.getNotificationChannels();
    if (channels == null) return const <String>[];

    const reminderChannelNames = <String, String>{
      dailyFaithChannelId: 'Daily faith',
      habitRemindersChannelId: 'Habit reminders',
      prayerRemindersChannelId: 'Prayer reminders',
    };
    return <String>[
      for (final channel in channels)
        if (reminderChannelNames.containsKey(channel.id) &&
            channel.importance == Importance.none)
          reminderChannelNames[channel.id]!,
    ];
  }

  Future<void> showTestNotification() async {
    if (!_initialized || !supportsLocalScheduling) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        testNotificationChannelId,
        'Faith Reminders',
        channelDescription:
            'Daily Scripture, devotionals, prayer, and habit reminders.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: androidNotificationIcon,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: testNotificationId,
      title: 'Notifications are working',
      body: 'The Word App can now send your faith reminders.',
      notificationDetails: details,
      payload: notificationCentrePayload,
    );
  }

  Future<void> openNotificationSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
    } on PlatformException {
      // Unsupported desktop/web platforms have no app-owned settings surface.
    } on MissingPluginException {
      // Tests and unsupported platforms intentionally have no native handler.
    }
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationType type,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_initialized || !supportsLocalScheduling) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _detailsFor(type),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  Future<void> cancel(int id) async {
    if (!_initialized || !supportsLocalScheduling) return;
    await _plugin.cancel(id: id);
  }

  Future<void> refreshTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _createAndroidChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        testNotificationChannelId,
        'Faith Reminders',
        description:
            'Daily Scripture, devotionals, prayer, and habit reminders.',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        dailyFaithChannelId,
        'Daily faith',
        description: 'Daily Scripture, devotional, and reflection reminders',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        habitRemindersChannelId,
        'Habit reminders',
        description: 'Reading plan and Scripture Memory reminders',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        prayerRemindersChannelId,
        'Prayer reminders',
        description: 'Gentle reminders to pause for prayer',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        appUpdatesChannelId,
        'App updates',
        description: 'New content, features, and important announcements',
        importance: Importance.low,
      ),
    ];
    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  NotificationDetails _detailsFor(NotificationType type) {
    final channel = switch (type) {
      NotificationType.dailyVerse ||
      NotificationType.dailyDevotional ||
      NotificationType.eveningReflection =>
        (
          id: dailyFaithChannelId,
          name: 'Daily faith',
          description: 'Daily Scripture, devotional, and reflection reminders',
          importance: Importance.defaultImportance,
        ),
      NotificationType.readingPlan ||
      NotificationType.scriptureMemoryReview =>
        (
          id: habitRemindersChannelId,
          name: 'Habit reminders',
          description: 'Reading plan and Scripture Memory reminders',
          importance: Importance.defaultImportance,
        ),
      NotificationType.prayerReminder => (
          id: prayerRemindersChannelId,
          name: 'Prayer reminders',
          description: 'Gentle reminders to pause for prayer',
          importance: Importance.defaultImportance,
        ),
      NotificationType.appUpdate || NotificationType.importantAnnouncement => (
          id: appUpdatesChannelId,
          name: 'App updates',
          description: 'New content, features, and important announcements',
          importance: Importance.low,
        ),
    };

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: androidNotificationIcon,
        importance: channel.importance,
        priority: channel.importance == Importance.low
            ? Priority.low
            : Priority.defaultPriority,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        threadIdentifier: channel.id,
      ),
    );
  }
}
