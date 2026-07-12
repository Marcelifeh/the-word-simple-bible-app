import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/narration/models/narration_state.dart';
import '../../../shared/state/app_state.dart';
import '../../devotional/model/devotional_model.dart';
import '../models/devotional_audio_session.dart';
import '../services/devotional_audio_service.dart';
import '../widgets/devotional_waveform.dart';
import '../widgets/stage_progress.dart';
import 'journal_response_screen.dart';

class DevotionalPlayerScreen extends StatefulWidget {
  final DevotionalModel devotional;

  const DevotionalPlayerScreen({super.key, required this.devotional});

  @override
  State<DevotionalPlayerScreen> createState() => _DevotionalPlayerScreenState();
}

class _DevotionalPlayerScreenState extends State<DevotionalPlayerScreen> {
  late DevotionalAudioService _audioService;
  bool _initialized = false;

  static const _stageGradients = {
    DevotionalStage.scripture: [Color(0xFF0F0C29), Color(0xFF302B63)],
    DevotionalStage.understanding: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    DevotionalStage.deepInsight: [Color(0xFF200122), Color(0xFF6F0000)],
    DevotionalStage.keyTruth: [Color(0xFF0F2027), Color(0xFF203A43)],
    DevotionalStage.reflection: [Color(0xFF1A3A1A), Color(0xFF0D1F0D)],
    DevotionalStage.prayer: [Color(0xFF1A0533), Color(0xFF2D0B5C)],
    DevotionalStage.journal: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
    DevotionalStage.completed: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      final state = AppScope.of(context);
      _audioService = DevotionalAudioService(state.narrationController);
      _audioService.startDevotional(widget.devotional);
      _audioService.addListener(_onServiceChange);
      _initialized = true;
    }
  }

  void _onServiceChange() {
    if (!mounted) return;
    final session = _audioService.session;
    if (session != null && session.currentStage == DevotionalStage.journal) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JournalResponseScreen(devotional: widget.devotional),
        ),
      );
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _audioService.removeListener(_onServiceChange);
    _audioService.dispose();
    super.dispose();
  }

  List<Color> _gradientForStage(DevotionalStage stage) =>
      _stageGradients[stage] ??
      [const Color(0xFF1E1E2C), const Color(0xFF1E1E2C)];

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final controller = appState.narrationController;
    final session = _audioService.session;
    if (session == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final narrationSession = controller.currentSession;
    final narrationStatus = narrationSession?.status;
    final isPlaying = narrationStatus == NarrationStatus.playing;
    final isLoading = narrationStatus == NarrationStatus.loading;
    final gradient = _gradientForStage(session.currentStage);
    final stageText = _getStageText(session.currentStage, widget.devotional);
    final headingText =
        _getStageHeading(session.currentStage, widget.devotional);

    return Scaffold(
      backgroundColor: gradient.first,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _PlayerTopBar(
                title: widget.devotional.title,
                ambientMode: session.ambientMode,
                onClose: () {
                  controller.stop();
                  Navigator.pop(context);
                },
                onToggleAmbient: _audioService.toggleAmbientMode,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: StageProgress(currentStage: session.currentStage),
              ),
              const SizedBox(height: 14),
              _PlaybackControls(
                isPlaying: isPlaying,
                isLoading: isLoading,
                onBack: () => controller.skipRelativeSegment(-1),
                onPlayPause: () {
                  if (isLoading) return;
                  if (isPlaying) {
                    controller.pause();
                  } else {
                    controller.resume();
                  }
                },
                onForward: () => controller.skipRelativeSegment(1),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: DevotionalWaveform(isPlaying: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (headingText.isNotEmpty) ...[
                                Text(
                                  headingText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.58),
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              Text(
                                stageText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w300,
                                  height: 1.62,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStageHeading(DevotionalStage stage, DevotionalModel dev) {
    switch (stage) {
      case DevotionalStage.scripture:
        return dev.scriptureReference;
      case DevotionalStage.understanding:
        return dev.sections.isNotEmpty ? dev.sections.first.heading : '';
      case DevotionalStage.deepInsight:
        return dev.sections.length > 1 ? dev.sections[1].heading : '';
      case DevotionalStage.keyTruth:
        return 'KEY TRUTH';
      case DevotionalStage.reflection:
        return 'REFLECT';
      case DevotionalStage.prayer:
        return 'PRAYER';
      default:
        return '';
    }
  }

  String _getStageText(DevotionalStage stage, DevotionalModel dev) {
    switch (stage) {
      case DevotionalStage.scripture:
        return '"${dev.scripture}"';
      case DevotionalStage.understanding:
        return dev.sections.isNotEmpty ? dev.sections.first.body : '';
      case DevotionalStage.deepInsight:
        return dev.sections.length > 1
            ? dev.sections.skip(1).map((e) => e.body).join('\n\n')
            : '';
      case DevotionalStage.keyTruth:
        return dev.finalRevelation;
      case DevotionalStage.reflection:
        return dev.reflectionQuestions.isNotEmpty
            ? dev.reflectionQuestions.first
            : '';
      case DevotionalStage.prayer:
        return dev.prayer;
      case DevotionalStage.journal:
      case DevotionalStage.completed:
        return 'Preparing your journal...';
    }
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({
    required this.title,
    required this.ambientMode,
    required this.onClose,
    required this.onToggleAmbient,
  });

  final String title;
  final bool ambientMode;
  final VoidCallback onClose;
  final VoidCallback onToggleAmbient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close narration',
            icon: const Icon(Icons.close, color: Colors.white70, size: 24),
            onPressed: onClose,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Ambient mode',
            icon: Icon(
              ambientMode
                  ? Icons.self_improvement
                  : Icons.self_improvement_outlined,
              color: Colors.white70,
              size: 23,
            ),
            onPressed: onToggleAmbient,
          ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.isPlaying,
    required this.isLoading,
    required this.onBack,
    required this.onPlayPause,
    required this.onForward,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SkipButton(
            tooltip: 'Previous section',
            icon: Icons.replay_10_rounded,
            onPressed: onBack,
          ),
          const SizedBox(width: 24),
          _PlayButton(
            isPlaying: isPlaying,
            isLoading: isLoading,
            onPressed: onPlayPause,
          ),
          const SizedBox(width: 24),
          _SkipButton(
            tooltip: 'Next section',
            icon: Icons.forward_10_rounded,
            onPressed: onForward,
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: isLoading ? null : onPressed,
      radius: 40,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.5,
          ),
          color: Colors.white.withValues(alpha: 0.13),
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(48),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white.withValues(alpha: 0.78),
      ),
      icon: Icon(icon, size: 24),
    );
  }
}
