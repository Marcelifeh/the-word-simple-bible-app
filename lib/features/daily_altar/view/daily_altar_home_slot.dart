import 'dart:async';

import 'package:flutter/material.dart';

import '../services/daily_altar_today_service.dart';
import '../services/daily_altar_today_status.dart';
import 'daily_altar_home_card.dart';

typedef DailyAltarHomeOpenCallback = Future<void> Function();

/// Guarded bridge between an app surface and My Daily Altar.
///
/// The slot owns status loading and refresh behavior so the production Home
/// screen does not need to understand persistence, lifecycle calculations,
/// or Daily Altar stages.
///
/// When disabled, or when local status cannot be read safely, this widget
/// renders nothing and does not interfere with the host screen.
class DailyAltarHomeSlot extends StatefulWidget {
  const DailyAltarHomeSlot({
    super.key,
    required this.enabled,
    required this.onOpen,
    this.todayService = const DailyAltarTodayService(),
  });

  final bool enabled;
  final DailyAltarHomeOpenCallback onOpen;
  final DailyAltarTodayService todayService;

  @override
  State<DailyAltarHomeSlot> createState() => _DailyAltarHomeSlotState();
}

class _DailyAltarHomeSlotState extends State<DailyAltarHomeSlot>
    with WidgetsBindingObserver {
  DailyAltarTodaySnapshot? _snapshot;
  bool _loading = false;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.enabled) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(
    DailyAltarHomeSlot oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled) {
      _requestGeneration++;

      if (_snapshot != null || _loading) {
        setState(() {
          _snapshot = null;
          _loading = false;
        });
      }

      return;
    }

    if (!oldWidget.enabled || oldWidget.todayService != widget.todayService) {
      unawaited(_load());
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed && widget.enabled) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.enabled) {
      return;
    }

    final generation = ++_requestGeneration;

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final snapshot = await widget.todayService.getToday();

      if (!mounted || generation != _requestGeneration || !widget.enabled) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      // MDA status must never make the host Home screen unavailable.
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _snapshot = null;
        _loading = false;
      });
    }
  }

  Future<void> _open() async {
    if (!widget.enabled) {
      return;
    }

    await widget.onOpen();

    if (!mounted || !widget.enabled) {
      return;
    }

    await _load();
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
