import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  const codec = DailyAltarStorageCodec();

  DailyAltarStoredRecord record() {
    final session = DailyAltarSession(
      id: 'altar-2026-10-31',
      localDate: DateTime(2026, 10, 31),
      stage: DailyAltarStage.returnToAltar,
      posture: DailyAltarPosture.seekingDeeperFellowship,
      startedAt: DateTime(2026, 10, 31, 7),
      morningCompletedAt: DateTime(2026, 10, 31, 7, 30),
    );

    return DailyAltarStoredRecord(
      session: session,
      contentId: 'john-15-abide-in-christ',
      response: DailyAltarUserResponse(
        sessionId: session.id,
        reflection: const DailyAltarReflectionResponse(
          aboutGod: 'Christ is my source.',
          aboutMe: 'I rely too much on myself.',
          response: 'I need to abide consciously.',
        ),
        personalPrayer: const DailyAltarPersonalPrayer(
          text: 'Father, keep me near Christ.',
        ),
        obedience: DailyAltarObedienceResponse(
          commitment: 'Pause before my important conversation.',
          completed: true,
          completedAt: DateTime(2026, 10, 31, 15, 30),
        ),
        evening: const DailyAltarEveningResponse(
          rememberedWord: 'I remembered John 15:5.',
          obedienceReflection: 'I paused and prayed.',
          relevanceReflection: 'It helped during a difficult moment.',
          heartResponse: 'I am thankful for God’s help.',
          carryForward: 'Continue depending on Christ.',
        ),
        updatedAt: DateTime(2026, 10, 31, 20),
      ),
    );
  }

  group('DailyAltarStorageCodec', () {
    test('round trips complete Daily Altar state', () {
      final original = record();

      final encoded = codec.encode(original);
      final restored = codec.decode(encoded);

      expect(restored.contentId, original.contentId);
      expect(restored.session.id, original.session.id);
      expect(
        restored.session.stage,
        DailyAltarStage.returnToAltar,
      );
      expect(
        restored.session.posture,
        DailyAltarPosture.seekingDeeperFellowship,
      );

      expect(
        restored.response.reflection?.aboutGod,
        'Christ is my source.',
      );

      expect(
        restored.response.personalPrayer?.text,
        'Father, keep me near Christ.',
      );

      expect(
        restored.response.obedience?.completed,
        isTrue,
      );

      expect(
        restored.response.evening?.carryForward,
        'Continue depending on Christ.',
      );
    });

    test('stores explicit schema version', () {
      final encoded = codec.encode(record());

      expect(
        encoded['schemaVersion'],
        DailyAltarStorageCodec.currentSchemaVersion,
      );
    });

    test('rejects mismatched response and session IDs', () {
      final session = DailyAltarSession(
        id: 'session-a',
        localDate: DateTime(2026, 10, 31),
        stage: DailyAltarStage.receive,
      );

      final invalid = DailyAltarStoredRecord(
        session: session,
        contentId: 'john-15-abide-in-christ',
        response: const DailyAltarUserResponse(
          sessionId: 'session-b',
        ),
      );

      expect(
        () => codec.encode(invalid),
        throwsA(
          isA<DailyAltarStorageException>(),
        ),
      );
    });

    test('rejects unknown schema versions', () {
      final encoded = codec.encode(record());

      encoded['schemaVersion'] = 999;

      expect(
        () => codec.decode(encoded),
        throwsA(
          isA<DailyAltarStorageException>(),
        ),
      );
    });
  });
}
