import 'daily_altar_access_decision.dart';
import 'daily_altar_access_policy.dart';

/// Current access implementation.
///
/// This class performs no purchase, subscription, account, network, billing,
/// entitlement, or Play Store operation.
///
/// It exists so the application can depend on DailyAltarAccessPolicy rather
/// than depending directly on a future billing system.
class OpenDailyAltarAccessPolicy implements DailyAltarAccessPolicy {
  const OpenDailyAltarAccessPolicy();

  @override
  Future<DailyAltarAccessDecision> evaluate() async {
    return const DailyAltarAccessDecision.allowed();
  }
}
