import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  DateTime fixedNow() => DateTime(2026, 10, 31, 7, 15);

  Future<void> loadScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyAltarExperienceScreen(
          now: fixedNow,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> choosePostureAndBegin(
    WidgetTester tester,
  ) async {
    await tester.tap(
      find.byKey(
        const Key('dailyAltarPostureDropdown'),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Seeking deeper fellowship with God').last,
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const Key('dailyAltarPrimaryAction'),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(
      find.byKey(
        const Key('dailyAltarPrimaryAction'),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('Daily Altar internal experience', () {
    testWidgets('starts at Come Before the Word', (tester) async {
      await loadScreen(tester);

      expect(
        find.text('Come Before the Word'),
        findsOneWidget,
      );

      expect(
        find.text('Where are you today?'),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key('dailyAltarPrimaryAction'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('begins with reviewed John 15 Scripture', (tester) async {
      await loadScreen(tester);
      await choosePostureAndBegin(tester);

      expect(
        find.text('Receive the Word'),
        findsOneWidget,
      );

      expect(
        find.text('John 15:4-5'),
        findsOneWidget,
      );

      expect(
        find.textContaining('Abide in me'),
        findsOneWidget,
      );
    });

    testWidgets('walks through the full formation sequence', (tester) async {
      await loadScreen(tester);
      await choosePostureAndBegin(tester);

      expect(find.text('Receive the Word'), findsOneWidget);

      await next(tester);
      expect(find.text('Understand the Word'), findsOneWidget);

      await next(tester);
      expect(find.text('Abide'), findsOneWidget);

      await next(tester);
      expect(find.text('Pray the Word'), findsOneWidget);

      await next(tester);
      expect(find.text('Walk in the Word'), findsOneWidget);

      await next(tester);
      expect(find.text('Carry the Word'), findsOneWidget);

      await next(tester);
      expect(find.text('Return to the Altar'), findsOneWidget);

      await next(tester);

      expect(
        find.byKey(
          const Key('dailyAltarCompletedTitle'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('captures personal reflection without persistence',
        (tester) async {
      await loadScreen(tester);
      await choosePostureAndBegin(tester);

      await next(tester);
      await next(tester);

      expect(find.text('Abide'), findsOneWidget);

      await tester.enterText(
        find.byKey(
          const Key('dailyAltarField_aboutGod'),
        ),
        'Christ is the source of my strength.',
      );

      await next(tester);

      expect(
        find.text('Pray the Word'),
        findsOneWidget,
      );
    });

    testWidgets('uses open access policy without a billing flow',
        (tester) async {
      await loadScreen(tester);

      expect(
        find.text('Come Before the Word'),
        findsOneWidget,
      );

      expect(
        find.textContaining('purchase'),
        findsNothing,
      );

      expect(
        find.textContaining('Subscribe'),
        findsNothing,
      );
    });
  });
}
