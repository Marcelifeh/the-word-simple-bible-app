import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/daily_altar/daily_altar.dart';

void main() {
  testWidgets('My Daily Altar shell renders independently', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DailyAltarPlaceholderScreen(),
      ),
    );

    expect(find.text('My Daily Altar'), findsWidgets);
    expect(
      find.text('Meet God in His Word. Carry His truth into your day.'),
      findsOneWidget,
    );
    expect(find.text('Feature foundation ready.'), findsOneWidget);
  });
}
