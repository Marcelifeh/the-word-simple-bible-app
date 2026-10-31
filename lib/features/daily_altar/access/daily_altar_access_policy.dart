import 'daily_altar_access_decision.dart';

/// Abstraction controlling access to My Daily Altar.
///
/// MDA currently uses a local open policy only.
///
/// In the future, a Google Play billing or entitlement implementation may
/// implement this interface without changing the Daily Altar journey engine,
/// content contract, user-response contract, or persistence layer.
abstract interface class DailyAltarAccessPolicy {
  Future<DailyAltarAccessDecision> evaluate();
}
