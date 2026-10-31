import 'daily_altar_stored_record.dart';

/// Persistence boundary for My Daily Altar.
///
/// UI and formation-domain code depend on this abstraction rather than Hive.
abstract interface class DailyAltarRepository {
  Future<void> save(DailyAltarStoredRecord record);

  Future<DailyAltarStoredRecord?> load(String sessionId);

  Future<void> delete(String sessionId);
}
