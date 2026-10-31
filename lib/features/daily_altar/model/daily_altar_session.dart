import 'daily_altar_posture.dart';
import 'daily_altar_stage.dart';

/// Immutable state for one calendar-day My Daily Altar journey.
///
/// MDA-2 deliberately stores only formation state. Scripture content,
/// reflections, prayers and persistence are introduced separately so this
/// foundation can remain stable.
class DailyAltarSession {
  const DailyAltarSession({
    required this.id,
    required this.localDate,
    required this.stage,
    this.posture,
    this.startedAt,
    this.morningCompletedAt,
    this.completedAt,
  });

  final String id;

  /// Date represented as a local calendar date with the time normalized by
  /// the caller. Persistence policy will be defined in a later phase.
  final DateTime localDate;

  final DailyAltarStage stage;
  final DailyAltarPosture? posture;

  final DateTime? startedAt;
  final DateTime? morningCompletedAt;
  final DateTime? completedAt;

  bool get hasStarted => startedAt != null;

  bool get morningJourneyCompleted =>
      morningCompletedAt != null ||
      stage == DailyAltarStage.returnToAltar ||
      stage == DailyAltarStage.completed;

  bool get isCompleted =>
      stage == DailyAltarStage.completed && completedAt != null;

  DailyAltarSession copyWith({
    DailyAltarStage? stage,
    DailyAltarPosture? posture,
    DateTime? startedAt,
    DateTime? morningCompletedAt,
    DateTime? completedAt,
  }) {
    return DailyAltarSession(
      id: id,
      localDate: localDate,
      stage: stage ?? this.stage,
      posture: posture ?? this.posture,
      startedAt: startedAt ?? this.startedAt,
      morningCompletedAt: morningCompletedAt ?? this.morningCompletedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
