import 'package:hive/hive.dart';

import 'daily_altar_repository.dart';
import 'daily_altar_storage_codec.dart';
import 'daily_altar_storage_exception.dart';
import 'daily_altar_stored_record.dart';

/// Hive-backed local persistence for My Daily Altar.
///
/// This box belongs only to My Daily Altar and is not shared with Journal,
/// Prayer, Scripture Memory, settings, billing, or other features.
class HiveDailyAltarRepository implements DailyAltarRepository {
  const HiveDailyAltarRepository({
    this.codec = const DailyAltarStorageCodec(),
  });

  static const String boxName = 'daily_altar_sessions';

  final DailyAltarStorageCodec codec;

  Future<Box<dynamic>> _box() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<dynamic>(boxName);
      }

      return await Hive.openBox<dynamic>(boxName);
    } catch (error) {
      throw DailyAltarStorageException(
        'Unable to open Daily Altar local storage.',
        error,
      );
    }
  }

  @override
  Future<void> save(
    DailyAltarStoredRecord record,
  ) async {
    final encoded = codec.encode(record);

    try {
      final box = await _box();

      await box.put(
        record.session.id,
        encoded,
      );

      await box.flush();
    } on DailyAltarStorageException {
      rethrow;
    } catch (error) {
      throw DailyAltarStorageException(
        'Unable to save Daily Altar session.',
        error,
      );
    }
  }

  @override
  Future<DailyAltarStoredRecord?> load(
    String sessionId,
  ) async {
    if (sessionId.trim().isEmpty) {
      throw const DailyAltarStorageException(
        'sessionId must not be empty.',
      );
    }

    try {
      final box = await _box();
      final raw = box.get(sessionId);

      if (raw == null) {
        return null;
      }

      return codec.decode(raw);
    } on DailyAltarStorageException {
      rethrow;
    } catch (error) {
      throw DailyAltarStorageException(
        'Unable to load Daily Altar session.',
        error,
      );
    }
  }

  @override
  Future<void> delete(
    String sessionId,
  ) async {
    if (sessionId.trim().isEmpty) {
      throw const DailyAltarStorageException(
        'sessionId must not be empty.',
      );
    }

    try {
      final box = await _box();

      await box.delete(sessionId);
      await box.flush();
    } on DailyAltarStorageException {
      rethrow;
    } catch (error) {
      throw DailyAltarStorageException(
        'Unable to delete Daily Altar session.',
        error,
      );
    }
  }
}
