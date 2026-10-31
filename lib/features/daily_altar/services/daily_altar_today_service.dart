import '../model/daily_altar_stage.dart';
import '../persistence/daily_altar_repository.dart';
import '../persistence/hive_daily_altar_repository.dart';
import 'daily_altar_return_policy.dart';
import 'daily_altar_today_status.dart';
import 'daily_altar_today_status_exception.dart';

/// Read-only coordinator describing the user's Daily Altar state for today.
///
/// Consumers do not need to understand:
/// - Hive box names
/// - persistence record structure
/// - journey stages
/// - morning/evening timing calculations
///
/// This service performs no writes and has no billing, network, account,
/// notification, or analytics dependency.
class DailyAltarTodayService {
  const DailyAltarTodayService({
    this.repository = const HiveDailyAltarRepository(),
    this.returnPolicy = const DailyAltarReturnPolicy(),
  });

  final DailyAltarRepository repository;
  final DailyAltarReturnPolicy returnPolicy;

  Future<DailyAltarTodaySnapshot> getToday({
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();

    final localDate = DateTime(
      current.year,
      current.month,
      current.day,
    );

    final sessionId = _sessionId(localDate);

    try {
      final record = await repository.load(sessionId);

      if (record == null) {
        return DailyAltarTodaySnapshot(
          status: DailyAltarTodayStatus.notStarted,
          localDate: localDate,
          sessionId: sessionId,
        );
      }

      if (record.session.id != sessionId) {
        throw const DailyAltarTodayStatusException(
          'Stored Daily Altar session ID does not match today.',
        );
      }

      if (!_sameLocalDate(
        record.session.localDate,
        localDate,
      )) {
        throw const DailyAltarTodayStatusException(
          'Stored Daily Altar date does not match today.',
        );
      }

      switch (record.session.stage) {
        case DailyAltarStage.completed:
          return DailyAltarTodaySnapshot(
            status: DailyAltarTodayStatus.completed,
            localDate: localDate,
            sessionId: sessionId,
            session: record.session,
            contentId: record.contentId,
          );

        case DailyAltarStage.returnToAltar:
          final decision = returnPolicy.evaluate(
            session: record.session,
            now: current,
          );

          return DailyAltarTodaySnapshot(
            status: decision.isAllowed
                ? DailyAltarTodayStatus.eveningAvailable
                : DailyAltarTodayStatus.waitingForEvening,
            localDate: localDate,
            sessionId: sessionId,
            session: record.session,
            contentId: record.contentId,
            earliestReturnAt: decision.earliestReturnAt,
          );

        case DailyAltarStage.come:
        case DailyAltarStage.receive:
        case DailyAltarStage.understand:
        case DailyAltarStage.abide:
        case DailyAltarStage.pray:
        case DailyAltarStage.obey:
        case DailyAltarStage.carry:
          return DailyAltarTodaySnapshot(
            status: DailyAltarTodayStatus.morningInProgress,
            localDate: localDate,
            sessionId: sessionId,
            session: record.session,
            contentId: record.contentId,
          );
      }
    } on DailyAltarTodayStatusException {
      rethrow;
    } catch (error) {
      throw DailyAltarTodayStatusException(
        'Unable to determine today' 's Daily Altar status.',
        error,
      );
    }
  }

  String _sessionId(
    DateTime localDate,
  ) {
    final month = localDate.month.toString().padLeft(2, '0');

    final day = localDate.day.toString().padLeft(2, '0');

    return 'altar-${localDate.year}-$month-$day';
  }

  bool _sameLocalDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
