import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/scripture_memory/model/memory_verse.dart';
import 'package:simple_bible_app/features/scripture_memory/repository/memory_collection_repository.dart';
import 'package:simple_bible_app/features/scripture_memory/repository/memory_verse_repository.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled collection JSON files validate', () async {
    final collections = await MemoryCollectionRepository().loadCollections();

    expect(collections, hasLength(5));
    expect(collections.every((item) => item.references.isNotEmpty), isTrue);
    expect(collections.map((item) => item.id).toSet(), hasLength(5));
  });

  test('collection additions deduplicate and stagger beyond daily goal',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('memory_collection_test_');
    Hive.init(directory.path);
    try {
      final repository = MemoryVerseRepository();
      await repository.init();
      final drafts = [
        for (var verse = 1; verse <= 6; verse++)
          MemoryVerseDraft(
            bookId: 'john',
            bookName: 'John',
            chapter: 1,
            startVerse: verse,
            translation: BibleTranslation.kjv,
            text: 'Verse $verse.',
            source: MemoryVerseSource.collection,
            collectionIds: const ['foundations_of_faith'],
          ),
      ];

      await repository.saveCollectionDrafts(drafts);
      await repository.saveCollectionDrafts(drafts);

      expect(repository.list(), hasLength(6));
      final today = MemoryScheduler.formatLocalDate(DateTime.now());
      expect(
        repository.list().where(
              (verse) => verse.schedule.dueLocalDate == today,
            ),
        hasLength(5),
      );
    } finally {
      await Hive.close();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    }
  });
}
