import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppBackupException implements Exception {
  AppBackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Limits allow substantial sermon audio and Word Studio media while bounding
/// memory, storage, entry-count, and decompression-amplification attacks.
class BackupLimits {
  const BackupLimits({
    this.maxZipBytes = 512 * 1024 * 1024,
    this.maxManifestBytes = 4 * 1024 * 1024,
    this.maxArchiveEntries = 10000,
    this.maxSingleFileBytes = 512 * 1024 * 1024,
    this.maxTotalUncompressedBytes = 4 * 1024 * 1024 * 1024,
    this.maxCompressionRatio = 200,
  });

  final int maxZipBytes;
  final int maxManifestBytes;
  final int maxArchiveEntries;
  final int maxSingleFileBytes;
  final int maxTotalUncompressedBytes;
  final double maxCompressionRatio;
}

class BackupManifestFile {
  const BackupManifestFile(
      {required this.path, required this.size, required this.sha256});
  final String path;
  final int size;
  final String sha256;

  Map<String, dynamic> toJson() =>
      {'path': path, 'size': size, 'sha256': sha256};

  static BackupManifestFile fromJson(Map<String, dynamic> json) {
    if (json['path'] is! String ||
        json['size'] is! num ||
        json['sha256'] is! String) {
      throw AppBackupException('Backup manifest has an invalid file entry.');
    }
    return BackupManifestFile(
      path: json['path'] as String,
      size: (json['size'] as num).toInt(),
      sha256: json['sha256'] as String,
    );
  }
}

class BackupManifest {
  const BackupManifest({
    required this.schemaVersion,
    required this.packageName,
    required this.exportedAt,
    required this.files,
  });

  static const currentSchemaVersion = 1;
  static const expectedPackageName = 'org.thewordapp.mobile';
  final int schemaVersion;
  final String packageName;
  final DateTime exportedAt;
  final List<BackupManifestFile> files;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'packageName': packageName,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'files': files.map((file) => file.toJson()).toList(growable: false),
      };

  static BackupManifest fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final exportedAt = DateTime.tryParse(json['exportedAt'] as String? ?? '');
    if (rawFiles is! List ||
        json['schemaVersion'] is! num ||
        json['packageName'] is! String ||
        exportedAt == null) {
      throw AppBackupException('Backup manifest is invalid.');
    }
    final files = <BackupManifestFile>[];
    for (final rawFile in rawFiles) {
      if (rawFile is! Map) {
        throw AppBackupException('Backup manifest has an invalid file entry.');
      }
      files
          .add(BackupManifestFile.fromJson(Map<String, dynamic>.from(rawFile)));
    }
    return BackupManifest(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      packageName: json['packageName'] as String,
      exportedAt: exportedAt,
      files: files,
    );
  }
}

class AppBackupService {
  AppBackupService({
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? temporaryDirectory,
    this.limits = const BackupLimits(),
    DateTime Function()? now,
  })  : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
        _now = now ?? DateTime.now;

  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory> Function() _temporaryDirectory;
  final DateTime Function() _now;
  final BackupLimits limits;

  static const _manifestName = 'backup_manifest.json';
  static const _documentsPrefix = 'documents/';
  static const _portablePrefix = 'the_word_app_backup_';
  static const _safetyDirectoryName = 'word_app_restore_safety';
  static const _portableRetention = Duration(hours: 24);
  static const _failedSafetyRetention = Duration(days: 30);

  static const _knownHiveBoxes = <String>{
    'settings',
    'favorites',
    'notes',
    'sermon_notes',
    'sermon_note_drafts',
    'memory_verses',
    'memory_review_history',
    'memory_preferences',
    'memory_session_draft',
    'user_tracts',
    'devotional_journal',
    'notification_preferences',
    'notification_inbox',
    'scheduled_notifications',
    'narration_preferences',
    'word_studio_custom_backgrounds',
    'word_studio_custom_background_files',
    'commentary',
  };

  Future<File> createPortableBackup() async {
    await cleanupStaleTemporaryBackups();
    await _flushKnownHiveBoxes();
    final temp = await _temporaryDirectory();
    await temp.create(recursive: true);
    final stamp = _now().toUtc().toIso8601String().replaceAll(':', '-');
    return _createBackupFile(
        File(p.join(temp.path, '$_portablePrefix$stamp.zip')));
  }

