import 'dart:io';
import '../models/narration_capabilities.dart';
import '../models/narration_voice.dart';
import 'narration_engine.dart';

/// Stub implementation of the Piper local neural TTS engine.
/// Placeholder for Phase 1.7.
class PiperEngine implements NarrationEngine {
  @override
  NarrationCapabilities get capabilities => NarrationCapabilities.piper;

  @override
  Future<List<NarrationVoice>> loadVoices() async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<void> speak(String text) async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<void> stop() async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<void> pause() async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<void> setPitch(double pitch) async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<bool> setVoice(NarrationVoice voice) async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  void setCompletionHandler(void Function() onComplete) {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  void setCancelHandler(void Function() onCancel) {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  void setErrorHandler(void Function(dynamic error) onError) {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  void setProgressHandler(void Function(String text, int start, int end, String word) onProgress) {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<File?> synthesizeToFile(String text) async {
    throw UnimplementedError('Piper TTS is not implemented yet.');
  }

  @override
  Future<void> dispose() async {
    // No-op
  }
}
