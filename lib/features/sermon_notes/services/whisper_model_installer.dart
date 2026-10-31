import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Reviewed, immutable artifact. See docs/whisper-model-provenance.md.
class WhisperModelArtifact {
  const WhisperModelArtifact(this.url, this.sha256, this.bytes);

  final String url;
  final String sha256;
  final int bytes;

  static const baseEnglish = WhisperModelArtifact(
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/'
        '5359861c739e955e79d9a303bcbc70fb988958b1/ggml-base.en.bin',
    'a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002',
    147964211,
  );
}

abstract interface class WhisperModelBackend {
  Future<bool> hasVerifiedModel();
  Future<void> installVerifiedModel(String privateCachePath);
  Future<bool> deleteModel();
}

class WhisperModelStorageException implements Exception {
  const WhisperModelStorageException();
}

enum WhisperModelState {
  notInstalled('Not Installed'),
  downloading('Downloading'),
  verifying('Verifying'),
  installing('Installing'),
  ready('Ready'),
  failed('Failed');

  const WhisperModelState(this.label);
  final String label;
}

/// Downloads only model weights. No recording paths or audio enter this class.
/// A failed transfer is resumable; every resumed file is verified in full.
class WhisperModelInstaller extends ChangeNotifier {
  static WhisperModelInstaller? _activeInstaller;
  WhisperModelInstaller(this.backend)
      : artifact = WhisperModelArtifact.baseEnglish,
        _clientFactory = http.Client.new,
        _cacheDirectory = getTemporaryDirectory;

  @visibleForTesting
  WhisperModelInstaller.testing(
    this.backend, {
    required this.artifact,
    required http.Client Function() clientFactory,
    required Future<Directory> Function() cacheDirectory,
  })  : _clientFactory = clientFactory,
        _cacheDirectory = cacheDirectory;

  final WhisperModelBackend backend;
  final WhisperModelArtifact artifact;
  final http.Client Function() _clientFactory;
  final Future<Directory> Function() _cacheDirectory;
  WhisperModelState state = WhisperModelState.notInstalled;
  String? message;
  int receivedBytes = 0;
  bool _busy = false;
  bool _cancelled = false;
  bool _disposed = false;
  http.Client? _client;
  Completer<void>? _abort;

  bool get busy => _busy;
  bool get canCancel => _busy && state == WhisperModelState.downloading;
  double get progress => (receivedBytes / artifact.bytes).clamp(0, 1);

  void _update(WhisperModelState value, [String? detail]) {
    state = value;
    message = detail;
    if (!_disposed) notifyListeners();
  }

