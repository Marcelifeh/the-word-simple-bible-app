import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/shared/widgets/adaptive_feature_hero.dart';

void main() {
  testWidgets('long hero content sizes naturally on a narrow large-text screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: AdaptiveFeatureHero(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.deepPurple],
                ),
                badge: const Text(
                  'DEVOTIONAL',
                  style: TextStyle(color: Colors.white),
                ),
                eyebrow:
                    'A thoughtful introduction that needs room to wrap safely.',
                title: 'Walking Daily in Your God-Given Calling and Purpose',
                subtitle:
                    'A longer scripture reference that remains fully readable.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Walking Daily'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
