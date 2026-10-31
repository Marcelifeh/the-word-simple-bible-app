import '../model/daily_altar_user_response.dart';
import 'daily_altar_response_validation_exception.dart';

/// Validates user-owned Daily Altar response data.
///
/// Empty optional responses are allowed because reflection should never be
/// coerced merely to satisfy storage requirements.
class DailyAltarResponseValidator {
  const DailyAltarResponseValidator();

  void validate(DailyAltarUserResponse response) {
    final errors = <String>[];

    if (response.sessionId.trim().isEmpty) {
      errors.add('sessionId must not be empty');
    }

    final obedience = response.obedience;

    if (obedience != null) {
      if (obedience.commitment.trim().isEmpty) {
        errors.add(
          'obedience.commitment must not be empty when obedience is present',
        );
      }

      if (obedience.completed && obedience.completedAt == null) {
        errors.add(
          'obedience.completedAt is required when obedience is completed',
        );
      }

      if (!obedience.completed && obedience.completedAt != null) {
        errors.add(
          'obedience.completedAt must be null when obedience is incomplete',
        );
      }
    }

    if (errors.isNotEmpty) {
      throw DailyAltarResponseValidationException(
        List.unmodifiable(errors),
      );
    }
  }
}
