import 'dart:async';

import 'package:flutter/material.dart';

import '../services/daily_altar_today_service.dart';
import '../services/daily_altar_today_status.dart';
import 'daily_altar_home_card.dart';

typedef DailyAltarHomeOpenCallback = Future<void> Function();

/// Isolated bridge between Home and My Daily Altar.
///
/// No Home-owned persistence, billing, or lifecycle calculation is required.
class DailyAltarHomeSlot extends StatefulWidget {
  const DailyAltarHomeSlot({
    super.key,
    required this.enabled,
    required this.onOpen,
    this.todayService = const DailyAltarTodayService(),
    this.now,
  });

  final bool enabled;
  final DailyAltarHomeOpenCallback onOpen;
  final DailyAltarTodayService todayService;

  /// Optional clock for deterministic lifecycle and timing tests.
  final DateTime Function()? now;

  @override
  State<DailyAltarHomeSlot> createState() => _DailyAltarHomeSlotState();
}

class _DailyAltarHomeSlotState extends State<DailyAltarHomeSlot>
    with WidgetsBindingObserver {
  DailyAltarTodaySnapshot? _snapshot;

  bool _loading = false;
  bool _opening = false;
  int _requestGeneration = 0;

  Timer? _clockCheckTimer;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.enabled) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(DailyAltarHomeSlot oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled) {
      _clockCheckTimer?.cancel();
      _requestGeneration++;

      if (_snapshot != null || _loading) {
        setState(() {
          _snapshot = null;
          _loading = false;
        });
      }
      return;
    }

    if (!oldWidget.enabled ||
        oldWidget.todayService != widget.todayService ||
        oldWidget.now != widget.now) {
      unawaited(_load());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.enabled) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    _clockCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.enabled) return;

    _clockCheckTimer?.cancel();
    final generation = ++_requestGeneration;

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final snapshot = await widget.todayService.getToday(now: _now);

      if (!mounted || !widget.enabled || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });

      _scheduleClockCheck();
    } catch (_) {
      // An MDA storage failure must never make Home unavailable.
      if (!mounted || generation != _requestGeneration) return;

      setState(() {
        _snapshot = null;
        _loading = false;
      });
    }
  }

  /// Checks the clock without reading storage unnecessarily.
  ///
  /// This avoids a permanent "waiting for evening" card when the app
  /// stays open, and detects local-day rollover within roughly one minute.
  void _scheduleClockCheck() {
    _clockCheckTimer?.cancel();

    if (!mounted || !widget.enabled || _snapshot == null) return;

    _clockCheckTimer = Timer(
      const Duration(minutes: 1),
      _checkClock,
    );
  }

  void _checkClock() {
    if (!mounted || !widget.enabled) return;

    final snapshot = _snapshot;
    if (snapshot == null) return;

    final current = _now;
    final storedDay = snapshot.localDate;

    final newLocalDay = current.year != storedDay.year ||
        current.month != storedDay.month ||
        current.day != storedDay.day;

    final returnAt = snapshot.earliestReturnAt;

    final eveningUnlocked =
        snapshot.status == DailyAltarTodayStatus.waitingForEvening &&
            returnAt != null &&
            !current.isBefore(returnAt);

    if (newLocalDay || eveningUnlocked) {
      unawaited(_load());
    } else {
      _scheduleClockCheck();
    }
  }

  Future<void> _open() async {
    if (!widget.enabled || _opening) return;

    _opening = true;

    try {
      await widget.onOpen();
    } catch (_) {
      // Navigation errors must not propagate into Home.
      if (mounted && widget.enabled) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open My Daily Altar. Please try again.',
            ),
          ),
        );
      }
    } finally {
      try {
        if (mounted && widget.enabled) {
          await _load();
        }
      } finally {
        _opening = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink(
        key: Key('dailyAltarHomeSlotDisabled'),
      );
    }

    final snapshot = _snapshot;

    if (_loading && snapshot == null) {
      return const SizedBox.shrink(
        key: Key('dailyAltarHomeSlotLoading'),
      );
    }

    if (snapshot == null) {
      return const SizedBox.shrink(
        key: Key('dailyAltarHomeSlotUnavailable'),
      );
    }

    return DailyAltarHomeCard(
      snapshot: snapshot,
      onPressed: _open,
    );
  }
}
