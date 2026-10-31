import '../model/daily_altar_session.dart';

/// High-level state of today's My Daily Altar journey.
///
/// This is deliberately independent of Flutter UI and Hive details so
/// production surfaces can consume one stable status contract later.
enum DailyAltarTodayStatus {
  notStarted,
  morningInProgress,
  waitingForEvening,
  eveningAvailable,
  completed,
}

class DailyAltarTodaySnapshot {
  const DailyAltarTodaySnapshot({
    required this.status,
    required this.localDate,
    required this.sessionId,
    this.session,
    this.contentId,
    this.earliestReturnAt,
  });

  final DailyAltarTodayStatus status;
  final DateTime localDate;
  final String sessionId;

  final DailyAltarSession? session;
  final String? contentId;

  /// Present when a morning altar is complete and a later return time
  /// can be calculated.
  final DateTime? earliestReturnAt;

  bool get hasStarted => status != DailyAltarTodayStatus.notStarted;

  bool get isComplete => status == DailyAltarTodayStatus.completed;

  bool get canReturnThisEvening =>
      status == DailyAltarTodayStatus.eveningAvailable;
}