  Future<void> check() async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      _update(WhisperModelState.verifying, 'Checking your offline model…');
      final installed = await backend.hasVerifiedModel();
      _update(
          installed ? WhisperModelState.ready : WhisperModelState.notInstalled);
    } catch (_) {
      _update(
          WhisperModelState.failed, 'Could not check the model. Please retry.');
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<File> _partialFile() async {
    final cache = await _cacheDirectory();
    final directory = Directory('${cache.path}/whisper-download');
    await directory.create(recursive: true);
    return File('${directory.path}/${artifact.sha256}.part');
  }

  void _checkCancellation() {
    if (_cancelled || _disposed) throw const _ModelDownloadCancelled();
  }

  Future<void> install() async {
    if (_busy || _disposed) return;
    if (_activeInstaller != null && !identical(_activeInstaller, this)) {
      _update(WhisperModelState.failed,
          'A model installation is already running in another sermon.');
      return;
    }
    _activeInstaller = this;
    _busy = true;
    _cancelled = false;
    _abort = Completer<void>();
    File? partial;
    RandomAccessFile? output;
    try {
      _update(WhisperModelState.verifying, 'Checking for an installed model…');
      if (await backend.hasVerifiedModel()) {
        _update(WhisperModelState.ready);
        return;
      }
      _checkCancellation();
      partial = await _partialFile();
      receivedBytes = await partial.exists() ? await partial.length() : 0;
      if (receivedBytes > artifact.bytes) {
        await partial.delete();
        receivedBytes = 0;
      }
      _update(
          WhisperModelState.downloading,
          receivedBytes > 0
              ? 'Resuming your download…'
              : 'Downloading English recognition…');
      if (receivedBytes < artifact.bytes) {
        _client = _clientFactory();
        final request = http.AbortableRequest('GET', Uri.parse(artifact.url),
            abortTrigger: _abort!.future);
        request.headers['Accept-Encoding'] = 'identity';
        if (receivedBytes > 0) {
          request.headers['Range'] = 'bytes=$receivedBytes-';
        }
        final response =
            await _client!.send(request).timeout(const Duration(seconds: 30));
        _checkCancellation();
        if (response.statusCode == 200) {
          receivedBytes = 0; // Server ignored Range: restart, never append.
        } else if (response.statusCode == 206 && receivedBytes > 0) {
          final expected =
              'bytes $receivedBytes-${artifact.bytes - 1}/${artifact.bytes}';
          if (response.headers['content-range'] != expected) {
            throw const FormatException('Invalid resumed download range');
          }
        } else {
          throw HttpException(
              'Download server returned ${response.statusCode}');
        }
        final remaining = artifact.bytes - receivedBytes;
        if (response.contentLength != null &&
            response.contentLength != remaining) {
          throw const FormatException('Unexpected model download size');
        }
        output = await partial.open(
            mode: receivedBytes == 0 ? FileMode.write : FileMode.append);
        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 30))) {
          _checkCancellation();
          if (receivedBytes + chunk.length > artifact.bytes) {
            throw const FormatException('Model download exceeds expected size');
          }
          await output.writeFrom(chunk);
          receivedBytes += chunk.length;
          if (!_disposed) notifyListeners();
        }
        await output.flush();
        await output.close();
        output = null;
      }
      _checkCancellation();
      if (receivedBytes != artifact.bytes) {
        throw const HttpException('Download interrupted');
      }
      _update(WhisperModelState.verifying, 'Checking model integrity…');
      final digest = await sha256.bind(partial.openRead()).first;
      _checkCancellation();
      if (digest.toString() != artifact.sha256) {
        await partial.delete();
        throw const FormatException('Model checksum mismatch');
      }
      _update(WhisperModelState.installing, 'Securing your offline model…');
      await backend.installVerifiedModel(partial.path);
      // Cache cleanup must not turn a completed atomic install into a failure.
      try {
        await partial.delete();
      } on FileSystemException {
        // A later Delete Model or cache eviction can remove this verified copy.
      }
      _update(WhisperModelState.ready);
    } catch (error) {
      try {
        await output?.close();
      } on FileSystemException {
        // Preserve the original storage/transfer failure for the UI.
      }
      output = null;
      if (_cancelled || _disposed || error is _ModelDownloadCancelled) {
        await _discard(partial);
        receivedBytes = 0;
        _update(WhisperModelState.notInstalled,
            'Download cancelled. You can install it anytime.');
      } else {
        // Keep a bounded partial transfer for Retry/process-death recovery.
        // Invalid full downloads must not cause an endless verification loop.
        if (error is FormatException) {
          await _discard(partial);
        }
        _update(
            WhisperModelState.failed,
            error is FileSystemException ||
                    error is WhisperModelStorageException
                ? 'Not enough storage or storage is unavailable. Free some space and retry.'
                : error is FormatException
                    ? 'The model could not be verified. Retry to download a fresh copy.'
                    : 'Installation interrupted. Check your connection and retry.');
      }
    } finally {
      _client?.close();
      _client = null;
      _abort = null;
      _busy = false;
      if (identical(_activeInstaller, this)) _activeInstaller = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _discard(File? file) async {
    try {
      if (file != null && await file.exists()) await file.delete();
    } on FileSystemException {
      // Retry still verifies the full file; leftover bytes are never trusted.
    }
  }

  void cancel() {
    if (!canCancel) return;
    _cancelled = true;
    if (!(_abort?.isCompleted ?? true)) _abort!.complete();
    _client?.close();
  }

  Future<void> delete() async {
    if (_busy || _disposed) return;
    if (_activeInstaller != null) {
      _update(WhisperModelState.failed,
          'Finish or cancel the active model download before deleting.');
      return;
    }
    _activeInstaller = this;
    _busy = true;
    try {
      if (!await backend.deleteModel()) {
        throw const FileSystemException('Delete failed');
      }
      final partial = await _partialFile();
      if (await partial.exists()) await partial.delete();
      receivedBytes = 0;
      _update(WhisperModelState.notInstalled);
    } catch (_) {
      _update(WhisperModelState.failed,
          'Could not delete the model. Please retry.');
    } finally {
      _busy = false;
      if (identical(_activeInstaller, this)) _activeInstaller = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    cancel();
    _disposed = true;
    super.dispose();
  }
}

class _ModelDownloadCancelled implements Exception {
  const _ModelDownloadCancelled();
}
