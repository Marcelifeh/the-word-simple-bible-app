enum DevotionalStage {
  scripture,
  understanding,
  deepInsight,
  keyTruth,
  reflection,
  prayer,
  journal,
  completed
}

class DevotionalAudioSession {
  final String devotionalId;
  final DevotionalStage currentStage;
  final bool ambientMode;

  const DevotionalAudioSession({
    required this.devotionalId,
    this.currentStage = DevotionalStage.scripture,
    this.ambientMode = false,
  });

  DevotionalAudioSession copyWith({
    String? devotionalId,
    DevotionalStage? currentStage,
    bool? ambientMode,
  }) {
    return DevotionalAudioSession(
      devotionalId: devotionalId ?? this.devotionalId,
      currentStage: currentStage ?? this.currentStage,
      ambientMode: ambientMode ?? this.ambientMode,
    );
  }
}
