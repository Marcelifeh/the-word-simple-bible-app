import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/home/services/weekly_sermon_progress.dart';
import 'package:simple_bible_app/features/sermon_notes/model/sermon_note.dart';

void main() {
  test('counts sermon notes from Sunday through today', () {
    final notes = <SermonNote>[
      SermonNote(
        id: 'monday-note-only',
        title: 'Grace',
        date: DateTime(2026, 7, 27, 9),
      ),
      SermonNote(
        id: 'current-sunday',
        title: 'Hope',
        date: DateTime(2026, 7, 26, 18),
      ),
      SermonNote(
        id: 'next-sunday',
        title: 'Faith',
        date: DateTime(2026, 8, 2, 9),
      ),
    ];

    expect(
      sermonsCapturedThisWeek(
        notes,
        now: DateTime(2026, 7, 29, 12),
      ),
      2,
    );
  });

  test('previous Saturday is excluded after the Sunday reset', () {
    final notes = <SermonNote>[
      SermonNote(
        id: 'previous-saturday',
        title: 'Before the boundary',
        date: DateTime(2026, 8, 1, 18),
      ),
      SermonNote(
        id: 'current-sunday',
        title: 'A new week',
        date: DateTime(2026, 8, 2, 9),
      ),
    ];

    expect(
      sermonsCapturedThisWeek(
        notes,
        now: DateTime(2026, 8, 2, 12),
      ),
      1,
    );
  });

  test('counts each sermon once regardless of its clip count', () {
    final note = SermonNote(
      id: 'multi-clip-sermon',
      title: 'Called to Serve',
      date: DateTime(2026, 7, 28, 10),
      recordingClips: [
        SermonRecordingClip(
          id: 'clip-1',
          filePath: 'clip-1.m4a',
          createdAtUtc: DateTime.utc(2026, 7, 28, 14),
          durationMs: 1000,
          sequence: 0,
          status: SermonRecordingClipStatus.completed,
        ),
        SermonRecordingClip(
          id: 'clip-2',
          filePath: 'clip-2.m4a',
          createdAtUtc: DateTime.utc(2026, 7, 28, 14, 5),
          durationMs: 1000,
          sequence: 1,
          status: SermonRecordingClipStatus.completed,
        ),
      ],
    );

    expect(
      sermonsCapturedThisWeek(
        [note],
        now: DateTime(2026, 7, 29, 12),
      ),
      1,
    );
  });
}
