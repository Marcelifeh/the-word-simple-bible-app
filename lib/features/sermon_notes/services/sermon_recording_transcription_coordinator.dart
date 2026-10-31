import '../model/sermon_note.dart';
import 'sermon_transcription_engine.dart';

/// Runs recorded clips in their stored order, without uploading audio.
/// The caller must persist the returned output only after completion.
class SermonRecordingTranscriptionCoordinator {
  SermonRecordingTranscriptionCoordinator(this.engine);

  final SermonTranscriptionEngine engine;
  bool _cancelled = false;

  Future<SermonTranscriptionOutput> transcribeClips({
    required List<SermonRecordingClip> clips,
    required void Function(SermonTranscriptionProgress) onProgress,
  }) async {
    _cancelled = false;
    if (!engine.isOnDevice) {
      throw const SermonTranscriptionUnavailable(
        'Offline transcription requires an on-device engine.',
      );
    }
    if (!await engine.isReady()) {
      throw const SermonTranscriptionUnavailable(
        'Offline speech model is not installed or native engine is unavailable.',
      );
    }
    final ordered = clips.where((clip) => clip.isPlayable).toList()
      ..sort((a, b) {
        final sequence = a.sequence.compareTo(b.sequence);
        return sequence != 0 ? sequence : a.createdAtUtc.compareTo(b.createdAtUtc);
      });
    if (ordered.isEmpty) {
      throw const SermonTranscriptionUnavailable('No completed sermon recordings found.');
    }
    final total = Duration(milliseconds: ordered.fold<int>(
      0, (sum, clip) => sum + clip.durationMs,
    ));
    var elapsed = Duration.zero;
    final texts = <String>[];
    final segments = <SermonTranscriptSegment>[];
    String? language;
    for (var i = 0; i < ordered.length; i++) {
      if (_cancelled) throw const SermonTranscriptionCancelled();
      final clip = ordered[i];
      onProgress(SermonTranscriptionProgress(
        status: SermonTranscriptionStatus.preparing,
        processed: elapsed,
        total: total,
        message: 'Preparing recording ${i + 1} of ${ordered.length}',
      ));
      final output = await engine.transcribeRecording(
        audioPath: clip.filePath,
        onProgress: (progress) {
          if (_cancelled) return;
          final withinClip = progress.processed > clip.duration
              ? clip.duration
              : progress.processed;
          onProgress(SermonTranscriptionProgress(
            status: progress.status,
            processed: elapsed + withinClip,
            total: total,
            message: 'Recording ${i + 1} of ${ordered.length}: ${progress.message ?? ''}',
          ));
        },
      );
      if (_cancelled) throw const SermonTranscriptionCancelled();
      if (output.text.trim().isNotEmpty) texts.add(output.text.trim());
      language ??= output.language;
      for (final segment in output.segments) {
        segments.add(SermonTranscriptSegment(
          start: elapsed + segment.start,
          end: elapsed + segment.end,
          text: segment.text,
        ));
      }
      elapsed += clip.duration;
    }
    onProgress(SermonTranscriptionProgress(
      status: SermonTranscriptionStatus.completed,
      processed: total,
      total: total,
    ));
    return SermonTranscriptionOutput(
      text: texts.join('\n\n'), segments: segments, language: language,
    );
  }

  Future<void> cancel() async {
    _cancelled = true;
    await engine.cancel();
  }
}

class SermonTranscriptionCancelled implements Exception {
  const SermonTranscriptionCancelled();
  @override
  String toString() => 'Sermon transcription cancelled; existing notes were not changed.';
}
