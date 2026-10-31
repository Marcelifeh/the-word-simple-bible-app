import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  group('My Daily Altar feature shell', () {
    test('is disabled during MDA-1', () {
      expect(DailyAltarFeatureFlags.enabled, isFalse);
    });

    test('does not enforce premium entitlement during MDA-1', () {
      expect(DailyAltarFeatureFlags.premiumGateEnabled, isFalse);
    });

    test('has stable feature identity', () {
      expect(DailyAltarFeature.id, 'my_daily_altar');
      expect(DailyAltarFeature.title, 'My Daily Altar');
    });
  });
}
