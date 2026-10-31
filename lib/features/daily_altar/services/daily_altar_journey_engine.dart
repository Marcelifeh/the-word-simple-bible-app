import '../model/daily_altar_posture.dart';
import '../model/daily_altar_session.dart';
import '../model/daily_altar_stage.dart';
import 'daily_altar_transition_exception.dart';

/// Pure domain engine controlling My Daily Altar stage progression.
///
/// It has no Flutter, storage, billing, network, AI, notification or existing
/// feature dependencies. This isolation is intentional.
class DailyAltarJourneyEngine {
  const DailyAltarJourneyEngine();

  DailyAltarSession start({
    required String sessionId,
    required DateTime localDate,
    required DateTime now,
    required DailyAltarPosture posture,
  }) {
    return DailyAltarSession(
      id: sessionId,
      localDate: localDate,
      stage: DailyAltarStage.receive,
      posture: posture,
      startedAt: now,
    );
  }

  DailyAltarSession advance({
    required DailyAltarSession session,
    required DateTime now,
  }) {
    switch (session.stage) {
      case DailyAltarStage.come:
        throw const DailyAltarTransitionException(
          'A posture must be selected before leaving Come to the Altar.',
        );

      case DailyAltarStage.receive:
        return session.copyWith(stage: DailyAltarStage.understand);

      case DailyAltarStage.understand:
        return session.copyWith(stage: DailyAltarStage.abide);

      case DailyAltarStage.abide:
        return session.copyWith(stage: DailyAltarStage.pray);

      case DailyAltarStage.pray:
        return session.copyWith(stage: DailyAltarStage.obey);

      case DailyAltarStage.obey:
        return session.copyWith(stage: DailyAltarStage.carry);

      case DailyAltarStage.carry:
        return session.copyWith(
          stage: DailyAltarStage.returnToAltar,
          morningCompletedAt: now,
        );

      case DailyAltarStage.returnToAltar:
        return session.copyWith(
          stage: DailyAltarStage.completed,
          completedAt: now,
        );

      case DailyAltarStage.completed:
        throw const DailyAltarTransitionException(
          'A completed Daily Altar session cannot be advanced.',
        );
    }
  }
}
