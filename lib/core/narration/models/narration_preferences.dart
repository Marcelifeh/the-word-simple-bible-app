import 'narration_profile.dart';
import 'narration_state.dart';
import 'saved_voice.dart';

class NarrationPreferences {
  final double speed;
  final double pitch;
  final SavedVoice? savedVoice;
  final bool autoPlayNext;
  final bool autoScroll;
  final bool highlightVerses;
  final NarrationMode mode;
  final String profileId;
  final String languageCode;

  const NarrationPreferences({
    this.speed = 0.36, // Warm, unhurried pace for devotional narration
    this.pitch = 1.04, // Slightly elevated pitch sounds less robotic
    this.savedVoice,
    this.autoPlayNext = true,
    this.autoScroll = true,
    this.highlightVerses = true,
    this.mode = NarrationMode.reading,
    this.profileId = 'reading',
    this.languageCode = 'en',
  });

  factory NarrationPreferences.fromProfile(
    NarrationProfile profile, {
    SavedVoice? savedVoice,
    bool autoPlayNext = true,
    bool autoScroll = true,
    bool highlightVerses = true,
    String languageCode = 'en',
  }) {
    return NarrationPreferences(
      speed: profile.speed,
      pitch: profile.pitch,
      savedVoice: savedVoice,
      autoPlayNext: autoPlayNext,
      autoScroll: autoScroll,
      highlightVerses: highlightVerses,
      mode: profile.mode,
      profileId: profile.id,
      languageCode: languageCode,
    );
  }

  NarrationPreferences copyWith({
    double? speed,
    double? pitch,
    SavedVoice? savedVoice,
    bool? autoPlayNext,
    bool? autoScroll,
    bool? highlightVerses,
    NarrationMode? mode,
    String? profileId,
    String? languageCode,
  }) {
    return NarrationPreferences(
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      savedVoice: savedVoice ?? this.savedVoice,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      autoScroll: autoScroll ?? this.autoScroll,
      highlightVerses: highlightVerses ?? this.highlightVerses,
      mode: mode ?? this.mode,
      profileId: profileId ?? this.profileId,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'speed': speed,
      'pitch': pitch,
      'savedVoice': savedVoice?.toJson(),
      'autoPlayNext': autoPlayNext,
      'autoScroll': autoScroll,
      'highlightVerses': highlightVerses,
      'mode': mode.name,
      'profileId': profileId,
      'languageCode': languageCode,
    };
  }

  factory NarrationPreferences.fromJson(Map<dynamic, dynamic> json) {
    final modeName = json['mode'] as String?;
    final profileId = json['profileId'] as String?;
    final mode = NarrationMode.values
            .where((value) => value.name == modeName)
            .firstOrNull ??
        NarrationMode.reading;
    return NarrationPreferences(
      speed: (json['speed'] as num?)?.toDouble() ?? 0.36,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.04,
      savedVoice: json['savedVoice'] != null
          ? SavedVoice.fromJson(json['savedVoice'])
          : null,
      autoPlayNext: json['autoPlayNext'] as bool? ?? true,
      autoScroll: json['autoScroll'] as bool? ?? true,
      highlightVerses: json['highlightVerses'] as bool? ?? true,
      mode: mode,
      profileId: profileId == 'study' ? 'reading' : profileId ?? 'reading',
      languageCode: json['languageCode'] as String? ?? 'en',
    );
  }
}
