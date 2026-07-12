import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contracts/narratable_content.dart';
import '../models/narration_event.dart';
import '../models/narration_preferences.dart';
import '../models/narration_profile.dart';
import '../models/narration_session.dart';
import '../models/narration_state.dart';
import '../models/narration_sync_state.dart';
import '../models/narration_voice.dart';
import '../models/saved_voice.dart';
import 'narration_cache_service.dart';
import 'narration_preferences_service.dart';
import 'narration_queue.dart';
import 'narration_service.dart';
import 'narration_sync_engine.dart';

class NarrationController extends ChangeNotifier {
  NarrationController(
    this._narrationService, {
    required NarrationPreferencesService preferencesService,
    required NarrationSyncEngine syncEngine,
    required NarrationCacheService cacheService,
  })  : _preferencesService = preferencesService,
        _syncEngine = syncEngine,
        _cacheService = cacheService {
    _setupHandlers();
  }

  final NarrationService _narrationService;
  final NarrationQueue queue = NarrationQueue();
  final NarrationPreferencesService _preferencesService;
  final NarrationSyncEngine _syncEngine;
  final NarrationCacheService _cacheService;
  final StreamController<NarrationEvent> _events =
      StreamController<NarrationEvent>.broadcast();
  NarrationSession? _currentSession;
  NarrationPreferences _preferences = const NarrationPreferences();
  String _activeProfileId = NarrationProfile.reading.id;
  bool _isStopping = false;
  NarrationSession? get currentSession => _currentSession;
  NarrationPreferences get preferences => _preferences;
  ValueListenable<NarrationSyncState> get syncState => _syncEngine.state;
  Stream<NarrationEvent> get events => _events.stream;
  String get activeProfileId => _activeProfileId;
  bool get isPlaying => _currentSession?.status == NarrationStatus.playing;
  List<NarrationVoice> get availableVoices => _narrationService.availableVoices;

  Future<void> hydratePreferences() async {
    _preferences = _preferencesService.loadPreferences();
    _activeProfileId = _preferencesService.loadActiveProfileId();

    if (_preferences.savedVoice != null) {
      final savedVoice = _preferences.savedVoice!;
      final isAvailable = availableVoices.any((v) => v.id == savedVoice.id);
      if (!isAvailable) {
        final fallback = _narrationService.bestVoiceForLocale(
          savedVoice.locale,
          savedVoice.id,
        );
        if (fallback != null) {
          _preferences = _preferences.copyWith(
            savedVoice: SavedVoice(
              id: fallback.id,
              locale: fallback.locale,
              displayName: fallback.name,
              provider: fallback.provider,
            ),
          );
          await _preferencesService.savePreferences(_preferences);
        } else {
          _emitEvent(
            NarrationEventType.voiceMissing,
            message: savedVoice.id,
          );
        }
      }
    }

    await _narrationService.applyPreferences(_preferences);
    _sync();
    notifyListeners();
  }

  void _setupHandlers() {
    _narrationService.setCompletionHandler(() {
      _handleSegmentCompletion();
    });
    _narrationService.setCancelHandler(() {
      if (_isStopping) {
        return;
      }
      _updateStatus(NarrationStatus.paused);
      _emitEvent(NarrationEventType.paused);
    });
    _narrationService.setErrorHandler((error) {
      final message = '$error';
      final normalizedMessage = message.toLowerCase();
      if (normalizedMessage.contains('interrupted') ||
          normalizedMessage.contains('canceled') ||
          normalizedMessage.contains('cancelled')) {
        debugPrint('Narration interruption ignored: $message');
        return;
      }
      _updateStatus(NarrationStatus.error);
      _emitEvent(NarrationEventType.failed, message: message);
      debugPrint('Narration error: $message');
    });
    _narrationService.setProgressHandler((text, start, end, word) {
      final session = _currentSession;
      if (session == null || session.currentSegment == null) {
        return;
      }
      final denominator = text.isEmpty ? 1 : text.length;
      final segmentProgress = (end / denominator).clamp(0.0, 1.0);
      _currentSession = session.copyWith(
        progress: _sessionProgress(session, segmentProgress: segmentProgress),
      );
      _sync();
    });
  }

