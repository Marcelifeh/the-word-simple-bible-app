import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/notifications/services/app_notification_service.dart';
import 'package:simple_bible_app/features/notifications/services/notification_navigation_service.dart';
import 'package:simple_bible_app/shared/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('permission denial can later resolve to enabled', () {
    expect(
      resolveNotificationPermissionStatus(
        supported: true,
        enabled: false,
        hasPrompted: false,
      ),
      AppNotificationPermissionStatus.notDetermined,
    );
    expect(
      resolveNotificationPermissionStatus(
        supported: true,
        enabled: false,
        hasPrompted: true,
      ),
      AppNotificationPermissionStatus.denied,
    );
    expect(
      resolveNotificationPermissionStatus(
        supported: true,
        enabled: true,
        hasPrompted: true,
      ),
      AppNotificationPermissionStatus.granted,
    );
  });

  test('malformed and unknown payloads are ignored safely', () async {
    final service = NotificationNavigationService(AppState());

    await service.handlePayload('not-json');
    await service.handlePayload(jsonEncode(<String, String>{
      'type': 'unknown',
      'route': '/missing',
    }));

    expect(service.pendingPayloadCount, 0);
  });

  test('valid terminated-state payload waits for the root navigator', () async {
    final service = NotificationNavigationService(AppState());

    await service.handlePayload(jsonEncode(<String, String>{
      'type': 'daily_verse',
      'route': '/daily-verse',
      'date': '2026-07-24',
    }));

    expect(service.pendingPayloadCount, 1);
  });
}
