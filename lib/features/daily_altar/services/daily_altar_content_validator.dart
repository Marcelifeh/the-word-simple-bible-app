import '../model/daily_altar_content.dart';
import 'daily_altar_content_validation_exception.dart';

/// Structural validator for Daily Altar content.
///
/// This validator intentionally focuses on contract integrity rather than
/// theological inference. Editorial/theological review remains a separate
/// responsibility.
class DailyAltarContentValidator {
  const DailyAltarContentValidator();

  void validate(DailyAltarContent content) {
    final errors = <String>[];

    void requireText(String value, String field) {
      if (value.trim().isEmpty) {
        errors.add('$field must not be empty');
      }
    }

    requireText(content.id, 'id');

    requireText(content.scripture.reference, 'scripture.reference');
    requireText(content.scripture.translationId, 'scripture.translationId');
    requireText(content.scripture.text, 'scripture.text');

    requireText(content.understanding.context, 'understanding.context');
    requireText(
      content.understanding.centralTruth,
      'understanding.centralTruth',
    );
    requireText(content.understanding.lookAgain, 'understanding.lookAgain');

    requireText(content.reflection.aboutGod, 'reflection.aboutGod');
    requireText(content.reflection.aboutMe, 'reflection.aboutMe');
    requireText(content.reflection.response, 'reflection.response');

    requireText(content.prayer.text, 'prayer.text');
    requireText(content.obedience.text, 'obedience.text');

    requireText(content.carryWord.reference, 'carryWord.reference');
    requireText(content.carryWord.translationId, 'carryWord.translationId');
    requireText(content.carryWord.text, 'carryWord.text');

    requireText(
      content.eveningReflection.rememberedWordPrompt,
      'eveningReflection.rememberedWordPrompt',
    );
    requireText(
      content.eveningReflection.obediencePrompt,
      'eveningReflection.obediencePrompt',
    );
    requireText(
      content.eveningReflection.relevancePrompt,
      'eveningReflection.relevancePrompt',
    );
    requireText(
      content.eveningReflection.heartResponsePrompt,
      'eveningReflection.heartResponsePrompt',
    );
    requireText(
      content.eveningReflection.carryForwardPrompt,
      'eveningReflection.carryForwardPrompt',
    );

    if (content.carryWord.translationId.trim() !=
        content.scripture.translationId.trim()) {
      errors.add(
        'carryWord.translationId must match scripture.translationId',
      );
    }

    if (errors.isNotEmpty) {
      throw DailyAltarContentValidationException(
        List.unmodifiable(errors),
      );
    }
  }
}
