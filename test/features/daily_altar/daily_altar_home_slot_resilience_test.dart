import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _MutableRepository implements DailyAltarRepository {
  int loadCalls = 0;
  bool failRead = false;
  DailyAltarStoredRecord? record;

  @override
  Future<DailyAltarStoredRecord?> load(String sessionId) async {
    loadCalls++;

    if (failRead) {
      throw StateError('Simulated local storage failure');
    }

    return record;
  }

  @override
  Future<void> save(DailyAltarStoredRecord record) async {
    this.record = record;
  }

  @override
  Future<void> delete(String sessionId) async {
    record = null;
  }
}

class _DelayedRepository implements DailyAltarRepository {
  final List<Completer<DailyAltarStoredRecord?>> requests = [];

  @override
  Future<DailyAltarStoredRecord?> load(String sessionId) {
    final completer = Completer<DailyAltarStoredRecord?>();
    requests.add(completer);
    return completer.future;
  }

  @override
  Future<void> save(DailyAltarStoredRecord record) async {}

  @override
  Future<void> delete(String sessionId) async {}
}

DailyAltarStoredRecord _morningRecord() {
  final now = DateTime.now();
  final localDate = DateTime(now.year, now.month, now.day);
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  final id = 'altar-${localDate.year}-$month-$day';

  return DailyAltarStoredRecord(
    session: DailyAltarSession(
      id: id,
      localDate: localDate,
      stage: DailyAltarStage.receive,
      posture: DailyAltarPosture.seekingDeeperFellowship,
      startedAt: DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
        7,
      ),
    ),
    contentId: 'john-15-abide-in-christ',
    response: DailyAltarUserResponse(sessionId: id),
  );
}

Future<void> _mount(
  WidgetTester tester, {
  required bool enabled,
  required DailyAltarTodayService service,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            const Text('Existing Home content remains available'),
            DailyAltarHomeSlot(
              key: const Key('resilienceTestSlot'),
              enabled: enabled,
              todayService: service,
              onOpen: () async {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'disabled slot never reads storage even after app resume',
    (tester) async {
      final repository = _MutableRepository();
      final service = DailyAltarTodayService(repository: repository);

      await _mount(tester, enabled: false, service: service);
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();

      expect(repository.loadCalls, 0);
      expect(find.byKey(const Key('dailyAltarHomeCard')), findsNothing);
      expect(
        find.text('Existing Home content remains available'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'dynamic enable loads status and disabling hides the card',
    (tester) async {
      final repository = _MutableRepository();
      final service = DailyAltarTodayService(repository: repository);

      await _mount(tester, enabled: false, service: service);
      await tester.pumpAndSettle();

      expect(repository.loadCalls, 0);

      await _mount(tester, enabled: true, service: service);
      await tester.pumpAndSettle();

      expect(repository.loadCalls, 1);
      expect(find.text('Begin today\'s altar'), findsOneWidget);

      await _mount(tester, enabled: false, service: service);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dailyAltarHomeCard')), findsNothing);
      expect(
        find.byKey(const Key('dailyAltarHomeSlotDisabled')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'disabling during a pending read ignores its late result',
    (tester) async {
      final repository = _DelayedRepository();
      final service = DailyAltarTodayService(repository: repository);

      await _mount(tester, enabled: true, service: service);

      expect(repository.requests.length, 1);

      await _mount(tester, enabled: false, service: service);

      repository.requests.first.complete(_morningRecord());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dailyAltarHomeSlotDisabled')),
        findsOneWidget,
      );
      expect(find.text('Continue your altar'), findsNothing);
      expect(find.byKey(const Key('dailyAltarHomeCard')), findsNothing);
    },
  );

  testWidgets(
    'app resume refreshes status and recovers from storage failure',
    (tester) async {
      final repository = _MutableRepository();
      final service = DailyAltarTodayService(repository: repository);

      await _mount(tester, enabled: true, service: service);
      await tester.pumpAndSettle();

      expect(find.text('Begin today\'s altar'), findsOneWidget);

      repository.record = _morningRecord();

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue your altar'), findsOneWidget);

      repository.failRead = true;

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dailyAltarHomeSlotUnavailable')),
        findsOneWidget,
      );
      expect(
        find.text('Existing Home content remains available'),
        findsOneWidget,
      );

      repository.failRead = false;

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue your altar'), findsOneWidget);
      expect(repository.loadCalls, 4);
    },
  );

  testWidgets(
    'older asynchronous read cannot overwrite newer status',
    (tester) async {
      final repository = _DelayedRepository();
      final service = DailyAltarTodayService(repository: repository);

      await _mount(tester, enabled: true, service: service);

      expect(repository.requests.length, 1);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();

      expect(repository.requests.length, 2);

      // Newer request finishes first.
      repository.requests[1].complete(_morningRecord());
      await tester.pumpAndSettle();

      expect(find.text('Continue your altar'), findsOneWidget);

      // Older request finishes later with obsolete information.
      repository.requests[0].complete(null);
      await tester.pumpAndSettle();

      expect(find.text('Continue your altar'), findsOneWidget);
      expect(find.text('Begin today\'s altar'), findsNothing);
    },
  );
}
