import 'dart:io';
import '../models/narration_capabilities.dart';
import '../models/narration_voice.dart';

/// Abstract class representing a Text-to-Speech (TTS) or audio narration engine.
/// Allows plug-and-play switching between different speech synthesis technologies.
abstract class NarrationEngine {
  /// Check what features this engine supports.
  NarrationCapabilities get capabilities;

  /// Load available voices for this engine.
  Future<List<NarrationVoice>> loadVoices();

  /// Start speaking the provided text.
  Future<void> speak(String text);

  /// Stop the current speech output.
  Future<void> stop();

  /// Pause the current speech output if supported.
  Future<void> pause();

  /// Set the speech speed/rate.
  Future<void> setSpeechRate(double rate);

  /// Set the speech pitch.
  Future<void> setPitch(double pitch);

  /// Select a voice.
  Future<bool> setVoice(NarrationVoice voice);

  /// Set callback for when speech finishes.
  void setCompletionHandler(void Function() onComplete);

  /// Set callback for when speech is cancelled.
  void setCancelHandler(void Function() onCancel);

  /// Set callback for when speech encounters an error.
  void setErrorHandler(void Function(dynamic error) onError);

  /// Set callback for word/character level progress.
  void setProgressHandler(void Function(String text, int start, int end, String word) onProgress);

  /// Synthesize speech to a local audio file if supported.
  /// Returns null if not supported or failed.
  Future<File?> synthesizeToFile(String text);

  /// Free up engine resources.
  Future<void> dispose();
}
