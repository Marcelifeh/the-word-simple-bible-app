import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_review_event.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_session_draft.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';
import 'package:simple_bible_app/features/scripture_memory/repository/memory_verse_repository.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('memory_repo_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  test('valid records survive restart while malformed records are skipped',
      () async {
    final repository = MemoryVerseRepository();
    await repository.init();
    final original = await repository.saveDraft(_draft());

    final versesBox = Hive.box<dynamic>('memory_verses');
    await versesBox.put('malformed', '{not-json');
    await Hive.close();

    Hive.init(hiveDirectory.path);
    final restoredRepository = MemoryVerseRepository();
    await restoredRepository.init();

    expect(restoredRepository.list(), hasLength(1));
    expect(restoredRepository.list().single.id, original.id);

    final duplicate = await restoredRepository.saveDraft(
      _draft(categories: const ['Hope']),
    );
    expect(duplicate.id, original.id);
    expect(restoredRepository.list(), hasLength(1));
    expect(duplicate.categories, const ['Hope']);
  });

  test('session draft survives restart and corrupt draft is cleared', () async {
    final repository = MemoryVerseRepository();
    await repository.init();
    final verse = await repository.saveDraft(_draft());
    final draft = await repository.startSession([verse.id]);
    await repository.saveSessionDraft(
      draft.copyWith(
        results: {
          verse.id: const MemoryDraftResult(
            memoryVerseId: 'pending',
            mode: MemoryExerciseMode.progressiveFade,
            hintCount: 1,
          ),
        },
      ),
    );
    await Hive.close();

    Hive.init(hiveDirectory.path);
    final restored = MemoryVerseRepository();
    await restored.init();
    expect(restored.sessionDraft?.id, draft.id);
    expect(restored.sessionDraft?.results[verse.id]?.hintCount, 1);

    await Hive.box<dynamic>('memory_session_draft').put('active', '{broken');
    await Hive.close();
    Hive.init(hiveDirectory.path);
    final recovered = MemoryVerseRepository();
    await recovered.init();
    expect(recovered.sessionDraft, isNull);
    expect(recovered.list(), hasLength(1));
  });

  test('restored commit id cannot advance the schedule twice', () async {
    final repository = MemoryVerseRepository();
    await repository.init();
    final verse = await repository.saveDraft(_draft());

    await repository.recordReview(
      memoryVerseId: verse.id,
      mode: MemoryExerciseMode.typeIt,
      rating: MemoryReviewRating.remembered,
      eventId: 'session:verse',
      internalAccuracy: 0.92,
      hintCount: 1,
    );
    await repository.recordReview(
      memoryVerseId: verse.id,
      mode: MemoryExerciseMode.typeIt,
      rating: MemoryReviewRating.remembered,
      eventId: 'session:verse',
      internalAccuracy: 0.92,
      hintCount: 1,
    );

    expect(repository.findById(verse.id)?.schedule.reviewCount, 1);
    expect(repository.historyFor(verse.id), hasLength(1));
  });

  test('completed or discarded session clears its durable draft', () async {
    final repository = MemoryVerseRepository();
    await repository.init();
    final verse = await repository.saveDraft(_draft());
    await repository.startSession([verse.id]);

    await repository.clearSessionDraft();
    expect(repository.sessionDraft, isNull);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restored = MemoryVerseRepository();
    await restored.init();
    expect(restored.sessionDraft, isNull);
  });

  test('archived and deleted verses are skipped when restoring', () async {
    final repository = MemoryVerseRepository();
    await repository.init();
    final first = await repository.saveDraft(_draft());
    final second = await repository.saveDraft(
      _draftAt(17),
    );
    final third = await repository.saveDraft(
      _draftAt(18),
    );
    final draft = await repository.startSession([
      first.id,
      second.id,
      third.id,
    ]);
    await repository.archive(second.id);
    await repository.deletePermanently(third.id);

    expect(
      repository.resumableSessionVerses(draft).map((verse) => verse.id),
      [first.id],
    );
  });
}

MemoryVerseDraft _draft({List<String> categories = const ['Faith']}) {
  return MemoryVerseDraft(
    bookId: 'john',
    bookName: 'John',
    chapter: 3,
    startVerse: 16,
    translation: BibleTranslation.kjv,
    text: 'For God so loved the world.',
    source: MemoryVerseSource.bible,
    categories: categories,
  );
}

MemoryVerseDraft _draftAt(int verse) {
  return MemoryVerseDraft(
    bookId: 'john',
    bookName: 'John',
    chapter: 3,
    startVerse: verse,
    translation: BibleTranslation.kjv,
    text: 'Verse $verse.',
    source: MemoryVerseSource.bible,
  );
}
