import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/sermon_notes/model/sermon_note.dart';

void main() {
  SermonRecordingClip clip({
    required String id,
    required int sequence,
    int durationMs = 1000,
    String? filePath,
    SermonRecordingClipStatus status = SermonRecordingClipStatus.completed,
  }) {
    return SermonRecordingClip(
      id: id,
      filePath: filePath ?? '$id.m4a',
      createdAtUtc: DateTime.utc(2026, 7, 20),
      durationMs: durationMs,
      sequence: sequence,
      status: status,
    );
  }

  group('SermonRecordingClip', () {
    test('fromJson and toJson round-trip preserves every field', () {
      final clip = SermonRecordingClip(
        id: 'clip-1',
        filePath: '/path/to/clip1.m4a',
        createdAtUtc: DateTime.utc(2026, 7, 20, 12, 0, 0),
        durationMs: 15000,
        sequence: 1,
        status: SermonRecordingClipStatus.completed,
        sizeBytes: 123456,
        mimeType: 'audio/mp4',
      );

      final json = clip.toJson();
      final decoded = SermonRecordingClip.fromJson(json);

      expect(decoded.id, 'clip-1');
      expect(decoded.filePath, '/path/to/clip1.m4a');
      expect(decoded.createdAtUtc, DateTime.utc(2026, 7, 20, 12, 0, 0));
      expect(decoded.durationMs, 15000);
      expect(decoded.sequence, 1);
      expect(decoded.status, SermonRecordingClipStatus.completed);
      expect(decoded.sizeBytes, 123456);
      expect(decoded.mimeType, 'audio/mp4');
      expect(decoded.isPlayable, true);
    });

    test('isPlayable excludes recording, interrupted, and missing clips', () {
      final playable = SermonRecordingClip(
        id: '1',
        filePath: 'path.m4a',
        createdAtUtc: DateTime.now(),
        durationMs: 100,
        sequence: 0,
        status: SermonRecordingClipStatus.completed,
      );
      expect(playable.isPlayable, true);

      final recording =
          playable.copyWith(status: SermonRecordingClipStatus.recording);
      expect(recording.isPlayable, false);

      final interrupted =
          playable.copyWith(status: SermonRecordingClipStatus.interrupted);
      expect(interrupted.isPlayable, false);

      final missing =
          playable.copyWith(status: SermonRecordingClipStatus.missing);
      expect(missing.isPlayable, false);

      final emptyPath = playable.copyWith(filePath: '  ');
      expect(emptyPath.isPlayable, false);
    });

    test('copyWith replaces only specified fields', () {
      final original = clip(id: 'original', sequence: 4).copyWith(
        sizeBytes: 42,
        mimeType: 'audio/aac',
      );

      final updated = original.copyWith(
        durationMs: 9000,
        status: SermonRecordingClipStatus.interrupted,
      );

      expect(updated.id, original.id);
      expect(updated.filePath, original.filePath);
      expect(updated.createdAtUtc, original.createdAtUtc);
      expect(updated.sequence, original.sequence);
      expect(updated.sizeBytes, original.sizeBytes);
      expect(updated.mimeType, original.mimeType);
      expect(updated.durationMs, 9000);
      expect(updated.status, SermonRecordingClipStatus.interrupted);
    });
  });

  group('SermonNote.fromJson legacy migration', () {
    test('audioPath and duration become a completed clip', () {
      final legacyJson = {
        'id': 'legacy-note-id',
        'title': 'Legacy Sermon',
        'preacher': 'John Doe',
        'content': 'Preached word',
        'textAlign': 'center',
        'audioPath': '/legacy/path.m4a',
        'audioDurationMs': 60000,
        'audioSizeBytes': 9999,
        'audioMimeType': 'audio/aac',
        'recordedAt': '2026-07-20T12:00:00Z',
        'date': '2026-07-20T10:00:00Z',
        'lastModified': '2026-07-20T11:00:00Z',
        'timestampedNotes': [
          {'offsetMs': 5000, 'text': 'Intro point'}
        ],
      };

      final note = SermonNote.fromJson(legacyJson);

      expect(note.schemaVersion, SermonNote.currentSchemaVersion);
      expect(note.recordingClips.length, 1);
      final clip = note.recordingClips.first;
      expect(clip.id, 'legacy-legacy-note-id');
      expect(clip.filePath, '/legacy/path.m4a');
      expect(clip.durationMs, 60000);
      expect(clip.sequence, 0);
      expect(clip.status, SermonRecordingClipStatus.completed);
      expect(clip.sizeBytes, 9999);
      expect(clip.mimeType, 'audio/aac');

      expect(note.timestampedNotes.length, 1);
      final ts = note.timestampedNotes.first;
      expect(ts.offset.inMilliseconds, 5000);
      expect(ts.clipId, isNull);
      expect(ts.positionInClipMs, 5000);
    });

    test('audioPath without duration becomes an interrupted clip', () {
      final legacyJson = {
        'id': 'interrupted-id',
        'audioPath': '/legacy/path.m4a',
      };

      final note = SermonNote.fromJson(legacyJson);
      expect(note.recordingClips.first.status,
          SermonRecordingClipStatus.interrupted);
    });

    test('missing audioPath becomes an empty clip list', () {
      final note = SermonNote.fromJson({'id': 'text-only'});

      expect(note.recordingClips, isEmpty);
      expect(note.hasRecording, false);
    });

    test('schema v2 recordingClips parse directly', () {
      final v2Json = {
        'id': 'v2-id',
        'schemaVersion': 2,
        'recordingClips': [
          {
            'id': 'c1',
            'filePath': 'p1.m4a',
            'createdAtUtc': '2026-07-20T12:00:00Z',
            'durationMs': 1000,
            'sequence': 1,
            'status': 'completed',
          }
        ],
        'timestampedNotes': [
          {
            'offsetMs': 1000,
            'clipId': 'c1',
            'positionInClipMs': 1000,
            'text': 'note',
          }
        ]
      };

      final note = SermonNote.fromJson(v2Json);
      expect(note.schemaVersion, 2);
      expect(note.recordingClips.length, 1);
      expect(note.recordingClips.first.id, 'c1');
      expect(note.timestampedNotes.first.clipId, 'c1');
      expect(note.timestampedNotes.first.positionInClipMs, 1000);
    });
  });

  group('SermonNote.fromJson timestamp migration', () {
    test('legacy timestamp defaults local position to global offset', () {
      final note = SermonNote.fromJson({
        'id': 'legacy-timestamp',
        'timestampedNotes': [
          {'offsetMs': 4200, 'text': 'Point'}
        ],
      });

      final timestamp = note.timestampedNotes.single;
      expect(timestamp.clipId, isNull);
      expect(timestamp.positionInClipMs, 4200);
      expect(timestamp.globalPositionMs, 4200);
    });

    test('v2 timestamp preserves clip and local position', () {
      final note = SermonNote.fromJson({
        'id': 'v2-timestamp',
        'schemaVersion': 2,
        'recordingClips': <Object?>[],
        'timestampedNotes': [
          {
            'offsetMs': 12000,
            'clipId': 'clip-2',
            'positionInClipMs': 2000,
          }
        ],
      });

      final timestamp = note.timestampedNotes.single;
      expect(timestamp.offset.inMilliseconds, 12000);
      expect(timestamp.clipId, 'clip-2');
      expect(timestamp.positionInClipMs, 2000);
    });
  });

  group('SermonNote computed getters', () {
    test('computed getters', () {
      final note = SermonNote(
        recordingClips: [
          clip(id: 'c1', sequence: 2, durationMs: 5000),
          clip(id: 'c2', sequence: 1, durationMs: 10000),
          clip(
            id: 'c3',
            sequence: 3,
            durationMs: 9999,
            status: SermonRecordingClipStatus.interrupted,
          ),
        ],
      );

      expect(note.hasRecording, true);
      expect(note.clipCount, 2);
      expect(note.playableClips.length, 2);
      // Sorted by sequence (sequence 1 then 2)
      expect(note.playableClips[0].id, 'c2');
      expect(note.playableClips[1].id, 'c1');
      expect(note.totalDurationMs, 15000);
      expect(note.totalRecordingDuration, const Duration(seconds: 15));
    });
  });

  group('SermonNote.copyWith', () {
    test('copies recordingClips into a new unmodifiable list', () {
      final source = <SermonRecordingClip>[clip(id: 'c1', sequence: 0)];
      final original = SermonNote(recordingClips: source);
      final replacement = <SermonRecordingClip>[
        clip(id: 'c2', sequence: 1),
      ];

      final copied = original.copyWith(recordingClips: replacement);
      replacement.add(clip(id: 'c3', sequence: 2));

      expect(copied.recordingClips.map((item) => item.id), ['c2']);
      expect(
        () => copied.recordingClips.add(clip(id: 'c4', sequence: 3)),
        throwsUnsupportedError,
      );
      expect(identical(copied.recordingClips, original.recordingClips), false);
    });
  });

  group('sequence safety', () {
    test('uses max existing sequence plus one', () {
      expect(
        nextSermonRecordingClipSequence([
          clip(id: 'c1', sequence: 7),
          clip(id: 'c2', sequence: 2),
          clip(id: 'c3', sequence: 4),
        ]),
        8,
      );
    });

    test('empty clips start at sequence zero', () {
      expect(nextSermonRecordingClipSequence(const []), 0);
    });
  });

  group('global position calculation', () {
    final clips = [
      clip(id: 'c1', sequence: 0, durationMs: 5000),
      clip(id: 'c2', sequence: 1, durationMs: 7000),
      clip(id: 'c3', sequence: 2, durationMs: 9000),
    ];

    test('adds durations before the current clip', () {
      expect(
        calculateSermonGlobalPosition(
          clips: clips,
          currentIndex: 1,
          positionInClip: const Duration(milliseconds: 1200),
        ),
        const Duration(milliseconds: 6200),
      );
    });

    test('index zero returns the local position', () {
      expect(
        calculateSermonGlobalPosition(
          clips: clips,
          currentIndex: 0,
          positionInClip: const Duration(milliseconds: 1200),
        ),
        const Duration(milliseconds: 1200),
      );
    });

    test('an index beyond the list safely adds all clip durations', () {
      expect(
        calculateSermonGlobalPosition(
          clips: clips,
          currentIndex: 99,
          positionInClip: const Duration(milliseconds: 1200),
        ),
        const Duration(milliseconds: 22200),
      );
    });
  });

  group('clip signature', () {
    final original = clip(id: 'c1', sequence: 0, durationMs: 5000);

    test('identical clips have identical signatures', () {
      expect(
        buildSermonClipSignature([original]),
        buildSermonClipSignature([original.copyWith()]),
      );
    });

    test('sequence changes the signature', () {
      expect(
        buildSermonClipSignature([original]),
        isNot(buildSermonClipSignature([original.copyWith(sequence: 1)])),
      );
    });

    test('file path changes the signature', () {
      expect(
        buildSermonClipSignature([original]),
        isNot(buildSermonClipSignature([
          original.copyWith(filePath: 'different.m4a'),
        ])),
      );
    });

    test('duration changes the signature', () {
      expect(
        buildSermonClipSignature([original]),
        isNot(buildSermonClipSignature([
          original.copyWith(durationMs: 9999),
        ])),
      );
    });

    test('status changes the signature', () {
      expect(
        buildSermonClipSignature([original]),
        isNot(buildSermonClipSignature([
          original.copyWith(status: SermonRecordingClipStatus.missing),
        ])),
      );
    });
  });
}
