import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'sermon_outline.dart';

// ── Recording clip status ─────────────────────────────────────────────────────

/// Represents the lifecycle state of a [SermonRecordingClip].
enum SermonRecordingClipStatus {
  /// Recorder is active; clip is not yet finalised by [SermonRecordingService.stop].
  recording,

  /// [SermonRecordingService.stop] returned a valid path; clip is ready to play.
  completed,

  /// Recorder was active when the app terminated abnormally (crash / force-close).
  interrupted,

  /// File path is on record but could not be found on disk (moved or deleted).
  missing,
}

int nextSermonRecordingClipSequence(
  Iterable<SermonRecordingClip> clips,
) {
  var nextSequence = 0;
  for (final clip in clips) {
    if (clip.sequence >= nextSequence) {
      nextSequence = clip.sequence + 1;
    }
  }
  return nextSequence;
}

Duration calculateSermonGlobalPosition({
  required List<SermonRecordingClip> clips,
  required int currentIndex,
  required Duration positionInClip,
}) {
  var totalMs = positionInClip.inMilliseconds;
  final precedingClipCount = currentIndex.clamp(0, clips.length);
  for (var i = 0; i < precedingClipCount; i++) {
    totalMs += clips[i].durationMs;
  }
  return Duration(milliseconds: totalMs);
}

String buildSermonClipSignature(Iterable<SermonRecordingClip> clips) {
  return clips
      .map(
        (clip) => '${clip.id}:${clip.sequence}:${clip.filePath}:'
            '${clip.durationMs}:${clip.status.name}',
      )
      .join('|');
}

// ── Recording clip ────────────────────────────────────────────────────────────

/// A single contiguous audio file captured during a sermon recording session.
///
/// Clips are stored in sequence order within [SermonNote.recordingClips].
/// Only clips with [SermonRecordingClipStatus.completed] and a non-empty
/// [filePath] are considered [isPlayable].
class SermonRecordingClip {
  const SermonRecordingClip({
    required this.id,
    required this.filePath,
    required this.createdAtUtc,
    required this.durationMs,
    required this.sequence,
    required this.status,
    this.sizeBytes,
    this.mimeType = 'audio/mp4',
  });

  final String id;
  final String filePath;
  final DateTime createdAtUtc;

  /// Duration in milliseconds. Accurate only for [SermonRecordingClipStatus.completed]
  /// clips; may be 0 for [recording] or [interrupted] clips.
  final int durationMs;

  /// Ordering index within the note's clip list. Gaps are allowed; use
  /// [SermonNote.playableClips] which sorts by this value.
  final int sequence;

  final SermonRecordingClipStatus status;
  final int? sizeBytes;
  final String mimeType;

  /// True only when this clip has a valid file and can be loaded for playback.
  bool get isPlayable =>
      status == SermonRecordingClipStatus.completed &&
      filePath.trim().isNotEmpty;

  Duration get duration => Duration(milliseconds: durationMs);

  SermonRecordingClip copyWith({
    String? id,
    String? filePath,
    DateTime? createdAtUtc,
    int? durationMs,
    int? sequence,
    SermonRecordingClipStatus? status,
    int? sizeBytes,
    String? mimeType,
  }) {
    return SermonRecordingClip(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      durationMs: durationMs ?? this.durationMs,
      sequence: sequence ?? this.sequence,
      status: status ?? this.status,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'durationMs': durationMs,
        'sequence': sequence,
        'status': status.name,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
      };

  factory SermonRecordingClip.fromJson(Map<String, dynamic> json) {
    return SermonRecordingClip(
      id: json['id'] as String? ?? const Uuid().v4(),
      filePath: json['filePath'] as String? ?? '',
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      durationMs: json['durationMs'] as int? ?? 0,
      sequence: json['sequence'] as int? ?? 0,
      status: _clipStatusFromJson(json['status']),
      sizeBytes: json['sizeBytes'] as int?,
      mimeType: json['mimeType'] as String? ?? 'audio/mp4',
    );
  }

  static SermonRecordingClipStatus _clipStatusFromJson(Object? value) {
    if (value is String) {
      return SermonRecordingClipStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => SermonRecordingClipStatus.completed,
      );
    }
    return SermonRecordingClipStatus.completed;
  }
}

