import '../model/daily_altar_content.dart';
import '../model/daily_altar_posture.dart';
import '../services/daily_altar_content_validator.dart';
import 'daily_altar_content_not_found_exception.dart';
import 'daily_altar_content_provider.dart';
import 'daily_altar_curated_library.dart';

/// Offline, human-curated content source for My Daily Altar.
///
/// This implementation deliberately has:
/// - no HTTP client
/// - no AI provider
/// - no billing dependency
/// - no account requirement
/// - no database dependency
///
/// As the curated library grows, posture mappings can expand without changing
/// the rest of the My Daily Altar feature.
class CuratedDailyAltarContentProvider implements DailyAltarContentProvider {
  const CuratedDailyAltarContentProvider({
    this.validator = const DailyAltarContentValidator(),
  });

  final DailyAltarContentValidator validator;

  @override
  DailyAltarContent getForPosture(DailyAltarPosture posture) {
    final content = _contentForPosture(posture);

    validator.validate(content);

    return content;
  }

  @override
  DailyAltarContent getById(String id) {
    for (final content in DailyAltarCuratedLibrary.all) {
      if (content.id == id) {
        validator.validate(content);
        return content;
      }
    }

    throw DailyAltarContentNotFoundException(id);
  }

  DailyAltarContent _contentForPosture(DailyAltarPosture posture) {
    switch (posture) {
      case DailyAltarPosture.seekingDeeperFellowship:
        return DailyAltarCuratedLibrary.abideInChrist;

      // MDA-2D currently contains one carefully reviewed encounter.
      // Until additional encounters are curated, all other postures use the
      // same general Scripture-centered fallback rather than fabricated or
      // dynamically generated spiritual direction.
      case DailyAltarPosture.hearFromScripture:
      case DailyAltarPosture.seekingDirection:
      case DailyAltarPosture.thankful:
      case DailyAltarPosture.discouraged:
      case DailyAltarPosture.waitingOnGod:
      case DailyAltarPosture.spirituallyDry:
      case DailyAltarPosture.facingTemptation:
      case DailyAltarPosture.anxious:
      case DailyAltarPosture.needingStrength:
        return DailyAltarCuratedLibrary.abideInChrist;
    }
  }
}
