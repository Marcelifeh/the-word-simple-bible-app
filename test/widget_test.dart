// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_bible_app/features/home/view/home_screen.dart';
import 'package:simple_bible_app/shared/state/app_state.dart';

void main() {
  testWidgets(
      'Home screen shows a time-aware greeting and notifications action',
      (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final state = AppState();

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            const <String>{
              'Good Morning',
              'Good Afternoon',
              'Good Evening',
              'Good Night',
            }.contains(widget.data),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });
}
