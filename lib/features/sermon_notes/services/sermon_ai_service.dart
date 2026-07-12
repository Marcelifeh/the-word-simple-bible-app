import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/utils/env.dart';
import '../model/sermon_note.dart';
import '../model/sermon_outline.dart';
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

class SermonApiException implements Exception {
  const SermonApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SermonCloudUnavailableException extends SermonApiException {
  const SermonCloudUnavailableException(super.message);
}

class SermonAiService {
  SermonAiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _requestTimeout = Duration(seconds: 90);

  Future<SermonTranscriptionResult> transcribeAudio(String audioPath) async {
    final uri = Env.apiUri('/sermon/transcribe');
    late final http.StreamedResponse response;
    late final String body;

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await sermonAudioMultipartFile(audioPath));
      response = await request.send();
      body = await response.stream.bytesToString();
    } catch (e) {
      throw const SermonCloudUnavailableException(
        'Cloud services are temporarily unavailable. '
        'Your notes and recordings remain saved on this device.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 503) {
        throw const SermonCloudUnavailableException(
          'Cloud transcription is not enabled on the current server plan. '
          'Your recording remains saved safely on this device.',
        );
      }
      throw SermonApiException(
        _errorDetail(
          body,
          fallbackMessage:
              'AI processing is temporarily unavailable. Please try again later.',
        ),
      );
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
    final response = await _client
        .post(
          Env.apiUri('/sermon/summary'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'transcript': transcript}),
        )
        .timeout(_requestTimeout);

    _throwIfFailed(
      response,
      fallbackMessage:
          'AI processing is temporarily unavailable. Please try again later.',
    );

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

  Future<SermonOutline> generateOutline({
    required String transcript,
    SermonInsight? insight,
  }) async {
    final response = await _client
        .post(
          Env.apiUri('/sermon/outline'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'transcript': transcript,
            'insight': insight?.toJson(),
          }),
        )
        .timeout(_requestTimeout);

    _throwIfFailed(
      response,
      fallbackMessage:
          'AI processing is temporarily unavailable. Please try again later.',
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['outline'] is! Map) {
      throw Exception('Invalid sermon outline response.');
    }

    return SermonOutline.fromJson(
      (decoded['outline'] as Map).cast<String, dynamic>(),
    );
  }

  void _throwIfFailed(
    http.Response response, {
    required String fallbackMessage,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final message = _errorDetail(
      response.body,
      fallbackMessage: fallbackMessage,
    );

    if (response.statusCode == 503) {
      throw SermonCloudUnavailableException(
        message.isEmpty
            ? 'Cloud services are temporarily unavailable. '
                'Your notes and recordings remain saved on this device.'
            : message,
      );
    }

    throw SermonApiException(message);
  }

  String _errorDetail(
    String body, {
    required String fallbackMessage,
  }) {
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['detail'] != null) {
          return decoded['detail'].toString();
        }
      } catch (_) {
        // Use the generic message below.
      }
    }
    return fallbackMessage;
  }

  void dispose() {
    _client.close();
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
