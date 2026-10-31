import '../model/daily_altar_content.dart';
import '../model/daily_altar_evening_reflection.dart';
import '../model/daily_altar_obedience_step.dart';
import '../model/daily_altar_prayer_prompt.dart';
import '../model/daily_altar_reflection_prompts.dart';
import '../model/daily_altar_scripture.dart';
import '../model/daily_altar_support_origin.dart';
import '../model/daily_altar_understanding.dart';

/// Human-curated offline Daily Altar content.
///
/// This library deliberately contains no generated or network-fetched
/// spiritual guidance.
abstract final class DailyAltarCuratedLibrary {
  static const abideInChrist = DailyAltarContent(
    id: 'john-15-abide-in-christ',
    scripture: DailyAltarScripture(
      reference: 'John 15:4-5',
      translationId: 'kjv',
      text: 'Abide in me, and I in you. As the branch cannot bear fruit of '
          'itself, except it abide in the vine; no more can ye, except ye '
          'abide in me. I am the vine, ye are the branches: He that abideth '
          'in me, and I in him, the same bringeth forth much fruit: for '
          'without me ye can do nothing.',
    ),
    understanding: DailyAltarUnderstanding(
      context:
          'Jesus spoke these words to His disciples as He prepared them for '
          'life and ministry after His departure. Using the picture of a vine '
          'and its branches, He showed that spiritual life and fruitfulness '
          'depend upon continuing fellowship with Him.',
      centralTruth:
          'Spiritual fruit is not produced by independence from Christ but by '
          'continual dependence upon Him.',
      lookAgain:
          'Jesus places abiding before fruitfulness. The branch does not '
          'struggle to manufacture life; it remains connected to the vine, '
          'and fruit grows from that living union.',
      origin: DailyAltarSupportOrigin.curated,
    ),
    reflection: DailyAltarReflectionPrompts(
      aboutGod:
          'What does this passage reveal about Christ as the source of your '
          'spiritual life and strength?',
      aboutMe:
          'Where have you been relying mainly on your own strength instead of '
          'remaining consciously dependent on Christ?',
      response:
          'What would abiding in Christ look like practically in one part of '
          'your life today?',
      origin: DailyAltarSupportOrigin.curated,
    ),
    prayer: DailyAltarPrayerPrompt(
      text: 'Father, teach me to remain in Christ instead of depending upon my '
          'own strength. Draw my heart continually back to Your Word and Your '
          'presence. Let my choices, attitudes, work, and relationships grow '
          'out of fellowship with You. Produce in me the fruit that I cannot '
          'produce by myself.',
      origin: DailyAltarSupportOrigin.curated,
    ),
    obedience: DailyAltarObedienceStep(
      text:
          'Choose one important task, decision, or conversation today. Before '
          'you enter it, pause deliberately and pray, acknowledging your '
          'dependence on Christ rather than rushing ahead in self-reliance.',
      origin: DailyAltarSupportOrigin.curated,
    ),
    carryWord: DailyAltarScripture(
      reference: 'John 15:5',
      translationId: 'kjv',
      text: 'For without me ye can do nothing.',
    ),
    eveningReflection: DailyAltarEveningReflection(
      rememberedWordPrompt: 'When did today’s Scripture return to your mind?',
      obediencePrompt:
          'Did you pause and consciously depend on Christ before the action '
          'you chose this morning? What happened?',
      relevancePrompt:
          'Where did the truth about abiding in Christ become especially '
          'relevant during your day?',
      heartResponsePrompt:
          'Is there anything from today that you want to confess, surrender, '
          'or thank God for?',
      carryForwardPrompt:
          'What truth about depending on Christ do you want to carry into '
          'tomorrow?',
      origin: DailyAltarSupportOrigin.curated,
    ),
  );

  static const all = <DailyAltarContent>[
    abideInChrist,
  ];
}
