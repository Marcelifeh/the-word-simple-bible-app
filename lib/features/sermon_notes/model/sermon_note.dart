import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'sermon_outline.dart';

class LinkedScripture {
  final String rawText;
  final String matchText;
  final String bookId;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  const LinkedScripture({
    required this.rawText,
    required this.matchText,
    required this.bookId,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });

  String get displayTitle {
    if (startVerse != null && endVerse != null) {
      return '$matchText:$startVerse-$endVerse';
    } else if (startVerse != null) {
      return '$matchText:$startVerse';
    }
    return matchText;
  }
}

class SermonTimestampedNote {
  final Duration offset;
  final String text;
  final DateTime createdAt;

  SermonTimestampedNote({
    required this.offset,
    this.text = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'offsetMs': offset.inMilliseconds,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SermonTimestampedNote.fromJson(Map<String, dynamic> json) {
    final offsetMs = json['offsetMs'];
    return SermonTimestampedNote(
      offset: Duration(milliseconds: offsetMs is int ? offsetMs : 0),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SermonTranscriptSegment {
  final Duration start;
  final Duration end;
  final String text;

  const SermonTranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
        'startMs': start.inMilliseconds,
        'endMs': end.inMilliseconds,
        'text': text,
      };

  factory SermonTranscriptSegment.fromJson(Map<String, dynamic> json) {
    final startMs = json['startMs'];
    final endMs = json['endMs'];
    return SermonTranscriptSegment(
      start: Duration(milliseconds: startMs is int ? startMs : 0),
      end: Duration(milliseconds: endMs is int ? endMs : 0),
      text: json['text'] as String? ?? '',
    );
  }
}

class SermonInsight {
  final String title;
  final String mainTheme;
  final List<String> keyLessons;
  final List<String> scripturesMentioned;
  final List<String> prayerPoints;
  final List<String> actionSteps;
  final String shortDevotional;

  const SermonInsight({
    this.title = '',
    this.mainTheme = '',
    this.keyLessons = const <String>[],
    this.scripturesMentioned = const <String>[],
    this.prayerPoints = const <String>[],
    this.actionSteps = const <String>[],
    this.shortDevotional = '',
  });

  bool get hasContent =>
      title.trim().isNotEmpty ||
      mainTheme.trim().isNotEmpty ||
      keyLessons.isNotEmpty ||
      scripturesMentioned.isNotEmpty ||
      prayerPoints.isNotEmpty ||
      actionSteps.isNotEmpty ||
      shortDevotional.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'title': title,
        'mainTheme': mainTheme,
        'keyLessons': keyLessons,
        'scripturesMentioned': scripturesMentioned,
        'prayerPoints': prayerPoints,
        'actionSteps': actionSteps,
        'shortDevotional': shortDevotional,
      };

  factory SermonInsight.fromJson(Map<String, dynamic> json) {
    return SermonInsight(
      title: json['title'] as String? ?? '',
      mainTheme: json['mainTheme'] as String? ?? '',
      keyLessons: _stringList(json['keyLessons']),
      scripturesMentioned: _stringList(json['scripturesMentioned']),
      prayerPoints: _stringList(json['prayerPoints']),
      actionSteps: _stringList(json['actionSteps']),
      shortDevotional: json['shortDevotional'] as String? ?? '',
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class SermonNote {
  final String id;
  String title;
  String preacher;
  String content;
  TextAlign textAlign;
  String? audioPath;
  Duration? audioDuration;
  int? audioSizeBytes;
  String? audioMimeType;
  DateTime? recordedAt;
  String? transcript;
  String? summary;
  SermonInsight? insight;
  SermonOutline? outline;
  List<SermonTranscriptSegment> transcriptSegments;
  List<SermonTimestampedNote> timestampedNotes;
  DateTime date;
  DateTime lastModified;

  SermonNote({
    String? id,
    this.title = '',
    this.preacher = '',
    this.content = '',
    this.textAlign = TextAlign.left,
    this.audioPath,
    this.audioDuration,
    this.audioSizeBytes,
    this.audioMimeType,
    this.recordedAt,
    this.transcript,
    this.summary,
    this.insight,
    this.outline,
    List<SermonTranscriptSegment>? transcriptSegments,
    List<SermonTimestampedNote>? timestampedNotes,
    DateTime? date,
    DateTime? lastModified,
  })  : id = id ?? const Uuid().v4(),
        transcriptSegments = transcriptSegments ?? <SermonTranscriptSegment>[],
        timestampedNotes = timestampedNotes ?? <SermonTimestampedNote>[],
        date = date ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'preacher': preacher,
        'content': content,
        'textAlign': textAlign.name,
        'audioPath': audioPath,
        'audioDurationMs': audioDuration?.inMilliseconds,
        'audioSizeBytes': audioSizeBytes,
        'audioMimeType': audioMimeType,
        'recordedAt': recordedAt?.toIso8601String(),
        'transcript': transcript,
        'summary': summary,
        'insight': insight?.toJson(),
        'outline': outline?.toJson(),
        'transcriptSegments':
            transcriptSegments.map((segment) => segment.toJson()).toList(),
        'timestampedNotes':
            timestampedNotes.map((note) => note.toJson()).toList(),
        'date': date.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
      };

  SermonNote copyWith({
    String? title,
    String? preacher,
    String? content,
    TextAlign? textAlign,
    String? audioPath,
    Duration? audioDuration,
    int? audioSizeBytes,
    String? audioMimeType,
    DateTime? recordedAt,
    String? transcript,
    String? summary,
    SermonInsight? insight,
    SermonOutline? outline,
    bool clearSummary = false,
    bool clearInsight = false,
    bool clearOutline = false,
    List<SermonTranscriptSegment>? transcriptSegments,
    List<SermonTimestampedNote>? timestampedNotes,
    DateTime? date,
    DateTime? lastModified,
  }) {
    return SermonNote(
      id: id,
      title: title ?? this.title,
      preacher: preacher ?? this.preacher,
      content: content ?? this.content,
      textAlign: textAlign ?? _safeTextAlign(this.textAlign),
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      audioSizeBytes: audioSizeBytes ?? this.audioSizeBytes,
      audioMimeType: audioMimeType ?? this.audioMimeType,
      recordedAt: recordedAt ?? this.recordedAt,
      transcript: transcript ?? this.transcript,
      summary: clearSummary ? null : summary ?? this.summary,
      insight: clearInsight ? null : insight ?? this.insight,
      outline: clearOutline ? null : outline ?? this.outline,
      transcriptSegments: transcriptSegments ??
          List<SermonTranscriptSegment>.from(this.transcriptSegments),
      timestampedNotes: timestampedNotes ??
          List<SermonTimestampedNote>.from(this.timestampedNotes),
      date: date ?? this.date,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  factory SermonNote.fromJson(Map<String, dynamic> json) {
    final rawTimestampedNotes = json['timestampedNotes'];
    final rawTranscriptSegments = json['transcriptSegments'];
    final rawInsight = json['insight'];
    final rawOutline = json['outline'];
    final audioDurationMs = json['audioDurationMs'];
    return SermonNote(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      preacher: json['preacher'] as String? ?? '',
      content: json['content'] as String? ?? '',
      textAlign: _textAlignFromJson(json['textAlign']),
      audioPath: json['audioPath'] as String?,
      audioDuration: audioDurationMs is int
          ? Duration(milliseconds: audioDurationMs)
          : null,
      audioSizeBytes: json['audioSizeBytes'] as int?,
      audioMimeType: json['audioMimeType'] as String?,
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? ''),
      transcript: json['transcript'] as String?,
      summary: json['summary'] as String?,
      insight: rawInsight is Map
          ? SermonInsight.fromJson(rawInsight.cast<String, dynamic>())
          : null,
      outline: rawOutline is Map
          ? SermonOutline.fromJson(rawOutline.cast<String, dynamic>())
          : null,
      transcriptSegments: rawTranscriptSegments is List
          ? rawTranscriptSegments
              .whereType<Map>()
              .map(
                (item) => SermonTranscriptSegment.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList()
          : <SermonTranscriptSegment>[],
      timestampedNotes: rawTimestampedNotes is List
          ? rawTimestampedNotes
              .whereType<Map>()
              .map(
                (item) => SermonTimestampedNote.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList()
          : <SermonTimestampedNote>[],
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

TextAlign _safeTextAlign(Object? value) {
  return value is TextAlign ? value : TextAlign.left;
}

TextAlign _textAlignFromJson(Object? value) {
  final name = value as String? ?? 'left';
  return TextAlign.values.firstWhere(
    (align) => align.name == name,
    orElse: () => TextAlign.left,
  );
}
