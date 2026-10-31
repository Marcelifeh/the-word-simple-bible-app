import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _MemoryDailyAltarRepository implements DailyAltarRepository {
  final Map<String, DailyAltarStoredRecord> records =
      <String, DailyAltarStoredRecord>{};

  @override
  Future<void> save(
    DailyAltarStoredRecord record,
  ) async {
    records[record.session.id] = record;
  }

  @override
  Future<DailyAltarStoredRecord?> load(
    String sessionId,
  ) async {
    return records[sessionId];
  }

  @override
  Future<void> delete(
    String sessionId,
  ) async {
    records.remove(sessionId);
  }
}

class _FailingDailyAltarRepository implements DailyAltarRepository {
  @override
  Future<void> save(
    DailyAltarStoredRecord record,
  ) async {
    throw const DailyAltarStorageException(
      'Test failure',
    );
  }

  @override
  Future<DailyAltarStoredRecord?> load(
    String sessionId,
  ) async {
    return null;
  }

  @override
  Future<void> delete(
    String sessionId,
  ) async {}
}

void main() {
  DateTime fixedNow() => DateTime(2026, 10, 31, 7, 15);

  Future<void> loadScreen(
    WidgetTester tester, {
    required DailyAltarRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyAltarExperienceScreen(
          now: fixedNow,
          repository: repository,
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
        const Key(
          'dailyAltarPostureDropdown',
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find
          .text(
            'Seeking deeper fellowship with God',
          )
          .last,
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const Key(
          'dailyAltarPrimaryAction',
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> next(
    WidgetTester tester,
  ) async {
    await tester.tap(
      find.byKey(
        const Key(
          'dailyAltarPrimaryAction',
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('Daily Altar resumable experience', () {
    testWidgets(
      'starts at Come Before the Word',
      (tester) async {
        final repository = _MemoryDailyAltarRepository();

        await loadScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('Come Before the Word'),
          findsOneWidget,
        );

        expect(
          find.text('Where are you today?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'begins with reviewed John 15 Scripture and saves',
      (tester) async {
        final repository = _MemoryDailyAltarRepository();

        await loadScreen(
          tester,
          repository: repository,
        );

        await choosePostureAndBegin(tester);

        expect(
          find.text('Receive the Word'),
          findsOneWidget,
        );

        expect(
          find.text('John 15:4-5'),
          findsOneWidget,
        );

        final saved = repository.records['altar-2026-10-31'];

        expect(saved, isNotNull);

        expect(
          saved!.session.stage,
          DailyAltarStage.receive,
        );
      },
    );

    testWidgets(
      'walks through the full formation sequence',
      (tester) async {
        final repository = _MemoryDailyAltarRepository();

        await loadScreen(
          tester,
          repository: repository,
        );

        await choosePostureAndBegin(tester);

        expect(
          find.text('Receive the Word'),
          findsOneWidget,
        );

        await next(tester);
        expect(
          find.text('Understand the Word'),
          findsOneWidget,
        );

        await next(tester);
        expect(
          find.text('Abide'),
          findsOneWidget,
        );

        await next(tester);
        expect(
          find.text('Pray the Word'),
          findsOneWidget,
        );

        await next(tester);
        expect(
          find.text('Walk in the Word'),
          findsOneWidget,
        );

        await next(tester);
        expect(
          find.text('Carry the Word'),
          findsOneWidget,
        );

        await next(tester);
        expect(
          find.text('Return to the Altar'),
          findsOneWidget,
        );

        await next(tester);

        expect(
          find.byKey(
            const Key(
              'dailyAltarCompletedTitle',
            ),
          ),
          findsOneWidget,
        );

        expect(
          repository.records['altar-2026-10-31']!.session.stage,
          DailyAltarStage.completed,
        );
      },
    );

    testWidgets(
      'restores exact saved stage after screen is reopened',
      (tester) async {
        final repository = _MemoryDailyAltarRepository();

        await loadScreen(
          tester,
          repository: repository,
        );

        await choosePostureAndBegin(tester);

        await next(tester);
        await next(tester);

        expect(
          find.text('Abide'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(
            const Key(
              'dailyAltarField_aboutGod',
            ),
          ),
          'Christ is my source.',
        );

        await next(tester);

        expect(
          find.text('Pray the Word'),
          findsOneWidget,
        );

        await tester.pumpWidget(
          const SizedBox.shrink(),
        );

        await tester.pumpAndSettle();

        await loadScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('Pray the Word'),
          findsOneWidget,
        );

        final restored = repository.records['altar-2026-10-31'];

        expect(
          restored!.response.reflection?.aboutGod,
          'Christ is my source.',
        );
      },
    );

    testWidgets(
      'hydrates saved reflection fields',
      (tester) async {
        final repository = _MemoryDailyAltarRepository();

        final session = DailyAltarSession(
          id: 'altar-2026-10-31',
          localDate: DateTime(2026, 10, 31),
          stage: DailyAltarStage.abide,
          posture: DailyAltarPosture.seekingDeeperFellowship,
          startedAt: DateTime(2026, 10, 31, 7),
        );

        repository.records[session.id] = DailyAltarStoredRecord(
          session: session,
          contentId: 'john-15-abide-in-christ',
          response: DailyAltarUserResponse(
            sessionId: session.id,
            reflection: const DailyAltarReflectionResponse(
              aboutGod: 'Christ sustains me.',
              aboutMe: 'I often rely on myself.',
              response: 'I will pause and pray.',
            ),
          ),
        );

        await loadScreen(
          tester,
          repository: repository,
        );

        expect(
          find.text('Abide'),
          findsOneWidget,
        );

        final field = tester.widget<TextField>(
          find.byKey(
            const Key(
              'dailyAltarField_aboutGod',
            ),
          ),
        );

        expect(
          field.controller!.text,
          'Christ sustains me.',
        );
      },
    );

    testWidgets(
      'storage failure does not destroy the active experience',
      (tester) async {
        final repository = _FailingDailyAltarRepository();

        await loadScreen(
          tester,
          repository: repository,
        );

        await choosePostureAndBegin(tester);

        expect(
          find.text('Receive the Word'),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const Key(
              'dailyAltarStorageMessage',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'uses open access without a billing flow',
      (tester) async {
        final repository = _MemoryDailyAltarRepository();

        await loadScreen(
          tester,
          repository: repository,
        );

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
      },
    );
  });
}