// ── Linked scripture ──────────────────────────────────────────────────────────

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

// ── Timestamped note ──────────────────────────────────────────────────────────

/// A timestamp marker inserted into note content during or after recording.
///
/// [offset] is the canonical global timeline position and is always populated.
/// For legacy notes (schema v1), [clipId] and [positionInClipMs] are null;
/// seeking falls back to the global offset.
/// For new notes (schema v2+), all three positional fields are populated.
class SermonTimestampedNote {
  /// Global timeline offset from the start of the entire recording session.
  final Duration offset;

  final String text;
  final DateTime createdAt;

  /// ID of the [SermonRecordingClip] this timestamp was captured in.
  /// Null for timestamps from before schema v2.
  final String? clipId;

  /// Position within the named clip, in milliseconds.
  /// Null for timestamps from before schema v2.
  final int? positionInClipMs;

  int get globalPositionMs => offset.inMilliseconds;

  SermonTimestampedNote({
    required this.offset,
    this.text = '',
    DateTime? createdAt,
    this.clipId,
    this.positionInClipMs,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'offsetMs': offset.inMilliseconds,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        if (clipId != null) 'clipId': clipId,
        if (positionInClipMs != null) 'positionInClipMs': positionInClipMs,
      };

  factory SermonTimestampedNote.fromJson(Map<String, dynamic> json) {
    final offsetMs = json['offsetMs'];
    final effectiveOffsetMs = offsetMs is int ? offsetMs : 0;
    return SermonTimestampedNote(
      offset: Duration(milliseconds: effectiveOffsetMs),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      clipId: json['clipId'] as String?,
      // Legacy notes: positionInClipMs defaults to offsetMs (single-clip case).
      positionInClipMs: json['positionInClipMs'] as int? ?? effectiveOffsetMs,
    );
  }
}

// ── Transcript segment ────────────────────────────────────────────────────────

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

// ── Sermon insight ────────────────────────────────────────────────────────────

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

// ── Sermon note ───────────────────────────────────────────────────────────────

class SermonNote {
  /// Current on-disk JSON schema version.
  /// v1 — single audioPath field.
  /// v2 — recordingClips list; legacy fields migrated on first read.
  static const int currentSchemaVersion = 2;

  final String id;
  String title;
  String preacher;
  String content;
  TextAlign textAlign;

  /// Immutable ordered list of all recording clips, including in-progress or
  /// interrupted ones. Mutate only via [copyWith]. Use [playableClips] for
  /// audio operations.
  final List<SermonRecordingClip> recordingClips;

