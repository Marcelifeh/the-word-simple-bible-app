import 'narration_state.dart';

/// Quality tier for a TTS voice — drives star ratings and recommendations in UI.
enum VoiceQuality {
  premium,   // ★★★★★ — Google Neural / Piper neural
  excellent, // ★★★★  — Standard Google
  good,      // ★★★   — OEM (Samsung, Huawei, etc.)
  standard,  // ★★    — Generic device voices
  basic,     // ★     — Unknown / fallback
}

/// Returns the star string for a given quality tier.
extension VoiceQualityDisplay on VoiceQuality {
  String get stars {
    switch (this) {
      case VoiceQuality.premium:   return '★★★★★ Premium';
      case VoiceQuality.excellent: return '★★★★ Excellent';
      case VoiceQuality.good:      return '★★★ Good';
      case VoiceQuality.standard:  return '★★ Standard';
      case VoiceQuality.basic:     return '★ Basic';
    }
  }

  int get sortOrder {
    switch (this) {
      case VoiceQuality.premium:   return 0;
      case VoiceQuality.excellent: return 1;
      case VoiceQuality.good:      return 2;
      case VoiceQuality.standard:  return 3;
      case VoiceQuality.basic:     return 4;
    }
  }
}

enum VoiceProvider {
  device,
  piper,
  cloud,
}

class NarrationVoice {
  final String id;
  final String name;
  final String locale;
  final bool isDefault;
  final bool isInstalled;
  final VoiceProvider provider;

  /// Quality tier — used for star ratings and sort order.
  final VoiceQuality quality;

  /// Modes this voice is recommended for.
  final Set<NarrationMode> recommendedModes;

  const NarrationVoice({
    required this.id,
    required this.name,
    required this.locale,
    this.isDefault = false,
    this.isInstalled = true,
    this.provider = VoiceProvider.device,
    this.quality = VoiceQuality.standard,
    this.recommendedModes = const {},
  });
}
