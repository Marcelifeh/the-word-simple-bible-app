import '../model/sermon_note.dart';

/// The capture mode is independent of the inference engine. The first release
/// uses [recorded]; [live] is reserved for a future streaming implementation.
enum SermonTranscriptionMode { recorded, live }

enum SermonTranscriptionStatus {
  unavailable,
  ready,
  preparing,
  transcribing,
  completed,
  cancelled,
  failed,
}

class SermonTranscriptionProgress {
  const SermonTranscriptionProgress({
    required this.status,
    this.processed = Duration.zero,
    this.total,
    this.message,
  });

  final SermonTranscriptionStatus status;
  final Duration processed;
  final Duration? total;
  final String? message;

  double? get fraction {
    final totalMs = total?.inMilliseconds;
    if (totalMs == null || totalMs <= 0) return null;
    return (processed.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }
}

class SermonTranscriptionOutput {
  const SermonTranscriptionOutput({
    required this.text,
    this.segments = const <SermonTranscriptSegment>[],
    this.language,
  });

  final String text;
  final List<SermonTranscriptSegment> segments;
  final String? language;
}

class SermonTranscriptionUnavailable implements Exception {
  const SermonTranscriptionUnavailable(this.reason);
  final String reason;

  @override
  String toString() => reason;
}

/// Platform-neutral contract for recorded audio and future streaming.
/// Implementations must not upload recordings unless explicitly selected by
/// the user; the offline implementation must perform all inference on-device.
abstract class SermonTranscriptionEngine {
  String get engineId;
  bool get isOnDevice;
  bool get supportsLive;

  Future<bool> isReady();

  Future<SermonTranscriptionOutput> transcribeRecording({
    required String audioPath,
    required void Function(SermonTranscriptionProgress) onProgress,
  });

  /// Reserved for a future live implementation. Do not call for phase A.
  Stream<SermonTranscriptionOutput> transcribeLive(
    Stream<List<int>> pcm16Mono16kHz,
  );

  Future<void> cancel();
}

/// Explicitly unavailable until the native Android whisper.cpp bridge and
/// model installer are implemented. Never silently fall back to cloud.
class PendingOfflineWhisperEngine implements SermonTranscriptionEngine {
  const PendingOfflineWhisperEngine();

  @override
  String get engineId => 'whisper_cpp_android';
  @override
  bool get isOnDevice => true;
  @override
  bool get supportsLive => false;
  @override
  Future<bool> isReady() async => false;

  @override
  Future<SermonTranscriptionOutput> transcribeRecording({
    required String audioPath,
    required void Function(SermonTranscriptionProgress) onProgress,
  }) async {
    throw const SermonTranscriptionUnavailable(
      'Offline transcription is not installed yet. Your recording is safe. '
      'A native whisper.cpp engine and local model are required.',
    );
  }

  @override
  Stream<SermonTranscriptionOutput> transcribeLive(
    Stream<List<int>> pcm16Mono16kHz,
  ) => Stream<SermonTranscriptionOutput>.error(
        const SermonTranscriptionUnavailable(
          'Live transcription is reserved for a future release.',
        ),
      );

  @override
  Future<void> cancel() async {}
}
