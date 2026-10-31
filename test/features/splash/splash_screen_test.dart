import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/splash/view/splash_screen.dart';
// Use the interface shipped with video_player to simulate a stalled platform.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _StalledVideoPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) =>
      Completer<int?>().future;
}

void main() {
  testWidgets('opens the app even when splash video creation never completes',
      (tester) async {
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _StalledVideoPlatform();
    addTearDown(() => VideoPlayerPlatform.instance = original);

    await tester.pumpWidget(const MaterialApp(
      home: SplashScreen(nextScreen: Scaffold(body: Text('Bible ready'))),
    ));
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    expect(find.text('Bible ready'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
