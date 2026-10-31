import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const validator = DailyAltarResponseValidator();

  group('Daily Altar user response contract', () {
    test('allows an empty optional response record', () {
      const response = DailyAltarUserResponse(
        sessionId: 'altar-2026-10-31',
      );

      expect(response.hasAnyResponse, isFalse);
      expect(
        () => validator.validate(response),
        returnsNormally,
      );
    });

    test('detects morning reflection', () {
      const response = DailyAltarUserResponse(
        sessionId: 'altar-2026-10-31',
        reflection: DailyAltarReflectionResponse(
          aboutGod: 'God is faithful.',
        ),
      );

      expect(response.hasMorningResponse, isTrue);
      expect(response.hasEveningResponse, isFalse);
      expect(response.hasAnyResponse, isTrue);
    });

    test('personal prayer is user-owned and distinct from prayer prompt', () {
      const prayer = DailyAltarPersonalPrayer(
        text: 'Father, help me depend on You today.',
      );

      expect(prayer.isEmpty, isFalse);
      expect(prayer, isA<DailyAltarPersonalPrayer>());
    });

    test('obedience commitment can be completed later', () {
      const obedience = DailyAltarObedienceResponse(
        commitment: 'Pause and pray before my important conversation.',
      );

      final completedAt = DateTime(2026, 10, 31, 15, 30);
      final completed = obedience.markCompleted(completedAt);

      expect(obedience.completed, isFalse);
      expect(completed.completed, isTrue);
      expect(completed.completedAt, completedAt);

      expect(
        () => validator.validate(
          DailyAltarUserResponse(
            sessionId: 'altar-2026-10-31',
            obedience: completed,
          ),
        ),
        returnsNormally,
      );
    });

    test('rejects completed obedience without completion timestamp', () {
      const response = DailyAltarUserResponse(
        sessionId: 'altar-2026-10-31',
        obedience: DailyAltarObedienceResponse(
          commitment: 'Forgive someone.',
          completed: true,
        ),
      );

      expect(
        () => validator.validate(response),
        throwsA(
          isA<DailyAltarResponseValidationException>().having(
            (error) => error.errors,
            'errors',
            contains(
              'obedience.completedAt is required when obedience is completed',
            ),
          ),
        ),
      );
    });

    test('evening response is independent from morning response', () {
      const response = DailyAltarUserResponse(
        sessionId: 'altar-2026-10-31',
        evening: DailyAltarEveningResponse(
          relevanceReflection:
              'I remembered the passage when I became impatient.',
        ),
      );

      expect(response.hasMorningResponse, isFalse);
      expect(response.hasEveningResponse, isTrue);
      expect(response.hasAnyResponse, isTrue);
    });

    test('rejects blank session id', () {
      const response = DailyAltarUserResponse(
        sessionId: ' ',
      );

      expect(
        () => validator.validate(response),
        throwsA(
          isA<DailyAltarResponseValidationException>().having(
            (error) => error.errors,
            'errors',
            contains('sessionId must not be empty'),
          ),
        ),
      );
    });

    test('copyWith preserves existing user responses', () {
      const original = DailyAltarUserResponse(
        sessionId: 'altar-2026-10-31',
        reflection: DailyAltarReflectionResponse(
          aboutMe: 'I need to trust God more.',
        ),
      );

      final updatedAt = DateTime(2026, 10, 31, 8);

      final updated = original.copyWith(
        personalPrayer: const DailyAltarPersonalPrayer(
          text: 'Lord, deepen my trust in You.',
        ),
        updatedAt: updatedAt,
      );

      expect(
        updated.reflection?.aboutMe,
        'I need to trust God more.',
      );
      expect(
        updated.personalPrayer?.text,
        'Lord, deepen my trust in You.',
      );
      expect(updated.updatedAt, updatedAt);
    });
  });
}
