import 'dart:io';
import '../models/narration_capabilities.dart';
import '../models/narration_voice.dart';
import 'narration_engine.dart';

/// Stub implementation of Azure Neural Cloud TTS engine.
/// Placeholder for Phase 1.8.
class AzureEngine implements NarrationEngine {
  @override
  NarrationCapabilities get capabilities => NarrationCapabilities.azure;

  @override
  Future<List<NarrationVoice>> loadVoices() async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<void> speak(String text) async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<void> stop() async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<void> pause() async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<void> setPitch(double pitch) async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<bool> setVoice(NarrationVoice voice) async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  void setCompletionHandler(void Function() onComplete) {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  void setCancelHandler(void Function() onCancel) {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  void setErrorHandler(void Function(dynamic error) onError) {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  void setProgressHandler(void Function(String text, int start, int end, String word) onProgress) {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<File?> synthesizeToFile(String text) async {
    throw UnimplementedError('Azure Neural TTS is not implemented yet.');
  }

  @override
  Future<void> dispose() async {
    // No-op
  }
}
