import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/utils/color_utils.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _navigated = false;

  // Maximum splash duration (video or animation)
  final Duration _maxSplashDuration = const Duration(seconds: 9);
  Duration _videoCutoff = Duration.zero;

  final List<Offset> _particles = [];
  final int _particleCount = 18;
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 33),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 27),
    ]).animate(_controller);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.8, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 33),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.03)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.03, end: 1.08)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 27),
    ]).animate(_controller);

    _glowAnim = Tween<double>(begin: 4.0, end: 28.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.333, 0.733, curve: Curves.easeInOut),
      ),
    );

    for (var i = 0; i < _particleCount; i++) {
      _particles.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishSplash();
      }
    });

    // The web video plugin can retain browser callbacks across hot restarts.
    // Use the lightweight animated splash there and keep video on mobile.
    if (kIsWeb) {
      _controller.forward();
    } else {
      _attemptPlayVideo();
    }
  }

  Future<void> _attemptPlayVideo() async {
    VideoPlayerController? videoController;
    try {
      videoController = VideoPlayerController.asset(
          'assets/videos/the_word_landing_page.mp4');
      _videoController = videoController;
      await videoController.initialize();
      // Mute to allow autoplay on web and other platforms
      await videoController.setVolume(0.0);
      await videoController.setLooping(false);

      // Determine a cutoff so we never show the splash longer than [_maxSplashDuration].
      final dur = videoController.value.duration;
      _videoCutoff = (dur > Duration.zero && dur < _maxSplashDuration)
          ? dur
          : _maxSplashDuration;

      if (!mounted || !identical(_videoController, videoController)) return;
      setState(() {
        _isVideoReady = true;
      });

      videoController.addListener(_handleVideoProgress);
      await videoController.play();
    } catch (_) {
      videoController?.removeListener(_handleVideoProgress);
      if (identical(_videoController, videoController)) {
        _videoController = null;
        await videoController?.dispose();
      }
      if (!mounted) return;
      setState(() {
        _isVideoReady = false;
      });
      _controller.forward();
    }
  }

  void _handleVideoProgress() {
    final videoController = _videoController;
    if (videoController == null || !videoController.value.isInitialized) return;

    final endThreshold = _videoCutoff - const Duration(milliseconds: 200);
    if (videoController.value.position >= endThreshold) {
      _finishSplash();
    }
  }

  void _finishSplash() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final videoController = _videoController;
    if (videoController != null) {
      videoController.removeListener(_handleVideoProgress);
      unawaited(videoController.pause());
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  void dispose() {
    final videoController = _videoController;
    _videoController = null;
    videoController?.removeListener(_handleVideoProgress);
    _controller.dispose();
    if (videoController != null) {
      unawaited(videoController.dispose());
    }
    super.dispose();
  }

  Widget _buildParticles(Size size) {
    return Stack(
      children: List.generate(_particleCount, (i) {
        final pos = _particles[i];
        final dx = pos.dx * size.width;
        final dy = pos.dy * size.height * 0.85 + size.height * 0.05;
        final phase = (i / _particleCount) * 2 * pi;
        final v = _controller.value;
        final t = sin((v * 2 * pi * 1.2) + phase) * 0.5 + 0.5;
        final opacity =
            (0.15 + (t * 0.6)).clamp(0.0, 1.0) * (v < 0.05 ? (v / 0.05) : 1.0);
        final sizeDot = 1.5 + (t * 2.5);
        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: sizeDot,
              height: sizeDot,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // If a bundled video was initialized successfully, show it (cover).
    if (_isVideoReady &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      final v = _videoController!;
      return Scaffold(
        body: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: v.value.size.width,
              height: v.value.size.height,
              child: VideoPlayer(v),
            ),
          ),
        ),
      );
    }

    // Fallback: original animated splash
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF120018), Color(0xFF0B0426)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildParticles(size),

                // Radiating radial glow behind the logo
                Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: 420 * _scaleAnim.value,
                    height: 420 * _scaleAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          applyOpacity(
                              Colors.amber, 0.22 * (_glowAnim.value / 28.0)),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                        center: Alignment.center,
                      ),
                    ),
                  ),
                ),

                // Logo with subtle scale + glowing shadow (responsive width)
                Opacity(
                  opacity: _opacityAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: applyOpacity(
                                Colors.amber, 0.9 * (_glowAnim.value / 28.0)),
                            blurRadius: _glowAnim.value,
                            spreadRadius: _glowAnim.value / 4,
                          ),
                        ],
                      ),
                      child: Builder(builder: (context) {
                        final logoWidth = min(240.0, size.width * 0.6);
                        return Image.asset(
                          AppBranding.logoAsset,
                          width: logoWidth,
                          fit: BoxFit.contain,
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
