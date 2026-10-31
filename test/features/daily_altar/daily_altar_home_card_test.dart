import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const sessionId = 'altar-2026-10-31';

  final localDate = DateTime(
    2026,
    10,
    31,
  );

  DailyAltarTodaySnapshot snapshot(
    DailyAltarTodayStatus status, {
    DateTime? earliestReturnAt,
  }) {
    return DailyAltarTodaySnapshot(
      status: status,
      localDate: localDate,
      sessionId: sessionId,
      earliestReturnAt: earliestReturnAt,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    DailyAltarTodaySnapshot value, {
    VoidCallback? onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyAltarHomeCard(
            snapshot: value,
            onPressed: onPressed,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets(
    'notStarted invites user to begin today altar',
    (tester) async {
      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.notStarted,
        ),
      );

      expect(
        find.text('My Daily Altar'),
        findsOneWidget,
      );

      expect(
        find.text('Begin today\'s altar'),
        findsOneWidget,
      );

      expect(
        find.text('Begin'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'morningInProgress offers continuation',
    (tester) async {
      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.morningInProgress,
        ),
      );

      expect(
        find.text('Continue your altar'),
        findsOneWidget,
      );

      expect(
        find.text('Continue'),
        findsOneWidget,
      );

      expect(
        find.textContaining(
          'Continue where you left off',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'waitingForEvening shows actual return time',
    (tester) async {
      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.waitingForEvening,
          earliestReturnAt: DateTime(
            2026,
            10,
            31,
            17,
          ),
        ),
      );

      expect(
        find.text('Carry the Word'),
        findsOneWidget,
      );

      expect(
        find.text(
          'Return after 5 PM for evening reflection.',
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key(
            'dailyAltarHomeCardAction',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'waitingForEvening formats delayed return minutes',
    (tester) async {
      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.waitingForEvening,
          earliestReturnAt: DateTime(
            2026,
            10,
            31,
            20,
            30,
          ),
        ),
      );

      expect(
        find.text(
          'Return after 8:30 PM for evening reflection.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'eveningAvailable invites user to return',
    (tester) async {
      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.eveningAvailable,
        ),
      );

      expect(
        find.text('Return to your altar'),
        findsOneWidget,
      );

      expect(
        find.text('Return'),
        findsOneWidget,
      );

      expect(
        find.textContaining(
          'Reflect on how the Word met you',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'completed communicates completion',
    (tester) async {
      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.completed,
        ),
      );

      expect(
        find.text('Today\'s altar complete'),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key(
            'dailyAltarHomeCardIcon-completed',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.text('Review'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tap is delegated through callback only',
    (tester) async {
      var tapCount = 0;

      await pumpCard(
        tester,
        snapshot(
          DailyAltarTodayStatus.notStarted,
        ),
        onPressed: () {
          tapCount++;
        },
      );

      await tester.tap(
        find.byKey(
          const Key(
            'dailyAltarHomeCardTapTarget',
          ),
        ),
      );

      await tester.pump();

      expect(
        tapCount,
        1,
      );
    },
  );

  testWidgets(
    'card contains no billing or subscription language',
    (tester) async {
      for (final status in DailyAltarTodayStatus.values) {
        await pumpCard(
          tester,
          snapshot(status),
        );

        final textWidgets = tester.widgetList<Text>(
          find.byType(Text),
        );

        final visibleText = textWidgets
            .map(
              (widget) => widget.data ?? '',
            )
            .join(' ')
            .toLowerCase();

        expect(
          visibleText,
          isNot(
            contains('premium'),
          ),
        );

        expect(
          visibleText,
          isNot(
            contains('subscribe'),
          ),
        );

        expect(
          visibleText,
          isNot(
            contains('purchase'),
          ),
        );

        expect(
          visibleText,
          isNot(
            contains('paywall'),
          ),
        );
      }
    },
  );
}
