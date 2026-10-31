/// The user's chosen application or obedience commitment.
///
/// The app may suggest an application separately, but this model records what
/// the believer personally decides to carry into the day.
class DailyAltarObedienceResponse {
  const DailyAltarObedienceResponse({
    required this.commitment,
    this.completed = false,
    this.completedAt,
  });

  final String commitment;
  final bool completed;
  final DateTime? completedAt;

  DailyAltarObedienceResponse markCompleted(DateTime when) {
    return DailyAltarObedienceResponse(
      commitment: commitment,
      completed: true,
      completedAt: when,
    );
  }
}
