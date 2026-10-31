import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/core/narration/engines/narration_engine.dart';
import 'package:simple_bible_app/core/narration/models/narration_state.dart';
import 'package:simple_bible_app/core/narration/services/narration_cache_service.dart';
import 'package:simple_bible_app/core/narration/services/narration_controller.dart';
import 'package:simple_bible_app/core/narration/services/narration_preferences_service.dart';
import 'package:simple_bible_app/core/narration/services/narration_service.dart';
import 'package:simple_bible_app/core/narration/services/narration_sync_engine.dart';
import 'package:simple_bible_app/features/devotional/model/devotional_model.dart';
import 'package:simple_bible_app/features/devotional_audio/view/devotional_player_screen.dart';
import 'package:simple_bible_app/features/devotional_audio/widgets/devotional_waveform.dart';
import 'package:simple_bible_app/shared/state/app_state.dart';

class _Engine implements NarrationEngine {
  int pauses = 0;
  int speaks = 0;
  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> speak(String text) async {
    speaks++;
  }

  @override
  Future<void> stop() async {}
  @override
  void setCompletionHandler(void Function() handler) {}
  @override
  void setCancelHandler(void Function() handler) {}
  @override
  void setErrorHandler(void Function(dynamic) handler) {}
  @override
  void setProgressHandler(void Function(String, int, int, String) handler) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _State extends AppState {
  _State(this.controller);
  final NarrationController controller;
  @override
  NarrationController get narrationController => controller;
}

void main() {
  late _Engine engine;
  late NarrationController controller;
  late NarrationSyncEngine sync;

  setUp(() {
    engine = _Engine();
    sync = NarrationSyncEngine();
    controller = NarrationController(NarrationService(engine),
        preferencesService: NarrationPreferencesService(),
        syncEngine: sync,
        cacheService: LocalNarrationCacheService());
  });
  tearDown(() {
    controller.dispose();
    sync.dispose();
  });

  Future<void> openPlayer(WidgetTester tester) async {
    final devotional = DevotionalModel(
        id: 'test',
        title: 'Call to Me',
        theme: 'Prayer',
        scripture: 'Call to Me, and I will answer you.',
        scriptureReference: 'Jeremiah 33:3',
        sections: const [],
        finalRevelation: 'Trust God.',
        reflectionQuestions: const [],
        prayer: 'Amen.',
        createdAt: DateTime(2026));
    await tester.pumpWidget(AppScope(
        state: _State(controller),
        child:
            MaterialApp(home: DevotionalPlayerScreen(devotional: devotional))));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
      'button switches from pause to play and resumes within the same stage',
      (tester) async {
    await openPlayer(tester);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('Pause narration'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.currentSession!.status, NarrationStatus.paused);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(
        tester
            .widget<DevotionalWaveform>(find.byType(DevotionalWaveform))
            .isPlaying,
        isFalse);
    expect(engine.pauses, 1);

    await tester.tap(find.byTooltip('Play narration'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.currentSession!.status, NarrationStatus.playing);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(
        tester
            .widget<DevotionalWaveform>(find.byType(DevotionalWaveform))
            .isPlaying,
        isTrue);
    expect(engine.speaks, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'external pauses update the icon and leaving detaches the listener',
      (tester) async {
    await openPlayer(tester);
    await controller.pause();
    await tester.pump();
    expect(find.byTooltip('Play narration'), findsOneWidget);
    await controller.resume();
    await tester.pump();
    expect(find.byTooltip('Pause narration'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await controller.pause();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
