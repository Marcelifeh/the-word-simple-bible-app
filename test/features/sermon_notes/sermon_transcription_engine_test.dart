import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/sermon_notes/services/sermon_transcription_engine.dart';

void main() {
  test('progress fraction is bounded and handles unknown duration', () {
    expect(
      const SermonTranscriptionProgress(
        status: SermonTranscriptionStatus.transcribing,
      ).fraction,
      isNull,
    );
    expect(
      const SermonTranscriptionProgress(
        status: SermonTranscriptionStatus.transcribing,
        processed: Duration(seconds: 15),
        total: Duration(seconds: 30),
      ).fraction,
      0.5,
    );
    expect(
      const SermonTranscriptionProgress(
        status: SermonTranscriptionStatus.transcribing,
        processed: Duration(seconds: 40),
        total: Duration(seconds: 30),
      ).fraction,
      1.0,
    );
  });

  test('offline engine never silently uses cloud when uninstalled', () async {
    const engine = PendingOfflineWhisperEngine();
    expect(engine.isOnDevice, isTrue);
    expect(engine.supportsLive, isFalse);
    expect(await engine.isReady(), isFalse);
    await expectLater(
      engine.transcribeRecording(audioPath: 'sermon.m4a', onProgress: (_) {}),
      throwsA(isA<SermonTranscriptionUnavailable>()),
    );
  });
}
