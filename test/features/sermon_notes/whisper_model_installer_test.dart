import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';
import 'package:simple_bible_app/features/sermon_notes/services/whisper_model_installer.dart';

class _Backend implements WhisperModelBackend {
  bool installed = false;
  bool failInstall = false;
  int installs = 0;
  List<int>? bytes;

  @override
  Future<bool> hasVerifiedModel() async => installed;
  @override
  Future<void> installVerifiedModel(String privateCachePath) async {
    if (failInstall) throw const FileSystemException('No space');
    bytes = await File(privateCachePath).readAsBytes();
    installs++;
    installed = true;
  }

  @override
  Future<bool> deleteModel() async {
    installed = false;
    return true;
  }
}

void main() {
  late Directory directory;
  late _Backend backend;
  const weights = <int>[1, 2, 3, 4, 5, 6];
  final artifact = WhisperModelArtifact('https://example.invalid/pinned-model',
      sha256.convert(weights).toString(), weights.length);

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('whisper-installer-test-');
    backend = _Backend();
  });
  tearDown(() async => directory.delete(recursive: true));

  WhisperModelInstaller installer(http.Client Function() clientFactory,
      {Future<Directory> Function()? cacheDirectory}) {
    final manager = WhisperModelInstaller.testing(backend,
        artifact: artifact,
        clientFactory: clientFactory,
        cacheDirectory: cacheDirectory ?? () async => directory);
    addTearDown(manager.dispose);
    return manager;
  }

  File partial() =>
      File('${directory.path}/whisper-download/${artifact.sha256}.part');

  test('Flutter and native trust the same pinned artifact', () async {
    final source = await File(
            'android/app/src/main/kotlin/org/thewordapp/mobile/OfflineWhisperChannel.kt')
        .readAsString();
    expect(
        source,
        contains(
            'MODEL_SHA256 = "${WhisperModelArtifact.baseEnglish.sha256}"'));
    expect(source,
        contains('MODEL_BYTES = ${WhisperModelArtifact.baseEnglish.bytes}L'));
    expect(WhisperModelArtifact.baseEnglish.url,
        contains('/5359861c739e955e79d9a303bcbc70fb988958b1/'));
  });

  test('separate sermon screens cannot concurrently mutate download storage',
      () async {
    final response = Completer<http.Response>();
    final first = installer(() => MockClient((_) => response.future));
    final operation = first.install();
    final second = installer(
        () => MockClient((_) async => http.Response.bytes(weights, 200)));
    await second.install();
    expect(second.state, WhisperModelState.failed);
    expect(second.message, contains('already running'));
    response.complete(http.Response.bytes(weights, 200));
    await operation;
    expect(first.state, WhisperModelState.ready);
    expect(backend.installs, 1);
  });

  test('native storage errors are presented as storage failures', () async {
    final manager = installer(
        () => MockClient((_) async => http.Response.bytes(weights, 200)));
    backend.failInstall = true;
    await manager.install();
    expect(manager.message, contains('storage'));
  });

  test('successful installation streams, verifies, installs, and clears cache',
      () async {
    final states = <WhisperModelState>[];
    final manager = installer(() => MockClient.streaming((request, _) async {
          expect(request.url.toString(), artifact.url);
          return http.StreamedResponse(
              Stream.fromIterable([weights.sublist(0, 2), weights.sublist(2)]),
              200,
              contentLength: weights.length);
        }));
    manager.addListener(() => states.add(manager.state));
    await manager.install();
    expect(manager.state, WhisperModelState.ready);
    expect(backend.bytes, weights);
    expect(await partial().exists(), isFalse);
    expect(
        states,
        containsAllInOrder([
          WhisperModelState.downloading,
          WhisperModelState.verifying,
          WhisperModelState.installing,
          WhisperModelState.ready,
        ]));
  });

  test(
      'checksum mismatch never reaches native installation and removes corrupt file',
      () async {
    final manager = installer(() =>
        MockClient((_) async => http.Response.bytes([6, 5, 4, 3, 2, 1], 200)));
    await manager.install();
    expect(manager.state, WhisperModelState.failed);
    expect(backend.installs, 0);
    expect(await partial().exists(), isFalse);
  });

  test(
      'interrupted stream is recovered by a new installer with validated Range',
      () async {
    final first = installer(() => MockClient.streaming((_, body) async =>
        http.StreamedResponse(Stream<List<int>>.multi((controller) {
          controller.add(weights.sublist(0, 2));
          controller.addError(const SocketException('Disconnected'));
          controller.close();
        }), 200, contentLength: weights.length)));
    await first.install();
    expect(first.state, WhisperModelState.failed);
    expect(await partial().length(), 2);
    final recovered = installer(() => MockClient.streaming((request, _) async {
          expect(request.headers['Range'], 'bytes=2-');
          return http.StreamedResponse(Stream.value(weights.sublist(2)), 206,
              contentLength: 4, headers: {'content-range': 'bytes 2-5/6'});
        }));
    await recovered.install();
    expect(recovered.state, WhisperModelState.ready);
    expect(backend.bytes, weights);
  });

  test('cancellation deletes partial bytes and never installs', () async {
    late WhisperModelInstaller manager;
    manager = installer(() => MockClient.streaming((_, body) async =>
        http.StreamedResponse(
            Stream.fromIterable([weights.sublist(0, 2), weights.sublist(2)]),
            200,
            contentLength: weights.length)));
    manager.addListener(() {
      if (manager.receivedBytes == 2 && manager.canCancel) manager.cancel();
    });
    await manager.install();
    expect(manager.state, WhisperModelState.notInstalled);
    expect(backend.installs, 0);
    expect(await partial().exists(), isFalse);
  });

  test('cancellation aborts a real HTTP response that stalls', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final releaseServer = Completer<void>();
    final serverFlushed = Completer<void>();
    addTearDown(() async {
      if (!releaseServer.isCompleted) releaseServer.complete();
      await server.close(force: true);
    });
    server.listen((request) async {
      await request.drain<void>();
      request.response.bufferOutput = false;
      request.response.contentLength = weights.length;
      request.response.add(weights.sublist(0, 2));
      await request.response.flush();
      serverFlushed.complete();
      await releaseServer.future;
      await request.response.close();
    });
    final manager = WhisperModelInstaller.testing(backend,
        artifact: WhisperModelArtifact('http://127.0.0.1:${server.port}/model',
            artifact.sha256, weights.length),
        clientFactory: () =>
            IOClient(HttpClient()..findProxy = (_) => 'DIRECT'),
        cacheDirectory: () async => directory);
    addTearDown(manager.dispose);
    final operation = manager.install();
    await serverFlushed.future.timeout(const Duration(seconds: 5));
    manager.cancel();
    await operation.timeout(const Duration(seconds: 5));
    expect(manager.state, WhisperModelState.notInstalled);
    expect(await partial().exists(), isFalse);
    expect(backend.installs, 0);
  });

  test('cache storage failure produces a recoverable Failed state', () async {
    final blockingFile = File('${directory.path}/file');
    await blockingFile.writeAsString('not a directory');
    final manager = installer(
        () => MockClient((_) async => http.Response.bytes(weights, 200)),
        cacheDirectory: () async => Directory(blockingFile.path));
    await manager.install();
    expect(manager.state, WhisperModelState.failed);
    expect(manager.message, contains('storage'));
    expect(backend.installs, 0);
  });

  test(
      'native storage failure can retry a fully verified download without network',
      () async {
    backend.failInstall = true;
    var requests = 0;
    final manager = installer(() => MockClient((_) async {
          requests++;
          return http.Response.bytes(weights, 200);
        }));
    await manager.install();
    expect(manager.state, WhisperModelState.failed);
    backend.failInstall = false;
    await manager.install();
    expect(manager.state, WhisperModelState.ready);
    expect(requests, 1);
  });

  test('repeated and concurrent installation is idempotent', () async {
    var requests = 0;
    final manager = installer(() => MockClient((_) async {
          requests++;
          return http.Response.bytes(weights, 200);
        }));
    await Future.wait([manager.install(), manager.install()]);
    await manager.install();
    expect(backend.installs, 1);
    expect(requests, 1);
    expect(manager.state, WhisperModelState.ready);
  });

  test('server ignoring Range restarts instead of appending', () async {
    await partial().parent.create(recursive: true);
    await partial().writeAsBytes(weights.sublist(0, 2));
    final manager = installer(
        () => MockClient((_) async => http.Response.bytes(weights, 200)));
    await manager.install();
    expect(manager.state, WhisperModelState.ready);
    expect(backend.bytes, weights);
  });

  test('invalid Content-Range cannot install or retain corrupt resume data',
      () async {
    await partial().parent.create(recursive: true);
    await partial().writeAsBytes(weights.sublist(0, 2));
    final manager = installer(() => MockClient.streaming((_, body) async =>
        http.StreamedResponse(Stream.value(weights.sublist(2)), 206,
            headers: {'content-range': 'bytes 1-4/6'})));
    await manager.install();
    expect(manager.state, WhisperModelState.failed);
    expect(backend.installs, 0);
    expect(await partial().exists(), isFalse);
  });

  test('delete removes model and resumable cache', () async {
    backend.installed = true;
    await partial().parent.create(recursive: true);
    await partial().writeAsBytes([1, 2]);
    final manager =
        installer(() => MockClient((_) async => http.Response('', 500)));
    await manager.check();
    expect(manager.state, WhisperModelState.ready);
    await manager.delete();
    expect(manager.state, WhisperModelState.notInstalled);
    expect(backend.installed, isFalse);
    expect(await partial().exists(), isFalse);
  });
}
