import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/data/bible/bible_asset_repository.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/features/daily_verse/services/promise_verse_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getTodayPromise loads for KJV', () async {
    final repo = BibleAssetRepository();
    final service = PromiseVerseService(bibleRepository: repo);
    final promise = await service.getTodayPromise(translation: BibleTranslation.kjv);
    expect(promise.text, isNotEmpty);
  });

  test('getTodayPromise loads for WEB', () async {
    final repo = BibleAssetRepository();
    final service = PromiseVerseService(bibleRepository: repo);
    final promise = await service.getTodayPromise(translation: BibleTranslation.web);
    expect(promise.text, isNotEmpty);
  });
}
