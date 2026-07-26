import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../daily_verse/view/daily_verse_screen.dart';
import '../../devotional/view/devotional_detail_screen.dart';
import '../../devotional/view/devotional_screen.dart';
import '../../journal/view/journal_screen.dart';
import '../../prayer/view/prayer_screen.dart';
import '../../reading_plan/view/reading_plan_screen.dart';
import '../../scripture_memory/view/scripture_memory_screen.dart';
import '../model/notification_type.dart';

class NotificationNavigationService {
  NotificationNavigationService(this._state);

  static const notificationCentreType = 'notification_centre';

  final AppState _state;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<String> _pendingPayloads = <String>[];
  bool _flushing = false;

  int get pendingPayloadCount => _pendingPayloads.length;

  Future<void> handlePayload(String payload) async {
    final data = _parsePayload(payload);
    if (data == null || !_isSupportedType(data['type'] as String?)) {
      return;
    }
    if (navigatorKey.currentContext == null) {
      _pendingPayloads.add(payload);
      return;
    }
    await _navigate(payload);
  }

  Future<void> flushPending() async {
    if (_flushing || navigatorKey.currentContext == null) return;
    _flushing = true;
    try {
      while (
          _pendingPayloads.isNotEmpty && navigatorKey.currentContext != null) {
        await _navigate(_pendingPayloads.removeAt(0));
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _navigate(String payload) async {
    final data = _parsePayload(payload);
    if (data == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) {
      _pendingPayloads.add(payload);
      return;
    }

    final wireType = data['type'] as String?;
    if (wireType == notificationCentreType) {
      await AppRouter.pushNamed(
        context,
        AppRouter.notificationSettingsRoute,
        rootNavigator: true,
      );
      return;
    }

    final type = NotificationTypeX.fromWireName(wireType);
    if (type == null) return;
    switch (type) {
      case NotificationType.dailyVerse:
        await AppRouter.push(
          context,
          const DailyVerseScreen(),
          transition: AppTransitionType.devotional,
        );
        return;
      case NotificationType.dailyDevotional:
        final devotionalId = data['devotionalId'] as String?;
        final devotional = devotionalId == null
            ? _state.devotionalService.getTodaysDevotional()
            : _state.devotionalService.getById(devotionalId);
        if (devotional == null) {
          await AppRouter.push(context, const DevotionalScreen());
          return;
        }
        await AppRouter.push(
          context,
          DevotionalDetailScreen(
            devotional: devotional,
            activeDate: _parseDate(data['date'] as String?),
          ),
          transition: AppTransitionType.devotional,
        );
        return;
      case NotificationType.readingPlan:
        await AppRouter.push(
          context,
          ReadingPlanScreen(initialDate: _parseDate(data['date'] as String?)),
          transition: AppTransitionType.slideRight,
        );
        return;
      case NotificationType.scriptureMemoryReview:
        await AppRouter.push(
          context,
          const ScriptureMemoryScreen(),
          transition: AppTransitionType.slideRight,
        );
        return;
      case NotificationType.prayerReminder:
        await AppRouter.push(
          context,
          const PrayerScreen(),
          transition: AppTransitionType.fade,
        );
        return;
      case NotificationType.eveningReflection:
        await AppRouter.push(
          context,
          const JournalScreen(),
          transition: AppTransitionType.scale,
        );
        return;
      case NotificationType.appUpdate:
      case NotificationType.importantAnnouncement:
        await AppRouter.pushNamed(
          context,
          AppRouter.notificationInboxRoute,
          rootNavigator: true,
        );
        return;
    }
  }

  Map<String, dynamic>? _parsePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  bool _isSupportedType(String? value) =>
      value == notificationCentreType ||
      NotificationTypeX.fromWireName(value) != null;

  DateTime? _parseDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
