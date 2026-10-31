import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sermon_transcription_engine.dart';
import '../model/sermon_note.dart';
import 'whisper_model_installer.dart';

/// Explicit Android-only adapter. Never contacts the sermon API.
/// Readiness requires the native library and the pinned, verified model.
class AndroidWhisperTranscriptionEngine
    implements SermonTranscriptionEngine, WhisperModelBackend {
  AndroidWhisperTranscriptionEngine({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('the_word/offline_whisper');
  final MethodChannel _channel;
  @override
  String get engineId => 'whisper_cpp_android';
  @override
  bool get isOnDevice => true;
  @override
  bool get supportsLive => false;
  @override
  Future<bool> isReady() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('isReady') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<String?> modelStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMethod<String>('modelStatus');
    } on PlatformException catch (e) {
      return e.message;
    } on MissingPluginException {
      return null;
    }
  }

  /// Model lifecycle is independent of inference readiness. A model alone is not enough.
  Future<Map<String, dynamic>?> modelInfo() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('modelInfo');
      return info == null ? null : Map<String, dynamic>.from(info);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> hasVerifiedModel() async =>
      (await modelInfo())?['installed'] == true;

  /// Native code independently checks the application's pinned digest.
  @override
  Future<void> installVerifiedModel(String privateCachePath) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const SermonTranscriptionUnavailable(
          'Model import is Android-only.');
    }
    try {
      await _channel.invokeMethod<Object>('importModel', {
        'uri': Uri.file(privateCachePath).toString(),
      });
    } on PlatformException catch (error) {
      if (error.code == 'MODEL_STORAGE_FAILED') {
        throw const WhisperModelStorageException();
      }
      rethrow;
    }
  }

  @override
  Future<bool> deleteModel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return await _channel.invokeMethod<bool>('deleteModel') ?? false;
  }

  @override
  Future<SermonTranscriptionOutput> transcribeRecording({
    required String audioPath,
    required void Function(SermonTranscriptionProgress) onProgress,
  }) async {
    if (!await isReady()) {
      throw const SermonTranscriptionUnavailable(
        'Offline transcription engine is not installed yet. Recording remains on this device.',
      );
    }
    onProgress(const SermonTranscriptionProgress(
        status: SermonTranscriptionStatus.preparing));
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('transcribe', {'path': audioPath});
      if (raw == null) {
        throw const SermonTranscriptionUnavailable(
            'Native transcription returned no result.');
      }
      final segments = <SermonTranscriptSegment>[];
      for (final item in (raw['segments'] as List? ?? const [])) {
        if (item is! Map) continue;
        final start = (item['startMs'] as num?)?.toInt() ?? 0;
        final end = (item['endMs'] as num?)?.toInt() ?? start;
        segments.add(SermonTranscriptSegment(
            start: Duration(milliseconds: start),
            end: Duration(milliseconds: end),
            text: (item['text'] ?? '').toString()));
      }
      return SermonTranscriptionOutput(
          text: (raw['text'] ?? '').toString(),
          language: raw['language']?.toString(),
          segments: segments);
    } on PlatformException catch (e) {
      throw SermonTranscriptionUnavailable(
          e.message ?? 'Native offline transcription failed.');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } on MissingPluginException {/* Android engine not registered. */}
  }

  @override
  Stream<SermonTranscriptionOutput> transcribeLive(
          Stream<List<int>> pcm16Mono16kHz) =>
      Stream<SermonTranscriptionOutput>.error(
          const SermonTranscriptionUnavailable(
              'Live transcription will be supported in a future release.'));
}
