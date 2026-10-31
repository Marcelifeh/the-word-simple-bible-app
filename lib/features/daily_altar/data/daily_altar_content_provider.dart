import '../model/daily_altar_content.dart';
import '../model/daily_altar_posture.dart';

/// Source of spiritual content for My Daily Altar.
///
/// The initial implementation is entirely curated and offline.
///
/// Future implementations may choose content differently, but callers depend
/// only on this interface rather than on storage, AI, network, or billing.
abstract interface class DailyAltarContentProvider {
  DailyAltarContent getForPosture(DailyAltarPosture posture);

  DailyAltarContent getById(String id);
}
