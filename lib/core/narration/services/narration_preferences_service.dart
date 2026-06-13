import 'package:hive/hive.dart';

import '../models/narration_preferences.dart';
import '../models/narration_profile.dart';

class NarrationPreferencesService {
  static const _boxName = 'narration_preferences';
  static const _preferencesKey = 'preferences';
  static const _profileKey = 'activeProfileId';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  NarrationPreferences loadPreferences() {
    final box = _box;
    if (box == null) {
      return const NarrationPreferences();
    }

    final raw = box.get(_preferencesKey);
    if (raw is Map) {
      return NarrationPreferences.fromJson(raw);
    }

    return const NarrationPreferences();
  }

  Future<void> savePreferences(NarrationPreferences preferences) async {
    final box = _box;
    if (box == null) {
      return;
    }

    await box.put(_preferencesKey, preferences.toJson());
  }

  String loadActiveProfileId() {
    final box = _box;
    if (box == null) {
      return NarrationProfile.reading.id;
    }

    final profileId = box.get(_profileKey) as String?;
    return profileId == 'study'
        ? NarrationProfile.reading.id
        : profileId ?? NarrationProfile.reading.id;
  }

  Future<void> saveActiveProfileId(String profileId) async {
    final box = _box;
    if (box == null) {
      return;
    }

    await box.put(_profileKey, profileId);
  }
}
