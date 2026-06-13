import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SermonRecordingService {
  SermonRecordingService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String> start({required String sermonId}) async {
    final fileName =
        'sermon_${sermonId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = kIsWeb ? fileName : await _recordingPath(fileName);

    await _recorder.start(
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

  Future<String?> stop() => _recorder.stop();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<void> dispose() => _recorder.dispose();
}
