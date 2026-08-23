import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:simple_bible_app/features/settings/backup/app_backup_service.dart';

void main() {
  late Directory root;
  late Directory documents;
  late Directory temporary;

  AppBackupService service(
          {BackupLimits limits = const BackupLimits(),
          DateTime Function()? now}) =>
      AppBackupService(
        documentsDirectory: () async => documents,
        temporaryDirectory: () async => temporary,
        limits: limits,
        now: now,
      );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('word_app_backup_test_');
    documents = Directory(p.join(root.path, 'documents'))
      ..createSync(recursive: true);
    temporary = Directory(p.join(root.path, 'temporary'))
      ..createSync(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('normal round trip preserves nested audio and image files', () async {
    File(p.join(documents.path, 'settings.hive')).writeAsStringSync('settings');
    File(p.join(documents.path, 'audio', 'sermon.m4a'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3, 4]);
    File(p.join(documents.path, 'word_studio', 'backgrounds', 'photo.jpg'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([5, 6, 7]);

    final backup = await service().createPortableBackup();
    final manifest = await service().validateBackup(backup);
    expect(manifest.files, hasLength(3));
    File(p.join(documents.path, 'settings.hive')).writeAsStringSync('changed');
    await service().restoreBackup(backup);

    expect(File(p.join(documents.path, 'settings.hive')).readAsStringSync(),
        'settings');
    expect(
        File(p.join(documents.path, 'audio', 'sermon.m4a')).readAsBytesSync(),
        [1, 2, 3, 4]);
    expect(
      File(p.join(documents.path, 'word_studio', 'backgrounds', 'photo.jpg'))
          .readAsBytesSync(),
      [5, 6, 7],
    );
  });

  test('malformed ZIP is rejected before current data changes', () async {
    final current = File(p.join(documents.path, 'keep.txt'))
      ..writeAsStringSync('keep');
    final corrupt = File(p.join(root.path, 'corrupt.zip'))
      ..writeAsStringSync('not a zip');
    await expectLater(
        service().restoreBackup(corrupt), throwsA(isA<AppBackupException>()));
    expect(current.readAsStringSync(), 'keep');
  });

  test('checksum mismatch is rejected', () async {
    final backup = _writeBackup(root,
        payloads: {'documents/a.txt': utf8.encode('tampered')},
        manifestPayloads: {'documents/a.txt': utf8.encode('original')});
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('checksum')));
  });

  test('file-size mismatch is rejected', () async {
    final backup = _writeBackup(root, payloads: {
      'documents/a.txt': [1, 2]
    }, sizeOverrides: {
      'documents/a.txt': 3
    });
    await expectLater(
        service().validateBackup(backup), throwsA(_messageContains('size')));
  });

  for (final unsafePath in [
    'documents/../escape.txt',
    'documents/./dot.txt',
    '/absolute.txt',
    'documents/C:/drive.txt',
    'documents/two//slashes.txt',
    'documents/empty\u0000name.txt',
  ]) {
    test('unsafe path is rejected: $unsafePath', () async {
      final backup = _writeBackup(root, payloads: {
        unsafePath: [1]
      });
      await expectLater(
          service().validateBackup(backup), throwsA(isA<AppBackupException>()));
    });
  }

  test('extra unmanifested file is rejected', () async {
    final backup = _writeBackup(
      root,
      payloads: {
        'documents/a.txt': [1],
        'documents/extra.txt': [2]
      },
      manifestPayloads: {
        'documents/a.txt': [1]
      },
    );
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('not authenticated')));
  });

  test('manifest entry missing from ZIP is rejected', () async {
    final backup = _writeBackup(
      root,
      payloads: {
        'documents/a.txt': [1]
      },
      manifestPayloads: {
        'documents/a.txt': [1],
        'documents/missing.txt': [2]
      },
    );
    await expectLater(
        service().validateBackup(backup), throwsA(_messageContains('missing')));
  });

  test('duplicate ZIP entry is rejected', () async {
    final archive = _archiveFor({
      'documents/a.txt': [1]
    });
    final backup = _writeArchiveWithDuplicate(
      root,
      archive,
      ArchiveFile('documents/a.txt', 1, [1]),
    );
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('duplicate')));
  });

  test('duplicate normalized path is rejected', () async {
    final backup = _writeBackup(
      root,
      payloads: {
        'documents/A.txt': [1],
        'documents/a.txt': [2]
      },
    );
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('normalized')));
  });

  test('unexpected top-level entry is rejected', () async {
    final backup = _writeBackup(root, payloads: {
      'other.txt': [1]
    });
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('unexpected')));
  });

  test('directory entry is rejected', () async {
    final archive = _archiveFor({
      'documents/a.txt': [1]
    });
    final directory = ArchiveFile('documents/folder/', 0, <int>[])
      ..isFile = false;
    archive.addFile(directory);
    final backup = _writeArchive(root, archive, 'directory.zip');
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('directory')));
  });

  test('too many entries are rejected', () async {
    final backup = _writeBackup(root, payloads: {
      'documents/a': [1],
      'documents/b': [2],
      'documents/c': [3]
    });
    const limits = BackupLimits(maxArchiveEntries: 3);
    await expectLater(service(limits: limits).validateBackup(backup),
        throwsA(_messageContains('number of entries')));
  });

  test('oversized single file is rejected', () async {
    final backup = _writeBackup(root, payloads: {
      'documents/a': [1, 2, 3, 4]
    });
    const limits = BackupLimits(maxSingleFileBytes: 3);
    await expectLater(service(limits: limits).validateBackup(backup),
        throwsA(_messageContains('oversized')));
  });

  test('excessive total uncompressed size is rejected', () async {
    final backup = _writeBackup(root, payloads: {
      'documents/a': [1, 2, 3],
      'documents/b': [4, 5, 6]
    });
    const limits = BackupLimits(maxTotalUncompressedBytes: 5);
    await expectLater(service(limits: limits).validateBackup(backup),
        throwsA(_messageContains('total size')));
  });

  test('invalid manifest is rejected', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('backup_manifest.json', 4, utf8.encode('nope')));
    final backup = _writeArchive(root, archive, 'invalid_manifest.zip');
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('manifest')));
  });

  test('wrong package is rejected', () async {
    final backup = _writeBackup(root,
        payloads: {
          'documents/a': [1]
        },
        packageName: 'other.app');
    await expectLater(service().validateBackup(backup),
        throwsA(_messageContains('different app')));
  });

  test('stale temporary backups are cleaned but recent share file is retained',
      () async {
    final now = DateTime.utc(2026, 8, 23, 12);
    final stale = File(p.join(temporary.path, 'the_word_app_backup_stale.zip'))
      ..writeAsBytesSync([1]);
    final recent =
        File(p.join(temporary.path, 'the_word_app_backup_recent.zip'))
          ..writeAsBytesSync([1]);
    stale.setLastModifiedSync(now.subtract(const Duration(days: 2)));
    recent.setLastModifiedSync(now.subtract(const Duration(hours: 2)));

    await service(now: () => now).cleanupStaleTemporaryBackups();
    expect(stale.existsSync(), isFalse);
    expect(recent.existsSync(), isTrue);
  });
}

