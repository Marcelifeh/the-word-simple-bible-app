import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'daily_altar_hive_test_',
    );

    Hive.init(tempDirectory.path);
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(
        recursive: true,
      );
    }
  });

  DailyAltarStoredRecord record() {
    final session = DailyAltarSession(
      id: 'altar-2026-10-31',
      localDate: DateTime(2026, 10, 31),
      stage: DailyAltarStage.carry,
      posture: DailyAltarPosture.seekingDeeperFellowship,
      startedAt: DateTime(2026, 10, 31, 7),
    );

    return DailyAltarStoredRecord(
      session: session,
      contentId: 'john-15-abide-in-christ',
      response: DailyAltarUserResponse(
        sessionId: session.id,
        personalPrayer: const DailyAltarPersonalPrayer(
          text: 'Lord, help me abide in You.',
        ),
        updatedAt: DateTime(2026, 10, 31, 7, 25),
      ),
    );
  }

  group('HiveDailyAltarRepository', () {
    test('saves and reloads a session', () async {
      const repository = HiveDailyAltarRepository();

      await repository.save(record());

      final restored = await repository.load(
        'altar-2026-10-31',
      );

      expect(restored, isNotNull);

      expect(
        restored!.contentId,
        'john-15-abide-in-christ',
      );

      expect(
        restored.session.stage,
        DailyAltarStage.carry,
      );

      expect(
        restored.response.personalPrayer?.text,
        'Lord, help me abide in You.',
      );
    });

    test('survives Hive box close and reopen', () async {
      const repository = HiveDailyAltarRepository();

      await repository.save(record());

      await Hive.box<dynamic>(
        HiveDailyAltarRepository.boxName,
      ).close();

      final restored = await repository.load(
        'altar-2026-10-31',
      );

      expect(restored, isNotNull);

      expect(
        restored!.session.id,
        'altar-2026-10-31',
      );
    });

    test('returns null for an unknown session', () async {
      const repository = HiveDailyAltarRepository();

      final restored = await repository.load(
        'altar-does-not-exist',
      );

      expect(restored, isNull);
    });

    test('deletes a stored session', () async {
      const repository = HiveDailyAltarRepository();

      await repository.save(record());

      await repository.delete(
        'altar-2026-10-31',
      );

      final restored = await repository.load(
        'altar-2026-10-31',
      );

      expect(restored, isNull);
    });
  });
}
