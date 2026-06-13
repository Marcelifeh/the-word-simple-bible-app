enum NarrationEventType {
  started,
  completed,
  paused,
  resumed,
  failed,
  segmentChanged,
  queueFinished,
  voiceMissing,
  voiceSelected,
  modeChanged,
  autoScrollEnabled,
  autoScrollDisabled,
}

class NarrationEvent {
  const NarrationEvent({
    required this.type,
    this.sessionId,
    this.segmentId,
    this.message,
  });

  final NarrationEventType type;
  final String? sessionId;
  final String? segmentId;
  final String? message;
}