  final int schemaVersion;

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
    List<SermonRecordingClip>? recordingClips,
    int? schemaVersion,
    this.transcript,
    this.summary,
    this.insight,
    this.outline,
    List<SermonTranscriptSegment>? transcriptSegments,
    List<SermonTimestampedNote>? timestampedNotes,
    DateTime? date,
    DateTime? lastModified,
  })  : id = id ?? const Uuid().v4(),
        recordingClips =
            List.unmodifiable(recordingClips ?? const <SermonRecordingClip>[]),
        schemaVersion = schemaVersion ?? SermonNote.currentSchemaVersion,
        transcriptSegments = transcriptSegments ?? <SermonTranscriptSegment>[],
        timestampedNotes = timestampedNotes ?? <SermonTimestampedNote>[],
        date = date ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // ── Computed ─────────────────────────────────────────────────────────────

  /// True when at least one clip has [SermonRecordingClipStatus.completed].
  bool get hasRecording => recordingClips.any((c) => c.isPlayable);

  /// Completed clips sorted by [SermonRecordingClip.sequence]. Immutable.
  List<SermonRecordingClip> get playableClips {
    final result = recordingClips.where((c) => c.isPlayable).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return List.unmodifiable(result);
  }

  /// Combined duration of all [playableClips] in milliseconds.
  int get totalDurationMs =>
      playableClips.fold(0, (sum, c) => sum + c.durationMs);

  /// Combined duration of all [playableClips] as a [Duration].
  Duration get totalRecordingDuration =>
      Duration(milliseconds: totalDurationMs);

  /// Number of [playableClips].
  int get clipCount => playableClips.length;

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'schemaVersion': SermonNote.currentSchemaVersion,
        'id': id,
        'title': title,
        'preacher': preacher,
        'content': content,
        'textAlign': textAlign.name,
        'recordingClips': recordingClips.map((c) => c.toJson()).toList(),
        'transcript': transcript,
        'summary': summary,
        'insight': insight?.toJson(),
        'outline': outline?.toJson(),
        'transcriptSegments':
            transcriptSegments.map((s) => s.toJson()).toList(),
        'timestampedNotes': timestampedNotes.map((n) => n.toJson()).toList(),
        'date': date.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
      };

  factory SermonNote.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    final noteId = json['id'] as String? ?? const Uuid().v4();

    // ── Recording clips — with v1 → v2 migration ─────────────────────────
    List<SermonRecordingClip> clips;

    if (schemaVersion >= 2 && json['recordingClips'] is List) {
      clips = (json['recordingClips'] as List)
          .whereType<Map>()
          .map((m) => SermonRecordingClip.fromJson(m.cast<String, dynamic>()))
          .toList();
    } else {
      // Schema v1: single audioPath field.
      final legacyPath = json['audioPath'] as String?;
      // Duration was stored as 'audioDurationMs' (int, milliseconds).
      final legacyDurationMs = () {
        final raw = json['audioDurationMs'];
        return raw is int ? raw : 0;
      }();

      if (legacyPath != null && legacyPath.isNotEmpty) {
        clips = [
          SermonRecordingClip(
            id: 'legacy-$noteId',
            filePath: legacyPath,
            createdAtUtc:
                DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
                    DateTime.tryParse(json['lastModified'] as String? ?? '') ??
                    DateTime.now().toUtc(),
            durationMs: legacyDurationMs,
            sequence: 0,
            // A legacy note with no duration was interrupted mid-recording.
            status: legacyDurationMs > 0
                ? SermonRecordingClipStatus.completed
                : SermonRecordingClipStatus.interrupted,
            sizeBytes: json['audioSizeBytes'] as int?,
            mimeType: json['audioMimeType'] as String? ?? 'audio/mp4',
          ),
        ];
      } else {
        clips = const <SermonRecordingClip>[];
      }
    }

    // ── Timestamps — with v1 migration ───────────────────────────────────
    final rawTimestamps = json['timestampedNotes'];
    final timestamps = rawTimestamps is List
        ? rawTimestamps
            .whereType<Map>()
            .map((m) => SermonTimestampedNote.fromJson(
                  m.cast<String, dynamic>(),
                ))
            .toList()
        : <SermonTimestampedNote>[];

    final rawTranscriptSegments = json['transcriptSegments'];
    final rawInsight = json['insight'];
    final rawOutline = json['outline'];

    return SermonNote(
      id: noteId,
      title: json['title'] as String? ?? '',
      preacher: json['preacher'] as String? ?? '',
      content: json['content'] as String? ?? '',
      textAlign: _textAlignFromJson(json['textAlign']),
      recordingClips: clips,
      // Normalise schema version: next save will write v2.
      schemaVersion: SermonNote.currentSchemaVersion,
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
              .map((m) =>
                  SermonTranscriptSegment.fromJson(m.cast<String, dynamic>()))
              .toList()
          : <SermonTranscriptSegment>[],
      timestampedNotes: timestamps,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  SermonNote copyWith({
    String? title,
    String? preacher,
    String? content,
    TextAlign? textAlign,
    List<SermonRecordingClip>? recordingClips,
    int? schemaVersion,
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
      recordingClips:
          recordingClips ?? List<SermonRecordingClip>.from(this.recordingClips),
      schemaVersion: schemaVersion ?? this.schemaVersion,
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
