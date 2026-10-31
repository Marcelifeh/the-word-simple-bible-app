import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/sermon_notes/model/sermon_note.dart';
import 'package:simple_bible_app/features/sermon_notes/services/sermon_recording_transcription_coordinator.dart';
import 'package:simple_bible_app/features/sermon_notes/services/sermon_transcription_engine.dart';

class FakeOfflineEngine implements SermonTranscriptionEngine {
  final paths = <String>[];
  @override String get engineId => 'test';
  @override bool get isOnDevice => true;
  @override bool get supportsLive => false;
  @override Future<bool> isReady() async => true;
  @override Future<void> cancel() async {}
  @override Stream<SermonTranscriptionOutput> transcribeLive(Stream<List<int>> pcm16Mono16kHz) => const Stream.empty();
  @override
  Future<SermonTranscriptionOutput> transcribeRecording({
    required String audioPath,
    required void Function(SermonTranscriptionProgress) onProgress,
  }) async {
    paths.add(audioPath);
    return SermonTranscriptionOutput(text: audioPath, segments: [
      const SermonTranscriptSegment(start: Duration(seconds: 1), end: Duration(seconds: 2), text: 'Amen'),
    ]);
  }
}

void main() {
  test('processes every playable clip in sequence and offsets timestamps', () async {
    final engine = FakeOfflineEngine();
    final coordinator = SermonRecordingTranscriptionCoordinator(engine);
    SermonRecordingClip clip(String path, int sequence, SermonRecordingClipStatus status) =>
      SermonRecordingClip(id: path, filePath: path, createdAtUtc: DateTime.utc(2026),
        durationMs: 10000, sequence: sequence, status: status);
    final result = await coordinator.transcribeClips(clips: [
      clip('second.m4a', 2, SermonRecordingClipStatus.completed),
      clip('incomplete.m4a', 3, SermonRecordingClipStatus.interrupted),
      clip('first.m4a', 1, SermonRecordingClipStatus.completed),
    ], onProgress: (_) {});
    expect(engine.paths, ['first.m4a', 'second.m4a']);
    expect(result.text, 'first.m4a\n\nsecond.m4a');
    expect(result.segments.map((s) => s.start.inSeconds), [1, 11]);
  });
  test('never falls back to a cloud engine', () async {
    final coordinator = SermonRecordingTranscriptionCoordinator(const PendingOfflineWhisperEngine());
    await expectLater(coordinator.transcribeClips(clips: [], onProgress: (_) {}),
      throwsA(isA<SermonTranscriptionUnavailable>()));
  });
}
