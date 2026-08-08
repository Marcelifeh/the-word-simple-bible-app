import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/home/activity/model/faith_activity_type.dart';
import 'package:simple_bible_app/features/home/activity/repository/faith_activity_repository.dart';

void main() {
  group('FaithActivityRepository', () {
    test('record returns true for a new date', () {
      final repo = FaithActivityRepository();
      expect(
        repo.record(FaithActivityType.dailyVerse, DateTime(2026, 8, 8, 9)),
        isTrue,
      );
    });

    // User-specified test: same activity twice on the same date → isFalse
    test('same activity recorded twice on same date does not increase score',
        () {
      final repo = FaithActivityRepository();
      final first = repo.record(
        FaithActivityType.dailyVerse,
        DateTime(2026, 8, 8, 9),
      );
      final second = repo.record(
        FaithActivityType.dailyVerse,
        DateTime(2026, 8, 8, 21),
      );
      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('different types on the same date are independent', () {
      final repo = FaithActivityRepository();
      expect(
        repo.record(FaithActivityType.dailyVerse, DateTime(2026, 8, 8)),
        isTrue,
      );
      expect(
        repo.record(FaithActivityType.promise, DateTime(2026, 8, 8)),
        isTrue,
      );
      expect(
        repo.record(FaithActivityType.scriptureMemory, DateTime(2026, 8, 8)),
        isTrue,
      );
    });

    test('same type on different dates both return true', () {
      final repo = FaithActivityRepository();
      expect(
        repo.record(FaithActivityType.promise, DateTime(2026, 8, 7)),
        isTrue,
      );
      expect(
        repo.record(FaithActivityType.promise, DateTime(2026, 8, 8)),
        isTrue,
      );
    });

    test('hasActivityOn returns true after recording', () {
      final repo = FaithActivityRepository();
      final when = DateTime(2026, 8, 8, 10);
      repo.record(FaithActivityType.scriptureMemory, when);
      expect(
        repo.hasActivityOn(FaithActivityType.scriptureMemory, when),
        isTrue,
      );
    });

    test('hasActivityOn returns false before recording', () {
      final repo = FaithActivityRepository();
      expect(
        repo.hasActivityOn(FaithActivityType.dailyVerse, DateTime(2026, 8, 8)),
        isFalse,
      );
    });

    test('hasActivityOn false for different date', () {
      final repo = FaithActivityRepository();
      repo.record(FaithActivityType.promise, DateTime(2026, 8, 7));
      expect(
        repo.hasActivityOn(FaithActivityType.promise, DateTime(2026, 8, 8)),
        isFalse,
      );
    });

    test('encode / decode round-trips correctly', () {
      final repo = FaithActivityRepository();
      repo.record(FaithActivityType.dailyVerse, DateTime(2026, 8, 8));
      repo.record(FaithActivityType.promise, DateTime(2026, 8, 7));
      repo.record(FaithActivityType.scriptureMemory, DateTime(2026, 8, 6));

      final encoded = repo.encode();

      final repo2 = FaithActivityRepository();
      repo2.decode(encoded);

      expect(
        repo2.hasActivityOn(FaithActivityType.dailyVerse, DateTime(2026, 8, 8)),
        isTrue,
      );
      expect(
        repo2.hasActivityOn(FaithActivityType.promise, DateTime(2026, 8, 7)),
        isTrue,
      );
      expect(
        repo2.hasActivityOn(
            FaithActivityType.scriptureMemory, DateTime(2026, 8, 6)),
        isTrue,
      );
      // Activity on a different date must not appear
      expect(
        repo2.hasActivityOn(FaithActivityType.dailyVerse, DateTime(2026, 8, 7)),
        isFalse,
      );
    });

    test('decode with null input clears the repository', () {
      final repo = FaithActivityRepository();
      repo.record(FaithActivityType.dailyVerse, DateTime(2026, 8, 8));
      repo.decode(null);
      expect(
        repo.hasActivityOn(FaithActivityType.dailyVerse, DateTime(2026, 8, 8)),
        isFalse,
      );
    });

    test('decode with malformed JSON leaves repository empty', () {
      final repo = FaithActivityRepository();
      repo.decode('{not valid json}');
      expect(
        repo.hasActivityOn(FaithActivityType.dailyVerse, DateTime(2026, 8, 8)),
        isFalse,
      );
    });

    test('encode output is valid JSON with sorted dates', () {
      final repo = FaithActivityRepository();
      repo.record(FaithActivityType.dailyVerse, DateTime(2026, 8, 8));
      repo.record(FaithActivityType.dailyVerse, DateTime(2026, 8, 6));
      final map = jsonDecode(repo.encode()) as Map<String, dynamic>;
      final dates = (map['dailyVerse'] as List).cast<String>();
      expect(dates, ['2026-08-06', '2026-08-08']);
    });

    test('local calendar date boundary shift creates distinct activity days',
        () {
      final repo = FaithActivityRepository();

      // User records Promise at 11:30 PM local on Aug 8
      final nightEvent = DateTime(2026, 8, 8, 23, 30);
      expect(repo.record(FaithActivityType.promise, nightEvent), isTrue);
      expect(repo.hasActivityOn(FaithActivityType.promise, nightEvent), isTrue);

      // Local calendar date shifts to Aug 9 (after midnight or timezone shift)
      final morningEvent = DateTime(2026, 8, 9, 0, 15);
      expect(repo.record(FaithActivityType.promise, morningEvent), isTrue);

      // Both local dates are independently recorded
      expect(repo.hasActivityOn(FaithActivityType.promise, nightEvent), isTrue);
      expect(
        repo.hasActivityOn(FaithActivityType.promise, morningEvent),
        isTrue,
      );
    });
  });
}
