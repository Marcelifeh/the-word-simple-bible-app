import '../model/daily_altar_session.dart';
import '../model/daily_altar_user_response.dart';

/// Persisted state for one My Daily Altar encounter.
///
/// Curated spiritual content itself is not duplicated into local storage.
/// [contentId] points back to the reviewed content provider.
class DailyAltarStoredRecord {
  const DailyAltarStoredRecord({
    required this.session,
    required this.contentId,
    required this.response,
  });

  final DailyAltarSession session;
  final String contentId;
  final DailyAltarUserResponse response;
}
