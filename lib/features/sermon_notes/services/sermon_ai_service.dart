import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/sermon_note.dart';
import 'sermon_audio_multipart_file.dart';

class SermonTranscriptionResult {
  const SermonTranscriptionResult({
    required this.transcript,
    this.language,
    this.duration,
    this.segments = const <SermonTranscriptSegment>[],
  });

  final String transcript;
  final String? language;
  final Duration? duration;
  final List<SermonTranscriptSegment> segments;
}

class SermonSummaryResult {
  const SermonSummaryResult({
    required this.summary,
    required this.insight,
  });

  final String summary;
  final SermonInsight insight;
}

class SermonAiService {
  const SermonAiService({
    required this.baseUrl,
  });

  final String baseUrl;

  Future<SermonTranscriptionResult> transcribeAudio(String audioPath) async {
    final uri = Uri.parse(_join('/sermon/transcribe'));
    late final http.StreamedResponse response;
    late final String body;

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await sermonAudioMultipartFile(audioPath));
      response = await request.send();
      body = await response.stream.bytesToString();
    } catch (e) {
      throw Exception(
        'Could not reach sermon transcription server at $uri. '
        'Start the backend on port 8000 or pass SERMON_API_URL. ($e)',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to transcribe sermon: $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) throw Exception('Invalid transcription response.');
    return SermonTranscriptionResult(
      transcript: (decoded['transcript'] ?? '').toString(),
      language: decoded['language']?.toString(),
      duration: _durationFromSeconds(decoded['duration']),
      segments: _segmentsFrom(decoded['segments']),
    );
  }

  Future<SermonSummaryResult> generateSummary(String transcript) async {
    final uri = Uri.parse(_join('/sermon/summary'));

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'transcript': transcript}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to summarize sermon: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid summary response.');
    }
    return SermonSummaryResult(
      summary: (decoded['summary'] ?? '').toString(),
      insight: SermonInsight(
        title: (decoded['title'] ?? '').toString(),
        mainTheme: (decoded['mainTheme'] ?? '').toString(),
        keyLessons: _stringList(decoded['keyLessons']),
        scripturesMentioned: _stringList(decoded['scripturesMentioned']),
        prayerPoints: _stringList(decoded['prayerPoints']),
        actionSteps: _stringList(decoded['actionSteps']),
        shortDevotional: (decoded['shortDevotional'] ?? '').toString(),
      ),
    );
  }

  String _join(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$root$path';
  }

  Duration? _durationFromSeconds(Object? value) {
    if (value is num) {
      return Duration(milliseconds: (value * 1000).round());
    }
    return null;
  }

  List<SermonTranscriptSegment> _segmentsFrom(Object? value) {
    if (value is! List) return const <SermonTranscriptSegment>[];
    return value
        .whereType<Map>()
        .map((item) {
          final map = item.cast<String, dynamic>();
          return SermonTranscriptSegment(
            start: _durationFromSeconds(map['start']) ?? Duration.zero,
            end: _durationFromSeconds(map['end']) ?? Duration.zero,
            text: (map['text'] ?? '').toString(),
          );
        })
        .where((segment) => segment.text.trim().isNotEmpty)
        .toList();
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
