import '../../core/narration/contracts/narratable_content.dart';
import '../../core/narration/models/narration_segment.dart';

/// Gospel Tract model — each entry is a self-contained shareable scripture card.
class TractModel implements NarratableContent {
  const TractModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.hook,
    required this.body,
    required this.keyVerse,
    required this.keyVerseRef,
    required this.shareText,
    required this.category,
    required this.gradientColors,
  });

  final String id;
  final String title;
  final String summary; // 1-line subtitle shown in list
  final String hook; // Short emotional hook shown above title & in share
  final String body; // Full tract body shown in detail screen
  final String keyVerse; // Highlighted verse text
  final String keyVerseRef; // e.g. "John 3:16"
  final String shareText; // Pre-composed viral share message
  final String category; // evangelism | encouragement | salvation
  /// Gradient color values (2 entries), e.g. [0xFF8B5CF6, 0xFF6D28D9]
  /// Gradient color values (2 entries), e.g. [0xFF8B5CF6, 0xFF6D28D9]
  final List<int> gradientColors;

  @override
  List<NarrationSegment> get narrationSegments {
    return [
      NarrationSegment(id: '${id}_title', text: title),
      NarrationSegment(id: '${id}_hook', text: hook, pauseAfter: const Duration(milliseconds: 800)),
      NarrationSegment(id: '${id}_verse', text: '$keyVerse... $keyVerseRef', reference: keyVerseRef, pauseAfter: const Duration(milliseconds: 1500)),
      NarrationSegment(id: '${id}_body', text: body),
    ];
  }

  /// Seed data — 3 bundled tracts shipped with the app.
  static const List<TractModel> seeds = [
    TractModel(
      id: 'good_news',
      title: 'The Good News',
      summary: 'Why Jesus came — and what it means for you',
      hook: 'Have you heard the most important message ever?',
      category: 'evangelism',
      gradientColors: [0xFF8B5CF6, 0xFF6D28D9],
      keyVerse:
          'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      keyVerseRef: 'John 3:16',
      body:
          '''God loves you — not because of what you do, but because of who He is.

We were all separated from God by sin (Romans 3:23). The consequence of sin is death — a spiritual, eternal separation from God (Romans 6:23).

But God, in His great love, sent Jesus — fully God and fully human — to take our punishment.

Jesus died on the cross as the perfect sacrifice, was buried, and on the third day rose again. This is the Good News: death is defeated.

What must you do?
→ Believe that Jesus died for your sins and rose again.
→ Confess Him as Lord of your life.
→ Begin a new life walking with Him.

"If you confess with your mouth, "Jesus is Lord," and believe in your heart that God raised him from the dead, you will be saved." — Romans 10:9

This is your moment. The door is open.''',
      shareText:
          'Have you heard the most important message ever? 🙏\n\n"For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life." — John 3:16\n\nGod loves you and has a plan for your life.\n\nRead the full Good News in The Word app 👇\n[your app link]',
    ),
    TractModel(
      id: 'gods_love',
      title: "God's Love",
      summary: 'A love that never fails, never fades',
      hook: 'You are not too broken to be loved.',
      category: 'encouragement',
      gradientColors: [0xFFF59E0B, 0xFFD97706],
      keyVerse:
          'But God demonstrates his own love for us in this: While we were still sinners, Christ died for us.',
      keyVerseRef: 'Romans 5:8',
      body: '''You are not an accident. You are deeply, intentionally loved.

Before the world was formed, God knew your name (Jeremiah 1:5). In your weakness, He is strong (2 Corinthians 12:9). In your failures, His mercy is new every morning (Lamentations 3:22–23).

No sin is too great. No wound is too deep. No distance is too far.

"I have loved you with an everlasting love; I have drawn you with unfailing kindness." — Jeremiah 31:3

God's love is not earned. It is given — freely, fully, forever.

If you've been told you are too broken, too far gone, or too sinful:
The Father ran to the prodigal son before he finished his sentence (Luke 15:20). He will run to you too.

Come home.''',
      shareText:
          'You are not too broken to be loved. ❤️\n\n"But God demonstrates his own love for us in this: While we were still sinners, Christ died for us." — Romans 5:8\n\nShare this with someone who needs to hear it today.\n\nRead more in The Word app 👇\n[your app link]',
    ),
    TractModel(
      id: 'how_to_be_saved',
      title: 'How to Be Saved',
      summary: 'Four simple truths that change everything',
      hook: 'What if four truths could change your life forever?',
      category: 'salvation',
      gradientColors: [0xFF10B981, 0xFF059669],
      keyVerse:
          'For it is by grace you have been saved, through faith — and this is not from yourselves, it is the gift of God.',
      keyVerseRef: 'Ephesians 2:8',
      body: '''Salvation is not earned — it is received. Here are four truths:

1. GOD LOVES YOU
"For God so loved the world..." — John 3:16
He created you for relationship with Him.

2. SIN SEPARATES US
"All have sinned and fall short of the glory of God." — Romans 3:23
Sin is anything that falls short of God's perfect standard. It breaks our connection with Him.

3. JESUS IS THE BRIDGE
"Christ died for our sins... He was buried... He was raised on the third day." — 1 Corinthians 15:3–4
Jesus paid the price we owed. He is the only way (John 14:6).

4. YOU MUST CHOOSE
Salvation is a gift — but a gift must be received.
→ Admit you have sinned.
→ Believe Jesus died and rose for you.
→ Commit your life to Him.

"Everyone who calls on the name of the Lord will be saved." — Romans 10:13

Pray this now:
"Lord Jesus, I know I am a sinner. I believe You died for my sins and rose again. I turn from my sins and invite You into my heart as my Lord and Saviour. Amen."

Welcome to the family.''',
      shareText:
          'What if four truths could change your life forever? 📖\n\n"Everyone who calls on the name of the Lord will be saved." — Romans 10:13\n\nSalvation is a free gift. Here\'s how to receive it:\n\nRead in The Word app 👇\n[your app link]',
    ),
  ];
}
