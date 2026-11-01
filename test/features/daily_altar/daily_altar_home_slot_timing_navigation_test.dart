import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _ScriptedTodayService extends DailyAltarTodayService {
  _ScriptedTodayService(this.resolve);

  final DailyAltarTodaySnapshot Function(DateTime) resolve;
  int calls = 0;

  @override
  Future<DailyAltarTodaySnapshot> getToday({DateTime? now}) async {
    calls++;
    return resolve(now ?? DateTime.now());
  }
}

DailyAltarTodaySnapshot snapshot(
  DateTime now,
  DailyAltarTodayStatus status, {
  DateTime? returnAt,
}) {
  final date = DateTime(now.year, now.month, now.day);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return DailyAltarTodaySnapshot(
    status: status,
    localDate: date,
    sessionId: 'altar-${date.year}-$month-$day',
    earliestReturnAt: returnAt,
  );
}

Future<void> _mountSlot(
  WidgetTester tester, {
  required bool enabled,
  required _ScriptedTodayService service,
  required DateTime Function() clock,
  Future<void> Function()? onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DailyAltarHomeSlot(
          enabled: enabled,
          todayService: service,
          now: clock,
          onOpen: onOpen ?? () async {},
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'evening unlocks while app stays open',
    (tester) async {
      var current = DateTime(2026, 10, 31, 16, 59);
      final unlock = DateTime(2026, 10, 31, 17);

      final service = _ScriptedTodayService(
        (now) => snapshot(
          now,
          now.isBefore(unlock)
              ? DailyAltarTodayStatus.waitingForEvening
              : DailyAltarTodayStatus.eveningAvailable,
          returnAt: unlock,
        ),
      );

      await _mountSlot(
        tester,
        enabled: true,
        service: service,
        clock: () => current,
      );

      expect(find.text('Carry the Word'), findsOneWidget);
      expect(service.calls, 1);

      current = unlock;
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text('Return to your altar'), findsOneWidget);
      expect(service.calls, 2);
    },
  );

  testWidgets(
    'local midnight refreshes the daily status',
    (tester) async {
      var current = DateTime(2026, 10, 31, 23, 59);

      final service = _ScriptedTodayService(
        (now) => snapshot(
          now,
          now.day == 31
              ? DailyAltarTodayStatus.completed
              : DailyAltarTodayStatus.notStarted,
        ),
      );

      await _mountSlot(
        tester,
        enabled: true,
        service: service,
        clock: () => current,
      );

      expect(find.text("Today's altar complete"), findsOneWidget);

      current = DateTime(2026, 11, 1);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text("Begin today's altar"), findsOneWidget);
      expect(service.calls, 2);
    },
  );

  testWidgets(
    'rapid taps cannot initiate duplicate navigation',
    (tester) async {
      var current = DateTime(2026, 10, 31, 9);
      var openings = 0;
      final navigationGate = Completer<void>();

      final service = _ScriptedTodayService(
        (now) => snapshot(now, DailyAltarTodayStatus.notStarted),
      );

      await _mountSlot(
        tester,
        enabled: true,
        service: service,
        clock: () => current,
        onOpen: () {
          openings++;
          return navigationGate.future;
        },
      );

      final target = find.byKey(
        const Key('dailyAltarHomeCardTapTarget'),
      );

      await tester.tap(target);
      await tester.pump();
      await tester.tap(target);
      await tester.pump();

      expect(openings, 1);

      navigationGate.complete();
      await tester.pumpAndSettle();

      expect(service.calls, 2);
    },
  );

  testWidgets(
    'navigation failure is contained and allows retry',
    (tester) async {
      final current = DateTime(2026, 10, 31, 9);
      var attempts = 0;

      final service = _ScriptedTodayService(
        (now) => snapshot(now, DailyAltarTodayStatus.notStarted),
      );

      await _mountSlot(
        tester,
        enabled: true,
        service: service,
        clock: () => current,
        onOpen: () async {
          attempts++;
          throw StateError('Simulated navigation failure');
        },
      );

      await tester.tap(
        find.byKey(const Key('dailyAltarHomeCardTapTarget')),
      );
      await tester.pumpAndSettle();

      expect(attempts, 1);
      expect(
        find.text('Unable to open My Daily Altar. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Begin today\'s altar'), findsOneWidget);
    },
  );

  testWidgets(
    'disabled slot never schedules clock-driven loads',
    (tester) async {
      var current = DateTime(2026, 10, 31, 9);

      final service = _ScriptedTodayService(
        (now) => snapshot(now, DailyAltarTodayStatus.notStarted),
      );

      await _mountSlot(
        tester,
        enabled: false,
        service: service,
        clock: () => current,
      );

      current = DateTime(2026, 11, 2);
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpAndSettle();

      expect(service.calls, 0);
      expect(
        find.byKey(const Key('dailyAltarHomeSlotDisabled')),
        findsOneWidget,
      );
    },
  );
}
