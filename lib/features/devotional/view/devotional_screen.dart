import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/animated_stagger_list.dart';
import '../../devotional/model/devotional_model.dart';
import '../../devotional/service/devotional_service.dart';
import 'devotional_detail_screen.dart';
import 'devotional_history_screen.dart';

class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({super.key});

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  final _service = const DevotionalService();
  late DevotionalModel _today;
  late Duration _timeLeft;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _today = _service.getTodaysDevotional();
    _timeLeft = _service.timeUntilNextDevotional;
    // Tick every second to update the countdown.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final newLeft = _service.timeUntilNextDevotional;
      if (newLeft.inSeconds <= 0) {
        // Midnight crossed — refresh the devotional.
        setState(() {
          _today = _service.getTodaysDevotional();
          _timeLeft = _service.timeUntilNextDevotional;
        });
        if (!mounted) return;
        final now = DateTime.now();
        AppScope.of(context).setCurrentDevotional(
          _today,
          activeDate: DateTime(now.year, now.month, now.day),
          stage: DevotionalResumeStage.reading,
        );
      } else {
        setState(() => _timeLeft = newLeft);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    AppScope.of(context).setCurrentDevotional(
      _today,
      activeDate: DateTime(now.year, now.month, now.day),
      stage: DevotionalResumeStage.reading,
    );
  }

  Future<void> _openDevotional(
    DevotionalModel devotional, {
    required DateTime activeDate,
  }) async {
    AppScope.of(context).setCurrentDevotional(
      devotional,
      activeDate: activeDate,
      stage: DevotionalResumeStage.reading,
    );
    await AppRouter.push(
      context,
      DevotionalDetailScreen(
        devotional: devotional,
        activeDate: activeDate,
      ),
      transition: AppTransitionType.devotional,
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _countdownLabel {
    final h = _pad(_timeLeft.inHours);
    final m = _pad(_timeLeft.inMinutes % 60);
    final s = _pad(_timeLeft.inSeconds % 60);
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final todayDate = DateTime.now();
    final normalizedToday =
        DateTime(todayDate.year, todayDate.month, todayDate.day);
    final todayProgress = state.devotionalProgressForDate(normalizedToday);
    final hasStartedToday = todayProgress > 0;
    final hasCompletedToday =
        state.isDevotionalCompletedForDate(normalizedToday);
    final missedDevotional = _findMissedDevotional(state, normalizedToday);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppBranding.logosDevotional),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Devotional history',
            onPressed: () => AppRouter.push(
              context,
              const DevotionalHistoryScreen(),
              transition: AppTransitionType.devotional,
            ),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
        children: [
          // ── Date label ──────────────────────────────────────────────────
          AnimatedStaggerItem(
            index: 0,
            child: _DateLabel(),
          ),
          const SizedBox(height: 16),

          // ── Today's hero card ──────────────────────────────────────────
          AnimatedStaggerItem(
            index: 1,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0.92, end: 1),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: _TodayHeroCard(
                devotional: _today,
                progress: todayProgress,
                hasStartedToday: hasStartedToday,
                hasCompletedToday: hasCompletedToday,
                missedDevotional: missedDevotional,
                onTap: () => _openDevotional(
                  _today,
                  activeDate: normalizedToday,
                ),
                onCatchUpTap: missedDevotional == null
                    ? null
                    : () => _openDevotional(
                          missedDevotional.devotional,
                          activeDate: missedDevotional.date,
                        ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Next devotional countdown ──────────────────────────────────
          AnimatedStaggerItem(
            index: 2,
            child: _CountdownCard(countdown: _countdownLabel),
          ),
        ],
      ),
    );
  }

  _MissedDevotionalEntry? _findMissedDevotional(
    AppState state,
    DateTime today,
  ) {
    var cursor = DateTime(today.year, 1, 1);
    if (cursor.isBefore(DevotionalService.contentStartDate)) {
      cursor = DevotionalService.contentStartDate;
    }

    while (cursor.isBefore(today)) {
      if (!state.isDevotionalCompletedForDate(cursor)) {
        return _MissedDevotionalEntry(
          date: cursor,
          devotional: _service.getDevotionalForDate(cursor),
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return null;
  }
}

class _MissedDevotionalEntry {
  const _MissedDevotionalEntry({
    required this.date,
    required this.devotional,
  });

  final DateTime date;
  final DevotionalModel devotional;
}

// ── Date label ──────────────────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final label =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    return Row(
      children: [
        const Text('📅', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ── Hero card ────────────────────────────────────────────────────────────────

class _TodayHeroCard extends StatelessWidget {
  const _TodayHeroCard({
    required this.devotional,
    required this.progress,
    required this.hasStartedToday,
    required this.hasCompletedToday,
    required this.missedDevotional,
    required this.onTap,
    required this.onCatchUpTap,
  });

  final DevotionalModel devotional;
  final double progress;
  final bool hasStartedToday;
  final bool hasCompletedToday;
  final _MissedDevotionalEntry? missedDevotional;
  final VoidCallback onTap;
  final VoidCallback? onCatchUpTap;

  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final progressValue = progress.clamp(0.0, 1.0);
    final progressAccent = hasCompletedToday
        ? const Color(0xFFBBF7D0)
        : hasStartedToday
            ? const Color(0xFFFDE68A)
            : Colors.white.withValues(alpha: 0.72);
    final progressLabel = hasCompletedToday
        ? 'Completed automatically as you reached the end of today\'s reading.'
        : hasStartedToday
            ? '${(progressValue * 100).round()}% complete. Keep going and the guide will finish itself.'
            : 'Start reading and the guide will automatically track your progress.';
    final catchUpDateLabel = missedDevotional == null
        ? null
        : localizations.formatShortDate(missedDevotional!.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [_indigo, _violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _indigo.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🌿  TODAY\'S DEVOTION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ReadStatusBadge(
                  hasStartedToday: hasStartedToday,
                  hasCompletedToday: hasCompletedToday,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              devotional.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // Scripture preview
            Text(
              '"${devotional.scripture.length > 120 ? '${devotional.scripture.substring(0, 120)}…' : devotional.scripture}"',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.82),
                fontStyle: FontStyle.italic,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— ${devotional.scriptureReference}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progressLabel,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasCompletedToday) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.check_circle_rounded,
                          color: progressAccent,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      valueColor: AlwaysStoppedAnimation<Color>(progressAccent),
                    ),
                  ),
                  if (missedDevotional != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onCatchUpTap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catchUpDateLabel == null
                                  ? 'Missed devotion'
                                  : 'Missed devotion · $catchUpDateLabel',
                              style: const TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Catch up with ${missedDevotional!.devotional.title}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasCompletedToday
                        ? 'Review Today\'s Devotion'
                        : hasStartedToday
                            ? 'Continue Today\'s Devotion'
                            : 'Begin Today\'s Devotion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadStatusBadge extends StatelessWidget {
  const _ReadStatusBadge({
    required this.hasStartedToday,
    required this.hasCompletedToday,
  });

  final bool hasStartedToday;
  final bool hasCompletedToday;

  @override
  Widget build(BuildContext context) {
    final accent = hasCompletedToday
        ? const Color(0xFFBBF7D0)
        : hasStartedToday
            ? const Color(0xFFFDE68A)
            : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        hasCompletedToday
            ? 'COMPLETED'
            : hasStartedToday
                ? 'IN PROGRESS'
                : 'NEW TODAY',
        style: TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Countdown card ───────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown});
  final String countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded,
              size: 16, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(width: 8),
          Text(
            'Next devotional in ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          Text(
            countdown,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF818CF8), // indigo-400
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