  Future<void> updatePreferences(NarrationPreferences newPrefs) async {
    final previous = _preferences;
    _preferences = newPrefs;
    _activeProfileId = newPrefs.profileId;
    await _narrationService.applyPreferences(_preferences);
    await _preferencesService.savePreferences(_preferences);
    await _preferencesService.saveActiveProfileId(_activeProfileId);
    if (_preferences.savedVoice != null &&
        !_narrationService.availableVoices
            .any((voice) => voice.id == _preferences.savedVoice!.id)) {
      _emitEvent(
        NarrationEventType.voiceMissing,
        message: _preferences.savedVoice!.id,
      );
    }
    if (previous.mode != _preferences.mode) {
      _emitEvent(
        NarrationEventType.modeChanged,
        message: _preferences.mode.name,
      );
    }
    if (previous.autoScroll != _preferences.autoScroll) {
      _emitEvent(
        _preferences.autoScroll
            ? NarrationEventType.autoScrollEnabled
            : NarrationEventType.autoScrollDisabled,
      );
    }
    _sync();
    notifyListeners();
  }

  void setVoice(SavedVoice voice) {
    unawaited(updatePreferences(_preferences.copyWith(savedVoice: voice)));
  }

  Future<void> previewVoice(SavedVoice voice) async {
    await _stopUnderlyingSpeech();
    String text;
    final locale = voice.locale.toLowerCase();
    if (locale.startsWith('ha')) {
      text = 'Ubangiji ne makiyayina, ba zan rasa komai ba.';
    } else if (locale.startsWith('ig')) {
      text = 'Jehova bụ onye ọzụzụ atụrụ m; onweghị ihe ga-akọ m.';
    } else if (locale.startsWith('yo')) {
      text = 'Oluwa ni oluṣọ agutan mi; emi ki yio ṣe alaini.';
    } else {
      text = 'The Lord is my shepherd, I shall not want.';
    }

    // Temporarily apply the new voice without saving preferences
    await _narrationService.selectVoiceById(voice.id);
    await _narrationService.speak(text);
  }

  void setAutoScroll(bool enabled) {
    unawaited(updatePreferences(_preferences.copyWith(autoScroll: enabled)));
  }

  void setHighlightVerses(bool enabled) {
    unawaited(
      updatePreferences(_preferences.copyWith(highlightVerses: enabled)),
    );
  }

  void setSpeed(double speed) {
    _activeProfileId = 'custom';
    notifyListeners();
    unawaited(
      updatePreferences(
        _preferences.copyWith(
          speed: speed,
          profileId: _activeProfileId,
        ),
      ),
    );
  }

  void applyProfilePreset(NarrationProfile profile) {
    unawaited(
      updatePreferences(
        _preferences.copyWith(
          speed: profile.speed,
          pitch: profile.pitch,
          mode: profile.mode,
          profileId: profile.id,
        ),
      ),
    );
  }

  Future<void> playContent(
    NarratableContent content, {
    required String id,
    required NarrationSourceType sourceType,
    NarrationMode? mode,
  }) async {
    await _stopUnderlyingSpeech();
    final effectiveMode = mode ?? _preferences.mode;
    _currentSession = NarrationSession(
      id: id,
      sourceType: sourceType,
      mode: effectiveMode,
      segments: content.narrationSegments,
      currentIndex: 0,
      status: NarrationStatus.loading,
      progress: 0,
    );
    _sync();
    notifyListeners();
    await _playCurrentSegment(lifecycleEvent: NarrationEventType.started);
  }

  Future<void> _playCurrentSegment({
    NarrationEventType? lifecycleEvent,
  }) async {
    final session = _currentSession;
    if (session == null || session.segments.isEmpty) {
      return;
    }
    final segment = session.currentSegment;
    if (segment == null) {
      return;
    }
    _currentSession = session.copyWith(
      status: NarrationStatus.playing,
      progress: _sessionProgress(session, segmentProgress: 0),
    );
    _sync();
    notifyListeners();
    if (lifecycleEvent != null) {
      _emitEvent(lifecycleEvent, segmentId: segment.id);
    }
    _emitEvent(NarrationEventType.segmentChanged, segmentId: segment.id);
    await _cacheService.getAudioPath(segment.id);
    await _narrationService.speak(segment.speechText);
  }

