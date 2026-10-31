import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const policy = DailyAltarReturnPolicy();

  DailyAltarSession waitingSession({
    required DateTime morningCompletedAt,
  }) {
    return DailyAltarSession(
      id: 'altar-2026-10-31',
      localDate: DateTime(2026, 10, 31),
      stage: DailyAltarStage.returnToAltar,
      posture: DailyAltarPosture.seekingDeeperFellowship,
      startedAt: DateTime(2026, 10, 31, 7),
      morningCompletedAt: morningCompletedAt,
    );
  }

  group('DailyAltarReturnPolicy', () {
    test(
      'early morning completion waits until 5 PM',
      () {
        final session = waitingSession(
          morningCompletedAt: DateTime(2026, 10, 31, 7, 30),
        );

        final decision = policy.evaluate(
          session: session,
          now: DateTime(2026, 10, 31, 10),
        );

        expect(
          decision.isAllowed,
          isFalse,
        );

        expect(
          decision.earliestReturnAt,
          DateTime(2026, 10, 31, 17),
        );
      },
    );

    test(
      'early morning altar opens at 5 PM',
      () {
        final session = waitingSession(
          morningCompletedAt: DateTime(2026, 10, 31, 7, 30),
        );

        final decision = policy.evaluate(
          session: session,
          now: DateTime(2026, 10, 31, 17),
        );

        expect(
          decision.isAllowed,
          isTrue,
        );
      },
    );

    test(
      'late altar waits two hours',
      () {
        final session = waitingSession(
          morningCompletedAt: DateTime(2026, 10, 31, 18, 30),
        );

        final tooEarly = policy.evaluate(
          session: session,
          now: DateTime(
            2026,
            10,
            31,
            20,
            29,
          ),
        );

        expect(
          tooEarly.isAllowed,
          isFalse,
        );

        expect(
          tooEarly.earliestReturnAt,
          DateTime(
            2026,
            10,
            31,
            20,
            30,
          ),
        );

        final available = policy.evaluate(
          session: session,
          now: DateTime(
            2026,
            10,
            31,
            20,
            30,
          ),
        );

        expect(
          available.isAllowed,
          isTrue,
        );
      },
    );

    test(
      'return requires morning completion',
      () {
        final session = DailyAltarSession(
          id: 'altar-2026-10-31',
          localDate: DateTime(2026, 10, 31),
          stage: DailyAltarStage.returnToAltar,
          posture: DailyAltarPosture.seekingDeeperFellowship,
          startedAt: DateTime(2026, 10, 31, 7),
        );

        final decision = policy.evaluate(
          session: session,
          now: DateTime(2026, 10, 31, 20),
        );

        expect(
          decision.isAllowed,
          isFalse,
        );

        expect(
          decision.earliestReturnAt,
          isNull,
        );
      },
    );

    test(
      'policy only applies to return stage',
      () {
        final session = DailyAltarSession(
          id: 'altar-2026-10-31',
          localDate: DateTime(2026, 10, 31),
          stage: DailyAltarStage.carry,
          posture: DailyAltarPosture.seekingDeeperFellowship,
          startedAt: DateTime(2026, 10, 31, 7),
        );

        final decision = policy.evaluate(
          session: session,
          now: DateTime(2026, 10, 31, 20),
        );

        expect(
          decision.isAllowed,
          isFalse,
        );
      },
    );
  });
}
