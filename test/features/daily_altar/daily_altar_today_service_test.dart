import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _MemoryTodayRepository implements DailyAltarRepository {
  final Map<String, DailyAltarStoredRecord> records =
      <String, DailyAltarStoredRecord>{};

  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> save(
    DailyAltarStoredRecord record,
  ) async {
    saveCalls++;
    records[record.session.id] = record;
  }

  @override
  Future<DailyAltarStoredRecord?> load(
    String sessionId,
  ) async {
    return records[sessionId];
  }

  @override
  Future<void> delete(
    String sessionId,
  ) async {
    deleteCalls++;
    records.remove(sessionId);
  }
}

class _FailingTodayRepository implements DailyAltarRepository {
  @override
  Future<DailyAltarStoredRecord?> load(
    String sessionId,
  ) async {
    throw StateError('Storage unavailable');
  }

  @override
  Future<void> save(
    DailyAltarStoredRecord record,
  ) async {}

  @override
  Future<void> delete(
    String sessionId,
  ) async {}
}

void main() {
  const contentId = 'john-15-abide-in-christ';

  final today = DateTime(2026, 10, 31);

  const sessionId = 'altar-2026-10-31';

  DailyAltarStoredRecord record({
    required DailyAltarStage stage,
    DateTime? morningCompletedAt,
    DateTime? completedAt,
    DateTime? localDate,
    String id = sessionId,
  }) {
    final session = DailyAltarSession(
      id: id,
      localDate: localDate ?? today,
      stage: stage,
      posture: DailyAltarPosture.seekingDeeperFellowship,
      startedAt: DateTime(2026, 10, 31, 7),
      morningCompletedAt: morningCompletedAt,
      completedAt: completedAt,
    );

    return DailyAltarStoredRecord(
      session: session,
      contentId: contentId,
      response: DailyAltarUserResponse(
        sessionId: session.id,
      ),
    );
  }

  group('DailyAltarTodayService', () {
    test(
      'returns notStarted when today has no saved altar',
      () async {
        final repository = _MemoryTodayRepository();

        final service = DailyAltarTodayService(
          repository: repository,
        );

        final snapshot = await service.getToday(
          now: DateTime(2026, 10, 31, 8),
        );

        expect(
          snapshot.status,
          DailyAltarTodayStatus.notStarted,
        );

        expect(
          snapshot.sessionId,
          sessionId,
        );

        expect(
          snapshot.session,
          isNull,
        );
      },
    );

    test(
      'reports morningInProgress during morning journey',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.abide,
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        final snapshot = await service.getToday(
          now: DateTime(2026, 10, 31, 9),
        );

        expect(
          snapshot.status,
          DailyAltarTodayStatus.morningInProgress,
        );

        expect(
          snapshot.contentId,
          contentId,
        );
      },
    );

    test(
      'reports waitingForEvening before return window',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.returnToAltar,
          morningCompletedAt: DateTime(
            2026,
            10,
            31,
            7,
            30,
          ),
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        final snapshot = await service.getToday(
          now: DateTime(2026, 10, 31, 14),
        );

        expect(
          snapshot.status,
          DailyAltarTodayStatus.waitingForEvening,
        );

        expect(
          snapshot.earliestReturnAt,
          DateTime(
            2026,
            10,
            31,
            17,
          ),
        );
      },
    );

    test(
      'reports eveningAvailable when return window opens',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.returnToAltar,
          morningCompletedAt: DateTime(
            2026,
            10,
            31,
            7,
            30,
          ),
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        final snapshot = await service.getToday(
          now: DateTime(2026, 10, 31, 17),
        );

        expect(
          snapshot.status,
          DailyAltarTodayStatus.eveningAvailable,
        );

        expect(
          snapshot.canReturnThisEvening,
          isTrue,
        );
      },
    );

    test(
      'reports completed for completed altar',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.completed,
          morningCompletedAt: DateTime(
            2026,
            10,
            31,
            7,
            30,
          ),
          completedAt: DateTime(
            2026,
            10,
            31,
            20,
          ),
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        final snapshot = await service.getToday(
          now: DateTime(2026, 10, 31, 21),
        );

        expect(
          snapshot.status,
          DailyAltarTodayStatus.completed,
        );

        expect(
          snapshot.isComplete,
          isTrue,
        );
      },
    );

    test(
      'late morning altar respects two-hour return delay',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.returnToAltar,
          morningCompletedAt: DateTime(
            2026,
            10,
            31,
            18,
            30,
          ),
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        final waiting = await service.getToday(
          now: DateTime(
            2026,
            10,
            31,
            20,
            29,
          ),
        );

        expect(
          waiting.status,
          DailyAltarTodayStatus.waitingForEvening,
        );

        expect(
          waiting.earliestReturnAt,
          DateTime(
            2026,
            10,
            31,
            20,
            30,
          ),
        );

        final available = await service.getToday(
          now: DateTime(
            2026,
            10,
            31,
            20,
            30,
          ),
        );

        expect(
          available.status,
          DailyAltarTodayStatus.eveningAvailable,
        );
      },
    );

    test(
      'service is read-only',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.receive,
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        await service.getToday(
          now: DateTime(2026, 10, 31, 8),
        );

        expect(
          repository.saveCalls,
          0,
        );

        expect(
          repository.deleteCalls,
          0,
        );
      },
    );

    test(
      'does not silently treat storage failure as notStarted',
      () async {
        final service = DailyAltarTodayService(
          repository: _FailingTodayRepository(),
        );

        expect(
          () => service.getToday(
            now: DateTime(2026, 10, 31, 8),
          ),
          throwsA(
            isA<DailyAltarTodayStatusException>(),
          ),
        );
      },
    );

    test(
      'rejects a record whose session date is not today',
      () async {
        final repository = _MemoryTodayRepository();

        repository.records[sessionId] = record(
          stage: DailyAltarStage.receive,
          localDate: DateTime(2026, 10, 30),
        );

        final service = DailyAltarTodayService(
          repository: repository,
        );

        expect(
          () => service.getToday(
            now: DateTime(
              2026,
              10,
              31,
              8,
            ),
          ),
          throwsA(
            isA<DailyAltarTodayStatusException>(),
          ),
        );
      },
    );
  });
}