Matcher _messageContains(String text) => isA<AppBackupException>().having(
      (error) => error.message.toLowerCase(),
      'message',
      contains(text.toLowerCase()),
    );

File _writeBackup(
  Directory root, {
  required Map<String, List<int>> payloads,
  Map<String, List<int>>? manifestPayloads,
  Map<String, int> sizeOverrides = const {},
  String packageName = BackupManifest.expectedPackageName,
}) =>
    _writeArchive(
      root,
      _archiveFor(
        payloads,
        manifestPayloads: manifestPayloads,
        sizeOverrides: sizeOverrides,
        packageName: packageName,
      ),
      'crafted_${DateTime.now().microsecondsSinceEpoch}.zip',
    );

Archive _archiveFor(
  Map<String, List<int>> payloads, {
  Map<String, List<int>>? manifestPayloads,
  Map<String, int> sizeOverrides = const {},
  String packageName = BackupManifest.expectedPackageName,
}) {
  final archive = Archive();
  for (final entry in payloads.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  final authenticated = manifestPayloads ?? payloads;
  final files = authenticated.entries
      .map((entry) => {
            'path': entry.key,
            'size': sizeOverrides[entry.key] ?? entry.value.length,
            'sha256': sha256.convert(entry.value).toString(),
          })
      .toList();
  final manifest = utf8.encode(jsonEncode({
    'schemaVersion': 1,
    'packageName': packageName,
    'exportedAt': '2026-08-23T12:00:00.000Z',
    'files': files,
  }));
  archive
      .addFile(ArchiveFile('backup_manifest.json', manifest.length, manifest));
  return archive;
}

File _writeArchive(Directory root, Archive archive, String name) {
  final encoded = ZipEncoder().encode(archive)!;
  return File(p.join(root.path, name))..writeAsBytesSync(encoded);
}

File _writeArchiveWithDuplicate(
  Directory root,
  Archive archive,
  ArchiveFile duplicate,
) {
  final output = File(p.join(root.path, 'duplicate.zip'));
  final encoder = ZipFileEncoder()..create(output.path);
  for (final entry in archive.files) {
    encoder.addArchiveFile(entry);
  }
  encoder.addArchiveFile(duplicate);
  encoder.close();
  return output;
}
