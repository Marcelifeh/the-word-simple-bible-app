import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const provider = CuratedDailyAltarContentProvider();
  const validator = DailyAltarContentValidator();

  group('Curated Daily Altar content provider', () {
    test('returns the abiding encounter for deeper fellowship', () {
      final content = provider.getForPosture(
        DailyAltarPosture.seekingDeeperFellowship,
      );

      expect(content.id, 'john-15-abide-in-christ');
      expect(content.scripture.reference, 'John 15:4-5');
      expect(content.carryWord.reference, 'John 15:5');
    });

    test('first curated encounter satisfies the full content contract', () {
      final content = provider.getById(
        'john-15-abide-in-christ',
      );

      expect(
        () => validator.validate(content),
        returnsNormally,
      );
    });

    test('all supporting material is explicitly curated', () {
      final content = provider.getById(
        'john-15-abide-in-christ',
      );

      expect(
        content.understanding.origin,
        DailyAltarSupportOrigin.curated,
      );
      expect(
        content.reflection.origin,
        DailyAltarSupportOrigin.curated,
      );
      expect(
        content.prayer.origin,
        DailyAltarSupportOrigin.curated,
      );
      expect(
        content.obedience.origin,
        DailyAltarSupportOrigin.curated,
      );
      expect(
        content.eveningReflection.origin,
        DailyAltarSupportOrigin.curated,
      );
    });

    test('Scripture remains structurally separate from support material', () {
      final content = provider.getById(
        'john-15-abide-in-christ',
      );

      expect(content.scripture, isA<DailyAltarScripture>());
      expect(content.carryWord, isA<DailyAltarScripture>());
      expect(
        content.understanding,
        isA<DailyAltarUnderstanding>(),
      );
      expect(
        content.prayer,
        isA<DailyAltarPrayerPrompt>(),
      );
    });

    test('unknown content id fails explicitly instead of inventing content',
        () {
      expect(
        () => provider.getById('does-not-exist'),
        throwsA(
          isA<DailyAltarContentNotFoundException>(),
        ),
      );
    });

    test('unsupported posture currently uses reviewed fallback content', () {
      final content = provider.getForPosture(
        DailyAltarPosture.anxious,
      );

      expect(
        content.id,
        'john-15-abide-in-christ',
      );
    });

    test('feature remains hidden while curated content is developed', () {
      expect(DailyAltarFeatureFlags.enabled, isFalse);
      expect(
        DailyAltarFeatureFlags.premiumGateEnabled,
        isFalse,
      );
    });

    test('current access policy remains non-billing and open', () async {
      const policy = OpenDailyAltarAccessPolicy();

      final decision = await policy.evaluate();

      expect(decision.isAllowed, isTrue);
    });
  });
}
