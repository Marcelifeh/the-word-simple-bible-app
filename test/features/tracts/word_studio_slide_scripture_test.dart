import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/tracts/model/tract_share_theme.dart';
import 'package:simple_bible_app/features/tracts/view/widgets/tract_canvas.dart';

void main() {
  const scripture = 'But God demonstrates his own love for us.';
  const invitation = 'You are invited to reflect and respond.';

  Future<void> showPage(WidgetTester tester, int page) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 500,
            child: TractCanvas(
              title: "God's Love",
              body: 'First paragraph.\n\nSecond paragraph.',
              scripture: scripture,
              scriptureRef: 'Romans 5:8',
              invitationText: invitation,
              theme: tractThemes.first,
              selectedPage: page,
              isExportMode: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('opening content slide includes the key verse', (tester) async {
    await showPage(tester, 1);
    expect(find.text(scripture), findsOneWidget);
    expect(find.text('First paragraph.\n\nSecond paragraph.'), findsOneWidget);
  });

  testWidgets('invitation slide does not repeat the key verse', (tester) async {
    // Two short paragraphs fit one content slide, so invitation is page 2.
    await showPage(tester, 2);
    expect(find.text(scripture), findsNothing);
    expect(find.text('— Romans 5:8'), findsNothing);
    expect(find.text(invitation), findsOneWidget);
  });

  testWidgets('full page retains the key verse before body', (tester) async {
    await showPage(tester, 0);
    expect(find.text(scripture), findsOneWidget);
    expect(find.text(invitation), findsOneWidget);
  });
}
