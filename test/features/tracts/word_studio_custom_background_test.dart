import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:simple_bible_app/features/tracts/model/word_studio_custom_background.dart';
import 'package:simple_bible_app/features/tracts/repository/word_studio_custom_background_repository.dart';
import 'package:simple_bible_app/features/tracts/services/word_studio_background_storage_base.dart';

void main() {
  test('metadata JSON excludes image bytes and round-trips settings', () {
    final background = WordStudioCustomBackground(
      id: 'background-1',
      createdAtUtc: DateTime.utc(2026, 7, 25, 12),
      displayName: 'Church photo',
      filePath: '/documents/word_studio/backgrounds/bg_1.jpg',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      mimeType: 'image/jpeg',
      overlayOpacity: 0.45,
      scale: 1.6,
      fit: BoxFit.contain,
      alignmentX: -0.25,
      alignmentY: 0.5,
    );

    final json = background.toJson();
    final restored = WordStudioCustomBackground.fromJson(json);

    expect(json, isNot(contains('bytes')));
    expect(restored.id, background.id);
    expect(restored.displayName, 'Church photo');
    expect(restored.overlayOpacity, 0.45);
    expect(restored.scale, 1.6);
    expect(restored.fit, BoxFit.contain);
    expect(restored.alignment, const Alignment(-0.25, 0.5));
    expect(restored.bytes, isNull);
  });

  test('malformed visual settings use safe bounds and defaults', () {
    final restored = WordStudioCustomBackground.fromJson(
      <String, dynamic>{
        'id': 'background-2',
        'createdAtUtc': '2026-07-25T12:00:00Z',
        'displayName': '',
        'overlayOpacity': 4,
        'scale': -2,
        'fit': 'unsupported',
        'alignmentX': -8,
        'alignmentY': 9,
      },
    );

    expect(restored.displayName, 'My background');
    expect(restored.overlayOpacity, 0.8);
    expect(restored.scale, 1);
    expect(restored.fit, BoxFit.cover);
    expect(restored.alignment, const Alignment(-1, 1));
  });

  test('visual controls replace an unmodifiable background snapshot', () {
    final original = WordStudioCustomBackground(
      id: 'background-3',
      createdAtUtc: DateTime.utc(2026, 7, 25, 12),
      displayName: 'Nature',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );
    final snapshot = List<WordStudioCustomBackground>.unmodifiable([original]);
    final replacement = original.copyWith(
      fit: BoxFit.contain,
      overlayOpacity: 0.6,
      scale: 2.2,
    );

    final updated = replaceWordStudioCustomBackground(snapshot, replacement);

    expect(updated.single.fit, BoxFit.contain);
    expect(updated.single.overlayOpacity, 0.6);
    expect(updated.single.scale, 2.2);
    expect(snapshot.single.fit, BoxFit.cover);
    expect(snapshot.single.overlayOpacity, 0.35);
    expect(snapshot.single.scale, 1);
  });

  group('repository', () {
    late Directory directory;
    late _MemoryBackgroundStorage storage;
    late WordStudioCustomBackgroundRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'word_studio_background_test_',
      );
      Hive.init(directory.path);
      storage = _MemoryBackgroundStorage();
      repository = WordStudioCustomBackgroundRepository(storage: storage);
      await repository.init();
    });

    tearDown(() async {
      await repository.close();
      await Hive.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('imports, updates, duplicates, and removes local images', () async {
      await repository.acknowledgePrivacy();
      final original = await repository.importImage(
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        originalName: 'Beach photo.jpg',
        mimeType: 'image/jpeg',
      );

      expect(repository.privacyAcknowledged, isTrue);
      expect(original.displayName, 'Beach photo');
      expect(repository.backgrounds, hasLength(1));

      await repository.rename(original.id, 'Sunday service');
      final duplicate = await repository.duplicate(original.id);

      expect(repository.backgrounds, hasLength(2));
      expect(duplicate?.displayName, 'Sunday service copy');

      await repository.remove(original.id);

      expect(repository.backgrounds, hasLength(1));
      expect(storage.deletedIds, contains(original.id));
    });

    test('rejects files larger than the local limit', () async {
      final bytes = Uint8List(
        WordStudioCustomBackgroundRepository.maxFileBytes + 1,
      );

      await expectLater(
        repository.importImage(
          bytes: bytes,
          originalName: 'too-large.jpg',
        ),
        throwsA(isA<WordStudioBackgroundException>()),
      );
    });
  });
}

class _MemoryBackgroundStorage implements WordStudioBackgroundStorage {
  final Map<String, Uint8List> bytesById = <String, Uint8List>{};
  final List<String> deletedIds = <String>[];

  @override
  Future<void> init() async {}

  @override
  Future<String?> save({
    required String id,
    required String extension,
    required Uint8List bytes,
  }) async {
    bytesById[id] = bytes;
    return null;
  }

  @override
  Future<Uint8List?> read({
    required String id,
    String? filePath,
  }) async {
    return bytesById[id];
  }

  @override
  Future<void> delete({
    required String id,
    String? filePath,
  }) async {
    deletedIds.add(id);
    bytesById.remove(id);
  }

  @override
  Future<void> close() async {
    bytesById.clear();
  }
}
