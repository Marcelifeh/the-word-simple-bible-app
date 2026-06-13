import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/narration_capabilities.dart';
import '../models/narration_voice.dart';
import 'narration_engine.dart';

class FlutterTtsEngine implements NarrationEngine {
  final FlutterTts _tts;

  FlutterTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  @override
  NarrationCapabilities get capabilities => NarrationCapabilities.flutterTts;

  @override
  Future<List<NarrationVoice>> loadVoices() async {
    try {
      final voices = await _tts.getVoices;
      final List<NarrationVoice> result = [];
      if (voices != null) {
        for (final voice in voices) {
          final locale = voice['locale'] as String?;
          final name = voice['name'] as String?;
          if (locale == null || name == null) continue;

          result.add(
            NarrationVoice(
              id: '$name-$locale',
              name: name,
              locale: locale,
              provider: _detectProvider(name),
              isInstalled: true,
            ),
          );
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  VoiceProvider _detectProvider(String name) {
    final n = name.toLowerCase();
    if (n.contains('google') || n.contains('neural')) {
      return VoiceProvider.cloud;
    }
    return VoiceProvider.device;
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  @override
  Future<bool> setVoice(NarrationVoice voice) async {
    try {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      await _tts.setLanguage(voice.locale);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void setCompletionHandler(void Function() onComplete) {
    _tts.setCompletionHandler(onComplete);
  }

  @override
  void setCancelHandler(void Function() onCancel) {
    _tts.setCancelHandler(onCancel);
  }

  @override
  void setErrorHandler(void Function(dynamic error) onError) {
    _tts.setErrorHandler(onError);
  }

  @override
  void setProgressHandler(
      void Function(String text, int start, int end, String word) onProgress) {
    _tts.setProgressHandler(onProgress);
  }

  @override
  Future<File?> synthesizeToFile(String text) async {
    return null;
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
  }
}
