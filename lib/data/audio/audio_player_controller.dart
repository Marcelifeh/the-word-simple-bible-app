import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerController {
  AudioPlayer? _player;

  AudioPlayer get _ensurePlayer => _player ??= AudioPlayer();

  Stream<PlayerState> get playerStateStream => _ensurePlayer.playerStateStream;

  /// Play a URL and return immediately (fire-and-forget).
  Future<void> playUrl(Uri url) async {
    final player = _ensurePlayer;
    await player.setUrl(url.toString());
    await player.play();
  }

  /// Play a URL and wait until playback actually finishes.
  ///
  /// Creates a **fresh** AudioPlayer for each call to work around
  /// a Chrome web issue where reusing the same <audio> element
  /// causes the browser to replay cached audio from the first URL.
  ///
  /// Returns `true` if the audio played to completion,
  /// `false` if it was stopped/cancelled or errored.
  Future<bool> playUrlUntilDone(Uri url) async {
    // Dispose old player to force a brand-new <audio> element in the DOM
    await _disposePlayer();
    final player = AudioPlayer();
    _player = player;

    try {
      debugPrint('AudioPlayerController: loading $url');
      await player.setUrl(url.toString());

      debugPrint('AudioPlayerController: starting playback');
      // Start playback (don't await — play() may not resolve on web)
      unawaited(player.play());

      // Wait for a terminal state
      await for (final state in player.playerStateStream) {
        final ps = state.processingState;
        debugPrint('AudioPlayerController: state=$ps playing=${state.playing}');
        if (ps == ProcessingState.completed) {
          return true; // Natural end of track
        }
        if (ps == ProcessingState.idle && state.playing == false) {
          // Player was stopped externally (user pressed stop, or error)
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('AudioPlayerController: playUrlUntilDone error: $e');
      return false;
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    final player = _ensurePlayer;
    await player.setLoopMode(mode);
  }

  Future<void> stop() async {
    final player = _player;
    if (player == null) return;
    await player.stop();
  }

  Future<void> _disposePlayer() async {
    final player = _player;
    _player = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {
      // ignore disposal errors
    }
  }

  Future<void> dispose() async {
    await _disposePlayer();
  }
}
