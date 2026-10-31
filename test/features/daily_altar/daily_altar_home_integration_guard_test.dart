import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  test(
    'Daily Altar production Home integration remains disabled',
    () {
      expect(
        DailyAltarFeatureFlags.enabled,
        isFalse,
      );

      expect(
        DailyAltarFeatureFlags.premiumGateEnabled,
        isFalse,
      );
    },
  );
}
