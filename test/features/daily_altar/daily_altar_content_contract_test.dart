import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const validator = DailyAltarContentValidator();

  DailyAltarContent validContent({
    String scriptureTranslation = 'kjv',
    String carryTranslation = 'kjv',
    String scriptureText = 'Abide in me, and I in you.',
  }) {
    return DailyAltarContent(
      id: 'john-15-abide',
      scripture: DailyAltarScripture(
        reference: 'John 15:4-5',
        translationId: scriptureTranslation,
        text: scriptureText,
      ),
      understanding: const DailyAltarUnderstanding(
        context:
            'Jesus prepares His disciples for faithful life and fruitfulness.',
        centralTruth:
            'Spiritual fruit flows from continuing fellowship with Christ.',
        lookAgain: 'The passage places abiding before fruitfulness.',
        origin: DailyAltarSupportOrigin.curated,
      ),
      reflection: const DailyAltarReflectionPrompts(
        aboutGod: 'What does this passage reveal about Christ?',
        aboutMe: 'Where am I relying on myself instead of abiding in Christ?',
        response: 'What response does this Scripture call me to today?',
        origin: DailyAltarSupportOrigin.curated,
      ),
      prayer: const DailyAltarPrayerPrompt(
        text: 'Father, teach me to remain in Christ and depend upon You today.',
        origin: DailyAltarSupportOrigin.curated,
      ),
      obedience: const DailyAltarObedienceStep(
        text:
            'Pause before one important decision today and consciously bring it to God in prayer.',
        origin: DailyAltarSupportOrigin.curated,
      ),
      carryWord: DailyAltarScripture(
        reference: 'John 15:5',
        translationId: carryTranslation,
        text: 'Without me ye can do nothing.',
      ),
      eveningReflection: const DailyAltarEveningReflection(
        rememberedWordPrompt: 'When did you remember today’s Scripture?',
        obediencePrompt: 'How did you respond to today’s obedience step?',
        relevancePrompt:
            'Where did this truth become relevant during your day?',
        heartResponsePrompt:
            'What do you want to confess, thank God for, or surrender?',
        carryForwardPrompt:
            'What truth from today should you carry into tomorrow?',
        origin: DailyAltarSupportOrigin.curated,
      ),
    );
  }

  group('Daily Altar content contract', () {
    test('accepts structurally complete curated content', () {
      expect(
        () => validator.validate(validContent()),
        returnsNormally,
      );
    });

    test('Scripture and supporting content use different model types', () {
      final content = validContent();

      expect(content.scripture, isA<DailyAltarScripture>());
      expect(content.carryWord, isA<DailyAltarScripture>());

      expect(
        content.understanding.origin,
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
    });

    test('generated supporting material is explicitly assistive', () {
      const understanding = DailyAltarUnderstanding(
        context: 'Context',
        centralTruth: 'Central truth',
        lookAgain: 'Observation',
        origin: DailyAltarSupportOrigin.generatedAssistive,
      );

      expect(
        understanding.origin,
        DailyAltarSupportOrigin.generatedAssistive,
      );
    });

    test('rejects empty Scripture text', () {
      final content = validContent(scriptureText: '   ');

      expect(
        () => validator.validate(content),
        throwsA(
          isA<DailyAltarContentValidationException>().having(
            (error) => error.errors,
            'errors',
            contains('scripture.text must not be empty'),
          ),
        ),
      );
    });

    test('requires carry verse and primary passage to use same translation',
        () {
      final content = validContent(
        scriptureTranslation: 'kjv',
        carryTranslation: 'other',
      );

      expect(
        () => validator.validate(content),
        throwsA(
          isA<DailyAltarContentValidationException>().having(
            (error) => error.errors,
            'errors',
            contains(
              'carryWord.translationId must match scripture.translationId',
            ),
          ),
        ),
      );
    });

    test('reflection contract preserves the three formation questions', () {
      final reflection = validContent().reflection;

      expect(reflection.aboutGod, isNotEmpty);
      expect(reflection.aboutMe, isNotEmpty);
      expect(reflection.response, isNotEmpty);
    });

    test('evening return contains five distinct reflection dimensions', () {
      final evening = validContent().eveningReflection;

      expect(evening.rememberedWordPrompt, isNotEmpty);
      expect(evening.obediencePrompt, isNotEmpty);
      expect(evening.relevancePrompt, isNotEmpty);
      expect(evening.heartResponsePrompt, isNotEmpty);
      expect(evening.carryForwardPrompt, isNotEmpty);
    });
  });
}
