import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _SlotMemoryRepository implements DailyAltarRepository {
  final Map<String, DailyAltarStoredRecord> records =
      <String, DailyAltarStoredRecord>{};

  int loadCalls = 0;

  @override
  Future<DailyAltarStoredRecord?> load(String sessionId) async {
    loadCalls++;
    return records[sessionId];
  }

  @override
  Future<void> save(DailyAltarStoredRecord record) async {
    records[record.session.id] = record;
  }

  @override
  Future<void> delete(String sessionId) async {
    records.remove(sessionId);
  }
}

class _FailingSlotRepository implements DailyAltarRepository {
  int loadCalls = 0;

  @override
  Future<DailyAltarStoredRecord?> load(String sessionId) async {
    loadCalls++;
    throw StateError('Storage unavailable');
  }

  @override
  Future<void> save(DailyAltarStoredRecord record) async {}

  @override
  Future<void> delete(String sessionId) async {}
}

void main() {
  Future<void> pumpSlot(
    WidgetTester tester, {
    required bool enabled,
    required DailyAltarTodayService service,
    required Future<void> Function() onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyAltarHomeSlot(
            enabled: enabled,
            todayService: service,
            onOpen: onOpen,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  DailyAltarStoredRecord morningRecordForToday() {
    final now = DateTime.now();

    final localDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final month = localDate.month.toString().padLeft(2, '0');

    final day = localDate.day.toString().padLeft(2, '0');

    final sessionId = 'altar-${localDate.year}-$month-$day';

    return DailyAltarStoredRecord(
      session: DailyAltarSession(
        id: sessionId,
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
      response: DailyAltarUserResponse(
        sessionId: sessionId,
      ),
    );
  }

  testWidgets(
    'disabled slot performs no status load and renders no card',
    (tester) async {
      final repository = _SlotMemoryRepository();

      final service = DailyAltarTodayService(
        repository: repository,
      );

      await pumpSlot(
        tester,
        enabled: false,
        service: service,
        onOpen: () async {},
      );

      expect(repository.loadCalls, 0);

      expect(
        find.byKey(
          const Key('dailyAltarHomeCard'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const Key('dailyAltarHomeSlotDisabled'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'enabled slot renders today status card',
    (tester) async {
      final repository = _SlotMemoryRepository();

      final service = DailyAltarTodayService(
        repository: repository,
      );

      await pumpSlot(
        tester,
        enabled: true,
        service: service,
        onOpen: () async {},
      );

      expect(
        find.text('My Daily Altar'),
        findsOneWidget,
      );

      expect(
        find.text('Begin today\'s altar'),
        findsOneWidget,
      );

      expect(repository.loadCalls, 1);
    },
  );

  testWidgets(
    'storage failure is isolated from host surface',
    (tester) async {
      final repository = _FailingSlotRepository();

      final service = DailyAltarTodayService(
        repository: repository,
      );

      await pumpSlot(
        tester,
        enabled: true,
        service: service,
        onOpen: () async {},
      );

      expect(repository.loadCalls, 1);

      expect(
        find.byKey(
          const Key('dailyAltarHomeSlotUnavailable'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key('dailyAltarHomeCard'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'slot refreshes status after altar screen returns',
    (tester) async {
      final repository = _SlotMemoryRepository();

      final service = DailyAltarTodayService(
        repository: repository,
      );

      await pumpSlot(
        tester,
        enabled: true,
        service: service,
        onOpen: () async {
          final record = morningRecordForToday();

          repository.records[record.session.id] = record;
        },
      );

      expect(
        find.text('Begin today\'s altar'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const Key(
            'dailyAltarHomeCardTapTarget',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Continue your altar'),
        findsOneWidget,
      );

      expect(repository.loadCalls, 2);
    },
  );
}
