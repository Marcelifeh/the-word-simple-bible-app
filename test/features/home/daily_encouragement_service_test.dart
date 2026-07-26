import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/home/model/daily_encouragement.dart';
import 'package:simple_bible_app/features/home/services/daily_encouragement_service.dart';

void main() {
  const service = DailyEncouragementService();

  DailyEncouragementContext context({
    DateTime? now,
    bool hasReadToday = false,
    bool readingPlanCompleted = false,
    bool devotionalCompleted = false,
    bool missedTwoDays = false,
    int streakDays = 0,
  }) {
    return DailyEncouragementContext(
      now: now ?? DateTime(2026, 7, 16, 13),
      hasReadToday: hasReadToday,
      readingPlanCompleted: readingPlanCompleted,
      devotionalCompleted: devotionalCompleted,
      missedTwoDays: missedTwoDays,
      streakDays: streakDays,
    );
  }

  test('seasonal state wins when multiple conditions match', () {
    final result = service.select(
      context(
        now: DateTime(2026, 12, 24, 20),
        readingPlanCompleted: true,
        missedTwoDays: true,
        streakDays: 30,
      ),
    );

    expect(result.kind, DailyEncouragementKind.christmas);
  });

  test('returning grace wins over completion and streak states', () {
    final result = service.select(
      context(
        readingPlanCompleted: true,
        devotionalCompleted: true,
        missedTwoDays: true,
        streakDays: 30,
      ),
    );

    expect(result.kind, DailyEncouragementKind.returning);
    expect(result.tone, isNot(DailyEncouragementTone.celebration));
  });

  test('reading-plan completion wins over devotional and streak states', () {
    final result = service.select(
      context(
        hasReadToday: true,
        readingPlanCompleted: true,
        devotionalCompleted: true,
        streakDays: 14,
      ),
    );

    expect(result.kind, DailyEncouragementKind.readingPlanComplete);
  });

  test('only explicit streak milestones receive a streak message', () {
    final milestone = service.select(context(streakDays: 14));
    final ordinaryDay = service.select(context(streakDays: 13));

    expect(milestone.kind, DailyEncouragementKind.streak);
    expect(ordinaryDay.kind, isNot(DailyEncouragementKind.streak));
  });

  test('evening message reflects actual reading activity', () {
    final unread = service.select(
      context(now: DateTime(2026, 7, 16, 20)),
    );
    final active = service.select(
      context(now: DateTime(2026, 7, 16, 20), hasReadToday: true),
    );

    expect(unread.kind, DailyEncouragementKind.eveningUnread);
    expect(active.kind, DailyEncouragementKind.eveningComplete);
  });
}