  Future<void> pause() async {
    await _narrationService.pause();
    _updateStatus(NarrationStatus.paused);
    _emitEvent(NarrationEventType.paused);
  }

  Future<void> resume() async {
    if (_currentSession != null &&
        _currentSession!.status == NarrationStatus.paused) {
      await _stopUnderlyingSpeech();
      await _playCurrentSegment(lifecycleEvent: NarrationEventType.resumed);
    }
  }

  Future<void> stop() async {
    await _stopUnderlyingSpeech();
    if (_currentSession == null) {
      return;
    }
    _currentSession = _currentSession!.copyWith(
      status: NarrationStatus.idle,
      progress: 0,
    );
    _sync();
    notifyListeners();
  }

  Future<void> skipRelativeSegment(int delta) async {
    final session = _currentSession;
    if (session == null || session.segments.isEmpty) {
      return;
    }

    final targetIndex = (session.currentIndex + delta)
        .clamp(0, session.segments.length - 1)
        .toInt();
    await _stopUnderlyingSpeech();
    final nextSession = session.copyWith(
      currentIndex: targetIndex,
      status: NarrationStatus.loading,
      progress: _sessionProgress(
        session.copyWith(currentIndex: targetIndex),
        segmentProgress: 0,
      ),
    );
    _currentSession = nextSession;
    _sync();
    notifyListeners();
    await _playCurrentSegment();
  }

  Future<void> _stopUnderlyingSpeech() async {
    _isStopping = true;
    try {
      await _narrationService.stop();
    } finally {
      _isStopping = false;
    }
  }

  void _handleSegmentCompletion() async {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    final nextIndex = session.currentIndex + 1;
    if (nextIndex < session.segments.length) {
      _currentSession = session.copyWith(
        currentIndex: nextIndex,
        progress: _sessionProgress(
          session.copyWith(currentIndex: nextIndex),
          segmentProgress: 0,
        ),
      );
      _sync();
      notifyListeners();
      final previousSegment = session.segments[nextIndex - 1];
      if (previousSegment.pauseAfter != null) {
        await Future.delayed(previousSegment.pauseAfter!);
      }
      await _playCurrentSegment();
      return;
    }
    _currentSession = session.copyWith(
      status: NarrationStatus.completed,
      progress: 1.0,
    );
    _sync();
    notifyListeners();
    _emitEvent(NarrationEventType.completed);
    if (_preferences.autoPlayNext && !queue.isEmpty) {
      final nextContent = queue.dequeue();
      if (nextContent != null) {
        unawaited(
          playContent(
            nextContent,
            id: 'queued_${DateTime.now().millisecondsSinceEpoch}',
            sourceType: _currentSession!.sourceType,
            mode: _currentSession!.mode,
          ),
        );
        return;
      }
    }
    _emitEvent(NarrationEventType.queueFinished);
  }

  void _updateStatus(NarrationStatus status) {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    _currentSession = session.copyWith(
      status: status,
      progress: status == NarrationStatus.idle ? 0 : session.progress,
    );
    _sync();
    notifyListeners();
  }

  double _sessionProgress(
    NarrationSession session, {
    required double segmentProgress,
  }) {
    if (session.segments.isEmpty) {
      return 0;
    }
    final base = session.currentIndex / session.segments.length;
    return (base + (segmentProgress / session.segments.length)).clamp(0.0, 1.0);
  }

  void _sync() {
    _syncEngine.syncSession(_currentSession,
        autoScroll: _preferences.autoScroll);
  }

  void _emitEvent(
    NarrationEventType type, {
    String? segmentId,
    String? message,
  }) {
    final session = _currentSession;
    final event = NarrationEvent(
      type: type,
      sessionId: session?.id,
      segmentId: segmentId ?? session?.currentSegment?.id,
      message: message,
    );
    debugPrint(
      'narration_${type.name}: session=${event.sessionId} '
              'segment=${event.segmentId} ${event.message ?? ''}'
          .trim(),
    );
    _events.add(event);
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
