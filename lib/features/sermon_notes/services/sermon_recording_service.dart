import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'sermon_audio_file_service.dart';

class SermonRecordingService {
  SermonRecordingService({AudioRecorder? recorder}) : _recorder = recorder;

  AudioRecorder? _recorder;
  AudioRecorder get _ensureRecorder => _recorder ??= AudioRecorder();
  final SermonAudioFileService _audioFileService =
      const SermonAudioFileService();

  Future<bool> hasPermission() => _ensureRecorder.hasPermission();

  Future<String> start({required String sermonId}) async {
    final fileName =
        'sermon_${sermonId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = kIsWeb ? fileName : await _recordingPath(fileName);

    await _ensureRecorder.start(
      const RecordConfig(
        bitRate: 96000,
        sampleRate: 44100,
      ),
      path: path,
    );

    return path;
  }

  Future<String> _recordingPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  Future<String?> stop() async => _recorder?.stop();

  Future<bool> isRecording() async => await _recorder?.isRecording() ?? false;

  Future<void> deleteFile(String path) async {
    if (kIsWeb) return;
    await _audioFileService.delete(path);
  }

  Future<void> dispose() async {
    final recorder = _recorder;
    _recorder = null;
    await recorder?.dispose();
  }
}
