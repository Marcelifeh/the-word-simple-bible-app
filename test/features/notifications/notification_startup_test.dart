import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/shared/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  test('notification initialization failure does not block app startup',
      () async {
    final state = AppState();
    addTearDown(state.dispose);

    await expectLater(
      state.initializeNotificationsForStartup(
        initializer: () async => throw Exception('invalid icon'),
      ),
      completes,
    );

    expect(state.notificationsAvailable, isFalse);
  });

  test('schedule refresh failure keeps notification services available',
      () async {
    final state = AppState();
    addTearDown(state.dispose);

    await expectLater(
      state.initializeNotificationsForStartup(
        initializer: () async {},
        refresher: () async => throw Exception('temporary alarm failure'),
      ),
      completes,
    );

    expect(state.notificationsAvailable, isTrue);
  });
}
