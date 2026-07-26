import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/tracts/view/widgets/word_studio_top_bar.dart';

void main() {
  testWidgets('Word Studio header fits a narrow large-text viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SafeArea(
              child: WordStudioTopBar(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Word Studio'), findsOneWidget);
    expect(find.text('Create • Share • Inspire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
