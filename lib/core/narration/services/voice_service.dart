import '../engines/narration_engine.dart';
import '../models/narration_state.dart';
import '../models/narration_voice.dart';

class VoiceService {
  final NarrationEngine _engine;
  List<NarrationVoice> _availableVoices = [];

  static const _premiumKeywords = [
    'neural',
    'natural',
    'google',
    'enhanced',
    'premium',
  ];

  static const _badKeywords = [
    'pico',
    'espeak',
    'samsung',
    'default',
  ];

  VoiceService(this._engine);

  Future<void> loadVoices() async {
    try {
      final rawVoices = await _engine.loadVoices();
      _availableVoices = [];

      for (final voice in rawVoices) {
        final quality = _detectQuality(voice.name);
        final recModes = _detectRecommendedModes(quality);

        _availableVoices.add(
          NarrationVoice(
            id: voice.id,
            name: voice.name,
            locale: voice.locale,
            provider: voice.provider,
            isInstalled: voice.isInstalled,
            quality: quality,
            recommendedModes: recModes,
          ),
        );
      }

      _availableVoices.sort(_compareVoices);
    } catch (_) {
      _availableVoices = [];
    }
  }

  List<NarrationVoice> getAvailableVoices() =>
      List.unmodifiable(_availableVoices);

  /// Returns voices that match a given language prefix (e.g. 'en', 'ha', 'ig', 'yo')
  List<NarrationVoice> getVoicesForLanguage(String langPrefix) {
    return _availableVoices
        .where(
            (v) => v.locale.toLowerCase().startsWith(langPrefix.toLowerCase()))
        .toList();
  }

  /// Best available voice for a locale prefix — implements a 6-step fallback chain.
  NarrationVoice? bestVoiceForLocale(String localePrefix,
      [String? savedVoiceId]) {
    if (_availableVoices.isEmpty) return null;

    // 1. Saved voice (by ID)
    if (savedVoiceId != null) {
      final saved =
          _availableVoices.where((v) => v.id == savedVoiceId).firstOrNull;
      if (saved != null) return saved;
    }

    final prefix = localePrefix.toLowerCase();

    // 2. Neural voice for locale prefix
    final neural = _availableVoices.where((v) {
      final matchesLocale = v.locale.toLowerCase().startsWith(prefix);
      return matchesLocale && _hasPremiumKeyword(v.name);
    }).firstOrNull;
    if (neural != null) return neural;

    // 3. Google voice for locale prefix
    final google = _availableVoices.where((v) {
      final matchesLocale = v.locale.toLowerCase().startsWith(prefix);
      final name = v.name.toLowerCase();
      return matchesLocale &&
          name.contains('google') &&
          !_hasBadKeyword(v.name);
    }).firstOrNull;
    if (google != null) return google;

    // 4. Locale prefix match
    final localeMatch = _availableVoices
        .where((v) =>
            v.locale.toLowerCase().startsWith(prefix) &&
            !_hasBadKeyword(v.name))
        .firstOrNull;
    if (localeMatch != null) return localeMatch;

    // 5. Any English voice
    final english = _availableVoices
        .where((v) =>
            v.locale.toLowerCase().startsWith('en') && !_hasBadKeyword(v.name))
        .firstOrNull;
    if (english != null) return english;

    // 6. First available
    return _availableVoices.firstOrNull;
  }

  Future<bool> setVoice(NarrationVoice voice) async {
    try {
      return await _engine.setVoice(voice);
    } catch (_) {
      return false;
    }
  }

  Future<bool> setVoiceFromSaved(NarrationVoice saved) async {
    return setVoice(saved);
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  VoiceQuality _detectQuality(String name) {
    final n = name.toLowerCase();

    // Neural / # voices -> premium (5★)
    if (n.contains('google') && (n.contains('neural') || n.contains('#'))) {
      return VoiceQuality.premium;
    }
    if (n.contains('natural') ||
        n.contains('enhanced') ||
        n.contains('premium')) {
      return VoiceQuality.premium;
    }
    // Standard Google -> excellent (4★)
    if (n.contains('google')) {
      return VoiceQuality.excellent;
    }
    if (n.contains('pico') || n.contains('espeak') || n.contains('default')) {
      return VoiceQuality.basic;
    }
    // OEM (Samsung, Huawei, etc.) -> good (3★)
    if (n.contains('samsung') ||
        n.contains('huawei') ||
        n.contains('oem') ||
        n.contains('device')) {
      return VoiceQuality.good;
    }
    // Others -> standard (2★)
    return VoiceQuality.standard;
  }

  Set<NarrationMode> _detectRecommendedModes(VoiceQuality quality) {
    switch (quality) {
      case VoiceQuality.premium:
        return {
          NarrationMode.reading,
          NarrationMode.devotional,
          NarrationMode.prayer,
          NarrationMode.meditation,
          NarrationMode.sermon,
          NarrationMode.children,
        };
      case VoiceQuality.excellent:
        return {
          NarrationMode.reading,
          NarrationMode.devotional,
          NarrationMode.sermon,
        };
      case VoiceQuality.good:
        return {
          NarrationMode.reading,
          NarrationMode.children,
        };
      case VoiceQuality.standard:
      case VoiceQuality.basic:
        return {};
    }
  }

  int _compareVoices(NarrationVoice a, NarrationVoice b) {
    final quality = a.quality.sortOrder.compareTo(b.quality.sortOrder);
    if (quality != 0) return quality;

    final voiceScore = _voiceScore(b).compareTo(_voiceScore(a));
    if (voiceScore != 0) return voiceScore;

    return a.name.compareTo(b.name);
  }

  int _voiceScore(NarrationVoice voice) {
    var score = 0;
    final name = voice.name.toLowerCase();
    for (final keyword in _premiumKeywords) {
      if (name.contains(keyword)) score += 2;
    }
    for (final keyword in _badKeywords) {
      if (name.contains(keyword)) score -= 3;
    }
    return score;
  }

  bool _hasPremiumKeyword(String name) {
    final lower = name.toLowerCase();
    return _premiumKeywords.any(lower.contains);
  }

  bool _hasBadKeyword(String name) {
    final lower = name.toLowerCase();
    return _badKeywords.any(lower.contains);
  }
}
