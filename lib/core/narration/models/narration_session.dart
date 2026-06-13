import 'narration_segment.dart';
import 'narration_state.dart';

class NarrationSession {
  final String id;
  final NarrationSourceType sourceType;
  final NarrationMode mode;
  final List<NarrationSegment> segments;
  final int currentIndex;
  final NarrationStatus status;
  final double progress;

  const NarrationSession({
    required this.id,
    required this.sourceType,
    required this.mode,
    required this.segments,
    this.currentIndex = 0,
    this.status = NarrationStatus.idle,
    this.progress = 0.0,
  });

  NarrationSegment? get currentSegment {
    if (currentIndex < 0 || currentIndex >= segments.length) {
      return null;
    }
    return segments[currentIndex];
  }

  NarrationSession copyWith({
    String? id,
    NarrationSourceType? sourceType,
    NarrationMode? mode,
    List<NarrationSegment>? segments,
    int? currentIndex,
    NarrationStatus? status,
    double? progress,
  }) {
    return NarrationSession(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      mode: mode ?? this.mode,
      segments: segments ?? this.segments,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
