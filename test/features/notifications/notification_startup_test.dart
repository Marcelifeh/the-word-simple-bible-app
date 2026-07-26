import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/shared/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
