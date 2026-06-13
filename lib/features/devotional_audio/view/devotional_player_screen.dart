import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/state/app_state.dart';
import '../../devotional/model/devotional_model.dart';
import '../models/devotional_audio_session.dart';
import '../services/devotional_audio_service.dart';
import '../widgets/stage_progress.dart';
import '../widgets/devotional_waveform.dart';
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

  // Gradient colours that shift per stage
  static const _stageGradients = {
    DevotionalStage.scripture:    [Color(0xFF0F0C29), Color(0xFF302B63)],
    DevotionalStage.understanding:[Color(0xFF1A1A2E), Color(0xFF16213E)],
    DevotionalStage.deepInsight:  [Color(0xFF200122), Color(0xFF6f0000)],
    DevotionalStage.keyTruth:     [Color(0xFF0F2027), Color(0xFF203A43)],
    DevotionalStage.reflection:   [Color(0xFF1a3a1a), Color(0xFF0d1f0d)],
    DevotionalStage.prayer:       [Color(0xFF1a0533), Color(0xFF2d0b5c)],
    DevotionalStage.journal:      [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
    DevotionalStage.completed:    [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
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
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _audioService.removeListener(_onServiceChange);
    _audioService.dispose();
    super.dispose();
  }

  List<Color> _gradientForStage(DevotionalStage stage) =>
      _stageGradients[stage] ?? [const Color(0xFF1E1E2C), const Color(0xFF1E1E2C)];

  @override
  Widget build(BuildContext context) {
    final state   = AppScope.of(context);
    final session = _audioService.session;
    if (session == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isPlaying    = state.narrationController.isPlaying;
    final gradient     = _gradientForStage(session.currentStage);
    final stageText    = _getStageText(session.currentStage, widget.devotional);
    final headingText  = _getStageHeading(session.currentStage, widget.devotional);

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
              // ── Top bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 22),
                      onPressed: () {
                        state.narrationController.stop();
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        session.ambientMode ? Icons.self_improvement : Icons.self_improvement_outlined,
                        color: Colors.white60,
                        size: 22,
                      ),
                      onPressed: _audioService.toggleAmbientMode,
                      tooltip: 'Ambient Mode',
                    ),
                  ],
                ),
              ),

              // ── Stage progress ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StageProgress(currentStage: session.currentStage),
              ),

              // ── Central content area ─────────────────────────────────
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Breathing orb fills entire area
                    const Positioned.fill(
                      child: DevotionalWaveform(isPlaying: true),
                    ),

                    // Text content sits on top
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Optional short heading for the stage
                            if (headingText.isNotEmpty) ...[
                              Text(
                                headingText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              stageText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w300,
                                height: 1.7,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Controls ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 40, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replay
                    _ControlButton(
                      icon: Icons.replay_10,
                      size: 26,
                      opacity: 0.4,
                      onTap: () {},
                    ),
                    const SizedBox(width: 36),

                    // Play / Pause
                    GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          state.narrationController.pause();
                        } else {
                          state.narrationController.resume();
                        }
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(width: 36),

                    // Forward
                    _ControlButton(
                      icon: Icons.forward_10,
                      size: 26,
                      opacity: 0.4,
                      onTap: () {},
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
      case DevotionalStage.scripture:     return dev.scriptureReference;
      case DevotionalStage.understanding: return dev.sections.isNotEmpty ? dev.sections.first.heading : '';
      case DevotionalStage.deepInsight:   return dev.sections.length > 1 ? dev.sections[1].heading : '';
      case DevotionalStage.keyTruth:      return 'KEY TRUTH';
      case DevotionalStage.reflection:    return 'REFLECT';
      case DevotionalStage.prayer:        return 'PRAYER';
      default: return '';
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
        return dev.reflectionQuestions.isNotEmpty ? dev.reflectionQuestions.first : '';
      case DevotionalStage.prayer:
        return dev.prayer;
      case DevotionalStage.journal:
      case DevotionalStage.completed:
        return 'Preparing your journal…';
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double opacity;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.opacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white.withValues(alpha: opacity), size: size),
    );
  }
}
