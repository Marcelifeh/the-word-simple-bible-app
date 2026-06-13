/// Describes what a NarrationEngine is capable of.
/// Each engine implementation returns its own capabilities instance.
class NarrationCapabilities {
  const NarrationCapabilities({
    required this.supportsPause,
    required this.supportsPitch,
    required this.supportsProgress,
    required this.supportsVoiceSelection,
    required this.supportsOffline,
    required this.supportsBackgroundPlayback,
    required this.supportsSynthesizeToFile,
  });

  /// Can speech be paused mid-utterance and resumed?
  final bool supportsPause;

  /// Can pitch be adjusted programmatically?
  final bool supportsPitch;

  /// Does the engine fire word-level progress callbacks?
  final bool supportsProgress;

  /// Can the user select from multiple voices?
  final bool supportsVoiceSelection;

  /// Does the engine work without an internet connection?
  final bool supportsOffline;

  /// Can speech continue playing when the app is backgrounded / screen is locked?
  final bool supportsBackgroundPlayback;

  /// Can the engine save synthesized audio to a local file?
  /// Unlocks sleep timer, rewind, and downloadable narration.
  final bool supportsSynthesizeToFile;

  // ── Preset capability profiles ──────────────────────────────────────────────

  static const flutterTts = NarrationCapabilities(
    supportsPause: true,
    supportsPitch: true,
    supportsProgress: true,
    supportsVoiceSelection: true,
    supportsOffline: true,
    supportsBackgroundPlayback: false,
    supportsSynthesizeToFile: false,
  );

  static const piper = NarrationCapabilities(
    supportsPause: true,
    supportsPitch: true,
    supportsProgress: false,
    supportsVoiceSelection: true,
    supportsOffline: true,
    supportsBackgroundPlayback: true,
    supportsSynthesizeToFile: true,
  );

  static const azure = NarrationCapabilities(
    supportsPause: true,
    supportsPitch: true,
    supportsProgress: true,
    supportsVoiceSelection: true,
    supportsOffline: false,
    supportsBackgroundPlayback: true,
    supportsSynthesizeToFile: true,
  );
}