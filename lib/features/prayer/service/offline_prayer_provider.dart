import '../model/prayer_model.dart';

class OfflinePrayerProvider implements IPrayerProvider {
  static const Map<String, Map<String, String>> _topicData = {
    'Peace': {
      'verse':
          'Peace I leave with you. My peace I give to you; not as the world gives, I give to you. Don’t let your heart be troubled, neither let it be fearful.',
      'ref': 'John 14:27',
      'reflection': "What area of your life needs God's peace today?"
    },
    'Fear': {
      'verse':
          'Don’t you be afraid, for I am with you. Don’t be dismayed, for I am your God. I will strengthen you. Yes, I will help you. Yes, I will uphold you with the right hand of my righteousness.',
      'ref': 'Isaiah 41:10',
      'reflection': 'What fear can you surrender to God right now?'
    },
    'Guidance': {
      'verse':
          'Trust in Yahweh with all your heart, and don’t lean on your own understanding. In all your ways acknowledge him, and he will make your paths straight.',
      'ref': 'Proverbs 3:5-6',
      'reflection': "Where do you need God's direction in your life?"
    },
    'Gratitude': {
      'verse':
          'Give thanks to Yahweh, for he is good, for his loving kindness endures forever.',
      'ref': 'Psalm 136:1',
      'reflection': 'What are three things you can thank God for today?'
    },
    'Strength': {
      'verse': 'I can do all things through Christ, who strengthens me.',
      'ref': 'Philippians 4:13',
      'reflection':
          "Where do you feel weak, and how can Christ's strength sustain you?"
    },
  };

  @override
  Future<PrayerModel> generate(String topic) async {
    // Simulate a slight network delay to make it feel like "generation"
    await Future.delayed(const Duration(seconds: 1));

    final data = _topicData[topic] ?? _topicData['Peace']!;

    final prayer = """
Lord, I bring my heart before You today.

Your word says: "${data['verse']}"

Help me to trust You in this area of $topic.
Strengthen me, guide me, and fill me with Your grace.

Amen.
""";

    return PrayerModel(
      topic: topic,
      verse: data['verse']!,
      reference: data['ref']!,
      prayer: prayer.trim(),
      reflection: data['reflection']!,
    );
  }
}
