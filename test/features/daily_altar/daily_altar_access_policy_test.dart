import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _FuturePremiumPolicy implements DailyAltarAccessPolicy {
  const _FuturePremiumPolicy();

  @override
  Future<DailyAltarAccessDecision> evaluate() async {
    return const DailyAltarAccessDecision.premiumRequired(
      reason: 'Future premium entitlement required.',
    );
  }
}

void main() {
  group('Daily Altar future premium access seam', () {
    test('current policy performs open local access only', () async {
      const policy = OpenDailyAltarAccessPolicy();

      final decision = await policy.evaluate();

      expect(decision.state, DailyAltarAccessState.allowed);
      expect(decision.isAllowed, isTrue);
    });

    test('access policy can later be replaced without billing in the domain',
        () async {
      const DailyAltarAccessPolicy policy = _FuturePremiumPolicy();

      final decision = await policy.evaluate();

      expect(
        decision.state,
        DailyAltarAccessState.premiumRequired,
      );
      expect(decision.isAllowed, isFalse);
    });

    test('premium enforcement remains disabled today', () {
      expect(
        DailyAltarFeatureFlags.premiumGateEnabled,
        isFalse,
      );
    });
  });
}
