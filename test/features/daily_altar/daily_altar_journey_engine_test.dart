import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const engine = DailyAltarJourneyEngine();

  final day = DateTime(2026, 10, 31);
  final startTime = DateTime(2026, 10, 31, 7, 0);

  group('DailyAltarJourneyEngine', () {
    test('starts after posture selection at Receive the Word', () {
      final session = engine.start(
        sessionId: 'altar-2026-10-31',
        localDate: day,
        now: startTime,
        posture: DailyAltarPosture.hearFromScripture,
      );

      expect(session.stage, DailyAltarStage.receive);
      expect(
        session.posture,
        DailyAltarPosture.hearFromScripture,
      );
      expect(session.startedAt, startTime);
      expect(session.hasStarted, isTrue);
      expect(session.isCompleted, isFalse);
    });

    test('follows the intended morning formation sequence', () {
      var session = engine.start(
        sessionId: 'altar-2026-10-31',
        localDate: day,
        now: startTime,
        posture: DailyAltarPosture.seekingDirection,
      );

      expect(session.stage, DailyAltarStage.receive);

      session = engine.advance(session: session, now: startTime);
      expect(session.stage, DailyAltarStage.understand);

      session = engine.advance(session: session, now: startTime);
      expect(session.stage, DailyAltarStage.abide);

      session = engine.advance(session: session, now: startTime);
      expect(session.stage, DailyAltarStage.pray);

      session = engine.advance(session: session, now: startTime);
      expect(session.stage, DailyAltarStage.obey);

      session = engine.advance(session: session, now: startTime);
      expect(session.stage, DailyAltarStage.carry);
    });

    test('Carry the Word closes morning journey but not full session', () {
      var session = engine.start(
        sessionId: 'altar-2026-10-31',
        localDate: day,
        now: startTime,
        posture: DailyAltarPosture.thankful,
      );

      while (session.stage != DailyAltarStage.carry) {
        session = engine.advance(session: session, now: startTime);
      }

      final morningCompletedAt = DateTime(2026, 10, 31, 7, 30);

      session = engine.advance(
        session: session,
        now: morningCompletedAt,
      );

      expect(session.stage, DailyAltarStage.returnToAltar);
      expect(session.morningCompletedAt, morningCompletedAt);
      expect(session.morningJourneyCompleted, isTrue);
      expect(session.isCompleted, isFalse);
    });

    test('Return to the Altar completes the daily journey', () {
      var session = engine.start(
        sessionId: 'altar-2026-10-31',
        localDate: day,
        now: startTime,
        posture: DailyAltarPosture.waitingOnGod,
      );

      while (session.stage != DailyAltarStage.returnToAltar) {
        session = engine.advance(session: session, now: startTime);
      }

      final eveningTime = DateTime(2026, 10, 31, 20, 15);

      session = engine.advance(
        session: session,
        now: eveningTime,
      );

      expect(session.stage, DailyAltarStage.completed);
      expect(session.completedAt, eveningTime);
      expect(session.isCompleted, isTrue);
    });

    test('completed journey cannot advance again', () {
      var session = engine.start(
        sessionId: 'altar-2026-10-31',
        localDate: day,
        now: startTime,
        posture: DailyAltarPosture.needingStrength,
      );

      while (session.stage != DailyAltarStage.completed) {
        session = engine.advance(session: session, now: startTime);
      }

      expect(
        () => engine.advance(session: session, now: startTime),
        throwsA(isA<DailyAltarTransitionException>()),
      );
    });

    test('feature remains disabled while formation engine is built', () {
      expect(DailyAltarFeatureFlags.enabled, isFalse);
      expect(DailyAltarFeatureFlags.premiumGateEnabled, isFalse);
    });
  });
}
