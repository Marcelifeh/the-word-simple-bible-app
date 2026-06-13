import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/narration/services/narration_controller.dart';
import '../../../core/narration/models/narration_event.dart';
import '../../../core/narration/models/narration_state.dart';
import '../../../core/narration/models/narration_segment.dart';
import '../../../core/narration/contracts/narratable_content.dart';
import '../../../features/devotional/model/devotional_model.dart';
import '../models/devotional_audio_session.dart';

class DevotionalAudioService extends ChangeNotifier {
  final NarrationController _narrationController;
  DevotionalAudioSession? _session;
  StreamSubscription? _eventSubscription;

  DevotionalAudioService(this._narrationController) {
    _eventSubscription = _narrationController.events.listen(_handleNarrationEvent);
  }

  DevotionalAudioSession? get session => _session;

  Future<void> startDevotional(DevotionalModel devotional) async {
    _session = DevotionalAudioSession(
      devotionalId: devotional.id,
      currentStage: DevotionalStage.scripture,
      ambientMode: false,
    );
    notifyListeners();

    // Use a custom object that implements NarratableContent
    // or just construct one locally
    final content = _AudioJourneyContent(devotional.audioJourneySegments);

    await _narrationController.playContent(
      content,
      id: 'devotional_${devotional.id}',
      sourceType: NarrationSourceType.devotional,
    );
  }

  void _handleNarrationEvent(NarrationEvent event) {
    if (_session == null) return;

    if (event.type == NarrationEventType.segmentChanged && event.segmentId != null) {
      final stage = _mapSegmentIdToStage(event.segmentId!);
      if (stage != null && stage != _session!.currentStage) {
        _session = _session!.copyWith(currentStage: stage);
        notifyListeners();
      }
    } else if (event.type == NarrationEventType.completed) {
      // Narration is done (prayer is the last segment).
      // Move to journal automatically.
      _session = _session!.copyWith(currentStage: DevotionalStage.journal);
      notifyListeners();
    }
  }
  
  void setStage(DevotionalStage stage) {
    if (_session != null) {
       _session = _session!.copyWith(currentStage: stage);
       notifyListeners();
    }
  }

  void toggleAmbientMode() {
    if (_session != null) {
      _session = _session!.copyWith(ambientMode: !_session!.ambientMode);
      notifyListeners();
    }
  }

  DevotionalStage? _mapSegmentIdToStage(String segmentId) {
    switch (segmentId) {
      case 'stage_scripture': return DevotionalStage.scripture;
      case 'stage_understanding': return DevotionalStage.understanding;
      case 'stage_insight': return DevotionalStage.deepInsight;
      case 'stage_key_truth': return DevotionalStage.keyTruth;
      case 'stage_reflection': return DevotionalStage.reflection;
      case 'stage_prayer': return DevotionalStage.prayer;
      default: return null;
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

class _AudioJourneyContent implements NarratableContent {
  @override
  final List<NarrationSegment> narrationSegments;

  _AudioJourneyContent(this.narrationSegments);
}
