import 'narration_state.dart';

class NarrationSyncState {
  const NarrationSyncState({
    required this.sessionId,
    required this.segmentId,
    required this.currentIndex,
    required this.progress,
    required this.status,
    required this.autoScroll,
    required this.updatedAt,
  });

  final String? sessionId;
  final String? segmentId;
  final int currentIndex;
  final double progress;
  final NarrationStatus status;
  final bool autoScroll;
  final DateTime updatedAt;

  static NarrationSyncState idle({bool autoScroll = true}) {
    return NarrationSyncState(
      sessionId: null,
      segmentId: null,
      currentIndex: 0,
      progress: 0,
      status: NarrationStatus.idle,
      autoScroll: autoScroll,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  NarrationSyncState copyWith({
    String? sessionId,
    String? segmentId,
    int? currentIndex,
    double? progress,
    NarrationStatus? status,
    bool? autoScroll,
    DateTime? updatedAt,
  }) {
    return NarrationSyncState(
      sessionId: sessionId ?? this.sessionId,
      segmentId: segmentId ?? this.segmentId,
      currentIndex: currentIndex ?? this.currentIndex,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      autoScroll: autoScroll ?? this.autoScroll,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}