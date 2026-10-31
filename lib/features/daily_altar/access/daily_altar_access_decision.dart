/// Result of evaluating access to My Daily Altar.
///
/// This model contains no billing implementation. The `premiumRequired`
/// state exists only so a future billing/entitlement adapter can plug in
/// without forcing changes to My Daily Altar's domain or UI contracts.
enum DailyAltarAccessState {
  allowed,
  premiumRequired,
  unavailable,
}

class DailyAltarAccessDecision {
  const DailyAltarAccessDecision({
    required this.state,
    this.reason,
  });

  const DailyAltarAccessDecision.allowed()
      : state = DailyAltarAccessState.allowed,
        reason = null;

  const DailyAltarAccessDecision.premiumRequired({
    this.reason,
  }) : state = DailyAltarAccessState.premiumRequired;

  const DailyAltarAccessDecision.unavailable({
    this.reason,
  }) : state = DailyAltarAccessState.unavailable;

  final DailyAltarAccessState state;
  final String? reason;

  bool get isAllowed => state == DailyAltarAccessState.allowed;
}
