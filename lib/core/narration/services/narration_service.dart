import 'dart:io';

import '../engines/flutter_tts_engine.dart';
import '../engines/narration_engine.dart';
import '../models/narration_capabilities.dart';
import '../models/narration_preferences.dart';
import '../models/narration_voice.dart';
import 'narration_text_processor.dart';
import 'voice_service.dart';

class NarrationService {
  static const Duration _chunkPause = Duration(milliseconds: 900);

  final NarrationEngine _engine;
  late final VoiceService voiceService;
  void Function()? _onComplete;
  List<String> _activeChunks = const [];
  int _activeChunkIndex = 0;
  int _speakToken = 0;

  NarrationService([NarrationEngine? engine])
      : _engine = engine ?? FlutterTtsEngine() {
    voiceService = VoiceService(_engine);
    _engine.setCompletionHandler(_handleEngineCompletion);
  }

  NarrationCapabilities get capabilities => _engine.capabilities;

  List<NarrationVoice> get availableVoices => voiceService.getAvailableVoices();

  NarrationVoice? bestVoiceForLocale(String localePrefix,
      [String? savedVoiceId]) {
    return voiceService.bestVoiceForLocale(localePrefix, savedVoiceId);
  }

  Future<void> initialize() async {
    await voiceService.loadVoices();

    // Warm defaults — avoids the robotic 'flat' sound of standard TTS
    await _engine.setSpeechRate(0.36);
    await _engine.setPitch(1.04);
  }

  Future<void> applyPreferences(NarrationPreferences prefs) async {
    await _engine.setSpeechRate(prefs.speed);
    await _engine.setPitch(prefs.pitch);
    final voice = bestVoiceForLocale(
      prefs.savedVoice?.locale ?? prefs.languageCode,
      prefs.savedVoice?.id,
    );
    if (voice != null) {
      await voiceService.setVoice(voice);
    }
  }

  Future<void> speak(String text) async {
    final chunks = NarrationTextProcessor.splitIntoNaturalChunks(text);
    final fallback = text.trim();
    _speakToken++;
    _activeChunks = chunks.isEmpty && fallback.isNotEmpty ? [fallback] : chunks;
    _activeChunkIndex = 0;

    if (_activeChunks.isEmpty) {
      _onComplete?.call();
      return;
    }

    await _engine.speak(_activeChunks[_activeChunkIndex]);
  }

  Future<void> stop() async {
    _speakToken++;
    _activeChunks = const [];
    _activeChunkIndex = 0;
    await _engine.stop();
  }

  Future<void> pause() async {
    await _engine.pause();
  }

  Future<File?> synthesizeToFile(String text) {
    return _engine.synthesizeToFile(text);
  }

  Future<bool> selectVoiceById(String voiceId) async {
    final voice = availableVoices
        .where((candidate) => candidate.id == voiceId)
        .firstOrNull;
    if (voice == null) {
      return false;
    }
    return voiceService.setVoice(voice);
  }

  void setCompletionHandler(void Function() onComplete) {
    _onComplete = onComplete;
  }

  void setCancelHandler(void Function() onCancel) {
    _engine.setCancelHandler(onCancel);
  }

  void setErrorHandler(void Function(dynamic) onError) {
    _engine.setErrorHandler(onError);
  }

  void setProgressHandler(
      void Function(String text, int start, int end, String word) onProgress) {
    _engine.setProgressHandler(onProgress);
  }

  Future<void> dispose() async {
    _speakToken++;
    _activeChunks = const [];
    await _engine.dispose();
  }

  Future<void> _handleEngineCompletion() async {
    final token = _speakToken;
    final nextIndex = _activeChunkIndex + 1;

    if (_activeChunks.isNotEmpty && nextIndex < _activeChunks.length) {
      _activeChunkIndex = nextIndex;
      await Future.delayed(_chunkPause);
      if (token == _speakToken && _activeChunks.isNotEmpty) {
        await _engine.speak(_activeChunks[_activeChunkIndex]);
      }
      return;
    }

    _activeChunks = const [];
    _activeChunkIndex = 0;
    _onComplete?.call();
  }
}
