import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

class _LifecycleMemoryRepository implements DailyAltarRepository {
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

void main() {
  testWidgets(
    'morning altar waits until evening before return',
    (tester) async {
      final repository = _LifecycleMemoryRepository();

      var now = DateTime(2026, 10, 31, 7, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyAltarExperienceScreen(
            repository: repository,
            now: () => now,
          ),
        ),
      );

      await tester.pumpAndSettle();

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

      Future<void> next() async {
        await tester.tap(
          find.byKey(
            const Key(
              'dailyAltarPrimaryAction',
            ),
          ),
        );

        await tester.pumpAndSettle();
      }

      // Begin -> Receive.
      await next();

      expect(
        find.text('Receive the Word'),
        findsOneWidget,
      );

      // Receive -> Understand.
      await next();

      // Understand -> Abide.
      await next();

      // Abide -> Pray.
      await next();

      // Pray -> Obey.
      await next();

      // Obey -> Carry.
      await next();

      expect(
        find.text('Carry the Word'),
        findsOneWidget,
      );

      // Carry -> pending Return stage.
      await next();

      expect(
        find.text('Return to the Altar'),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key(
            'dailyAltarReturnLocked',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key(
            'dailyAltarReturnForm',
          ),
        ),
        findsNothing,
      );

      final saved = repository.records['altar-2026-10-31'];

      expect(
        saved,
        isNotNull,
      );

      expect(
        saved!.session.stage,
        DailyAltarStage.returnToAltar,
      );

      expect(
        saved.session.morningCompletedAt,
        isNotNull,
      );

      // Still too early.
      now = DateTime(2026, 10, 31, 16, 59);

      await tester.tap(
        find.byKey(
          const Key(
            'dailyAltarPrimaryAction',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key(
            'dailyAltarReturnLocked',
          ),
        ),
        findsOneWidget,
      );

      // Evening threshold reached.
      now = DateTime(2026, 10, 31, 17);

      await tester.tap(
        find.byKey(
          const Key(
            'dailyAltarPrimaryAction',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key(
            'dailyAltarReturnLocked',
          ),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const Key(
            'dailyAltarReturnForm',
          ),
        ),
        findsOneWidget,
      );

      // Complete evening return.
      await next();

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
}
