import '../model/daily_altar_session.dart';
import '../model/daily_altar_stage.dart';

class DailyAltarReturnDecision {
  const DailyAltarReturnDecision({
    required this.isAllowed,
    required this.reason,
    this.earliestReturnAt,
  });

  final bool isAllowed;
  final String reason;
  final DateTime? earliestReturnAt;
}

/// Controls when the later Return to the Altar becomes available.
///
/// The return opens at the later of:
/// - 5:00 PM on the session's local date, or
/// - two hours after the morning journey was completed.
///
/// This policy has no billing, network, account, notification,
/// persistence, or platform dependency.
class DailyAltarReturnPolicy {
  const DailyAltarReturnPolicy({
    this.eveningHour = 17,
    this.minimumReturnDelay = const Duration(hours: 2),
  });

  final int eveningHour;
  final Duration minimumReturnDelay;

  DailyAltarReturnDecision evaluate({
    required DailyAltarSession session,
    required DateTime now,
  }) {
    if (session.stage != DailyAltarStage.returnToAltar) {
      return const DailyAltarReturnDecision(
        isAllowed: false,
        reason: 'The evening return is not the current Daily Altar stage.',
      );
    }

    final morningCompletedAt = session.morningCompletedAt;

    if (morningCompletedAt == null) {
      return const DailyAltarReturnDecision(
        isAllowed: false,
        reason:
            'Complete the morning Daily Altar journey before returning later.',
      );
    }

    final eveningStart = DateTime(
      session.localDate.year,
      session.localDate.month,
      session.localDate.day,
      eveningHour,
    );

    final delayedStart = morningCompletedAt.add(minimumReturnDelay);

    final earliestReturnAt =
        delayedStart.isAfter(eveningStart) ? delayedStart : eveningStart;

    if (now.isBefore(earliestReturnAt)) {
      return DailyAltarReturnDecision(
        isAllowed: false,
        earliestReturnAt: earliestReturnAt,
        reason:
            'Carry the Word with you and return later for evening reflection.',
      );
    }

    return DailyAltarReturnDecision(
      isAllowed: true,
      earliestReturnAt: earliestReturnAt,
      reason: 'The evening Return to the Altar is available.',
    );
  }
}