  Future<File> _createSafetyBackup() async {
    await _flushKnownHiveBoxes();
    final temp = await _temporaryDirectory();
    final safetyDir = Directory(p.join(temp.path, _safetyDirectoryName));
    await safetyDir.create(recursive: true);
    return _createBackupFile(File(p.join(
      safetyDir.path,
      'pre_restore_${_now().microsecondsSinceEpoch}.zip',
    )));
  }

  Future<File> _createBackupFile(File output) async {
    final documents = await _documentsDirectory();
    await documents.create(recursive: true);
    final archive = Archive();
    final manifestFiles = <BackupManifestFile>[];
    var totalSize = 0;

    await for (final entity
        in documents.list(recursive: true, followLinks: false)) {
      if (entity is! File || entity.path.toLowerCase().endsWith('.lock')) {
        continue;
      }
      final relative = p.relative(entity.path, from: documents.path);
      if (!_isSafeRelativePath(relative)) {
        throw AppBackupException(
            'Unsafe local file path encountered: $relative');
      }
      final length = await entity.length();
      if (length > limits.maxSingleFileBytes) {
        throw AppBackupException(
            'A local file is too large to back up safely.');
      }
      totalSize += length;
      if (totalSize > limits.maxTotalUncompressedBytes) {
        throw AppBackupException('Local data is too large to back up safely.');
      }
      if (manifestFiles.length + 1 >= limits.maxArchiveEntries) {
        throw AppBackupException('There are too many local files to back up.');
      }
      final bytes = await entity.readAsBytes();
      final archivePath = '$_documentsPrefix${_zipPath(relative)}';
      manifestFiles.add(BackupManifestFile(
        path: archivePath,
        size: bytes.length,
        sha256: sha256.convert(bytes).toString(),
      ));
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }

    manifestFiles.sort((a, b) => a.path.compareTo(b.path));
    final manifestBytes = utf8.encode(jsonEncode(BackupManifest(
      schemaVersion: BackupManifest.currentSchemaVersion,
      packageName: BackupManifest.expectedPackageName,
      exportedAt: _now(),
      files: manifestFiles,
    ).toJson()));
    if (manifestBytes.length > limits.maxManifestBytes) {
      throw AppBackupException('Backup manifest is too large.');
    }
    archive.addFile(
        ArchiveFile(_manifestName, manifestBytes.length, manifestBytes));
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw AppBackupException('Could not create backup archive.');
    }
    if (encoded.length > limits.maxZipBytes) {
      throw AppBackupException('Backup ZIP is too large to create safely.');
    }
    await output.parent.create(recursive: true);
    await output.writeAsBytes(encoded, flush: true);
    return output;
  }

  Future<BackupManifest> validateBackup(File backupFile) async {
    await cleanupStaleTemporaryBackups(preservePath: backupFile.path);
    return _validateArchive(await _readAndDecodeArchive(backupFile));
  }

  /// Validation completes before the safety snapshot is made or Documents is
  /// cleared. Existing repositories require an app restart after success.
  Future<BackupManifest> restoreBackup(File backupFile) async {
    await cleanupStaleTemporaryBackups(preservePath: backupFile.path);
    final archive = await _readAndDecodeArchive(backupFile);
    final manifest = _validateArchive(archive);
    final safetyBackup = await _createSafetyBackup();
    final documents = await _documentsDirectory();

    try {
      await Hive.close();
      await _clearDirectory(documents);
      await _extractDocuments(archive, documents);
      await _deleteIfPresent(safetyBackup);
      return manifest;
    } catch (restoreError) {
      try {
        final safetyArchive = await _readAndDecodeArchive(safetyBackup);
        _validateArchive(safetyArchive);
        await _clearDirectory(documents);
        await _extractDocuments(safetyArchive, documents);
        await _deleteIfPresent(safetyBackup);
      } catch (_) {
        throw AppBackupException(
          'Restore failed and automatic rollback also failed. The safety '
          'snapshot was preserved for recovery at ${safetyBackup.path}.',
        );
      }
      throw AppBackupException(
        'Restore failed, but your previous local data was recovered: $restoreError',
      );
    }
  }

  Future<Archive> _readAndDecodeArchive(File backupFile) async {
    if (!await backupFile.exists()) {
      throw AppBackupException('The selected backup file does not exist.');
    }
    final length = await backupFile.length();
    if (length <= 0 || length > limits.maxZipBytes) {
      throw AppBackupException(
          'The selected backup ZIP is too large or empty.');
    }
    try {
      final decoder = ZipDecoder();
      final archive =
          decoder.decodeBytes(await backupFile.readAsBytes(), verify: true);
      final rawNames = decoder.directory.fileHeaders
          .map((header) => header.filename)
          .toList(growable: false);
      if (rawNames.length > limits.maxArchiveEntries) {
        throw AppBackupException(
          'Backup contains an invalid number of entries.',
        );
      }
      final exactNames = <String>{};
      final normalizedNames = <String>{};
      for (final name in rawNames) {
        if (!exactNames.add(name)) {
          throw AppBackupException('Backup contains a duplicate ZIP entry.');
        }
        if (!normalizedNames.add(_normalizedArchiveKey(name))) {
          throw AppBackupException(
            'Backup contains duplicate normalized paths.',
          );
        }
      }
      return archive;
    } on AppBackupException {
      rethrow;
    } catch (_) {
      throw AppBackupException('The selected file is not a valid backup ZIP.');
    }
  }

  BackupManifest _validateArchive(Archive archive) {
    if (archive.files.isEmpty ||
        archive.files.length > limits.maxArchiveEntries) {
      throw AppBackupException('Backup contains an invalid number of entries.');
    }
    final entries = <String, ArchiveFile>{};
    final normalizedPaths = <String>{};
    var totalSize = 0;
    for (final entry in archive.files) {
      if (entry.isSymbolicLink || !entry.isFile) {
        throw AppBackupException(
            'Backup contains a directory, link, or unsupported entry.');
      }
      if (entries.containsKey(entry.name)) {
        throw AppBackupException('Backup contains a duplicate ZIP entry.');
      }
      if (!normalizedPaths.add(_normalizedArchiveKey(entry.name))) {
        throw AppBackupException('Backup contains duplicate normalized paths.');
      }
      if (entry.name != _manifestName &&
          !entry.name.startsWith(_documentsPrefix)) {
        throw AppBackupException(
            'Backup contains an unexpected payload entry.');
      }
      if (entry.name.startsWith(_documentsPrefix) &&
          !_isSafeRelativePath(entry.name.substring(_documentsPrefix.length))) {
        throw AppBackupException('Backup contains an unsafe file path.');
      }
      if (entry.size < 0 || entry.size > limits.maxSingleFileBytes) {
        throw AppBackupException('Backup contains an oversized file.');
      }
      totalSize += entry.size;
      if (totalSize > limits.maxTotalUncompressedBytes) {
        throw AppBackupException('Backup expands beyond the safe total size.');
      }
      _validateCompressionRatio(entry);
      entries[entry.name] = entry;
    }

    final manifestEntry = entries[_manifestName];
    if (manifestEntry == null) {
      throw AppBackupException('Backup manifest is missing.');
    }
    if (manifestEntry.size > limits.maxManifestBytes) {
      throw AppBackupException('Backup manifest is too large.');
    }
    late final BackupManifest manifest;
    try {
      final decoded = jsonDecode(utf8.decode(_entryBytes(manifestEntry)));
      if (decoded is! Map) {
        throw AppBackupException('Backup manifest is invalid.');
      }
      manifest = BackupManifest.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      if (error is AppBackupException) rethrow;
      throw AppBackupException('Backup manifest is damaged.');
    }
    if (manifest.schemaVersion != BackupManifest.currentSchemaVersion) {
      throw AppBackupException(
          'Unsupported backup version ${manifest.schemaVersion}.');
    }
    if (manifest.packageName != BackupManifest.expectedPackageName) {
      throw AppBackupException('This backup belongs to a different app.');
    }

    final manifestPaths = <String>{};
    final normalizedManifestPaths = <String>{};
    var manifestTotal = 0;
    for (final file in manifest.files) {
      if (!file.path.startsWith(_documentsPrefix) ||
          !_isSafeRelativePath(file.path.substring(_documentsPrefix.length))) {
        throw AppBackupException('Backup contains an unsafe file path.');
      }
      if (!manifestPaths.add(file.path)) {
        throw AppBackupException('Backup manifest contains a duplicate path.');
      }
      if (!normalizedManifestPaths.add(_normalizedArchiveKey(file.path))) {
        throw AppBackupException(
            'Backup manifest contains duplicate normalized paths.');
      }
      if (file.size < 0 || file.size > limits.maxSingleFileBytes) {
        throw AppBackupException(
            'Backup manifest contains an invalid file size.');
      }
      manifestTotal += file.size;
      if (manifestTotal > limits.maxTotalUncompressedBytes) {
        throw AppBackupException(
            'Backup manifest exceeds the safe total size.');
      }
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(file.sha256)) {
        throw AppBackupException(
            'Backup manifest contains an invalid checksum.');
      }
      final entry = entries[file.path];
      if (entry == null) {
        throw AppBackupException('Backup is missing ${file.path}.');
      }
      final bytes = _entryBytes(entry);
      if (bytes.length != file.size) {
        throw AppBackupException('Backup size check failed for ${file.path}.');
      }
      if (sha256.convert(bytes).toString() != file.sha256) {
        throw AppBackupException(
            'Backup checksum check failed for ${file.path}.');
      }
    }

    final documentPaths =
        entries.keys.where((name) => name.startsWith(_documentsPrefix)).toSet();
    if (documentPaths.length != manifestPaths.length ||
        !documentPaths.containsAll(manifestPaths)) {
      throw AppBackupException(
          'Backup contains a file that is not authenticated by its manifest.');
    }
    return manifest;
  }

  void _validateCompressionRatio(ArchiveFile entry) {
    if (entry.size == 0) return;
    final compressedSize = entry.rawContent?.length ?? entry.size;
    if (compressedSize <= 0 ||
        entry.size / compressedSize > limits.maxCompressionRatio) {
      throw AppBackupException('Backup contains an unsafe compression ratio.');
    }
  }

  Future<void> _extractDocuments(Archive archive, Directory documents) async {
    for (final entry in archive.files) {
      if (!entry.name.startsWith(_documentsPrefix)) continue;
      final relative = entry.name.substring(_documentsPrefix.length);
      final destination =
          File(p.joinAll([documents.path, ...relative.split('/')]));
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(_entryBytes(entry), flush: true);
    }
  }

  /// Share files remain for 24 hours so Android receivers can consume them.
  /// Failed rollback snapshots remain for 30 days for possible manual recovery.
  Future<void> cleanupStaleTemporaryBackups({String? preservePath}) async {
    final temp = await _temporaryDirectory();
    if (!await temp.exists()) return;
    final now = _now();
    await for (final entity in temp.list(followLinks: false)) {
      if (entity is File &&
          p.basename(entity.path).startsWith(_portablePrefix)) {
        await _deleteIfStale(entity, now, _portableRetention,
            preservePath: preservePath);
      }
    }
    final safetyDir = Directory(p.join(temp.path, _safetyDirectoryName));
    if (!await safetyDir.exists()) return;
    await for (final entity in safetyDir.list(followLinks: false)) {
      if (entity is File) {
        await _deleteIfStale(entity, now, _failedSafetyRetention,
            preservePath: preservePath);
      }
    }
  }

  Future<void> _deleteIfStale(File file, DateTime now, Duration retention,
      {String? preservePath}) async {
    if (preservePath != null && p.equals(file.path, preservePath)) return;
    try {
      if (now.difference(await file.lastModified()) > retention) {
        await file.delete();
      }
    } catch (_) {
      // Best effort: cleanup must not block a user backup or restore.
    }
  }

  Future<void> _deleteIfPresent(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Stale cleanup retries later.
    }
  }

  Future<void> _flushKnownHiveBoxes() async {
    for (final name in _knownHiveBoxes) {
      if (!Hive.isBoxOpen(name)) continue;
      try {
        await Hive.box<dynamic>(name).flush();
      } catch (_) {
        // Hive has already persisted typed-box writes.
      }
    }
  }

  Future<void> _clearDirectory(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      return;
    }
    await for (final entity in directory.list(followLinks: false)) {
      await entity.delete(recursive: true);
    }
  }

  static bool _isSafeRelativePath(String value) {
    if (value.isEmpty) return false;
    final normalized = value.replaceAll('\\', '/');
    if (normalized.startsWith('/') ||
        normalized.contains('\u0000') ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
      return false;
    }
    return !normalized.split('/').any(
          (segment) => segment.isEmpty || segment == '..' || segment == '.',
        );
  }

  static String _normalizedArchiveKey(String value) =>
      value.replaceAll('\\', '/').toLowerCase();
  static String _zipPath(String value) => value.replaceAll('\\', '/');

  static Uint8List _entryBytes(ArchiveFile entry) {
    final content = entry.content;
    if (content is Uint8List) return content;
    if (content is List<int>) return Uint8List.fromList(content);
    throw AppBackupException('Backup entry ${entry.name} cannot be read.');
  }
}
