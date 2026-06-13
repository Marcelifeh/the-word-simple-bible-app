import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/narration_session.dart';
import '../models/narration_state.dart';
import '../models/narration_sync_state.dart';

class NarrationSyncEngine {
  NarrationSyncEngine({
    Duration debounceDuration = const Duration(milliseconds: 200),
  })  : _debounceDuration = debounceDuration,
        state = ValueNotifier<NarrationSyncState>(NarrationSyncState.idle());

  final Duration _debounceDuration;
  final ValueNotifier<NarrationSyncState> state;

  Timer? _debounceTimer;
  NarrationSyncState? _pendingState;

  void syncSession(NarrationSession? session, {required bool autoScroll}) {
    if (session == null) {
      _emitNow(NarrationSyncState.idle(autoScroll: autoScroll));
      return;
    }

    _schedule(
      NarrationSyncState(
        sessionId: session.id,
        segmentId: session.currentSegment?.id,
        currentIndex: session.currentIndex,
        progress: session.progress,
        status: session.status,
        autoScroll: autoScroll,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void updateAutoScroll(bool enabled) {
    _schedule(
      state.value.copyWith(
        autoScroll: enabled,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _schedule(NarrationSyncState nextState) {
    final shouldEmitImmediately = nextState.status == NarrationStatus.idle ||
        nextState.status == NarrationStatus.completed ||
        nextState.status == NarrationStatus.error;
    if (shouldEmitImmediately) {
      _emitNow(nextState);
      return;
    }

    _pendingState = nextState;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final pending = _pendingState;
      if (pending != null) {
        _emitNow(pending);
      }
    });
  }

  void _emitNow(NarrationSyncState nextState) {
    _debounceTimer?.cancel();
    _pendingState = null;
    state.value = nextState;
  }

  void dispose() {
    _debounceTimer?.cancel();
    state.dispose();
  }
}