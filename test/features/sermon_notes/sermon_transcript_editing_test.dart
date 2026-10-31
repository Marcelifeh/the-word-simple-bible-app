import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simple_bible_app/features/sermon_notes/model/sermon_note.dart';
import 'package:simple_bible_app/features/sermon_notes/repository/sermon_note_repository.dart';
import 'package:simple_bible_app/features/sermon_notes/view/sermon_transcript_editor_screen.dart';

void main() {
  testWidgets('editor fits large text with the keyboard on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!),
        home: SermonTranscriptEditorScreen(
            transcript: 'Correct me', onSave: (_) async {})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);
  });
  test(
      'corrections persist, clear stale derived text, and preserve audio and notes',
      () async {
    final directory = await Directory.systemTemp.createTemp('transcript-edit-');
    Hive.init(directory.path);
    try {
      final repository = SermonNoteRepository();
      await repository.init();
      final original = SermonNote(
          title: 'Sermon',
          content: 'My written notes',
          transcript: 'Incorrect words',
          summary: 'Old summary',
          insight: const SermonInsight(title: 'Old insight'),
          timestampedNotes: [
            SermonTimestampedNote(
                offset: const Duration(seconds: 3), text: 'Keep this')
          ],
          recordingClips: [
            SermonRecordingClip(
                id: 'audio',
                filePath: '/private/sermon.m4a',
                createdAtUtc: DateTime.utc(2026),
                durationMs: 43000,
                sequence: 0,
                status: SermonRecordingClipStatus.completed)
          ],
          transcriptSegments: [
            const SermonTranscriptSegment(
                start: Duration.zero,
                end: Duration(seconds: 2),
                text: 'Incorrect words')
          ]);
      await repository
          .saveNote(original.withEditedTranscript('  Correct words  '));
      await Hive.close();
      final reopened = SermonNoteRepository();
      await reopened.init();
      final saved = reopened.list().single;
      expect(saved.transcript, 'Correct words');
      expect(saved.content, original.content);
      expect(saved.id, original.id);
      expect(saved.recordingClips.single.filePath, '/private/sermon.m4a');
      expect(saved.timestampedNotes.single.text, 'Keep this');
      expect(saved.summary, isNull);
      expect(saved.insight, isNull);
      expect(saved.transcriptSegments, isEmpty);
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('unchanged transcript keeps timings and existing insights', () {
    final note =
        SermonNote(transcript: 'Correct words', summary: 'Keep summary');
    expect(note.withEditedTranscript(' Correct words '), same(note));
    expect(() => note.withEditedTranscript('  '), throwsArgumentError);
  });

  Future<void> openEditor(
      WidgetTester tester, Future<void> Function(String) onSave) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<bool>(
                              builder: (_) => SermonTranscriptEditorScreen(
                                  transcript: 'Original words',
                                  onSave: onSave))),
                      child: const Text('Open editor')),
                ))));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets('saving corrections invokes persistence and closes the editor',
      (tester) async {
    String? saved;
    await openEditor(tester, (value) async => saved = value);
    await tester.enterText(find.byType(TextFormField), 'Corrected words');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, 'Corrected words');
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('save failure preserves edits and permits retry', (tester) async {
    var attempts = 0;
    await openEditor(tester, (_) async {
      if (++attempts == 1) throw StateError('Storage unavailable');
    });
    await tester.enterText(find.byType(TextFormField), 'Keep my corrections');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Keep my corrections'), findsOneWidget);
    expect(find.textContaining('Could not save'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('cancel confirms before discarding and does not save',
      (tester) async {
    var saved = false;
    await openEditor(tester, (_) async => saved = true);
    await tester.enterText(find.byType(TextFormField), 'Unsaved correction');
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved correction'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('empty transcript cannot overwrite the saved text',
      (tester) async {
    var saved = false;
    await openEditor(tester, (_) async => saved = true);
    await tester.enterText(find.byType(TextFormField), ' ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(
        find.text('Enter some transcript text before saving.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
