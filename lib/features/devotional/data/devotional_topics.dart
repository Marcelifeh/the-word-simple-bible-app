import '../model/devotional_model.dart';
import '../model/devotional_section.dart';

/// All seed devotionals shipped with the app — fully offline, zero API needed.
///
/// A growing set of themes, each with rich multi-section content. The service cycles
/// through them by date so every day brings a fresh experience.
final class DevotionalTopics {
  DevotionalTopics._();

  static final List<DevotionalModel> all = [
    // ── 1. PEACE ────────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'peace',
      theme: 'Peace',
      title: 'The Peace That Guards the Heart',
      scripture: 'Be anxious for nothing, but in everything by prayer and '
          'supplication, with thanksgiving, let your requests be made known to '
          'God; and the peace of God, which surpasses all understanding, will '
          'guard your hearts and minds through Christ Jesus.',
      scriptureReference: 'Philippians 4:6–7',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Anxiety Reveals the Weight the Heart Is Carrying',
          body:
              'Anxiety often grows where the heart feels responsible for outcomes '
              'it cannot control. It is the internal pressure created by '
              'uncertainty, fear, and the need to secure the future through '
              'human effort. While concern may be natural, anxiety becomes '
              'dangerous when it begins to dominate the mind and consume peace.\n\n'
              'Paul’s instruction to “be anxious for nothing” is not a denial of '
              'life’s realities but an invitation into a different response. God '
              'does not ignore human burdens; He redirects believers from '
              'carrying them alone into bringing them before Him. Anxiety thrives '
              'where dependence on God weakens, but peace begins where surrender '
              'starts.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Prayer Is the Exchange Point Between Burden and Peace',
          body: 'Philippians 4 reveals that prayer is not merely a religious '
              'activity — it is a spiritual exchange. Through prayer, burdens '
              'are transferred from human limitation into God’s hands. This is '
              'why Paul connects prayer directly to peace.\n\n'
              'Prayer acknowledges that God is both willing and able to carry '
              'what overwhelms us. Supplication reflects honest dependence, '
              'while thanksgiving shifts focus from fear to God’s faithfulness. '
              'Gratitude weakens anxiety because it reminds the heart of who God '
              'has already proven Himself to be. As 1 Peter 5:7 teaches, '
              'believers are invited to cast their cares upon God because He '
              'cares for them personally.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Mind Is a Primary Battlefield of Anxiety',
          body:
              'Anxiety often begins in the mind before it affects emotions and '
              'behavior. Thoughts about the future, fear of failure, unresolved '
              'uncertainty, and imagined outcomes can quietly take control if '
              'left unchecked.\n\n'
              'This is why Paul specifically says the peace of God will guard '
              'both hearts and minds. The word “guard” carries the image of '
              'protection, as though God’s peace stands watch over the inner life. '
              'Peace is not merely emotional calmness; it is spiritual protection '
              'against internal chaos. The enemy seeks to flood the mind with '
              'fear and instability, but God’s peace creates stability even when '
              'circumstances remain unresolved.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Peace Is Not Dependent on Circumstances',
          body: 'The peace described in Philippians 4 surpasses understanding '
              'because it does not operate according to natural logic. Human '
              'peace depends on favorable conditions, predictable outcomes, and '
              'resolved problems. But God’s peace remains even when circumstances '
              'are uncertain.\n\n'
              'This peace is supernatural because it flows from God’s presence '
              'rather than external control. Jesus reflects this in John 14:27 '
              'when He declares that His peace is different from the peace the '
              'world gives. A believer can experience inward calm while outward '
              'battles continue because divine peace is rooted in God’s '
              'unchanging nature.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Peace Must Be Maintained Through Continual Communion',
          body:
              'Peace is not sustained accidentally. It grows through continual '
              'relationship with God. Prayer, worship, meditation on Scripture, '
              'and thanksgiving keep the heart aligned with heaven rather than '
              'consumed by fear.\n\n'
              'When communion with God weakens, anxiety often increases because '
              'the soul begins drawing strength from itself instead of from God. '
              'But as dependence deepens, peace becomes stronger than panic. The '
              'believer is not called to deny problems but to face them from a '
              'place of spiritual security rather than fear-driven instability.',
        ),
      ],
      finalRevelation:
          'Peace is not the absence of problems — it is the presence of God '
          'ruling above them.',
      reflectionQuestions: const [
        'What anxieties have been occupying my heart and mind?',
        'Have I been carrying burdens God is asking me to surrender?',
        'Am I feeding fear or strengthening peace through communion with God?',
      ],
      prayer: 'Lord,\n'
          'You see every burden, fear, and anxious thought within me.\n'
          'Teach me to bring everything before You instead of carrying it alone.\n\n'
          'Guard my heart and mind with Your peace when uncertainty tries to '
          'overwhelm me.\n'
          'Help me to trust You beyond what I understand and to remain anchored '
          'in Your faithfulness.\n\n'
          'Strengthen my prayer life, deepen my dependence on You,\n'
          'and teach me to live from a place of peace rather than fear.\n\n'
          'Let Your presence calm every storm within me\n'
          'and remind me daily that You are in control.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 1),
    ),

    // ── 2. STRENGTH ──────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'strength',
      theme: 'Strength',
      title: 'Strength for the Weary Soul',
      scripture:
          'But those who wait on the Lord shall renew their strength; they '
          'shall mount up with wings like eagles, they shall run and not be '
          'weary, they shall walk and not faint.',
      scriptureReference: 'Isaiah 40:31',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Waiting on God Is Not Passive but Transformational',
          body:
              'In a world driven by speed, productivity, and constant movement, '
              'waiting often feels unproductive. Yet Scripture presents waiting '
              'on the Lord as a place of renewal rather than delay. Biblical '
              'waiting is not passive resignation; it is active dependence. It '
              'is the posture of a heart that remains anchored in trust even '
              'when answers are not immediate.\n\n'
              'Many believers become exhausted not because they are weak, but '
              'because they are carrying burdens God never intended them to '
              'carry alone. Human strength eventually reaches its limit, but '
              'divine strength flows from communion with God. Waiting shifts '
              'the believer from striving in self-effort to depending on '
              'God\'s sufficiency.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God Renews Strength Rather Than Merely Replacing It',
          body:
              'Isaiah does not simply say God gives strength; he says He renews '
              'it. Renewal implies restoration of what has been depleted. God '
              'understands human weakness, emotional exhaustion, spiritual '
              'weariness, and the weight of prolonged battles. He does not '
              'condemn the weary — He invites them into His strength.\n\n'
              'As Matthew 11:28 records, Jesus calls the weary and burdened '
              'to come to Him for rest. God\'s response to exhaustion is not '
              'rejection but invitation. He meets weakness with grace and '
              'weariness with renewal.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Weariness Becomes Dangerous When It Leads to Disconnection',
          body:
              'Physical tiredness is natural, but spiritual weariness becomes '
              'dangerous when it causes distance from God. Discouragement can '
              'slowly weaken prayer, reduce spiritual sensitivity, and make the '
              'believer vulnerable to hopelessness.\n\n'
              'The enemy often attacks weary seasons because exhaustion weakens '
              'resistance. This is why spiritual renewal is essential. Strength '
              'is not sustained merely through determination but through abiding '
              'in God\'s presence. As Jesus teaches in John 15:5, apart from '
              'Him we can do nothing. When connection with God weakens, '
              'endurance fades. But when intimacy with Him is restored, '
              'strength begins to rise again.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God Gives Strength for Every Season Differently',
          body: 'Isaiah describes three dimensions of movement: mounting up, '
              'running, and walking. This reveals that God provides strength '
              'appropriate for different seasons of life. Some seasons require '
              'soaring above challenges with unusual strength, while others '
              'require endurance to keep running faithfully. Yet many seasons '
              'simply require the grace to keep walking without fainting.\n\n'
              'Often, believers celebrate the soaring seasons but overlook the '
              'faithfulness required in ordinary walking seasons. Yet walking '
              'without fainting is also evidence of divine strength. God is not '
              'only present in extraordinary victories — He is equally present '
              'in quiet perseverance.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Endurance Is Built Through Continual Dependence',
          body: 'Strength is not renewed once for a lifetime; it is renewed '
              'continually through dependence on God. Every day presents '
              'opportunities either to rely on self or to draw from God\'s '
              'presence. Spiritual endurance grows through consistent communion, '
              'prayer, worship, and trust.\n\n'
              'The eagle imagery in Isaiah reflects elevation above storms '
              'rather than escape from them. God does not always remove the '
              'storm immediately, but He empowers the believer to rise above '
              'what once overwhelmed them. What once drained strength becomes '
              'the very place where God reveals His sustaining power.',
        ),
      ],
      finalRevelation:
          'God does not merely strengthen the believer to survive the journey '
          '— He renews them so they can rise above what once exhausted them.',
      reflectionQuestions: const [
        'What burdens have I been carrying in my own strength?',
        'Have I been waiting on God or striving without Him?',
        'Where do I need God\'s renewal most today?',
      ],
      prayer: 'Lord,\n'
          'You see every place where I am weary, burdened, and exhausted.\n'
          'Teach me to wait on You instead of relying on my own strength.\n\n'
          'Renew my heart where I have become discouraged,\n'
          'restore my mind where I have become overwhelmed,\n'
          'and strengthen my spirit where I have grown weak.\n\n'
          'Help me to remain connected to You in every season,\n'
          'whether I am soaring, running, or simply walking through '
          'difficult moments.\n\n'
          'Let Your strength sustain me daily,\n'
          'and teach me to rise above every weight through dependence on You.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 2),
    ),

    // ── 3. GUIDANCE ──────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'guidance',
      theme: 'Guidance',
      title: 'Trust Beyond Understanding',
      scripture:
          'Trust in the Lord with all your heart, and lean not on your own '
          'understanding; in all your ways acknowledge Him, and He shall '
          'direct your paths.',
      scriptureReference: 'Proverbs 3:5–6',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Trust Begins Where Human Understanding Reaches Its Limit',
          body:
              'Trust is easy when life makes sense, but true trust is revealed '
              'when clarity is absent. Proverbs 3:5 calls believers beyond '
              'intellectual dependence into wholehearted reliance on God. This '
              'does not mean understanding is unimportant, but it means human '
              'reasoning was never designed to replace dependence on God.\n\n'
              'Many struggles begin when people attempt to navigate life through '
              'limited perspective alone. Human understanding can interpret '
              'situations incorrectly because it only sees fragments, while God '
              'sees the complete picture. Trust requires accepting that God’s '
              'wisdom extends beyond what the mind can presently comprehend. '
              'As Isaiah 55:8–9 reveals, God’s thoughts and ways are higher '
              'than human thoughts and ways.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Leaning on Human Understanding Creates Instability',
          body:
              'The instruction not to lean on personal understanding reveals that '
              'human reasoning can become a false support system. To “lean” means '
              'to rest weight upon something for stability. Many people '
              'unknowingly place the weight of their security on emotions, logic, '
              'predictions, or visible circumstances rather than on God.\n\n'
              'The problem with human understanding is that it constantly shifts '
              'according to circumstances. What feels certain today may collapse '
              'tomorrow. But God remains unchanging. When trust is placed in Him '
              'instead of fluctuating understanding, stability replaces fear. '
              'This is why faith often requires obedience before complete '
              'explanation.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Control Often Competes with Trust',
          body:
              'One of the greatest enemies of trust is the desire for control. '
              'Human nature wants predictability, guarantees, and visible '
              'assurance before surrendering fully. Yet trust requires releasing '
              'the need to control every outcome.\n\n'
              'Control creates anxiety because it places pressure on human '
              'ability to manage what only God can truly sustain. Surrender, '
              'however, transfers that burden back to God. The believer was '
              'never meant to carry the responsibility of orchestrating every '
              'detail of life independently. As Philippians 4:6–7 teaches, '
              'peace begins to guard the heart when burdens are brought before '
              'God.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Acknowledging God Invites Divine Direction',
          body:
              'Proverbs 3:6 reveals that guidance flows from acknowledgment. To '
              'acknowledge God means more than occasional recognition — it means '
              'involving Him in every area of life. Many seek God only in '
              'crisis, but Scripture calls for continual dependence and '
              'communion.\n\n'
              'When God is acknowledged consistently, decisions become aligned '
              'with His wisdom rather than driven by impulse, fear, or pride. '
              'Divine direction often becomes clearer as intimacy with God '
              'deepens. Guidance is not merely about knowing where to go; it is '
              'about walking closely enough with God to recognize His leading.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Trust Is a Daily Walk, Not a One-Time Decision',
          body:
              'Trust is not established once and completed forever. Every day '
              'presents opportunities either to depend on God or retreat into '
              'self-reliance. Seasons of uncertainty repeatedly test where '
              'confidence truly rests.\n\n'
              'Walking with God requires continual surrender of fears, '
              'expectations, timelines, and personal plans. Yet each step of '
              'trust strengthens spiritual maturity. Over time, believers begin '
              'to discover that God’s faithfulness is more reliable than human '
              'understanding could ever be. As 2 Corinthians 5:7 reminds '
              'believers, the Christian life is lived by faith and not by sight.',
        ),
      ],
      finalRevelation:
          'Trust is not the absence of questions — it is the decision to follow '
          'God even when answers are incomplete.',
      reflectionQuestions: const [
        'Where have I been leaning on my own understanding instead of God?',
        'What area of my life am I struggling to fully surrender?',
        'Am I seeking control or cultivating trust?',
      ],
      prayer: 'Lord,\n'
          'Teach me to trust You beyond what I can see or understand.\n'
          'Help me to stop leaning on my own reasoning and depend fully on Your '
          'wisdom.\n\n'
          'Reveal areas where fear and control have replaced surrender within '
          'me.\n'
          'Guide my heart into deeper trust and help me acknowledge You in '
          'every part of my life.\n\n'
          'Direct my paths according to Your will,\n'
          'and strengthen my faith when clarity feels distant.\n\n'
          'Let my confidence rest not in human understanding,\n'
          'but in Your unchanging faithfulness.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 3),
    ),

    // ── 4. GRATITUDE ─────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'gratitude',
      theme: 'Gratitude',
      title: 'Gratitude in Every Season',
      scripture:
          'In everything give thanks; for this is the will of God in Christ '
          'Jesus for you.',
      scriptureReference: '1 Thessalonians 5:18',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Gratitude Is a Posture, Not a Reaction',
          body:
              'Most people naturally give thanks when life is favorable, prayers '
              'are answered quickly, and circumstances feel pleasant. But 1 '
              'Thessalonians 5:18 calls believers into something deeper — a '
              'lifestyle of gratitude that is not dependent on changing '
              'situations. Paul does not say to give thanks for everything, but '
              'in everything.\n\n'
              'This distinction reveals that gratitude is not denial of pain; '
              'it is the decision to remain aware of God even within difficulty. '
              'True gratitude flows from trust in God’s character rather than '
              'comfort in circumstances. Thanksgiving becomes a spiritual '
              'posture that keeps the heart connected to God instead of '
              'consumed by temporary realities.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Gratitude Protects the Heart from Bitterness and Despair',
          body:
              'One of the dangers of prolonged hardship is that it can slowly '
              'shift the heart toward bitterness, complaint, and '
              'discouragement. Gratitude interrupts this process by redirecting '
              'focus from what is lacking to what God has already done and '
              'continues to do.\n\n'
              'The human mind naturally magnifies problems when gratitude is '
              'absent. But thanksgiving restores perspective. It reminds the '
              'believer that God’s faithfulness is not determined by current '
              'emotions or unresolved situations. As Psalm 103:2 encourages, '
              'believers are called not to forget God’s benefits and faithfulness.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Enemy Seeks to Isolate the Heart Through Complaint',
          body:
              'Complaint often begins subtly. When disappointment is rehearsed '
              'continually, the heart becomes vulnerable to hopelessness, '
              'resentment, and spiritual weariness. The enemy understands that '
              'a heart consumed with negativity struggles to remain '
              'spiritually sensitive and faith-filled.\n\n'
              'Throughout Scripture, persistent complaining frequently revealed '
              'deeper issues of distrust toward God. The Israelites often '
              'allowed complaint to overshadow remembrance of God’s provision. '
              'Thanksgiving becomes spiritual resistance against despair '
              'because it keeps the believer mindful of God’s goodness even in '
              'unfinished seasons.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Gratitude Opens the Heart to Deeper Awareness of God',
          body: 'Thanksgiving does more than change perspective — it deepens '
              'awareness of God’s presence. A grateful heart becomes more '
              'sensitive to grace, provision, and divine activity that might '
              'otherwise be overlooked.\n\n'
              'Gratitude shifts the soul from striving into worship. It reminds '
              'believers that life itself, salvation, grace, strength, and '
              'daily sustenance are gifts from God. As James 1:17 declares, '
              'every good and perfect gift comes from above. The more gratitude '
              'grows, the more the believer begins to recognize God’s hand.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Thanksgiving Sustains Spiritual Strength Through Every Season',
          body: 'Gratitude is not only for victorious seasons; it sustains '
              'believers through difficult ones. In moments where answers are '
              'delayed and outcomes remain uncertain, thanksgiving keeps faith '
              'alive. It becomes an expression of confidence that God is still '
              'working even when circumstances appear unchanged.\n\n'
              'A thankful believer is someone who refuses to allow struggles to '
              'overshadow God’s faithfulness. Thanksgiving strengthens '
              'endurance because it keeps the heart anchored in hope rather '
              'than consumed by temporary frustration.',
        ),
      ],
      finalRevelation:
          'Gratitude does not ignore life’s difficulties — it reveals a heart '
          'that still sees God above them.',
      reflectionQuestions: const [
        'Have I allowed complaint to shape my perspective recently?',
        'What blessings and evidences of God’s faithfulness have I overlooked?',
        'Can I still give thanks even in unfinished or difficult seasons?',
      ],
      prayer: 'Lord,\n'
          'Teach me to cultivate gratitude in every season of life.\n'
          'Help me not to become consumed by difficulties, disappointments, or '
          'delays.\n\n'
          'Guard my heart from bitterness, complaint, and discouragement,\n'
          'and remind me continually of Your faithfulness and goodness.\n\n'
          'Open my eyes to recognize Your hand in both ordinary and difficult '
          'moments.\n'
          'Let thanksgiving become a constant posture within me,\n'
          'so that my heart remains anchored in worship and trust.\n\n'
          'Even when circumstances are uncertain,\n'
          'help me to remember that You are still good, still present, and '
          'still working.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 4),
    ),

    // ── 5. FAITH UNDER FEAR ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'fear',
      theme: 'Faith',
      title: 'Fear Cannot Remain Where God Is Present',
      scripture:
          'Fear not, for I am with you; be not dismayed, for I am your God. '
          'I will strengthen you, yes, I will help you, I will uphold you '
          'with My righteous right hand.',
      scriptureReference: 'Isaiah 41:10',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Fear Grows Where Awareness of God’s Presence Weakens',
          body:
              'Fear often becomes strongest when the heart feels alone, uncertain, '
              'or unsupported. It magnifies danger, exaggerates weakness, and '
              'convinces the mind that the future is unsafe. Yet God begins '
              'Isaiah 41:10 not with a command rooted in human strength, but '
              'with a reminder of divine presence: “Fear not, for I am with you.”\n\n'
              'This reveals that the answer to fear is not merely courage — it is '
              'awareness of God’s nearness. Throughout Scripture, God repeatedly '
              'reassured His people with His presence before addressing their '
              'battles. His presence changes the atmosphere of uncertainty '
              'because the believer no longer faces life alone. As Psalm 23:4 '
              'declares, even in the valley of the shadow of death, fear loses '
              'its dominance when God is present.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'God’s Relationship with You Is Greater Than Your Circumstances',
          body: 'The phrase “I am your God” reveals covenant relationship, not '
              'distant observation. God is not merely watching human struggles '
              'from afar — He identifies Himself personally with His people. '
              'Fear often causes believers to interpret circumstances as '
              'evidence of abandonment, but God’s declaration reminds them that '
              'their relationship with Him remains secure even in difficulty.\n\n'
              'Circumstances change constantly, but God’s character does not. '
              'His faithfulness is not determined by visible outcomes or '
              'temporary struggles. When the heart remembers who God is, fear '
              'begins to lose authority over the mind. This is why trust '
              'becomes stronger when identity is rooted in God’s covenant.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Fear Weakens the Mind Before It Weakens the Circumstances',
          body: 'Fear is not only emotional — it affects perception, '
              'decision-making, and spiritual stability. A fearful mind often '
              'expects defeat before the battle even begins. This is why the '
              'enemy frequently attacks through intimidation, discouragement, '
              'and anxiety.\n\n'
              'The word “dismayed” in Isaiah 41:10 carries the idea of being '
              'overwhelmed, shattered internally, or losing courage. Fear seeks '
              'to destabilize the inner life before external collapse ever '
              'occurs. But God responds with assurance: “I will strengthen you.” '
              'Divine strength is not the removal of all difficulty; it is God '
              'sustaining the believer within difficulty. As 2 Corinthians 12:9 '
              'reveals, God’s strength becomes most visible in human weakness.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God Does Not Only Strengthen—He Also Upholds',
          body:
              'Isaiah 41:10 moves beyond encouragement into divine commitment. '
              'God promises not only to strengthen and help, but also to uphold. '
              'To uphold means to sustain, support, and prevent collapse. This '
              'reveals that believers are not held together by personal '
              'strength alone but by God’s sustaining hand.\n\n'
              'Many people fear failure because they trust in their ability to '
              'remain strong indefinitely. But God never intended believers to '
              'sustain themselves independently. His righteous right hand '
              'represents both His power and His faithfulness. Even when '
              'personal strength feels exhausted, God remains capable of '
              'carrying what the believer cannot carry alone.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Courage Flows from Dependence, Not Self-Confidence',
          body: 'Biblical courage is not rooted in self-confidence but in '
              'confidence in God. Human confidence fluctuates according to '
              'ability, emotions, and circumstances, but confidence in God '
              'remains stable because He is unchanging.\n\n'
              'This is why believers can continue moving forward even while '
              'feeling weak internally. Courage is not the absence of fear — '
              'it is choosing trust despite fear. Dependence on God produces '
              'stability because it shifts the burden from fragile human ability '
              'to divine sufficiency. As Joshua 1:9 reminds believers, strength '
              'and courage are possible because God goes with them.',
        ),
      ],
      finalRevelation:
          'Fear loses its power when the heart becomes more aware of God’s '
          'presence than of its problems.',
      reflectionQuestions: const [
        'What fears have been influencing my thoughts and decisions recently?',
        'Have I become more focused on my problems than on God’s presence?',
        'Where do I need to depend on God’s strength instead of my own?',
      ],
      prayer: 'Lord,\n'
          'You see every fear, uncertainty, and burden within me.\n'
          'Help me to become more aware of Your presence than of the '
          'challenges surrounding me.\n\n'
          'Strengthen me where I feel weak,\n'
          'encourage me where I feel discouraged,\n'
          'and uphold me where I feel unstable.\n\n'
          'Teach me to trust You deeply even when circumstances remain '
          'uncertain.\n'
          'Guard my mind from fear and remind me continually that I am never '
          'alone.\n\n'
          'Let Your presence become my confidence,\n'
          'Your strength become my stability,\n'
          'and Your faithfulness become my peace.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 5),
    ),

    // ── 6. POWER ─────────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'power',
      theme: 'Power',
      title: 'The Greatness of God’s Power Within the Believer',
      scripture:
          'And what is the exceeding greatness of His power toward us who '
          'believe, according to the working of His mighty power.',
      scriptureReference: 'Ephesians 1:19',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Many Believers Live Below the Power Available to Them',
          body:
              'Paul’s prayer in Ephesians was not that believers would receive '
              'new power, but that they would understand the greatness of the '
              'power already working toward them. One of the greatest struggles '
              'in the Christian life is not the absence of God’s power but the '
              'lack of awareness of it.\n\n'
              'Many believers live defeated, discouraged, and spiritually weak '
              'because they see themselves through limitation rather than '
              'through what God has made available in Christ. Yet the same '
              'power that raised Christ from the dead is at work in those who '
              'believe, as revealed later in Ephesians 1:20.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God’s Power Is Not Merely External but Internal',
          body:
              'When people think about God’s power, they often imagine dramatic '
              'miracles or outward manifestations. But Scripture reveals that '
              'God’s power first works internally — transforming the heart, '
              'renewing the mind, strengthening faith, and producing spiritual '
              'endurance.\n\n'
              'True power is not only seen in outward victories but also in '
              'inward transformation. The ability to remain faithful under '
              'pressure, to walk in love despite offense, and to endure through '
              'trials are all evidence of divine power operating within the '
              'believer. As Ephesians 1:7 reveals, God has not given a spirit '
              'of fear but of power, love, and a sound mind.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Unbelief Limits What We Experience',
          body:
              'God’s power is available, but unbelief often prevents believers '
              'from walking in its fullness. Fear, doubt, insecurity, and '
              'spiritual passivity can cause a person to live beneath what God '
              'has already provided.\n\n'
              'Throughout Scripture, Jesus repeatedly responded to faith '
              'because faith creates alignment with what God desires to '
              'release. Unbelief does not diminish God’s power, but it limits '
              'human participation in it. This is why the renewal of the mind '
              'is essential. A believer cannot consistently walk in power '
              'while continually thinking from a place of defeat.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Power Is Meant to Produce Transformation',
          body: 'The purpose of God’s power is not merely display — it is '
              'transformation. Divine power changes desires, reshapes '
              'character, strengthens weakness, and enables obedience. It '
              'empowers believers to become what they could never become '
              'through human effort alone.\n\n'
              'As 2 Peter 1:3 explains, God’s divine power has given '
              'everything needed for life and godliness. This means the '
              'believer is not spiritually powerless or abandoned but fully '
              'equipped through Christ. Transformation happens when believers '
              'stop striving through self-effort and begin depending on God’s '
              'strength.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Power Becomes Evident Through Daily Dependence',
          body: 'God’s power is not sustained through occasional spiritual '
              'moments but through continual dependence. Daily prayer, '
              'obedience, surrender, and communion with God keep the believer '
              'aligned with the source of strength.\n\n'
              'The Christian life was never designed to be lived through human '
              'ability alone. As Jesus declares in John 15:5, apart from Him '
              'we can do nothing. Dependence is not weakness — it is the '
              'pathway through which divine power flows consistently.',
        ),
      ],
      finalRevelation:
          'God’s power is not distant from the believer — it is already '
          'working within those who believe.',
      reflectionQuestions: const [
        'Am I living with awareness of God’s power within me?',
        'What areas of my life are still ruled by fear or limitation?',
        'Am I depending on my strength or God’s power daily?',
      ],
      prayer: 'Lord,\n'
          'Open my eyes to the greatness of Your power working within me.\n'
          'Help me to stop living from fear, limitation, and self-reliance.\n\n'
          'Strengthen my faith and renew my mind so that I may walk in '
          'confidence and spiritual authority.\n'
          'Teach me to depend on Your strength daily and not my own ability.\n\n'
          'Let Your power transform my heart, my thinking, and my life,\n'
          'so that I reflect Christ in all I do.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 6),
    ),

    // ── 7. BROKENNESS ────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'brokenness',
      theme: 'Comfort',
      title: 'God’s Nearness in Brokenness',
      scripture:
          'The Lord is near to those who have a broken heart, and saves such '
          'as have a contrite spirit.',
      scriptureReference: 'Psalm 34:18',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Brokenness Does Not Drive God Away—It Draws Him Near',
          body:
              'Human nature often treats brokenness as something to hide. Pain '
              'makes people feel exposed, vulnerable, and ashamed, causing many '
              'to withdraw from both God and others. There is often an internal '
              'pressure to appear strong, composed, and spiritually stable even '
              'when the heart is quietly falling apart. This is because '
              'brokenness feels like weakness, and weakness often feels '
              'unacceptable in a world that celebrates self-sufficiency.\n\n'
              'Yet Psalm 34:18 reveals a completely different reality. God does '
              'not retreat from the brokenhearted; He moves toward them. His '
              'presence is not reserved for those who appear strong but is '
              'especially near to those who know they are weak. What human '
              'pride often conceals, divine compassion tenderly meets. God is '
              'not intimidated by shattered emotions, unanswered questions, or '
              'silent tears. He is drawn to the wounded places where healing is '
              'needed most.\n\n'
              'This reveals one of the deepest truths of God’s character: His '
              'nearness is not earned through strength but experienced through '
              'surrender. The heart that acknowledges its need becomes the very '
              'place where His presence rests most powerfully.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Brokenness Creates Space for Dependence on God',
          body: 'A broken heart often dismantles the illusion of control. Pain '
              'has a way of exposing how limited human strength truly is. Seasons '
              'of loss, disappointment, betrayal, or failure strip away '
              'confidence in personal ability and force the soul to confront '
              'its need for something greater. What once felt manageable '
              'suddenly feels overwhelming.\n\n'
              'Though painful, this exposure can become a sacred invitation into '
              'deeper dependence on God. Brokenness often softens areas of the '
              'heart that comfort leaves untouched. When earthly supports '
              'collapse, the soul becomes more receptive to divine strength. As '
              '2 Corinthians 12:9 teaches, God’s strength is perfected in '
              'weakness because weakness creates room for His power to be '
              'revealed.\n\n'
              'The very place where strength feels absent can become the place '
              'where grace is most fully experienced. What feels like collapse '
              'may actually be the beginning of spiritual rebuilding.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Enemy Uses Brokenness to Produce Isolation',
          body: 'One of the enemy’s most destructive strategies is convincing '
              'wounded people to isolate themselves. Pain often whispers that '
              'no one understands, that healing is impossible, or that God '
              'has somehow withdrawn. These lies can quietly lead the heart '
              'into loneliness, discouragement, and spiritual distance.\n\n'
              'Isolation magnifies pain because what remains hidden often grows '
              'heavier. The longer wounds are carried alone, the more hopeless '
              'healing can seem. This is why broken seasons often become '
              'spiritual battlegrounds. The enemy seeks not only to wound but '
              'to separate the wounded from the source of healing.\n\n'
              'Yet Psalm 34:18 directly confronts this deception by declaring '
              'God’s nearness in brokenness. Even when feelings suggest '
              'abandonment, His presence remains steady. He is closest '
              'precisely where the soul feels weakest. Choosing to remain open '
              'to Him in painful seasons breaks the power of isolation and '
              'creates room for restoration.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Contrition Opens the Door to Healing',
          body: 'The verse speaks not only of broken hearts but of contrite '
              'spirits. Contrition reflects humility, surrender, and honest '
              'openness before God. It is the posture of a heart that no '
              'longer pretends to be unaffected but comes before God with '
              'sincerity and trust.\n\n'
              'Pride often resists healing because it hides pain behind '
              'self-protection. It convinces people they must fix themselves '
              'before approaching God. But healing does not begin with '
              'performance — it begins with surrender. A contrite heart stops '
              'pretending and allows God access to the places that hurt most '
              'deeply.\n\n'
              'As Psalm 51:17 declares, God does not despise a broken and '
              'contrite heart. He honors vulnerability because vulnerability '
              'creates room for transformation. What pride conceals, humility '
              'releases into God’s healing hands.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'God Sustains Before He Restores',
          body: 'One of the most difficult realities of broken seasons is that '
              'healing often unfolds gradually. Answers may not come quickly, '
              'wounds may not close overnight, and circumstances may remain '
              'unresolved longer than expected. In these moments, it can feel '
              'as though God is silent.\n\n'
              'Yet His silence is never absence. Before restoration becomes '
              'visible, His presence sustains internally. He strengthens the '
              'heart before circumstances shift externally. His nearness '
              'becomes the quiet force that keeps the believer from collapsing '
              'completely.\n\n'
              'As the soul remains anchored in Him, endurance begins to grow. '
              'What once felt unbearable becomes survivable through grace. '
              'God’s sustaining presence often accomplishes a deeper work than '
              'immediate rescue ever could. Through this process, brokenness '
              'becomes not the end of the story but the place where deeper '
              'intimacy with God is formed.',
        ),
      ],
      finalRevelation:
          'Brokenness is not evidence that God has abandoned you — it is often '
          'the place where His presence becomes most personal and His healing '
          'most profound.',
      reflectionQuestions: const [
        'What pain have I been hiding instead of surrendering to God?',
        'Have I allowed brokenness to isolate me from His presence?',
        'Am I willing to trust God’s sustaining grace while healing unfolds?',
      ],
      prayer: 'Lord,\n'
          'You see every hidden wound, every silent disappointment, and every '
          'place within me that feels fragile.\n'
          'Thank You for drawing near to my brokenness instead of turning away '
          'from it.\n\n'
          'Help me to stop hiding behind fear, pride, or isolation.\n'
          'Teach me to come honestly before You with a surrendered and '
          'contrite heart.\n\n'
          'Heal the places where pain has weakened my trust and restore hope '
          'where discouragement has settled deeply.\n\n'
          'Strengthen me while I wait for healing to unfold.\n'
          'Let Your presence sustain me in every fragile moment,\n'
          'and remind me that even when restoration feels delayed, You are '
          'still near, still faithful, and still working within me.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 7),
    ),

    // ── 8. UNFORGETTABLE ─────────────────────────────────────────────────────
    DevotionalModel(
      id: 'unforgettable',
      theme: 'Love',
      title: 'The God Who Cannot Forget You',
      scripture:
          'Can a woman forget her nursing child, and not have compassion on '
          'the son of her womb? Surely they may forget, yet I will not forget '
          'you.',
      scriptureReference: 'Isaiah 49:15',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God’s Love Is Deeper Than Human Attachment',
          body:
              'Isaiah 49:15 uses one of the strongest human expressions of love — '
              'a mother’s care for her nursing child — to reveal the depth of '
              'God’s compassion. A nursing mother naturally carries deep '
              'affection, attentiveness, and emotional connection toward her '
              'child. Yet God declares that even the strongest human love '
              'cannot fully compare to His unfailing remembrance of His people.\n\n'
              'Human love, though sincere, remains imperfect and limited by '
              'weakness, emotion, and circumstance. People may fail, disappoint, '
              'withdraw, or become absent. But God’s love is not unstable or '
              'temporary. His remembrance is constant because it flows from His '
              'unchanging nature rather than fluctuating human emotion.\n\n'
              'This reveals that God’s commitment toward His children is not '
              'fragile. Even when circumstances make His presence feel distant, '
              'His heart remains continually attentive toward them.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Feelings of Abandonment Do Not Mean God Has Forgotten',
          body: 'One of the deepest struggles believers face is the feeling of '
              'being forgotten during painful or delayed seasons. Waiting, '
              'suffering, unanswered prayers, and prolonged difficulties can '
              'create the impression that God has become silent or distant. The '
              'heart begins questioning whether He still sees, cares, or '
              'remembers.\n\n'
              'Yet Isaiah 49:15 directly confronts this fear. God does not '
              'measure His faithfulness by human perception. Even when emotions '
              'suggest abandonment, His covenant remains unchanged. As '
              'Deuteronomy 31:6 declares, God never leaves nor forsakes His '
              'people.\n\n'
              'The absence of visible answers is not evidence of divine absence. '
              'God’s silence in a season never means forgetfulness. Often, He '
              'is still working in ways the believer cannot yet fully see or '
              'understand.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Enemy Attacks Identity Through Rejection and Neglect',
          body:
              'One of the enemy’s most subtle strategies is convincing people '
              'they are unseen, unwanted, or forgotten. Rejection, betrayal, '
              'disappointment, and emotional wounds can slowly shape identity '
              'if left unhealed. The wounded heart may begin interpreting life '
              'through the lens of abandonment instead of through the truth of '
              'God’s love.\n\n'
              'This is why remembering God’s perspective becomes essential. '
              'Identity rooted in human acceptance will always remain fragile '
              'because people are imperfect. But identity rooted in God’s '
              'remembrance becomes stable because His love is unwavering.\n\n'
              'The enemy seeks to isolate through feelings of neglect, but God '
              'continually draws near with assurance of His presence and care. '
              'His remembrance restores dignity to hearts that life has '
              'wounded deeply.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Remembrance Is Active, Not Passive',
          body:
              'When Scripture says God will not forget, it means more than mental '
              'awareness. Divine remembrance in Scripture often involves active '
              'involvement, care, and faithfulness toward His promises. God’s '
              'remembrance always carries purpose and movement.\n\n'
              'Throughout the Bible, whenever God “remembered” His people, '
              'restoration, provision, or deliverance followed. His remembrance '
              'is connected to His covenant faithfulness. Even when timing '
              'feels delayed, His attention never shifts away from His children.\n\n'
              'As Psalm 139:17–18 reveals, God’s thoughts toward His people are '
              'countless and continual. His care is ongoing, personal, and '
              'intentional.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Security Is Found in God’s Unchanging Compassion',
          body: 'Human relationships can sometimes become uncertain, but God’s '
              'compassion remains steady. Isaiah 49:15 reveals a God whose heart '
              'is moved with deep tenderness toward His people. He is not '
              'distant, cold, or emotionally detached from human pain.\n\n'
              'This truth brings deep security to the believer. Even in seasons '
              'where people fail to understand, support, or remain present, '
              'God’s compassion remains available. His love sustains the weary, '
              'comforts the wounded, and strengthens the discouraged.\n\n'
              'The believer who understands God’s compassion begins walking with '
              'greater confidence and peace. Fear of abandonment weakens because '
              'the soul becomes anchored in the assurance that God never forgets '
              'what belongs to Him.',
        ),
      ],
      finalRevelation:
          'God’s silence is never forgetfulness — His heart remains continually '
          'attentive to His children even when they cannot yet see His hand.',
      reflectionQuestions: const [
        'Have I allowed difficult seasons to make me feel forgotten by God?',
        'What wounds of rejection or abandonment still affect my identity?',
        'Am I willing to trust God’s remembrance even when answers seem delayed?',
      ],
      prayer: 'Lord,\n'
          'Thank You for loving me with a compassion deeper than human '
          'understanding. When life feels uncertain and my heart feels '
          'overlooked, remind me that You never forget Your children.\n\n'
          'Heal every wound of rejection, abandonment, and disappointment '
          'within me. Remove every lie that tells me I am unseen or unwanted, '
          'and anchor my identity in Your unchanging love.\n\n'
          'Help me to trust Your faithfulness even in seasons where answers are '
          'delayed. Strengthen my heart with the assurance that Your thoughts '
          'toward me remain continual and Your care for me never fades.\n\n'
          'Let Your compassion bring peace to every anxious place within me, '
          'and teach me to rest securely in the truth that I am always '
          'remembered by You.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 8),
    ),

    // ── 9. MERCY ─────────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'mercy',
      theme: 'Mercy',
      title: 'When God Arises to Show Mercy',
      scripture:
          'You will arise and have mercy on Zion; for the time to favor her, '
          'yes, the set time, has come.',
      scriptureReference: 'Psalm 102:13',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God’s Timing Is Never Random',
          body:
              'Psalm 102:13 reveals that God works according to appointed times '
              'and divine seasons. What feels delayed to humanity is never '
              'delayed in heaven. God’s timing is intentional, precise, and '
              'connected to His greater purposes. The verse speaks of a “set '
              'time,” revealing that certain breakthroughs, restorations, and '
              'manifestations of favor are divinely appointed rather than '
              'accidental.\n\n'
              'Many believers struggle during waiting seasons because silence can '
              'feel like abandonment. Yet waiting does not mean God is inactive. '
              'Often, He is preparing hearts, aligning circumstances, and '
              'accomplishing unseen work before visible answers appear. As '
              'Ecclesiastes 3:11 reveals, God makes everything beautiful in its '
              'proper time.\n\n'
              'The believer may not always understand the timing of God, but '
              'faith learns to trust that heaven’s schedule is wiser than human '
              'urgency. What God ordains for the right season will not arrive '
              'too late.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Divine Favor Is an Expression of God’s Mercy',
          body:
              'The verse connects favor with mercy, showing that God’s blessings '
              'are not merely rewards for human effort but expressions of His '
              'compassion and grace. Mercy reaches people in weakness, failure, '
              'limitation, and brokenness. Favor flows not because people '
              'deserve it perfectly, but because God is compassionate toward '
              'them.\n\n'
              'Human effort alone cannot produce divine favor. There are doors '
              'only God can open, restorations only He can orchestrate, and '
              'opportunities only His hand can create. As Proverbs 3:3–4 '
              'teaches, walking with God positions the believer to experience '
              'favor both with Him and with people.\n\n'
              'When God decides to show mercy, circumstances can shift suddenly. '
              'Situations that once felt impossible can change because divine '
              'favor carries the power to alter outcomes beyond human ability.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Seasons of Delay Often Test the Heart',
          body: 'Waiting seasons can expose what truly lives within the heart. '
              'Prolonged delays often test patience, faith, trust, and spiritual '
              'endurance. The human tendency during difficult seasons is to '
              'become discouraged, frustrated, or tempted to lose hope '
              'altogether.\n\n'
              'The enemy frequently uses delay to produce doubt. He whispers '
              'that prayers are unanswered because God has forgotten or rejected '
              'His people. But Psalm 102:13 reminds believers that God still '
              'arises on behalf of His people at the appointed time. His '
              'silence is never proof of absence.\n\n'
              'As Hebrews 10:36 teaches, endurance becomes necessary so '
              'believers can receive what God has promised. Delay may shape '
              'character, but it does not cancel divine purpose.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Arising Changes Atmospheres and Outcomes',
          body: 'The phrase “You will arise” reveals movement and intervention '
              'from God Himself. When God arises, situations that once appeared '
              'immovable begin to shift. His intervention brings restoration '
              'where there was loss, hope where there was despair, and '
              'breakthrough where there was resistance.\n\n'
              'Throughout Scripture, divine intervention repeatedly transformed '
              'impossible situations. God’s arising is not limited by human '
              'weakness, opposition, or circumstance. His power exceeds every '
              'limitation. What people cannot change through striving, God can '
              'alter through His sovereign hand.\n\n'
              'Even before visible change appears, faith must remain anchored in '
              'the certainty that God is still able to intervene. His timing '
              'may differ from human expectation, but His power remains '
              'unchanged.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Faith Must Remain Steady Until the Set Time Arrives',
          body:
              'One of the greatest challenges of faith is remaining steady before '
              'the appointed season arrives. It is easy to trust God after '
              'breakthrough appears, but maturity is developed when trust '
              'continues during uncertainty. Faith sustains the heart while '
              'waiting for God’s promises to unfold.\n\n'
              'The believer who remains anchored in God during difficult seasons '
              'develops deeper spiritual endurance and dependence. Waiting '
              'becomes less about passive delay and more about active trust. As '
              'Isaiah 40:31 declares, those who wait upon the Lord receive '
              'renewed strength.\n\n'
              'God’s set time always arrives with purpose. The season of waiting '
              'may feel long, but divine favor can accomplish in one moment '
              'what human effort could not achieve in years.',
        ),
      ],
      finalRevelation:
          'When God’s appointed time arrives, His mercy can change in a moment '
          'what struggle could not change over years.',
      reflectionQuestions: const [
        'Have I become discouraged while waiting on God’s timing?',
        'Am I trusting God’s process or resisting the waiting season?',
        'What areas of my life need renewed faith in God’s appointed time?',
      ],
      prayer: 'Lord,\n'
          'Help me to trust Your timing even when I do not fully understand the '
          'process. Strengthen my heart during seasons of waiting and guard me '
          'from discouragement, fear, and doubt.\n\n'
          'Teach me to remain faithful while Your plans unfold in ways I '
          'cannot yet see. Let Your mercy and favor rest upon every area of my '
          'life that feels delayed, broken, or uncertain.\n\n'
          'When the appointed time comes, let Your hand bring restoration, '
          'breakthrough, and renewed hope. Help me to remember that Your '
          'timing is never late and Your purposes never fail.\n\n'
          'May my faith remain steady until the fullness of Your promises is '
          'revealed.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 9),
    ),

    // ── 10. ABIDING ──────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'abiding',
      theme: 'Abiding',
      title: 'The Power of Remaining in Christ',
      scripture:
          'Abide in Me, and I in you. As the branch cannot bear fruit of '
          'itself, unless it abides in the vine, neither can you, unless you '
          'abide in Me. I am the vine, you are the branches. He who abides in '
          'Me, and I in him, bears much fruit; for without Me you can do '
          'nothing.',
      scriptureReference: 'John 15:4–5',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Spiritual Life Cannot Be Sustained Independently',
          body: 'Jesus uses the imagery of a vine and branches to reveal a '
              'foundational spiritual truth: life, strength, and fruitfulness '
              'flow from connection with Him. A branch separated from the vine '
              'may appear alive briefly, but eventually it withers because it '
              'no longer has access to its source. In the same way, believers '
              'cannot sustain spiritual vitality apart from continual communion '
              'with Christ.\n\n'
              'Many people attempt to live spiritually through personal effort, '
              'discipline, or outward activity while neglecting deep intimacy '
              'with God. Yet spiritual fruit is not produced through striving '
              'alone but through abiding. The Christian life was never '
              'designed to function independently of Christ’s sustaining '
              'presence.\n\n'
              'As Galatians 2:20 reveals, the believer’s life is meant to flow '
              'from Christ living within them rather than from self-sufficiency.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Abiding Is More Than Occasional Connection',
          body: 'To abide means to remain, dwell, continue, and stay connected '
              'consistently. Jesus was not speaking about occasional moments of '
              'prayer or temporary spiritual enthusiasm. He was describing an '
              'ongoing relationship where the believer continually lives in '
              'dependence upon Him.\n\n'
              'Many believers seek God only during crisis, difficulty, or urgent '
              'need, but abiding involves daily fellowship and continual '
              'awareness of His presence. Just as a branch draws nourishment '
              'constantly from the vine, the soul must continually draw '
              'strength, wisdom, and life from Christ.\n\n'
              'Abiding is cultivated through prayer, worship, meditation on '
              'Scripture, obedience, and surrender. The deeper the connection '
              'becomes, the stronger spiritual growth and stability develop '
              'over time.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Disconnection Leads to Spiritual Weakness',
          body:
              'Jesus makes a powerful statement: “Without Me you can do nothing.” '
              'This reveals that separation from Him eventually produces '
              'spiritual weakness, emptiness, and barrenness. Human effort may '
              'temporarily create outward activity, but lasting spiritual '
              'fruit cannot exist apart from Christ.\n\n'
              'The enemy often distracts believers into busyness without '
              'intimacy. It is possible to become active in spiritual routines '
              'while gradually drifting away from genuine communion with God. '
              'Over time, disconnection weakens discernment, drains spiritual '
              'strength, and leaves the soul vulnerable to discouragement and '
              'temptation.\n\n'
              'This is why maintaining intimacy with Christ is not optional — '
              'it is essential. Spiritual survival and fruitfulness depend on '
              'continual connection to the true source of life.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Fruitfulness Is the Evidence of Abiding',
          body:
              'Jesus teaches that those who abide in Him will bear much fruit. '
              'Fruit is the natural result of healthy connection to the vine. '
              'It reflects the visible evidence of inward transformation. Love, '
              'peace, patience, wisdom, obedience, humility, and spiritual '
              'maturity grow where intimacy with Christ is maintained.\n\n'
              'Fruitfulness is not produced by forcing external behavior but by '
              'internal transformation flowing from relationship with God. As '
              'Galatians 5:22–23 explains, the fruit of the Spirit develops '
              'through the Spirit’s work within the believer.\n\n'
              'The goal of abiding is not merely spiritual activity but becoming '
              'increasingly shaped into the character and likeness of Christ. '
              'Genuine fruit grows gradually through consistent communion with '
              'Him.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Dependence on Christ Produces Lasting Stability',
          body:
              'Branches do not struggle to remain alive when they stay connected '
              'to the vine because the vine continually supplies what they need. '
              'Likewise, believers who remain dependent on Christ discover '
              'strength beyond human ability. Stability develops not from '
              'self-confidence but from continual reliance on Him.\n\n'
              'Life’s pressures, disappointments, and uncertainties can easily '
              'drain human strength, but abiding keeps the soul anchored. The '
              'believer learns that peace, endurance, wisdom, and spiritual '
              'strength are sustained through ongoing communion with God rather '
              'than through personal striving alone.\n\n'
              'As dependence deepens, the heart becomes less controlled by '
              'external circumstances and more rooted in the life flowing from '
              'Christ Himself. Abiding transforms Christianity from mere '
              'religious practice into living relationship.',
        ),
      ],
      finalRevelation:
          'Fruitfulness is not produced by striving harder — it is produced by '
          'remaining deeply connected to Christ.',
      reflectionQuestions: const [
        'Am I truly abiding in Christ or only seeking Him occasionally?',
        'What distractions have weakened my intimacy with God recently?',
        'Is my life producing the fruit that flows from genuine connection with Christ?',
      ],
      prayer: 'Lord,\n'
          'Teach me to remain deeply connected to You in every season of life. '
          'Forgive me for the times I have tried to rely on my own strength '
          'instead of depending fully on Your presence.\n\n'
          'Draw my heart into deeper intimacy with You daily. Help me to '
          'cultivate a life of prayer, surrender, obedience, and continual '
          'fellowship with You. Remove every distraction that weakens my '
          'connection to Your voice and Your truth.\n\n'
          'Let Your life flow through me so that my character, thoughts, and '
          'actions reflect the fruit of Your Spirit. Strengthen me where I am '
          'weak and remind me continually that apart from You, I can do '
          'nothing.\n\n'
          'May my life remain firmly rooted in You, and let everything I '
          'produce flow from genuine communion with Christ.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 10),
    ),

    // ── 11. ROOTED ───────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'rooted',
      theme: 'Trust',
      title: 'Rooted Beyond the Seasons',
      scripture:
          'Blessed is the man who trusts in the Lord, and whose hope is the '
          'Lord. For he shall be like a tree planted by the waters, which '
          'spreads out its roots by the river, and will not fear when heat '
          'comes; but its leaf will be green, and will not be anxious in the '
          'year of drought, nor will cease from yielding fruit.',
      scriptureReference: 'Jeremiah 17:7–8',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'True Stability Comes from Trusting God',
          body: 'Jeremiah 17:7 reveals that blessing begins with trust in the '
              'Lord. In Scripture, blessing is not merely material increase or '
              'outward success—it reflects a life sustained, guided, and '
              'strengthened by God. Trust becomes the foundation of spiritual '
              'stability because it shifts dependence away from fragile human '
              'understanding and places confidence in God’s unchanging nature.\n\n'
              'Many people place their hope in circumstances, resources, '
              'relationships, or personal ability, but these things can change '
              'unexpectedly. When hope is rooted only in temporary things, fear '
              'and instability eventually follow. But the person who makes God '
              'their source develops inward security that remains steady even '
              'when life becomes uncertain.\n\n'
              'Trust in God does not remove challenges immediately, but it '
              'anchors the soul in something stronger than the challenges '
              'themselves. The heart learns to rest not in visible conditions '
              'but in the faithfulness of God.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Deep Roots Are Developed in Hidden Places',
          body:
              'The prophet compares the trusting believer to a tree planted by '
              'waters whose roots spread deeply into the river. Roots grow '
              'beneath the surface long before fruit becomes visible '
              'externally. In the same way, spiritual depth is often formed '
              'quietly through prayer, obedience, waiting, worship, and '
              'continual dependence on God.\n\n'
              'Many people desire visible fruit without developing deep '
              'spiritual roots. Yet shallow roots cannot sustain life during '
              'difficult seasons. It is the hidden life with God that produces '
              'endurance and stability when pressure comes. As Psalm 1:2–3 '
              'teaches, those who remain rooted in God’s Word become '
              'spiritually nourished and fruitful.\n\n'
              'God often uses unseen seasons to strengthen the inner life of '
              'the believer. What develops privately with Him becomes the '
              'source of strength publicly during trials.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Difficult Seasons Reveal the Depth of Our Roots',
          body: 'Jeremiah says the tree “will not fear when heat comes.” The '
              'heat represents seasons of pressure, adversity, uncertainty, and '
              'hardship. Trials do not create roots; they reveal whether roots '
              'already exist. Difficult seasons expose where trust has truly '
              'been placed.\n\n'
              'A shallow spiritual life often collapses quickly under pressure '
              'because it depends heavily on favorable conditions. But the '
              'believer deeply rooted in God remains spiritually sustained even '
              'during drought seasons. Fear loses its dominance because the '
              'soul continues drawing life from God rather than from external '
              'stability.\n\n'
              'The enemy seeks to use hardship to weaken faith, but God uses '
              'hardship to deepen dependence. What appears threatening '
              'externally often becomes the very process that strengthens '
              'spiritual maturity internally.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God Sustains Fruitfulness Even in Dry Seasons',
          body:
              'One of the most powerful promises in Jeremiah 17:8 is that the '
              'rooted tree continues yielding fruit even during drought. This '
              'reveals that spiritual fruitfulness is not controlled entirely '
              'by external conditions. God is able to sustain life within the '
              'believer even when circumstances around them feel dry and '
              'difficult.\n\n'
              'Many people assume fruitfulness can only exist in comfortable '
              'seasons, but Scripture teaches otherwise. Peace, faith, wisdom, '
              'endurance, and spiritual growth often become most visible '
              'during difficult times. As Galatians 5:22–23 explains, '
              'spiritual fruit is produced through the work of God within the '
              'believer.\n\n'
              'When roots remain connected to God, life continues flowing '
              'internally even when external seasons become challenging. '
              'Divine sustenance exceeds environmental limitation.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Hope in God Removes the Fear of the Future',
          body:
              'Jeremiah says the rooted tree “will not be anxious in the year '
              'of drought.” Anxiety often grows from uncertainty about the '
              'future and fear of insufficiency. But trust in God produces '
              'confidence that He will continue sustaining His people '
              'regardless of changing seasons.\n\n'
              'The believer rooted in God does not ignore reality but faces it '
              'with deeper assurance. Hope anchored in God creates inward calm '
              'because it rests on His faithfulness rather than on predictable '
              'circumstances. As Hebrews 13:8 reminds believers, God remains '
              'the same yesterday, today, and forever.\n\n'
              'When hope is firmly planted in God, fear gradually loses its '
              'power. The soul becomes steady because it trusts the One who '
              'continues supplying strength through every season.',
        ),
      ],
      finalRevelation:
          'The strength of a believer is not revealed by the absence of '
          'difficult seasons—it is revealed by remaining rooted in God '
          'through them.',
      reflectionQuestions: const [
        'What have my roots been connected to recently?',
        'Have difficult seasons exposed fear or deepened my trust in God?',
        'Am I cultivating hidden spiritual depth or only seeking visible results?',
      ],
      prayer: 'Lord,\n'
          'Teach me to place my trust fully in You and not in temporary '
          'circumstances or human strength. Deepen my roots in Your presence '
          'so that my life remains spiritually sustained through every season.\n\n'
          'Strengthen me during times of pressure, uncertainty, and waiting. '
          'Help me not to fear when difficult seasons arise, but to remain '
          'anchored in Your faithfulness and truth.\n\n'
          'Let my life continue producing spiritual fruit even during dry '
          'seasons. Remove anxiety about the future and replace it with '
          'confidence in Your continual provision and care.\n\n'
          'May my heart remain firmly planted in You, and let my strength '
          'flow from deep and continual dependence on Your presence.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 11),
    ),

    // ── 12. RENEWAL ─────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'mindrenewal',
      theme: 'Renewal',
      title: 'Transformation Begins in the Mind',
      scripture:
          'And do not be conformed to this world, but be transformed by the '
          'renewing of your mind, that you may prove what is that good and '
          'acceptable and perfect will of God.',
      scriptureReference: 'Romans 12:2',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Transformation Begins Internally Before It Appears Externally',
          body:
              'Romans 12:2 reveals that true transformation begins within the '
              'mind before it becomes visible in behavior, decisions, or '
              'lifestyle. Many people attempt outward change without '
              'addressing inward patterns of thinking, but lasting spiritual '
              'growth cannot occur without internal renewal. The mind shapes '
              'perspective, and perspective eventually shapes actions.\n\n'
              'The condition of the mind affects how a person interprets life, '
              'responds to challenges, and relates to God. This is why '
              'spiritual warfare often targets thoughts, beliefs, and '
              'perceptions first. God does not simply seek behavioral '
              'adjustment—He seeks inward transformation that changes the '
              'entire direction of life from the inside outward.\n\n'
              'Transformation is not achieved merely through external pressure '
              'or religious activity. It flows from allowing God’s truth to '
              'reshape the inner life continually.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'The World Constantly Pressures the Mind into Its Pattern',
          body: 'Paul warns believers not to be “conformed” to this world. '
              'Conformity happens when external influences slowly shape '
              'internal thinking. Culture, fear, pride, comparison, '
              'materialism, and ungodly values constantly compete for '
              'influence over the mind and heart.\n\n'
              'The danger of conformity is that it often happens gradually and '
              'subtly. Without spiritual awareness, people can begin thinking '
              'according to the world’s standards rather than God’s truth. '
              'What is repeatedly seen, heard, entertained, and embraced '
              'eventually influences thought patterns and spiritual '
              'sensitivity.\n\n'
              'As Colossians 3:2 teaches, believers are called to set their '
              'minds on things above rather than allowing earthly systems to '
              'dominate their thinking. Spiritual renewal requires intentional '
              'separation from destructive patterns of thought.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Renewal Requires the Replacing of Wrong Thinking',
          body: 'The renewing of the mind is not simply gaining information—it '
              'is the replacement of false perspectives with divine truth. '
              'Many struggles continue because wrong beliefs, unhealthy '
              'thought patterns, fears, and internal strongholds remain '
              'unchallenged within the mind.\n\n'
              'The enemy often builds strongholds through repeated agreement '
              'with lies. Fear, condemnation, insecurity, bitterness, and '
              'hopelessness grow stronger when continually rehearsed '
              'internally. But God’s Word has the power to dismantle '
              'destructive thinking and rebuild the mind according to truth.\n\n'
              'As 2 Corinthians 10:5 explains, believers are called to take '
              'thoughts captive and bring them into obedience to Christ. '
              'Renewal happens when truth consistently replaces deception.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'A Renewed Mind Produces Spiritual Discernment',
          body: 'Romans 12:2 teaches that renewed minds become able to discern '
              'the good, acceptable, and perfect will of God. Confusion often '
              'increases when the mind is clouded by fear, distraction, '
              'worldly influence, or emotional instability. Spiritual '
              'discernment grows where the mind becomes aligned with God’s '
              'truth.\n\n'
              'A renewed mind becomes more sensitive to God’s leading because '
              'inward noise decreases. The believer begins viewing life from '
              'God’s perspective rather than from emotional impulse or worldly '
              'reasoning. Decisions become guided more by wisdom, peace, and '
              'spiritual understanding.\n\n'
              'As intimacy with God deepens through prayer, Scripture, and '
              'obedience, the mind gradually becomes clearer and more '
              'spiritually stable. Renewal strengthens the ability to '
              'recognize what aligns with God’s heart and what does not.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Transformation Is a Continual Process',
          body:
              'The renewing of the mind is not a one-time event but an ongoing '
              'process. Every day presents new opportunities either to align '
              'thoughts with God’s truth or drift back into old patterns of '
              'thinking. Spiritual maturity develops through continual '
              'surrender and consistent renewal.\n\n'
              'Growth often happens gradually. God patiently reshapes '
              'perspectives, attitudes, desires, and reactions over time. The '
              'believer who continually submits their mind to God experiences '
              'increasing transformation in character, peace, wisdom, and '
              'spiritual stability.\n\n'
              'As Philippians 1:6 reminds believers, God faithfully continues '
              'the work He has begun within them. Renewal is evidence that '
              'spiritual life is actively growing.',
        ),
      ],
      finalRevelation: 'Lasting transformation does not begin with changing '
          'circumstances—it begins with a mind continually renewed by God’s '
          'truth.',
      reflectionQuestions: const [
        'What thought patterns have been shaping my life recently?',
        'Have I allowed worldly influences to affect my thinking more than God’s Word?',
        'What areas of my mind need deeper renewal through truth?',
      ],
      prayer: 'Lord,\n'
          'Renew my mind and transform the way I think. Expose every false '
          'belief, unhealthy pattern, and destructive thought that does not '
          'align with Your truth.\n\n'
          'Help me not to conform to the values and pressures of this world, '
          'but to remain anchored in Your Word and guided by Your Spirit. '
          'Teach me to guard my mind carefully and to meditate continually on '
          'what is true and life-giving.\n\n'
          'Strengthen me to reject fear, negativity, pride, and every thought '
          'that opposes Your will. Replace confusion with wisdom, instability '
          'with peace, and discouragement with hope.\n\n'
          'Let my life reflect the transformation that comes from continual '
          'intimacy with You, and may my mind become increasingly aligned with '
          'Your heart and purpose.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 12),
    ),

    // ── 13. FAITHFULNESS ────────────────────────────────────────────────────
    DevotionalModel(
      id: 'morningmercy',
      theme: 'Faithfulness',
      title: 'Mercy That Meets You Every Morning',
      scripture: 'Through the Lord’s mercies we are not consumed, because His '
          'compassions fail not. They are new every morning; great is Your '
          'faithfulness.',
      scriptureReference: 'Lamentations 3:22–23',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God’s Mercy Preserves Us Even When We Feel Weak',
          body: 'Lamentations was written in a season of sorrow, devastation, '
              'and deep suffering, yet in the middle of grief Jeremiah '
              'declares that it is because of the Lord’s mercies that people '
              'are not consumed. This reveals that even during painful '
              'seasons, God’s mercy continues sustaining what should have '
              'collapsed completely.\n\n'
              'Many times believers survive seasons they never imagined they '
              'could endure, not because of personal strength, but because God '
              'quietly upheld them. His mercy protects, preserves, and carries '
              'the soul even when emotional, spiritual, or physical exhaustion '
              'becomes overwhelming. Mercy becomes the invisible support '
              'beneath fragile hearts.\n\n'
              'God’s mercy is often working even when circumstances remain '
              'difficult. The believer may feel weak, but divine compassion '
              'continues preventing total destruction. What should have broken '
              'the soul completely is restrained by God’s sustaining grace.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God’s Compassion Does Not Expire',
          body: 'Jeremiah says God’s compassions “fail not,” revealing that '
              'divine compassion is constant and unchanging. Human compassion '
              'may grow weary, inconsistent, or limited, but God’s compassion '
              'remains steady through every season. He does not become '
              'exhausted by human weakness or impatient with sincere '
              'repentance.\n\n'
              'Many people struggle with the fear that they have failed too '
              'many times or drifted too far from God’s grace. Yet Scripture '
              'reveals a God whose compassion continues reaching toward His '
              'people even in brokenness. As Psalm 103:13 reminds believers, '
              'God’s compassion toward His children reflects the tenderness of '
              'a loving father.\n\n'
              'His mercy is not temporary kindness—it flows from His eternal '
              'character. God remains compassionate even when emotions '
              'fluctuate and circumstances become uncertain.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Enemy Wants You to Forget God’s Faithfulness',
          body: 'One of the enemy’s strategies during difficult seasons is to '
              'magnify pain so greatly that the believer forgets God’s '
              'faithfulness. Discouragement narrows perspective and causes the '
              'mind to focus only on present struggles while ignoring evidence '
              'of God’s sustaining hand.\n\n'
              'This is why remembering God’s mercy becomes spiritually '
              'important. Gratitude and remembrance restore perspective when '
              'despair attempts to dominate the heart. Jeremiah intentionally '
              'shifts focus from devastation to the faithfulness of God, '
              'showing that hope can still exist even in dark seasons.\n\n'
              'As Psalm 77:11 teaches, remembering the works and faithfulness '
              'of God strengthens the heart during difficult moments. What the '
              'soul remembers consistently shapes how it endures suffering.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Every Morning Carries Fresh Mercy',
          body: 'Jeremiah declares that God’s mercies are “new every morning.” '
              'This means God does not distribute grace only once for a '
              'lifetime—He continually provides fresh strength for each new '
              'day. Yesterday’s failures, fears, and burdens do not exhaust '
              'today’s supply of mercy.\n\n'
              'Every morning becomes evidence that God has not given up on His '
              'people. The rising of a new day carries renewed opportunity, '
              'renewed grace, and renewed compassion. Even when life feels '
              'repetitive or difficult, heaven continues releasing fresh mercy '
              'sufficient for the present season.\n\n'
              'As Matthew 6:34 teaches, grace is provided daily for daily '
              'needs. God supplies strength progressively, not all at once, so '
              'dependence on Him remains continual.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'God’s Faithfulness Remains Greater Than Human Instability',
          body: 'The passage ends with the declaration, “Great is Your '
              'faithfulness.” Human emotions, strength, and consistency often '
              'fluctuate, but God’s faithfulness remains steady. He continues '
              'fulfilling His promises even when believers struggle with '
              'weakness, fear, or uncertainty.\n\n'
              'Faithfulness means God remains dependable regardless of '
              'changing seasons. He does not abandon His work halfway or '
              'withdraw His love during hardship. The believer may feel '
              'unstable emotionally, but God remains unmoved and reliable '
              'through every circumstance.\n\n'
              'This truth creates deep spiritual security. Confidence grows '
              'not because life becomes predictable, but because God remains '
              'faithful even when life feels uncertain. His consistency '
              'becomes the anchor that steadies the soul.',
        ),
      ],
      finalRevelation:
          'Every new morning is proof that God’s mercy is still speaking over '
          'your life.',
      reflectionQuestions: const [
        'Have I forgotten how much God’s mercy has sustained me?',
        'What areas of discouragement have weakened my awareness of His faithfulness?',
        'Am I beginning each day with trust in God’s fresh mercy?',
      ],
      prayer: 'Lord,\n'
          'Thank You for the mercy that continues sustaining me even in '
          'difficult seasons. When I feel weak, discouraged, or overwhelmed, '
          'remind me that it is Your compassion that keeps me from being '
          'consumed.\n\n'
          'Help me never to lose sight of Your faithfulness. Strengthen my '
          'heart to remember Your goodness even when circumstances feel heavy '
          'or uncertain. Teach me to trust that Your mercy is renewed every '
          'morning and that Your grace is always sufficient for each day.\n\n'
          'Remove fear, hopelessness, and discouragement from my heart. '
          'Replace them with peace, gratitude, and renewed confidence in Your '
          'unchanging love.\n\n'
          'May my life remain anchored in the truth that Your compassion '
          'never fails and Your faithfulness never ends.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 13),
    ),

    // ── 14. STILLNESS ───────────────────────────────────────────────────────
    DevotionalModel(
      id: 'stillness',
      theme: 'Stillness',
      title: 'The Power of Stillness Before God',
      scripture: 'Be still, and know that I am God…',
      scriptureReference: 'Psalm 46:10',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Stillness Is an Invitation to Trust God’s Sovereignty',
          body: 'Psalm 46:10 was spoken in the context of chaos, instability, '
              'and turmoil. Nations were shaking, mountains were moving, and '
              'the earth itself appeared unstable, yet God’s response was: '
              '“Be still.” This reveals that divine peace is not dependent on '
              'calm circumstances but on confidence in God’s authority over '
              'every situation.\n\n'
              'Stillness does not mean inactivity or indifference. It means '
              'releasing panic, striving, and anxious control in order to rest '
              'in the reality that God remains sovereign. Human nature often '
              'reacts to uncertainty by trying to control outcomes, but God '
              'calls the believer into trust rather than constant internal '
              'agitation.\n\n'
              'When the soul becomes still before God, perspective changes. '
              'Fear loses some of its power because the heart begins focusing '
              'more on God’s greatness than on surrounding instability.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Noise Often Prevents Spiritual Awareness',
          body: 'The modern world is filled with constant noise—distractions, '
              'worries, opinions, responsibilities, and endless mental '
              'activity. The mind can become so overwhelmed that it loses '
              'sensitivity to God’s presence and direction. Many people seek '
              'answers from God while remaining internally restless.\n\n'
              'Stillness creates space for spiritual awareness. Throughout '
              'Scripture, God often spoke most clearly in quiet moments rather '
              'than in noise and chaos. As 1 Kings 19:11–12 reveals, Elijah '
              'encountered God not in the wind, earthquake, or fire, but in a '
              'still small voice.\n\n'
              'A restless heart struggles to discern clearly because anxiety '
              'constantly competes for attention. But when the mind quiets '
              'before God, His truth becomes easier to recognize and His peace '
              'begins to settle deeply within the soul.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Fear Pushes the Soul Toward Striving',
          body:
              'One of the primary reasons people struggle to be still is fear. '
              'Fear creates the pressure to fix everything immediately, '
              'anticipate every possible outcome, and carry burdens that were '
              'never meant to be carried alone. The enemy often uses anxiety '
              'to keep the mind in continual turmoil.\n\n'
              'Striving can create the illusion of control while quietly '
              'exhausting the soul. Yet Psalm 46:10 reminds believers that God '
              'alone remains fully sovereign. The believer was never designed '
              'to sustain life independently without dependence on God.\n\n'
              'As Matthew 11:28–29 teaches, Christ invites the weary into '
              'rest. Spiritual stillness becomes an act of surrender where '
              'burdens are released back into God’s hands instead of being '
              'carried endlessly through human effort.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Knowing God Deeply Requires Remaining Near Him',
          body: 'The verse says, “Be still, and know that I am God.” This '
              'knowledge is not merely intellectual information about God—it '
              'is experiential awareness developed through relationship and '
              'intimacy. Many know about God while remaining distant from His '
              'presence internally.\n\n'
              'Stillness allows the believer to encounter God beyond '
              'surface-level spirituality. Through quiet communion, prayer, '
              'meditation on Scripture, and surrender, the soul begins '
              'understanding His character more deeply. Confidence grows '
              'because intimacy replaces uncertainty.\n\n'
              'The more believers truly know God, the less easily shaken they '
              'become by changing circumstances. His faithfulness becomes '
              'personal rather than theoretical, and trust begins flowing from '
              'relationship rather than religious routine.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'True Peace Flows from Surrendered Dependence',
          body:
              'Stillness ultimately reflects surrender. It is the decision to '
              'stop relying entirely on human strength and to trust God with '
              'what cannot be controlled. Peace enters the heart when the '
              'pressure to manage everything alone is released.\n\n'
              'This kind of surrender does not remove responsibility, but it '
              'removes unhealthy striving and fear-driven control. The '
              'believer learns to move through life with dependence on God '
              'rather than constant internal tension. As Philippians 4:6–7 '
              'teaches, peace begins guarding the heart when burdens are '
              'brought before God instead of carried alone.\n\n'
              'The soul that learns stillness discovers a deeper kind of '
              'strength—one rooted not in self-sufficiency but in trustful '
              'dependence on God’s unchanging presence.',
        ),
      ],
      finalRevelation:
          'Stillness is not weakness—it is the quiet confidence that God '
          'remains sovereign over everything you cannot control.',
      reflectionQuestions: const [
        'What fears or worries have been disturbing my inner peace recently?',
        'Have I been striving excessively instead of resting in God’s sovereignty?',
        'When was the last time I truly became still before God?',
      ],
      prayer: 'Lord,\n'
          'Teach me to be still before You in a world filled with noise, '
          'fear, and distraction. Quiet every anxious thought and restless '
          'burden within my heart.\n\n'
          'Help me to release control over the things I cannot change and to '
          'trust fully in Your sovereignty. Strengthen me to stop striving '
          'endlessly through my own understanding and to rest deeply in Your '
          'faithfulness.\n\n'
          'Draw me into deeper intimacy with You. Let Your presence calm my '
          'fears, renew my mind, and restore peace to my soul. Teach me to '
          'recognize Your voice above every competing distraction around me.\n\n'
          'May my heart remain anchored in the confidence that You are God, '
          'and may Your peace govern my life daily.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 14),
    ),

    // ── 15. OBEDIENCE ───────────────────────────────────────────────────────
    DevotionalModel(
      id: 'desires',
      theme: 'Obedience',
      title: 'What God Truly Desires',
      scripture:
          'He has shown you, O man, what is good; and what does the Lord '
          'require of you but to do justly, to love mercy, and to walk humbly '
          'with your God?',
      scriptureReference: 'Micah 6:8',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God Desires Transformation More Than Religious Performance',
          body:
              'Micah 6:8 was spoken during a time when people maintained outward '
              'religious activity while their hearts drifted far from God. They '
              'offered sacrifices and ceremonies, yet neglected justice, mercy, '
              'and humility. This reveals that God’s greatest concern is not '
              'merely external devotion but inward transformation reflected '
              'through daily living.\n\n'
              'Many people associate spirituality primarily with rituals, appearances, '
              'or public expressions of faith, but God looks deeper into the '
              'condition of the heart. True devotion is revealed not only through '
              'worship services or spiritual language, but through character, '
              'compassion, integrity, and obedience in everyday life.\n\n'
              'God does not reject worship, prayer, or sacrifice, but He desires '
              'lives genuinely shaped by His nature. Spiritual maturity becomes '
              'visible when the heart begins reflecting God’s character '
              'consistently beyond religious environments.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Justice Reflects the Heart of God',
          body:
              'Micah says believers are called “to do justly,” revealing that '
              'God cares deeply about righteousness, fairness, truth, and '
              'integrity. Justice is not only about legal systems—it includes '
              'how people treat others, respond to dishonesty, and use influence '
              'or authority. God’s justice opposes oppression, manipulation, '
              'cruelty, and selfishness.\n\n'
              'Living justly requires integrity even when compromise would be '
              'easier. It means choosing truth over deception, fairness over '
              'selfish gain, and righteousness over convenience. As Proverbs '
              '21:3 teaches, doing righteousness and justice is more pleasing '
              'to God than outward sacrifice alone.\n\n'
              'The believer who walks in justice reflects God’s heart within '
              'everyday relationships and decisions. Faith becomes visible '
              'through the consistent practice of honesty, compassion, and '
              'moral integrity.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Mercy Reveals Spiritual Maturity',
          body: 'Micah does not simply say to show mercy but “to love mercy.” '
              'This reveals that compassion should become more than occasional '
              'behavior—it should become part of the believer’s nature. Mercy '
              'reflects God’s willingness to forgive, restore, and show '
              'compassion toward human weakness.\n\n'
              'The enemy often pushes people toward bitterness, pride, '
              'harshness, and unforgiveness, especially after experiencing pain '
              'or disappointment. But mercy softens the heart and prevents wounds '
              'from producing spiritual hardness internally.\n\n'
              'As Matthew 5:7 teaches, the merciful themselves receive mercy. '
              'A heart transformed by God gradually becomes more compassionate '
              'toward others because it recognizes how deeply it has received '
              'God’s grace personally.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Humility Keeps the Heart Dependent on God',
          body: 'Micah says believers are called “to walk humbly” with God. '
              'Humility is not weakness or insecurity—it is the recognition '
              'that life was never meant to be lived independently from God. '
              'Pride pushes the soul toward self-sufficiency, while humility '
              'keeps the heart teachable, surrendered, and dependent upon '
              'divine guidance.\n\n'
              'Walking humbly means acknowledging the need for God daily rather '
              'than relying entirely on personal strength, wisdom, or achievement. '
              'It produces a posture of continual surrender where the believer '
              'remains sensitive to correction, wisdom, and spiritual growth.\n\n'
              'As James 4:6 reveals, God resists the proud but gives grace to '
              'the humble. Humility creates room for God’s strength and wisdom '
              'to operate more fully within the believer’s life.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Walking with God Is a Daily Relationship',
          body:
              'Micah’s instruction is not merely to know about God but to “walk” '
              'with Him. Walking implies continual relationship, ongoing '
              'fellowship, and consistent communion. God never intended faith to '
              'become occasional or disconnected from everyday life.\n\n'
              'Walking with God involves daily obedience, continual trust, prayer, '
              'reflection, and dependence on His presence. It means allowing God '
              'to shape decisions, attitudes, priorities, and responses '
              'continually rather than only during spiritual moments.\n\n'
              'The believer who walks closely with God develops greater spiritual '
              'discernment, peace, and maturity over time. Relationship '
              'transforms faith from religious duty into living communion with '
              'the Creator Himself.',
        ),
      ],
      finalRevelation:
          'God is not seeking outward religion without inward transformation—\n'
          'He desires hearts that reflect His justice, mercy, and humility daily.',
      reflectionQuestions: const [
        'Does my life reflect God’s character beyond outward spirituality?',
        'Am I walking in justice, mercy, and humility consistently?',
        'Have I allowed pride, bitterness, or compromise to affect my relationship with God?',
      ],
      prayer: 'Lord,\n'
          'Teach me to live in a way that truly reflects Your heart. Remove every '
          'form of empty religion, pride, and hypocrisy from within me, and let my '
          'life be shaped by genuine transformation.\n\n'
          'Help me to walk in justice, integrity, and truth even when it is '
          'difficult. Fill my heart with mercy and compassion so that I reflect '
          'the grace You have shown toward me.\n\n'
          'Teach me to walk humbly with You daily. Keep my heart dependent on '
          'Your wisdom, sensitive to Your correction, and surrendered to Your '
          'will.\n\n'
          'May my relationship with You become deeper and more genuine each day,\n'
          'and let my life reveal the beauty of Your character to the world '
          'around me.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 15),
    ),

    // ── 16. FOCUS ───────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'eternal',
      theme: 'Focus',
      title: 'Setting the Mind on Eternal Things',
      scripture: 'Set your mind on things above, not on things on the earth.',
      scriptureReference: 'Colossians 3:2',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'The Direction of the Mind Shapes the Direction of Life',
          body:
              'Colossians 3:2 reveals that the mind is deeply connected to the '
              'course of a person’s life. Thoughts influence desires, decisions, '
              'emotions, and actions. Whatever consistently occupies the mind '
              'gradually begins shaping priorities, behavior, and spiritual '
              'condition. This is why Scripture places strong emphasis on what '
              'believers allow to govern their thinking.\n\n'
              'Many struggles begin internally long before they appear externally. '
              'When the mind becomes consumed with fear, comparison, worldly '
              'pressure, or temporary concerns, spiritual clarity weakens. But '
              'when the mind is directed toward God’s truth and eternal '
              'realities, the soul develops greater peace, wisdom, and stability.\n\n'
              'The mind naturally drifts toward earthly distractions if left '
              'unguarded. Spiritual growth requires intentional focus because '
              'what continually fills the mind eventually influences the heart.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Earthly Focus Can Quietly Distract the Soul',
          body:
              'Paul warns believers not to become consumed with “things on the '
              'earth.” This does not mean ignoring responsibilities or daily '
              'life, but it reveals the danger of becoming spiritually absorbed '
              'by temporary things. Wealth, recognition, possessions, success, '
              'entertainment, and worldly approval can slowly dominate the heart '
              'without being immediately noticed.\n\n'
              'Earthly things are temporary by nature. When identity and '
              'security become rooted in temporary things, instability '
              'eventually follows because earthly systems constantly change. As '
              '1 John 2:17 teaches, the world and its desires are passing away, '
              'but those who do the will of God endure forever.\n\n'
              'The enemy often distracts believers not only through obvious sin '
              'but also through excessive focus on temporary concerns. A '
              'distracted mind gradually loses sensitivity to eternal priorities '
              'and spiritual intimacy with God.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Spiritual Warfare Often Begins in the Mind',
          body:
              'One of the greatest battlegrounds of spiritual life is the mind. '
              'Thoughts influence emotions, and emotions often influence '
              'decisions. The enemy understands that controlling thought patterns '
              'can weaken faith, distort identity, and create spiritual instability.\n\n'
              'Fear, anxiety, lust, bitterness, insecurity, pride, and '
              'discouragement often grow through repeated mental agreement. This '
              'is why believers are called to intentionally set their minds on '
              'higher things rather than allowing thoughts to wander unchecked. '
              'As 2 Corinthians 10:5 teaches, thoughts must be brought into '
              'obedience to Christ.\n\n'
              'A mind consistently focused on God’s truth becomes stronger '
              'against deception and spiritual attack. What fills the mind '
              'regularly either strengthens or weakens the inner life.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Eternal Focus Produces Spiritual Stability',
          body: 'Setting the mind on things above means living with eternal '
              'perspective rather than becoming consumed only with temporary '
              'concerns. Eternal focus changes how believers respond to pressure, '
              'suffering, success, and uncertainty because life is viewed '
              'through the lens of God’s kingdom rather than through momentary '
              'circumstances alone.\n\n'
              'When eternal realities remain central, temporary difficulties lose '
              'some of their power to control emotions and perspective. As '
              '2 Corinthians 4:18 explains, visible things are temporary, but '
              'unseen eternal realities endure forever.\n\n'
              'The believer who continually focuses on God’s presence, promises, '
              'truth, and kingdom develops greater inward stability. Peace '
              'increases because the heart becomes anchored in what cannot be '
              'shaken by earthly change.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'A Heavenly Mindset Draws the Heart Closer to God',
          body: 'What the mind consistently pursues reveals where the heart is '
              'being drawn. Setting the mind on things above creates deeper '
              'intimacy with God because attention shifts from constant worldly '
              'distraction toward spiritual communion and eternal purpose.\n\n'
              'Prayer, worship, meditation on Scripture, gratitude, and obedience '
              'help train the mind to remain spiritually focused. Over time, the '
              'believer begins desiring God’s presence more deeply than temporary '
              'satisfaction. Spiritual hunger grows where attention continually '
              'turns toward God.\n\n'
              'As the mind becomes increasingly aligned with heavenly things, '
              'the believer begins reflecting the character, peace, and '
              'priorities of Christ more naturally. Transformation happens '
              'gradually through continual focus on what is eternal.',
        ),
      ],
      finalRevelation:
          'What continually fills the mind will eventually shape the condition '
          'of the soul.',
      reflectionQuestions: const [
        'What has been occupying my thoughts most consistently recently?',
        'Have temporary concerns distracted me from eternal priorities?',
        'Am I intentionally setting my mind on God’s truth daily?',
      ],
      prayer: 'Lord,\n'
          'Help me to set my mind continually on things above and not become '
          'consumed by temporary distractions. Guard my thoughts from fear, '
          'anxiety, pride, and every influence that pulls my heart away from You.\n\n'
          'Renew my thinking through Your Word and strengthen me to focus on '
          'what is eternal and life-giving. Teach me to view life through Your '
          'perspective rather than through worldly pressure and temporary '
          'concerns.\n\n'
          'Draw my heart into deeper intimacy with You daily. Let my thoughts '
          'reflect Your truth, my desires align with Your will, and my life '
          'remains anchored in Your presence.\n\n'
          'May my mind remain fixed on what is eternal, and may my soul grow '
          'stronger through continual focus on You.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 16),
    ),

    // ── 17. HELP ────────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'help',
      theme: 'Help',
      title: 'Help Comes From the Lord',
      scripture:
          'I will lift up my eyes to the hills—From whence comes my help? '
          'My help comes from the Lord, who made heaven and earth.',
      scriptureReference: 'Psalm 121:1–2',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Human Strength Has Limits, but God Does Not',
          body: 'Psalm 121 begins with a cry of dependence. The psalmist looks '
              'toward the hills while searching for help, revealing the natural '
              'human awareness of weakness and limitation. Life often brings '
              'situations that exceed personal strength, wisdom, resources, or '
              'emotional endurance. In such moments, people realize that human '
              'ability alone cannot sustain every burden.\n\n'
              'The psalmist quickly answers his own question by declaring that '
              'true help comes from the Lord, the Creator of heaven and earth. '
              'This reveals that the believer’s confidence is not rooted in '
              'earthly strength but in the power of the God who rules over all '
              'creation. The One who formed the universe is not limited by the '
              'obstacles confronting human life.\n\n'
              'When believers understand the greatness of God, fear begins '
              'losing some of its control. Problems may remain real, but they '
              'no longer appear greater than the God who is able to sustain and '
              'intervene.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Where We Look Determines How We Respond',
          body:
              'The phrase “I will lift up my eyes” reveals intentional focus. '
              'In difficult seasons, the direction of attention greatly affects '
              'the condition of the heart. Looking continually at problems often '
              'increases fear, anxiety, and discouragement, while looking toward '
              'God strengthens faith and spiritual stability.\n\n'
              'Many people become emotionally overwhelmed because their focus '
              'remains fixed only on visible challenges. Yet Scripture repeatedly '
              'calls believers to lift their eyes higher than temporary '
              'circumstances. As Hebrews 12:2 teaches, believers are called to '
              'fix their eyes on Jesus rather than becoming consumed by '
              'surrounding pressures.\n\n'
              'Spiritual focus does not deny difficulty, but it refuses to '
              'allow difficulty to become greater than God in the mind. Faith '
              'grows where the heart continually turns its attention toward the '
              'Lord.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Enemy Wants the Soul to Depend on Fear Instead of God',
          body:
              'One of the enemy’s strategies is convincing believers that they '
              'are alone in their struggles. Fear often magnifies weakness '
              'while minimizing awareness of God’s presence and power. When fear '
              'dominates the mind, people begin relying more on worry, striving, '
              'or self-preservation than on trust in God.\n\n'
              'The psalmist combats this by declaring where his help truly '
              'comes from. Speaking truth strengthens faith because it '
              'redirects the heart away from fear and back toward God’s '
              'faithfulness. As 2 Timothy 1:7 reminds believers, God has not '
              'given a spirit of fear but of power, love, and a sound mind.\n\n'
              'The believer was never meant to carry life independently. God’s '
              'help becomes most visible when human dependence shifts away from '
              'self-sufficiency and toward trust in Him.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Help Is Both Powerful and Personal',
          body: 'The psalmist identifies God as the Maker of heaven and earth, '
              'emphasizing His limitless power. Yet this same God also becomes '
              'personally involved in the lives of His people. Divine help is '
              'not distant or abstract—it is personal, intentional, and '
              'compassionate.\n\n'
              'Throughout Scripture, God repeatedly reveals Himself as a '
              'refuge, protector, provider, and sustainer. His help may come '
              'through strength, wisdom, peace, provision, guidance, or divine '
              'intervention depending on the season. Sometimes He changes '
              'circumstances, and sometimes He strengthens believers within them.\n\n'
              'As Isaiah 41:10 declares, God promises to uphold His people '
              'with His righteous hand. His presence becomes the believer’s '
              'greatest source of security during uncertain seasons.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Dependence on God Produces Inner Stability',
          body: 'When the believer truly understands that help comes from the '
              'Lord, inward stability begins to grow. Anxiety decreases because '
              'the soul no longer feels responsible for carrying every burden '
              'alone. Confidence develops not because life becomes easy, but '
              'because trust becomes rooted in God’s faithfulness.\n\n'
              'Dependence on God changes how difficulties are faced. Instead of '
              'responding with panic or hopelessness, the believer learns to '
              'respond with prayer, trust, and spiritual endurance. Peace grows '
              'where reliance on God becomes continual rather than occasional.\n\n'
              'The more believers experience God’s sustaining help personally, '
              'the stronger their confidence becomes for future seasons. Faith '
              'deepens through repeated encounters with His faithfulness.',
        ),
      ],
      finalRevelation:
          'Peace begins to grow when the heart fully realizes that its help '
          'comes from the Lord.',
      reflectionQuestions: const [
        'Where have I been looking for help outside of God?',
        'Have fear and pressure weakened my awareness of God’s presence?',
        'What situation in my life needs deeper trust in God’s help today?',
      ],
      prayer: 'Lord,\n'
          'Thank You for being my source of help in every season of life. When '
          'I feel weak, overwhelmed, or uncertain, remind me that my strength '
          'does not come from myself but from You alone.\n\n'
          'Help me to lift my eyes above fear, anxiety, and temporary '
          'circumstances. Teach me to focus on Your greatness more than on the '
          'challenges surrounding me. Strengthen my faith where discouragement '
          'has weakened my heart.\n\n'
          'Let Your presence become my peace and Your faithfulness become my '
          'confidence. Help me to rely on You daily instead of carrying '
          'burdens through my own strength alone.\n\n'
          'May my heart remain anchored in the truth that You are my helper,\n'
          'my sustainer, and my unfailing source of strength.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 17),
    ),

    // ── 18. PRESENCE ────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'storm',
      theme: 'Presence',
      title: 'God’s Presence Through Every Storm',
      scripture:
          'When you pass through the waters, I will be with you; and through '
          'the rivers, they shall not overflow you. When you walk through the '
          'fire, you shall not be burned, nor shall the flame scorch you.',
      scriptureReference: 'Isaiah 43:2',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God Never Promised a Life Without Trials',
          body:
              'Isaiah 43:2 does not promise the absence of waters, rivers, or '
              'fire. Instead, God promises His presence in the middle of them. '
              'This reveals an important spiritual truth: faith in God does not '
              'remove every difficulty from life, but it assures believers they '
              'will never face those difficulties alone.\n\n'
              'Many people mistakenly assume hardship means God has abandoned '
              'them, yet Scripture repeatedly shows that some of the deepest '
              'encounters with God happen during painful seasons. Trials often '
              'become places where His strength, faithfulness, and sustaining '
              'presence are experienced most personally.\n\n'
              'The verse says “when” you pass through the waters, not “if.” '
              'Challenges are part of human life, but God’s promise is that '
              'difficulties will not ultimately destroy those who remain '
              'anchored in Him.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God’s Presence Changes the Nature of the Battle',
          body:
              'The greatest promise in Isaiah 43:2 is not merely deliverance—it '
              'is divine presence. God says, “I will be with you.” His presence '
              'becomes the believer’s security even before circumstances change. '
              'Problems may still exist externally, but inward confidence grows '
              'when the heart knows God remains near.\n\n'
              'Throughout Scripture, God’s presence repeatedly strengthened '
              'people facing impossible situations. Moses faced Pharaoh with '
              'God’s presence. Daniel endured the lions’ den with God’s '
              'protection. The three Hebrew men walked through fire with '
              'divine companionship. God’s nearness transforms how battles are '
              'endured.\n\n'
              'As Matthew 28:20 reminds believers, Christ promised to remain '
              'with His people always. The soul becomes steadier when it '
              'realizes it is never abandoned in suffering.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Trials Reveal What the Heart Truly Depends On',
          body: 'Waters and fire symbolize overwhelming pressure, suffering, '
              'fear, and testing. Difficult seasons often expose hidden fears, '
              'insecurities, and areas where trust remains weak. What the heart '
              'truly depends on becomes visible when comfort and stability are '
              'shaken.\n\n'
              'The enemy often uses hardship to produce discouragement, '
              'hopelessness, and isolation. He attempts to convince believers '
              'that suffering means defeat or abandonment. But God uses trials '
              'differently—He uses them to deepen faith, refine character, and '
              'strengthen spiritual endurance.\n\n'
              'As 1 Peter 1:6–7 teaches, faith refined through testing becomes '
              'more precious than gold. God does not waste painful seasons; He '
              'often uses them to shape deeper spiritual maturity.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God Preserves What Belongs to Him',
          body: 'Isaiah 43:2 declares that the waters “shall not overflow you” '
              'and the fire “shall not burn you.” This does not mean believers '
              'avoid all pain, but it reveals that trials will not ultimately '
              'consume God’s people. Divine preservation remains active even '
              'during intense difficulty.\n\n'
              'There are seasons where life feels overwhelming, yet God quietly '
              'sustains the soul beneath the pressure. What should have '
              'destroyed the believer becomes survivable because God continues '
              'upholding them internally. His grace often carries people farther '
              'than their own strength ever could.\n\n'
              'As 2 Corinthians 12:9 reveals, God’s strength becomes perfected '
              'in human weakness. Preservation is not always dramatic outward '
              'deliverance—it is often the quiet sustaining power of God within '
              'the believer.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Passing Through Is Different from Remaining There',
          body:
              'One powerful word in Isaiah 43:2 is “through.” God did not say '
              'the believer would remain permanently in waters or fire. '
              'Difficult seasons may last for a time, but they are not the '
              'final destination. Pain is a passage, not a permanent identity.\n\n'
              'When suffering continues for long periods, it can feel endless. '
              'Yet God reminds His people that storms are temporary compared to '
              'His eternal faithfulness. The believer may walk through deep '
              'waters, but they are still moving forward under God’s care and '
              'guidance.\n\n'
              'Hope grows when the heart understands that difficult seasons are '
              'not permanent places of abandonment. God remains actively '
              'present, leading His people through what they could never '
              'survive alone.',
        ),
      ],
      finalRevelation:
          'The greatest protection in the storm is not the absence of '
          'difficulty, but the presence of God within it.',
      reflectionQuestions: const [
        'What trial or pressure am I currently walking through?',
        'Have I been focusing more on the storm than on God’s presence?',
        'What would change if I truly believed God is with me in this season?',
      ],
      prayer: 'Lord,\n'
          'Thank You for promising to remain with me through every season of '
          'life. When I walk through deep waters and difficult fires, help me '
          'to remember that I am never alone.\n\n'
          'Strengthen my faith when fear and uncertainty try to overwhelm my '
          'heart. Teach me to trust Your presence even when circumstances '
          'remain difficult or unclear. Remove discouragement, hopelessness, '
          'and every lie that tells me I have been abandoned.\n\n'
          'Preserve my heart through every trial and let Your strength sustain '
          'me where my own strength feels weak. Help me to see difficult '
          'seasons not as signs of defeat, but as places where Your '
          'faithfulness can be revealed more deeply.\n\n'
          'May I continue walking forward with confidence, knowing that You '
          'are with me through every storm.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 18),
    ),

    // ── 19. SURRENDER ───────────────────────────────────────────────────────
    DevotionalModel(
      id: 'humility',
      theme: 'Surrender',
      title: 'Humility, Surrender, and the God Who Cares',
      scripture:
          'Therefore humble yourselves under the mighty hand of God, that He '
          'may exalt you in due time, casting all your care upon Him, for He '
          'cares for you.',
      scriptureReference: '1 Peter 5:6–7',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Humility Begins with Recognizing Our Need for God',
          body:
              'Peter calls believers to humble themselves under the mighty hand '
              'of God. Humility is not weakness or self-hatred—it is the '
              'recognition that human strength, wisdom, and control are limited '
              'without God. Pride attempts to carry life independently, while '
              'humility acknowledges dependence on divine strength and guidance.\n\n'
              'Many struggles become heavier because people try to sustain '
              'burdens through their own understanding alone. Human pride often '
              'resists surrender because it desires control, certainty, and '
              'self-reliance. Yet true spiritual strength begins when the heart '
              'stops pretending to be self-sufficient and fully leans upon God.\n\n'
              'Humility positions the believer beneath God’s covering and '
              'leadership. It creates room for God’s wisdom, grace, and '
              'direction to work deeply within the heart.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God’s Timing Is Connected to Surrender',
          body: 'Peter says that God will exalt believers “in due time.” This '
              'reveals that elevation, restoration, breakthrough, and promotion '
              'are connected to divine timing rather than human striving. Many '
              'people become frustrated because they attempt to force outcomes '
              'before God’s appointed season arrives.\n\n'
              'Waiting seasons often test humility because the flesh naturally '
              'desires immediate results and visible answers. Yet surrender '
              'teaches patience and trust. God’s timing develops character '
              'internally before releasing certain blessings externally. As '
              'Ecclesiastes 3:11 reveals, God makes everything beautiful in its '
              'proper time.\n\n'
              'The believer who trusts God’s timing learns to rest without '
              'becoming consumed by anxiety or comparison. Surrender replaces '
              'striving with deeper confidence in God’s wisdom.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Anxiety Grows Where Burdens Are Carried Alone',
          body:
              'Peter immediately connects humility with casting cares upon God. '
              'Anxiety often increases when the heart attempts to carry '
              'responsibilities, fears, uncertainties, and emotional burdens '
              'without surrendering them to God. The human soul was never '
              'designed to carry life independently from divine help.\n\n'
              'The enemy often uses worry to exhaust the mind and weaken '
              'spiritual peace. Fear magnifies problems while making God’s '
              'presence feel distant. But Scripture calls believers to release '
              'their burdens rather than continually rehearse them internally.\n\n'
              'As Philippians 4:6–7 teaches, peace begins guarding the heart '
              'when anxieties are brought before God through prayer and '
              'surrender. What is continually surrendered to God loses some of '
              'its power to dominate the mind.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Care Is Personal and Intentional',
          body:
              'One of the most comforting truths in this passage is the statement, '
              '“for He cares for you.” God’s care is not distant, cold, or '
              'general—it is deeply personal. The Creator of heaven and earth '
              'remains attentive to the struggles, fears, wounds, and needs of '
              'His people.\n\n'
              'Many believers intellectually know God loves them yet still '
              'struggle to believe He truly cares about the details of their '
              'lives. But Scripture repeatedly reveals a God who is '
              'compassionate, attentive, and near to the brokenhearted. As '
              'Psalm 34:18 declares, God draws near to those who are hurting '
              'internally.\n\n'
              'Understanding God’s care changes how burdens are carried. The '
              'heart becomes more willing to surrender fears when it truly '
              'believes it is safe in God’s hands.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Surrender Produces Inner Peace',
          body:
              'Casting cares upon God is not a one-time action but a continual '
              'spiritual practice. Every day presents new opportunities either '
              'to carry burdens through fear or surrender them through trust. '
              'Peace grows gradually where dependence on God becomes consistent.\n\n'
              'The surrendered heart no longer feels pressured to control every '
              'outcome perfectly. Instead, it learns to rest in God’s '
              'faithfulness while continuing to walk in obedience and trust. '
              'This kind of peace does not come from having every answer—it '
              'comes from confidence that God remains present and in control.\n\n'
              'As surrender deepens, the soul becomes lighter, steadier, and '
              'less dominated by fear. Trust transforms the inner atmosphere of '
              'the heart.',
        ),
      ],
      finalRevelation:
          'Peace begins where pride releases control and the heart fully '
          'entrusts its burdens to God.',
      reflectionQuestions: const [
        'What burdens have I been carrying without fully surrendering them to God?',
        'Have fear and anxiety weakened my trust in His care for me?',
        'What would change if I truly rested in God’s timing and faithfulness?',
      ],
      prayer: 'Lord,\n'
          'Teach me to humble myself fully before You and to trust Your wisdom '
          'above my own understanding. Forgive me for the times I have tried '
          'to carry burdens alone instead of surrendering them into Your hands.\n\n'
          'Help me to release every fear, anxiety, pressure, and uncertainty '
          'that has been weighing heavily on my heart. Strengthen me to trust '
          'Your timing even when answers feel delayed and circumstances remain '
          'unclear.\n\n'
          'Remind me daily that You truly care for me and that Your love is '
          'personal, constant, and faithful. Let Your peace quiet every '
          'restless thought and bring stability to my soul.\n\n'
          'May my heart learn to rest deeply in Your presence, and may '
          'surrender become the pathway to lasting peace within me.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 19),
    ),

    // ── 20. SEARCH HEART ──────────────────────────────────────────────────────
    DevotionalModel(
      id: 'search_heart',
      theme: 'Surrender',
      title: 'The God Who Searches the Heart',
      scripture:
          'Search me, O God, and know my heart; try me, and know my anxieties; '
          'and see if there is any wicked way in me, and lead me in the way '
          'everlasting.',
      scriptureReference: 'Psalm 139:23–24',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'True Spiritual Growth Begins with Honest Surrender',
          body: 'Psalm 139:23 reveals David inviting God to search his heart '
              'completely. This is a profound act of humility because it requires '
              'openness before God without hiding weakness, fear, motives, or '
              'internal struggles. Many people desire outward change while '
              'resisting inward exposure, yet transformation begins where honesty '
              'before God becomes genuine.\n\n'
              'God already sees every hidden thought and intention, but He '
              'desires willing surrender from the believer. Spiritual maturity '
              'increases when the heart stops defending itself and becomes '
              'teachable before God. Honest surrender allows divine healing, '
              'correction, and restoration to reach areas that pride often keeps '
              'hidden.\n\n'
              'The soul cannot be deeply transformed while continually hiding '
              'behind appearances. Freedom begins where the heart becomes '
              'transparent before God.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'The Heart Can Carry Hidden Things Unnoticed',
          body:
              'David asks God to reveal anything within him that is contrary to '
              'His will. This shows that human beings are not always fully aware '
              'of their own internal condition. Hidden fears, pride, bitterness, '
              'insecurity, selfish ambition, and unresolved wounds can quietly '
              'influence behavior without being immediately recognized.\n\n'
              'The heart is complex, and self-deception can easily distort '
              'spiritual perception. As Jeremiah 17:9 teaches, the human heart '
              'can become deceitful when left unchecked. This is why continual '
              'self-examination before God remains spiritually important.\n\n'
              'God’s light exposes not to condemn, but to heal and restore. '
              'What remains hidden often continues growing stronger, but what '
              'is surrendered before God can begin transforming through His grace.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Anxiety Often Reveals Areas Needing Deeper Trust',
          body:
              'David specifically asks God to know his anxieties. This reveals '
              'that anxiety is not merely emotional pressure—it can also expose '
              'areas where fear, uncertainty, or lack of trust have entered the '
              'heart. Worry often grows where the soul feels pressured to '
              'control outcomes independently from God.\n\n'
              'The enemy frequently uses anxiety to create mental exhaustion '
              'and spiritual instability. Fear magnifies uncertainty while '
              'weakening awareness of God’s faithfulness. Yet bringing anxieties '
              'honestly before God opens the door for peace, healing, and '
              'renewed trust.\n\n'
              'As 1 Peter 5:7 teaches, believers are called to cast their cares '
              'upon God because He cares deeply for them. Surrender weakens the '
              'power anxiety holds over the heart.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Correction Is an Expression of His Love',
          body:
              'David asks God to reveal any “wicked way” within him, showing a '
              'willingness to receive correction. Many people resist correction '
              'because it feels uncomfortable, yet loving correction protects the '
              'soul from deeper spiritual damage. God exposes unhealthy patterns '
              'not to shame His people, but to lead them into greater freedom '
              'and alignment with Him.\n\n'
              'A hardened heart avoids conviction, but a surrendered heart '
              'welcomes God’s refining work. As Hebrews 12:6 explains, God '
              'disciplines those He loves. Divine correction is evidence of '
              'relationship, not rejection.\n\n'
              'The believer who remains teachable grows spiritually stronger over '
              'time. Correction becomes the pathway through which God shapes '
              'character, wisdom, and maturity.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'God Always Leads Toward Life and Restoration',
          body:
              'David ends by asking God to lead him “in the way everlasting.” '
              'God never exposes the heart without also offering direction, '
              'healing, and restoration. His goal is not merely to reveal '
              'problems but to guide believers into deeper life, truth, and '
              'intimacy with Him.\n\n'
              'The everlasting way is the path of continual dependence on God, '
              'ongoing transformation, and eternal perspective. As the believer '
              'submits more deeply to God’s leading, the soul becomes increasingly '
              'aligned with His peace, wisdom, and purpose.\n\n'
              'God’s leadership is not harsh or destructive. He leads with '
              'truth, patience, and grace, continually drawing His people toward '
              'spiritual wholeness and lasting peace.',
        ),
      ],
      finalRevelation:
          'God does not search the heart to destroy it — He searches it to heal, '
          'refine, and lead it closer to Him.',
      reflectionQuestions: const [
        'Are there hidden areas of my heart I have avoided surrendering to God?',
        'What anxieties have been revealing deeper fears or lack of trust?',
        'Am I willing to allow God to correct and refine me completely?',
      ],
      prayer: 'Lord,\n'
          'Search my heart completely and reveal anything within me that does '
          'not align with Your truth and will. Expose hidden fears, unhealthy '
          'motives, pride, anxiety, and every area where I have resisted Your '
          'transforming work.\n\n'
          'Help me not to fear Your correction, but to welcome it with humility '
          'and trust. Teach me to surrender every burden, worry, and hidden '
          'struggle into Your hands rather than carrying them alone.\n\n'
          'Purify my heart and renew my mind daily. Lead me away from every '
          'destructive path and guide me continually in the way everlasting. '
          'Let Your presence heal what is wounded, strengthen what is weak, '
          'and transform what is broken within me.\n\n'
          'May my heart remain open before You always, and may my life reflect '
          'continual surrender to Your truth and leading.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 20),
    ),

    // ── 21. FAITH UNCERTAIN ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'faith_uncertain',
      theme: 'Faith',
      title: 'Walking by Faith in an Uncertain World',
      scripture: 'For we walk by faith, not by sight.',
      scriptureReference: '2 Corinthians 5:7',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Faith Is a Way of Life, Not a Moment',
          body:
              'Paul does not describe faith as something occasional—he describes '
              'it as a way we walk. Walking implies movement, progression, and '
              'daily decisions. Faith is not reserved for crises alone; it is '
              'meant to shape how we think, choose, respond, and endure every '
              'single day.\n\n'
              'Scripture consistently affirms that faith is meant to be lived '
              'out continually. As Hebrews 11:6 teaches, “without faith it is '
              'impossible to please Him,” showing that faith is foundational to '
              'a relationship with God. Likewise, Proverbs 3:5–6 calls believers '
              'to trust in the Lord with all their heart—not just in certain '
              'moments, but in all their ways.\n\n'
              'To walk by faith means choosing to trust God in ordinary moments, '
              'unseen seasons, and uncertain outcomes. It is a daily commitment, '
              'not a temporary reaction.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Sight Represents Human Limitation',
          body:
              '“Sight” in this verse goes beyond physical vision—it represents '
              'reliance on what can be measured, controlled, or explained. Human '
              'nature gravitates toward what feels tangible and predictable. We '
              'feel safer when we can see outcomes, timelines, and guarantees.\n\n'
              'Yet Scripture reminds us that what is seen is temporary, while '
              'what is unseen is eternal (2 Corinthians 4:18). When life is '
              'interpreted only through visible evidence, fear, doubt, and '
              'confusion can easily take over. This is why Isaiah 55:8–9 '
              'emphasizes that God’s thoughts and ways are higher than ours—far '
              'beyond what we can perceive.\n\n'
              'Faith challenges this limitation by inviting us to trust beyond '
              'what is immediately apparent. It reminds us that God is working '
              'even when evidence is absent.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Faith Often Requires Letting Go of Control',
          body:
              'Walking by sight allows a sense of control—if we can see it, we '
              'feel we can manage it. Walking by faith requires releasing that '
              'illusion. It means trusting God’s direction without having the '
              'full picture.\n\n'
              'This is where many struggle. The desire for certainty, clarity, '
              'and control can resist the path of faith. Yet Scripture calls for '
              'surrender: “Commit your way to the Lord, trust also in Him, and '
              'He shall bring it to pass” (Psalm 37:5).\n\n'
              'God rarely reveals the entire journey at once. Instead, He '
              'provides enough light for the next step. As Psalm 119:105 says, '
              '“Your word is a lamp to my feet and a light to my path”—guidance '
              'for each step, not the entire road. Faith is not about having '
              'all the answers—it is about trusting the One who does.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Presence Is Greater Than What Is Seen',
          body:
              'One of the deepest truths behind this verse is that reality is '
              'not limited to what is visible. God’s presence, guidance, and '
              'work are often unseen, yet profoundly active.\n\n'
              'Even when circumstances appear stagnant, confusing, or painful, '
              'God is still moving. Romans 8:28 reminds us that “all things work '
              'together for good to those who love God,” even when that work is '
              'invisible in the moment.\n\n'
              'Throughout Scripture, God consistently works behind the scenes—'
              'shaping outcomes, protecting His people, and fulfilling His '
              'purposes in ways that are not immediately obvious. Faith allows '
              'us to rest in that unseen activity, echoing the truth of Hebrews '
              '11:1 that faith is “the substance of things hoped for, the '
              'evidence of things not seen.”',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Walking by Faith Produces Spiritual Stability',
          body:
              'When life is guided only by sight, emotions tend to rise and fall '
              'with circumstances. Good days bring confidence; difficult days '
              'bring discouragement. This creates instability within the heart.\n\n'
              'But faith produces steadiness. Isaiah 26:3 declares, “You will '
              'keep him in perfect peace, whose mind is stayed on You, because '
              'he trusts in You.” God’s faithfulness does not fluctuate with '
              'circumstances. His promises remain constant even when situations '
              'shift (Numbers 23:19).\n\n'
              'As faith deepens, the believer becomes less shaken by what is '
              'seen and more grounded in what is known about God. This creates '
              'inner strength, endurance, and peace even in uncertain seasons.',
        ),
      ],
      finalRevelation:
          'Faith is not the absence of uncertainty—it is the decision to trust '
          'God in the middle of it.',
      reflectionQuestions: const [
        'What situations in my life am I trying to control because I cannot see the outcome?',
        'Have I been relying more on what is visible than on what God has promised?',
        'What would it look like for me to truly walk by faith today, not just in words but in action?',
      ],
      prayer: 'Lord,\n'
          'Teach me to walk by faith and not by sight. When circumstances feel '
          'uncertain or unclear, help me to trust Your presence and Your plan '
          'above what I can see or understand.\n\n'
          'Forgive me for the times I have relied more on my own perception '
          'than on Your truth. Strengthen my heart to trust You even when the '
          'path ahead is not fully revealed.\n\n'
          'Help me release the need for control and rest in Your guidance. '
          'Remind me that You are working even in unseen ways, and that Your '
          'purposes are always good.\n\n'
          'Let my life reflect a steady trust in You, and teach my heart to '
          'move forward with confidence, one step of faith at a time.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 21),
    ),

    // ── 22. FINISHES STARTED ─────────────────────────────────────────────────
    DevotionalModel(
      id: 'finishes_started',
      theme: 'Faithfulness',
      title: 'The God Who Finishes What He Starts',
      scripture:
          'Being confident of this very thing, that He who has begun a good '
          'work in you will complete it until the day of Jesus Christ.',
      scriptureReference: 'Philippians 1:6',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God Is the Author of Your Spiritual Journey',
          body:
              'Paul begins with confidence rooted not in human effort, but in '
              'God’s initiative. “He who has begun a good work in you…” reminds '
              'us that salvation, transformation, and spiritual growth originate '
              'with God—not with human striving.\n\n'
              'Scripture affirms this truth repeatedly. As John 6:44 teaches, '
              'no one comes to God unless drawn by Him, and Ephesians 2:8–9 '
              'reveals that salvation is a gift of grace, not a result of works. '
              'This means your spiritual journey did not begin by accident or by '
              'your own strength—it began by divine intention.\n\n'
              'Understanding this shifts the pressure off self-reliance. You are '
              'not the origin of your transformation—God is. And what God '
              'initiates carries purpose, design, and intention.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God’s Work Within You Is Ongoing',
          body:
              'Paul speaks of a work that has begun, implying that it is still '
              'in progress. Spiritual growth is not instant or complete in a '
              'single moment—it unfolds over time through seasons, challenges, '
              'and refinement.\n\n'
              'This process can sometimes feel slow or even frustrating. Yet '
              'Scripture makes it clear that growth is progressive. As 2 '
              'Corinthians 3:18 explains, we are being transformed “from glory '
              'to glory,” indicating a continual process of becoming more like '
              'Christ.\n\n'
              'Even when change feels invisible, God is still working. Philippians '
              '2:13 reinforces this truth: “for it is God who works in you both '
              'to will and to do for His good pleasure.” What feels unfinished '
              'in you is often still under construction by God’s hands.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'God’s Faithfulness Is Greater Than Your Inconsistency',
          body: 'One of the most comforting truths in this verse is that the '
              'completion of the work depends on God, not on human perfection. '
              'Believers may struggle, stumble, or feel inconsistent—but God '
              'remains faithful.\n\n'
              'As 2 Timothy 2:13 declares, “If we are faithless, He remains '
              'faithful; He cannot deny Himself.” This does not excuse '
              'complacency, but it does provide assurance. God’s commitment to '
              'your growth does not waver with your weaknesses.\n\n'
              'The enemy often uses failure to convince believers that they are '
              'disqualified or stuck. But Scripture reveals a God who restores, '
              'renews, and continues His work despite human imperfection. '
              'Lamentations 3:22–23 reminds us that His mercies are new every '
              'morning.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Completion Is Certain, Even When Progress Feels Unclear',
          body:
              'Paul expresses confidence—not uncertainty—that God will complete '
              'His work. This confidence is not based on visible progress, but '
              'on God’s character.\n\n'
              'There are seasons when growth feels hidden. Habits may take time '
              'to change, prayers may seem unanswered, and breakthroughs may '
              'feel delayed. Yet Ecclesiastes 3:11 reminds us that God makes '
              'everything beautiful in its time.\n\n'
              'God sees the full picture, while we often see only fragments. '
              'What feels incomplete now is not abandoned—it is still being '
              'shaped. Romans 8:29 reveals that God’s ultimate goal is to '
              'conform believers to the image of Christ, and He will not abandon '
              'that purpose midway.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'The Journey Leads to a Glorious Completion',
          body:
              'Paul points to “the day of Jesus Christ,” referring to the future '
              'fulfillment when Christ returns and God’s work in believers is '
              'fully completed. This reminds us that spiritual growth is not '
              'only about present change—it is moving toward eternal '
              'transformation.\n\n'
              '1 John 3:2 declares that when Christ appears, “we shall be like '
              'Him,” revealing the final stage of what God is currently '
              'developing. What begins in this life will be perfected in '
              'eternity.\n\n'
              'This gives meaning to every step of the journey. Every struggle, '
              'every lesson, and every moment of growth is part of a larger, '
              'eternal process that God is faithfully guiding to completion.',
        ),
      ],
      finalRevelation:
          'What God begins in grace, He completes in faithfulness.',
      reflectionQuestions: const [
        'Do I truly believe that God is actively working in my life, even when I cannot see progress?',
        'Have I been discouraged by my imperfections instead of trusting God’s faithfulness?',
        'What would change if I lived with confidence that God will finish what He started in me?',
      ],
      prayer: 'Lord,\n'
          'Thank You for being the One who began a good work in me. Remind me '
          'that my journey of growth and transformation is not dependent on my '
          'strength alone, but on Your power and faithfulness.\n\n'
          'Forgive me for the times I have doubted Your work in my life or '
          'become discouraged by slow progress. Help me to trust that You are '
          'still shaping me, even when I cannot see it clearly.\n\n'
          'Strengthen my heart to rely on Your faithfulness rather than my own '
          'consistency. Teach me to walk in confidence, knowing that You will '
          'complete what You have started.\n\n'
          'Let my life reflect continual growth, surrender, and trust in You, '
          'until the day Your work in me is made complete in the presence of '
          'Christ.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 22),
    ),

    // ── 23. ENDURANCE ────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'endurance',
      theme: 'Endurance',
      title: 'Running with Endurance and Fixing Our Eyes on Christ',
      scripture:
          'Therefore we also, since we are surrounded by so great a cloud of '
          'witnesses, let us lay aside every weight, and the sin which so '
          'easily ensnares us, and let us run with endurance the race that is '
          'set before us, looking unto Jesus, the author and finisher of our '
          'faith...',
      scriptureReference: 'Hebrews 12:1–2',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'You Are Not Running Alone',
          body:
              'The passage begins with a powerful reminder: we are “surrounded '
              'by so great a cloud of witnesses.” This refers to the faithful '
              'men and women described in Hebrews 11—those who lived by faith, '
              'endured hardship, and trusted God despite uncertainty.\n\n'
              'Their lives serve as encouragement, not pressure. They testify '
              'that faith is possible, endurance is achievable, and God is '
              'faithful through every season. As Romans 15:4 teaches, what was '
              'written before was written for our learning, that we might have '
              'hope through perseverance and encouragement from the Scriptures.\n\n'
              'When the journey feels isolating, this truth matters deeply—you '
              'are part of a much larger story of faith. Others have walked '
              'difficult paths and remained faithful, and their testimony '
              'strengthens your resolve to keep going.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Not Everything That Slows You Is Sin—But It Still Matters',
          body:
              'The writer makes a clear distinction between “every weight” and '
              '“the sin which so easily ensnares us.” Sin is destructive and '
              'must be removed, but weights can be more subtle. They may not be '
              'sinful in themselves, yet they hinder spiritual progress.\n\n'
              'Weights can include distractions, unhealthy attachments, fear, '
              'comparison, or anything that consumes energy and focus away from '
              'God. As 1 Corinthians 10:23 reminds us, not everything that is '
              'permissible is beneficial.\n\n'
              'Spiritual growth requires intentional release. Letting go is not '
              'always about removing what is wrong—it is often about releasing '
              'what is unnecessary so that you can move forward freely.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Endurance Is Developed, Not Instant',
          body: 'The Christian life is described as a race—not a sprint, but a '
              'long-distance journey requiring perseverance. “Run with '
              'endurance” implies sustained effort through difficulty, delay, '
              'and resistance.\n\n'
              'Endurance is not something we naturally possess—it is built '
              'through testing. James 1:2–4 teaches that trials produce '
              'perseverance, and perseverance matures the believer. What feels '
              'like resistance is often part of God’s process of strengthening '
              'spiritual endurance.\n\n'
              'There will be moments of weariness, but Galatians 6:9 encourages '
              'us not to grow weary in doing good, for in due season we will '
              'reap if we do not give up. Endurance keeps you moving even when '
              'progress feels slow.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Focus Determines Direction',
          body:
              'The key to endurance is found in verse 2: “looking unto Jesus.” '
              'Where your focus rests will determine how you run the race.\n\n'
              'When focus is on circumstances, discouragement grows. When focus '
              'is on other people, comparison and insecurity can develop. But '
              'when focus is on Christ, faith is strengthened.\n\n'
              'Jesus is called “the author and finisher of our faith,” meaning '
              'He is both the beginning and the completion of our spiritual '
              'journey. As Colossians 3:2 instructs, we are to set our minds '
              'on things above, not on earthly things.\n\n'
              'Fixing your eyes on Christ brings clarity, direction, and strength. '
              'It realigns the heart when distractions and difficulties try to '
              'pull you off course.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Jesus Is the Perfect Example of Endurance',
          body: 'The passage points to Jesus, “who for the joy that was set '
              'before Him endured the cross, despising the shame, and has sat '
              'down at the right hand of the throne of God.”\n\n'
              'Jesus endured unimaginable suffering, yet He remained focused on '
              'the joy ahead—the fulfillment of God’s purpose. His endurance '
              'was rooted in vision beyond the present pain.\n\n'
              'This reveals a powerful truth: endurance is sustained when '
              'purpose is clear. As 2 Corinthians 4:17–18 explains, present '
              'afflictions are temporary compared to the eternal glory being '
              'prepared.\n\n'
              'When you fix your eyes on Christ, you not only receive strength—'
              'you also gain perspective. You begin to see your struggles in '
              'light of something greater and eternal.',
        ),
      ],
      finalRevelation:
          'Endurance grows when distractions are released and the eyes remain '
          'fixed on Christ.',
      reflectionQuestions: const [
        'What “weights” in my life may be slowing down my spiritual progress?',
        'Am I becoming discouraged because my focus has shifted away from Christ?',
        'What would it look like for me to run my race with endurance and intentional focus today?',
      ],
      prayer: 'Lord,\n'
          'Thank You for calling me to run this race of faith. Help me to lay '
          'aside every weight and every sin that hinders my walk with You. Give '
          'me discernment to recognize what is slowing me down and the strength '
          'to release it.\n\n'
          'Teach me to run with endurance, even when the journey feels long or '
          'difficult. Strengthen my heart in seasons of weariness and remind '
          'me that You are working through every step.\n\n'
          'Fix my eyes on Jesus, the author and finisher of my faith. When '
          'distractions arise or discouragement sets in, draw my focus back '
          'to You.\n\n'
          'Help me to follow the example of Christ, enduring with purpose and '
          'trusting in the joy set before me. Let my life be marked by '
          'perseverance, faith, and unwavering focus on You, until I finish '
          'the race You have set before me.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 23),
    ),

    // ── 24. DELIGHT SURRENDER ────────────────────────────────────────────────
    DevotionalModel(
      id: 'delight_surrender',
      theme: 'Surrender',
      title: 'Delight, Surrender, and the God Who Directs Your Path',
      scripture:
          'Delight yourself also in the Lord, and He shall give you the desires '
          'of your heart. Commit your way to the Lord, trust also in Him, and '
          'He shall bring it to pass.',
      scriptureReference: 'Psalm 37:4–5',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'Delight Reorients the Heart Toward God',
          body: 'The invitation to “delight yourself in the Lord” goes deeper '
              'than emotion—it speaks of finding true satisfaction, joy, and '
              'fulfillment in God Himself. Delight is not merely about receiving '
              'blessings; it is about treasuring the One who gives them.\n\n'
              'Human hearts naturally seek fulfillment in relationships, '
              'achievements, possessions, or outcomes. Yet these things, while '
              'meaningful, cannot fully satisfy the soul. Psalm 16:11 reveals '
              'that fullness of joy is found in God’s presence.\n\n'
              'As delight in God grows, the heart begins to shift. Desires are '
              'no longer driven solely by personal ambition but are gradually '
              'shaped by God’s will. What once seemed essential may lose its '
              'hold, while what matters to God becomes more precious.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God Transforms Desires Before He Fulfills Them',
          body: '“He shall give you the desires of your heart” is often '
              'misunderstood as a promise of immediate fulfillment. But in the '
              'context of delight, it reveals something deeper—God aligns the '
              'heart before He answers it.\n\n'
              'As believers draw closer to God, their desires begin to reflect '
              'His nature and purpose. This transformation is part of spiritual '
              'maturity. Romans 12:2 teaches that renewal of the mind leads to '
              'discernment of God’s will.\n\n'
              'Sometimes God fulfills desires directly. Other times, He reshapes '
              'them entirely. What once seemed urgent may be replaced by '
              'something more aligned with His plan. This is not denial—it is '
              'refinement.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Commitment Requires Surrender of Control',
          body:
              'Verse 5 shifts from delight to action: “Commit your way to the '
              'Lord.” To commit means to entrust, to roll your plans, decisions, '
              'and direction onto God. It is a conscious surrender of control.\n\n'
              'This can be challenging because the human heart often seeks '
              'certainty and control over outcomes. Yet Proverbs 16:3 echoes '
              'this truth: “Commit your works to the Lord, and your thoughts '
              'will be established.”\n\n'
              'Surrender does not mean passivity—it means active trust. You '
              'continue to move forward in obedience, but you release the need '
              'to control every detail. Commitment places your life under God’s '
              'direction rather than your own limited understanding.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Trust Bridges the Gap Between Surrender and Fulfillment',
          body: '“Trust also in Him” connects directly to commitment. It is '
              'possible to surrender something outwardly while still holding '
              'anxiety inwardly. True commitment is sustained by trust.\n\n'
              'Trust means believing that God’s ways are good even when they '
              'are unclear. Proverbs 3:5 reminds us to trust in the Lord with '
              'all our heart and not lean on our own understanding.\n\n'
              'There is often a gap between surrender and visible results. In '
              'that space, trust becomes essential. It steadies the heart when '
              'answers are delayed and prevents discouragement from taking root.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'God Is Faithful to Bring His Purposes to Pass',
          body:
              'The promise concludes with assurance: “He shall bring it to pass.” '
              'This does not mean everything will unfold exactly as imagined—but '
              'it does mean God will faithfully accomplish His will in and '
              'through your life.\n\n'
              'Isaiah 46:10 declares that God’s counsel will stand and He will '
              'accomplish all His purpose. What He brings to pass is always '
              'rooted in His wisdom, timing, and greater plan.\n\n'
              'Sometimes fulfillment looks different than expected, but it is '
              'always intentional. God’s outcomes are not random—they are '
              'purposeful and shaped by His perfect understanding of what is best.',
        ),
      ],
      finalRevelation:
          'When the heart delights in God, desires are aligned, surrender '
          'becomes natural, and trust leads to divine fulfillment.',
      reflectionQuestions: const [
        'What am I truly delighting in right now—God, or what I hope He will give me?',
        'Are my desires being shaped by God, or driven by my own understanding?',
        'What would it look like for me to fully commit my plans and trust God with the outcome?',
      ],
      prayer: 'Lord,\n'
          'Teach me to truly delight in You, not just in what You can give, '
          'but in who You are. Let my heart find its deepest joy and '
          'satisfaction in Your presence.\n\n'
          'Shape my desires according to Your will. Renew my mind and align '
          'my heart with what matters most to You.\n\n'
          'Help me to commit every part of my life into Your hands. Release my '
          'need for control and strengthen me to trust You fully, even when '
          'the path is unclear.\n\n'
          'Remind me that You are faithful to bring Your purposes to pass in '
          'my life. Let my life reflect a deep trust, steady surrender, and a '
          'heart that delights completely in You.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 24),
    ),
    // ── 25. REFUGE ──────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'refuge_strength',
      theme: 'Refuge',
      title: 'God Our Refuge and Strength',
      scripture:
          'God is our refuge and strength, a very present help in trouble.',
      scriptureReference: 'Psalms 46:1',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God Is Meant to Be Our First Refuge, Not Our Last Option',
          body:
              'Psalm 46:1 begins by declaring that God is our refuge. A refuge is '
              'a place of safety, shelter, and protection during danger or '
              'uncertainty. Too often, people run first to fear, human solutions, '
              'distractions, or emotional reactions before turning to God. Yet '
              'Scripture reveals that God desires to be the believer’s first source '
              'of security rather than the final option after every other solution '
              'fails.\n\n'
              'A refuge is not merely a temporary hiding place—it is a place where '
              'the soul finds rest and stability. God invites believers to bring '
              'every burden, fear, and uncertainty into His presence. When life '
              'becomes overwhelming, the heart needs more than temporary relief; '
              'it needs the security that only God’s presence can provide.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'A Very Present Help Means He Is Already There',
          body:
              'The scripture does not describe God as a distant helper who arrives '
              'after the trouble begins; it calls Him a “very present” help. This '
              'means that before the difficulty even arises, God’s presence is '
              'already there. Believers do not need to convince Him to show up or '
              'persuade Him to care—He is already intimately aware of every '
              'struggle.\n\n'
              'Trouble often creates the illusion of absence. When circumstances '
              'become chaotic, human emotions can misinterpret silence as '
              'abandonment. Yet the promise of Psalm 46 is that God’s nearness is '
              'not determined by the absence of trouble, but by His unchanging '
              'nature. Recognizing His constant presence changes the way a believer '
              'walks through difficulty.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Strength Is Needed When Human Endurance Fails',
          body:
              'While a refuge provides shelter, strength provides endurance. There '
              'are seasons where God removes the problem and provides safety, but '
              'there are other seasons where He requires the believer to walk '
              'through the problem. In those moments, He promises to be their '
              'strength.\n\n'
              'Human endurance is fragile and eventually runs out. Relying entirely '
              'on personal capability often leads to exhaustion and burnout. But '
              'when a believer leans on divine strength, they access power that '
              'does not deplete. God’s strength often becomes most evident '
              'precisely at the moment when human capability reaches its limit.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'Trouble Is Addressed, Not Ignored',
          body:
              'Notice that Psalm 46:1 does not promise a life free of trouble. It '
              'explicitly acknowledges that trouble exists. Being a believer does '
              'not grant immunity from hardship, pain, or challenging '
              'circumstances. What it does grant is access to a refuge and '
              'strength within the hardship.\n\n'
              'God’s peace is not the absence of storms—it is His presence within '
              'them. Those who try to navigate life’s difficulties alone are often '
              'crushed by the weight of their own anxieties. But those who run to '
              'the refuge find that while the storm may still rage outside, their '
              'inner world remains anchored.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'The Choice to Run to the Refuge Is Yours',
          body:
              'God provides the refuge, but the believer must choose to enter it. '
              'This requires an active decision to turn away from fear, panic, '
              'and self-reliance, and to turn toward Him in prayer, worship, and '
              'trust.\n\n'
              'When trouble comes, the immediate reflex often dictates the outcome. '
              'If the first reflex is worry, peace is lost. But if the first reflex '
              'is running to the Father, peace is sustained. Cultivating a habit '
              'of immediately turning to God in both small inconveniences and '
              'major crises builds spiritual resilience over time.',
        ),
      ],
      finalRevelation:
          'God is not intimidated by the size of the trouble; He simply asks '
          'His children to trust the size of their Refuge.',
      reflectionQuestions: const [
        'What is my first reaction when trouble arises—fear or turning to God?',
        'Where have I been relying on my own strength instead of His?',
        'How can I cultivate a deeper awareness of His “very present” help today?',
      ],
      prayer: 'Lord,\n'
          'Thank You for being my refuge and strength, a very present help when '
          'trouble surrounds me.\n'
          'Forgive me for the times I have turned to fear or relied on my own '
          'understanding instead of running to You first.\n\n'
          'When I am overwhelmed, remind my heart that You are already near.\n'
          'When I am exhausted, be the strength that sustains me.\n\n'
          'Help me to trust You completely, knowing that no storm is greater than '
          'Your power.\n'
          'Teach me to rest in the shelter of Your presence today.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 25),
    ),
    // ── 26. KINDNESS ────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'kindness_transformation',
      theme: 'Kindness',
      title: 'The Kindness That Leads to Transformation',
      scripture:
          'Or do you despise the riches of His goodness, forbearance, and longsuffering, not knowing that the goodness of God leads you to repentance?',
      scriptureReference: 'Romans 2:4',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God’s Goodness Is Greater Than We Often Realize',
          body:
              'Romans 2:4 speaks about the riches of God’s goodness, patience, and '
              'longsuffering. This reveals that God’s nature is abundantly compassionate '
              'and merciful toward humanity. Many people view God only through the lens '
              'of judgment while overlooking the depth of His kindness and patience toward '
              'human weakness.\n\n'
              'Every breath, opportunity, provision, and moment of grace reflects the '
              'goodness of God at work. Even during seasons of rebellion or spiritual '
              'drifting, God often continues extending mercy rather than immediate '
              'judgment. His goodness is not weakness—it is divine compassion giving '
              'people space to return to Him.\n\n'
              'The believer who truly understands God’s goodness develops deeper gratitude, '
              'humility, and reverence. Awareness of His mercy softens the heart and '
              'strengthens intimacy with Him.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'God’s Patience Is an Invitation, Not Permission',
          body:
              'Paul warns against despising God’s goodness and patience. Sometimes '
              'people mistake God’s patience for approval, assuming delayed consequences '
              'mean their actions do not matter spiritually. Yet God’s patience is not '
              'permission to remain unchanged—it is an opportunity for repentance and '
              'transformation.\n\n'
              'God delays judgment because He desires restoration rather than destruction. '
              'As Second Epistle of Peter 3:9 explains, God is patient because He desires '
              'people to come to repentance. His mercy creates space for hearts to turn '
              'back toward Him.\n\n'
              'The danger comes when the heart becomes hardened and continually ignores '
              'God’s conviction. Repeated resistance to truth slowly weakens spiritual '
              'sensitivity. But humility responds to God’s patience with surrender rather '
              'than complacency.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Sin Hardens the Heart Gradually',
          body:
              'Romans 2:4 reveals that people can “despise” God’s goodness without fully '
              'realizing it. Spiritual hardness rarely happens instantly; it often develops '
              'gradually through repeated compromise, pride, self-justification, and '
              'resistance to conviction.\n\n'
              'The enemy seeks to normalize sin until the conscience becomes less sensitive '
              'to God’s voice. What once produced conviction can eventually feel acceptable '
              'if continually entertained. This is why guarding the heart remains spiritually '
              'important.\n\n'
              'As Epistle to the Hebrews 3:13 teaches, sin can become deceitful and harden '
              'the heart over time. God’s truth continually calls believers back into '
              'humility, repentance, and spiritual sensitivity before deeper hardness develops.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'True Repentance Begins with Encountering God’s Heart',
          body:
              'One of the most powerful truths in this verse is that God’s goodness leads '
              'people to repentance. Transformation is not produced merely through fear or '
              'religious pressure—it flows from encountering the love, mercy, and holiness '
              'of God personally.\n\n'
              'Repentance is more than feeling guilty; it is a turning of the heart back '
              'toward God. When believers truly encounter His kindness, the desire for sin '
              'begins losing its attraction because intimacy with God becomes more valuable '
              'than temporary compromise.\n\n'
              'As First Epistle of John 1:9 teaches, God remains faithful to forgive and '
              'cleanse those who confess and return to Him sincerely. His mercy creates the '
              'pathway for restoration rather than condemnation.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'A Soft Heart Remains Teachable Before God',
          body:
              'Romans 2:4 ultimately challenges believers to remain spiritually responsive '
              'to God’s voice. A soft heart welcomes conviction, correction, and transformation '
              'because it desires continual closeness with God more than self-justification.\n\n'
              'The Holy Spirit gently reveals attitudes, motives, and behaviors that need '
              'refinement. Spiritual maturity grows where the believer remains humble and '
              'teachable rather than defensive or resistant. God’s correction is always '
              'motivated by love and the desire to draw His people deeper into truth and '
              'freedom.\n\n'
              'The believer who continually responds to God’s goodness with humility '
              'experiences ongoing renewal and deeper intimacy with Him over time.',
        ),
      ],
      finalRevelation:
          'God’s kindness is not meant to be ignored—it is meant to awaken the '
          'heart and draw it back to Him.',
      reflectionQuestions: const [
        'Have I mistaken God’s patience for permission to remain unchanged?',
        'What areas of my heart need deeper repentance and surrender?',
        'Am I responding to God’s goodness with humility or resistance?',
      ],
      prayer: 'Lord,\n'
          'Thank You for Your goodness, patience, and mercy toward me. Forgive me '
          'for the times I have ignored Your conviction, resisted Your correction, '
          'or taken Your grace lightly.\n\n'
          'Help me to remain sensitive to Your voice and responsive to Your leading. '
          'Remove every hardness, pride, and self-justification within my heart. '
          'Teach me to see repentance not as shame, but as the pathway back into '
          'deeper intimacy with You.\n\n'
          'Let Your kindness continually transform my thoughts, desires, and actions. '
          'Draw me closer to Your heart and help me to walk in humility, obedience, '
          'and spiritual sincerity daily.\n\n'
          'May my life never become hardened toward Your truth, and may Your goodness '
          'continually lead me deeper into transformation.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 26),
    ),
    // ── 27. GUIDANCE ────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'guided_steps',
      theme: 'Guidance',
      title: 'Guided by the Steps of God',
      scripture:
          'The steps of a good man are ordered by the Lord, and He delights in his way.',
      scriptureReference: 'Psalms 37:23',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God Is Personally Involved in the Direction of Our Lives',
          body:
              'Psalm 37:23 reveals that God is not distant from the daily lives of '
              'His people. He actively orders, guides, and directs the steps of those '
              'who seek Him. This means life is not meant to be lived independently '
              'from divine wisdom and leadership. God desires involvement not only in '
              'major decisions but also in the ordinary paths believers walk daily.\n\n'
              'Many people view God only as someone involved during crises or major '
              'spiritual moments, yet Scripture reveals a God who cares deeply about '
              'every detail of the believer’s journey. His guidance is not random or '
              'careless. He sees the beginning and the end simultaneously and leads '
              'with wisdom beyond human understanding.\n\n'
              'The soul finds peace when it realizes life does not rest entirely upon '
              'human ability to figure everything out alone. God remains actively '
              'involved in directing those who trust Him.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Divine Direction Requires Surrendered Dependence',
          body:
              'For steps to be ordered by God, the heart must become willing to follow '
              'His leading. Human nature often prefers control, personal plans, and '
              'visible certainty, but God’s guidance frequently requires trust beyond '
              'immediate understanding. Divine direction becomes clearer where surrender grows deeper.\n\n'
              'Many frustrations arise when people seek God’s blessing without truly '
              'desiring His leadership. Yet spiritual direction flows from relationship, '
              'obedience, and continual dependence upon Him. As Book of Proverbs 3:5–6 '
              'teaches, believers are called to trust in the Lord rather than lean entirely '
              'upon their own understanding.\n\n'
              'Surrender does not weaken the believer—it positions them beneath God’s '
              'wisdom and protection. The more the heart trusts Him, the more sensitive '
              'it becomes to His direction.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'God’s Guidance Does Not Eliminate Difficult Seasons',
          body:
              'Psalm 37:23 does not imply that every path ordered by God will always '
              'feel easy or comfortable. Sometimes God leads believers through seasons '
              'of waiting, testing, uncertainty, or refinement. Divine direction includes '
              'both green pastures and difficult valleys because God’s ultimate goal is '
              'not merely comfort, but spiritual maturity and deeper dependence upon Him.\n\n'
              'The enemy often tries to convince believers that hardship means they are '
              'outside God’s will. Yet throughout Scripture, many faithful people walked '
              'difficult paths while remaining under God’s guidance. Joseph endured '
              'betrayal, David experienced wilderness seasons, and Paul faced suffering '
              'while fulfilling divine purpose.\n\n'
              'As Book of Isaiah 55:8–9 reminds believers, God’s thoughts and ways are '
              'higher than human understanding. What feels confusing temporarily may '
              'later reveal deeper wisdom and purpose.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God Delights in the Life Surrendered to Him',
          body:
              'One of the most beautiful parts of this verse is the statement that God '
              '“delights in his way.” This reveals the relational heart of God. He does '
              'not guide His people reluctantly or mechanically—He delights in those who '
              'walk with Him sincerely.\n\n'
              'God takes pleasure in hearts that seek Him, trust Him, and desire '
              'alignment with His will. Even imperfect believers who genuinely pursue '
              'Him remain precious in His sight. His delight is not based upon flawless '
              'performance but upon relationship, surrender, and faith.\n\n'
              'As Book of Zephaniah 3:17 reveals, God rejoices over His people with '
              'gladness and love. Understanding this changes how believers view their '
              'relationship with Him. The Christian life becomes more than duty—it '
              'becomes fellowship with a loving Father.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Ordered Steps Produce Long-Term Stability',
          body:
              'A life directed by God develops a deeper kind of stability over time. '
              'This does not mean the absence of challenges, but it means the believer '
              'is no longer wandering aimlessly through life without spiritual direction. '
              'God’s leadership protects, corrects, redirects, and sustains His people '
              'along the journey.\n\n'
              'Often, believers understand God’s guidance more clearly in hindsight than '
              'in the moment itself. Looking back reveals how He closed certain doors, '
              'redirected paths, protected from unseen dangers, and led through seasons '
              'that eventually produced growth and maturity.\n\n'
              'The more believers walk with God consistently, the more confidence grows '
              'in His ability to guide future steps. Trust deepens through repeated '
              'encounters with His faithfulness.',
        ),
      ],
      finalRevelation:
          'A life surrendered to God will never be directionless, because the '
          'Lord Himself orders its steps.',
      reflectionQuestions: const [
        'Am I allowing God to truly direct the course of my life?',
        'Have I been resisting His guidance in certain areas?',
        'What would change if I trusted God more fully with my future?',
      ],
      prayer: 'Lord,\n'
          'Thank You for caring about every step of my life. Help me to trust Your '
          'direction even when I cannot fully understand where You are leading me.\n\n'
          'Teach me to surrender my plans, fears, and personal understanding into '
          'Your hands daily. Remove pride, impatience, and every desire to control '
          'my future apart from You. Strengthen my heart to follow Your leading with '
          'faith and obedience.\n\n'
          'Guide me through every season—whether easy or difficult—and help me remain '
          'sensitive to Your voice. Thank You for delighting in those who walk with You '
          'sincerely and for remaining faithful through every step of the journey.\n\n'
          'May my life remain aligned with Your will, and may every step I take be '
          'ordered by Your wisdom and grace.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 27),
    ),
    // ── 28. POWER ───────────────────────────────────────────────────────────
    DevotionalModel(
      id: 'power_belongs_to_god',
      theme: 'Power',
      title: 'Power Belongs to God Alone',
      scripture:
          'God has spoken once, twice I have heard this: that power belongs to God.',
      scriptureReference: 'Psalm 62:11',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'True Power Has a Single Source',
          body:
              'David declares a profound truth: “power belongs to God.” This is not '
              'shared, borrowed, or rivaled—true authority originates from God alone. '
              'Everything that appears powerful in this world is ultimately limited '
              'and dependent.\n\n'
              'Scripture consistently affirms this reality. Daniel 2:21 reveals that '
              'God removes kings and raises others up, and 1 Chronicles 29:11 proclaims '
              'that greatness, power, and glory all belong to Him.\n\n'
              'When we misunderstand the source of power, we may place confidence in '
              'people, systems, or resources. But when we recognize God as the ultimate '
              'authority, our trust is redirected to the only unshakable foundation.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'What God Speaks Carries Final Authority',
          body:
              'David says, “God has spoken once, twice I have heard this,” emphasizing '
              'certainty and repetition. What God speaks is not uncertain or temporary—it '
              'is established and unchanging.\n\n'
              'Isaiah 55:11 declares that God’s word will not return void but will '
              'accomplish what He pleases. Likewise, Numbers 23:19 reminds us that God '
              'does not lie or change His mind.\n\n'
              'This means His declarations about power are not symbolic—they are absolute. '
              'What God has spoken about His authority over creation, history, and our '
              'lives stands firm regardless of circumstances.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Human Strength Is Limited and Temporary',
          body:
              'In contrast to God’s power, human strength is fragile and finite. '
              'Achievements, influence, and control can shift quickly. Psalm 146:3 warns '
              'against putting trust in princes or human beings, who cannot save.\n\n'
              'It is easy to rely on visible strength—financial stability, influence, '
              'intelligence, or connections. Yet all of these are temporary and can fail. '
              'Isaiah 40:29–31 reminds us that even the strong grow weary, but those who '
              'trust in the Lord renew their strength.\n\n'
              'Recognizing human limitation is not discouraging—it is clarifying. It '
              'leads the heart away from false security and toward dependence on God’s '
              'enduring power.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Power Is Both Sovereign and Personal',
          body:
              'God’s power is not only vast—it is also personal. The same power that '
              'governs the universe is at work in the lives of those who trust Him.\n\n'
              'Ephesians 1:19–20 speaks of the “exceeding greatness of His power toward '
              'us who believe,” the same power that raised Christ from the dead. This '
              'means God’s strength is not distant—it is active and available.\n\n'
              'His power sustains, strengthens, protects, and transforms. It meets us in '
              'weakness, as 2 Corinthians 12:9 declares: “My grace is sufficient for you, '
              'for My strength is made perfect in weakness.”',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Trusting God’s Power Produces Rest',
          body:
              'Psalm 62 as a whole emphasizes rest in God. When the heart truly believes '
              'that power belongs to Him, striving begins to fade.\n\n'
              'There is no need to carry what only God can handle. No need to control '
              'what is beyond human ability. Trust replaces anxiety because the outcome '
              'is no longer dependent on limited human strength.\n\n'
              'As Psalm 62:1 affirms, “Truly my soul silently waits for God; from Him '
              'comes my salvation.” Rest grows when confidence in God’s power becomes '
              'deeper than fear of circumstances.',
        ),
      ],
      finalRevelation:
          'Peace begins when the heart releases trust in human strength and '
          'rests fully in the power of God.',
      reflectionQuestions: const [
        'Where have I been placing my trust—in human strength or in God’s power?',
        'Do I truly believe that God’s authority is greater than my current situation?',
        'What would change if I fully rested in the truth that power belongs to God?',
      ],
      prayer: 'Lord,\n'
          'Thank You for revealing that all power belongs to You (Psalm 62:11). '
          'Help me to truly understand this, not just in knowledge but in the way '
          'I live and trust You daily.\n\n'
          'Forgive me for the times I have relied on my own strength or placed '
          'confidence in things that cannot sustain me. Teach me to depend fully '
          'on Your power (Isaiah 40:31).\n\n'
          'Remind me that Your word is unchanging and Your authority is absolute '
          '(Numbers 23:19). Strengthen my heart to trust You in every situation, '
          'knowing that nothing is beyond Your control.\n\n'
          'Let Your power sustain me in weakness, guide me in uncertainty, and '
          'bring peace to my heart as I rest in You.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 28),
    ),
    // ── 29. POSSIBILITY ─────────────────────────────────────────────────────
    DevotionalModel(
      id: 'nothing_too_hard',
      theme: 'Faith',
      title: 'Nothing Is Too Hard for God',
      scripture:
          'Behold, I am the Lord, the God of all flesh. Is there anything too hard for Me?',
      scriptureReference: 'Jeremiah 32:27',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading: 'God’s Power Has No Limitation',
          body:
              'Jeremiah 32:27 is one of the clearest declarations of God’s limitless '
              'power. God identifies Himself as “the God of all flesh,” revealing His '
              'absolute authority over creation, humanity, circumstances, and every '
              'impossible situation. Human strength is limited by knowledge, resources, '
              'and time, but God is not confined by any earthly limitation.\n\n'
              'Many situations appear impossible because they exceed human ability and '
              'understanding. Yet impossibility exists only within human perspective, '
              'not within God’s power. What overwhelms people does not overwhelm Him. '
              'The One who created heaven and earth remains fully capable of intervening '
              'in every situation according to His wisdom and purpose.\n\n'
              'Faith begins to grow when the heart stops measuring problems against '
              'human ability and starts measuring them against the greatness of God.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Fear Often Comes from Forgetting Who God Is',
          body:
              'God’s question, “Is there anything too hard for Me?” exposes how easily '
              'fear can dominate the human mind. Anxiety often grows when circumstances '
              'appear larger than God in the believer’s perspective. The heart begins '
              'focusing more on obstacles, delays, and visible limitations than on God’s '
              'sovereignty and power.\n\n'
              'Throughout Scripture, God continually reminded His people of who He is '
              'because spiritual confidence is connected to revelation. When believers '
              'lose sight of God’s greatness, discouragement and fear begin taking root '
              'internally. But when the mind becomes filled again with the truth of His '
              'power and faithfulness, faith is strengthened.\n\n'
              'As Gospel of Luke 1:37 declares, nothing will be impossible with God. '
              'Divine possibility still exists where human hope appears exhausted.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'Impossible Seasons Often Become Places of Deep Faith',
          body:
              'God frequently allows believers to encounter situations beyond their '
              'personal ability because dependence on Him grows strongest there. Human '
              'nature naturally prefers control and certainty, but impossible seasons '
              'expose how deeply the heart truly trusts God.\n\n'
              'The enemy often uses difficult situations to produce hopelessness, doubt, '
              'and spiritual exhaustion. Yet God uses those same seasons to reveal His '
              'sustaining power and deepen faith within His people. What appears impossible '
              'externally often becomes the place where spiritual maturity develops internally.\n\n'
              'Throughout Scripture, many miracles occurred only after human ability reached '
              'its limit. Abraham and Sarah faced barrenness, Moses stood before the Red Sea, '
              'and Lazarus lay in the tomb. Again and again, God revealed His power where '
              'human strength could go no further.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God’s Timing and Methods Are Higher Than Human Understanding',
          body:
              'Sometimes believers struggle not because they doubt God’s power, but because '
              'they do not understand His timing. Delays can create confusion and frustration '
              'when prayers seem unanswered or circumstances remain unchanged. Yet God’s '
              'ways are often deeper and more purposeful than human understanding can '
              'immediately perceive.\n\n'
              'Jeremiah himself received this revelation during a national crisis when '
              'destruction surrounded Jerusalem. Even in chaos, God reminded him that divine '
              'purpose was still unfolding beyond what could presently be seen. As Book of '
              'Isaiah 55:8–9 teaches, God’s thoughts and ways are higher than human '
              'thoughts and ways.\n\n'
              'Trust grows when believers learn to rely not only on God’s power, but also '
              'on His wisdom. God sees the full picture while humanity sees only fragments.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Faith Moves the Heart from Despair to Expectation',
          body:
              'Jeremiah 32:27 invites believers to move from hopelessness into expectation. '
              'Faith does not ignore reality, but it refuses to conclude that God is '
              'powerless within difficult situations. Even when circumstances remain uncertain, '
              'faith continues believing that God is able to intervene, sustain, restore, '
              'and make a way.\n\n'
              'The believer who truly understands God’s greatness develops deeper spiritual '
              'resilience. Prayer becomes bolder, trust becomes steadier, and fear loses '
              'some of its control over the heart. Confidence grows not because every '
              'answer is visible immediately, but because God remains faithful and sovereign.\n\n'
              'As dependence on God deepens, the soul begins resting more fully in the '
              'certainty that nothing is beyond His authority or ability.',
        ),
      ],
      finalRevelation: 'What appears impossible to human strength\n'
          'remains fully possible within the power of God.',
      reflectionQuestions: const [
        'What situation in my life have I quietly labeled impossible?',
        'Have fear and discouragement caused me to forget God’s power?',
        'What would change if I truly believed nothing is too hard for God?',
      ],
      prayer: 'Lord,\n'
          'Help me to remember that You are the God of all flesh and that nothing '
          'is too difficult for You. Forgive me for the times fear, doubt, and '
          'discouragement have caused me to focus more on problems than on Your power.\n\n'
          'Strengthen my faith in seasons where circumstances feel impossible or '
          'overwhelming. Teach me to trust Your wisdom, timing, and sovereignty '
          'even when I cannot fully understand what You are doing.\n\n'
          'Remove hopelessness from my heart and fill me with renewed confidence '
          'in Your ability to sustain, restore, and make a way where none seems '
          'possible. Let my life remain anchored in the truth that Your power has '
          'no limitation.\n\n'
          'May my faith continue growing through every impossible season, and may '
          'my heart remain confident in the greatness of who You are.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 29),
    ),
    // ── 30. PERSEVERANCE ────────────────────────────────────────────────────
    DevotionalModel(
      id: 'do_not_grow_weary',
      theme: 'Perseverance',
      title: 'Do Not Grow Weary in Doing Good',
      scripture:
          'And let us not grow weary while doing good, for in due season we shall reap if we do not lose heart.',
      scriptureReference: 'Galatians 6:9',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Faithfulness Often Requires Endurance Before Results Appear',
          body:
              'Galatians 6:9 acknowledges a reality many believers experience: doing '
              'good can become exhausting when visible results seem delayed. Serving '
              'faithfully, praying consistently, loving people sincerely, and obeying '
              'God wholeheartedly can sometimes feel discouraging when immediate fruit '
              'is not seen. Yet Scripture reminds believers that spiritual faithfulness '
              'is never wasted.\n\n'
              'God often works beneath the surface long before visible manifestation '
              'appears. Seeds planted in obedience require time before harvest comes. '
              'Human nature desires immediate results, but spiritual growth and divine '
              'purpose frequently unfold gradually. The believer must learn that delay '
              'does not mean absence of progress.\n\n'
              'Faithfulness is tested most deeply in seasons where perseverance becomes '
              'necessary. The soul grows stronger when it continues obeying God even '
              'without immediate visible reward.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading: 'Weariness Can Affect the Heart Spiritually',
          body:
              'Paul specifically warns believers not to “grow weary.” Weariness is more '
              'than physical exhaustion—it can become spiritual discouragement within '
              'the heart. Repeated disappointment, unanswered prayers, difficult seasons, '
              'and emotional strain can slowly weaken motivation, hope, and spiritual passion.\n\n'
              'The enemy often attacks weary believers through discouragement and '
              'hopelessness. He attempts to convince them that their labor is pointless '
              'or that God has forgotten their sacrifices. Yet weariness becomes '
              'dangerous when it causes the heart to lose confidence in God’s faithfulness.\n\n'
              'As Book of Isaiah 40:31 teaches, those who wait upon the Lord receive '
              'renewed strength. Spiritual renewal comes when believers return continually '
              'to God as their source of endurance and encouragement.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading: 'The Enemy Wants Believers to Quit Prematurely',
          body:
              'One of the enemy’s greatest strategies is convincing believers to stop '
              'before breakthrough, growth, or harvest arrives. Many people abandon '
              'prayer, obedience, service, or spiritual discipline because discouragement '
              'blinds them from seeing that God is still working beyond what is visible.\n\n'
              'The phrase “if we do not lose heart” reveals that perseverance matters '
              'spiritually. Battles are often won not merely through intensity, but '
              'through consistency. The enemy understands that a believer who continues '
              'trusting God through difficulty becomes spiritually stronger over time.\n\n'
              'Throughout Scripture, many breakthroughs came after long seasons of '
              'endurance. Noah continued building before rain appeared, Joseph endured '
              'years before restoration came, and David waited before becoming king. '
              'God honors perseverance that remains rooted in faith.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading: 'God’s Timing Governs the Harvest',
          body:
              'Paul promises that believers “shall reap” in due season. This reveals '
              'that spiritual harvest operates according to divine timing rather than '
              'human impatience. God sees what is being cultivated internally and '
              'externally even when results remain hidden temporarily.\n\n'
              'Many people become discouraged because they expect harvest immediately '
              'after sowing. Yet every seed requires time, process, and unseen '
              'development before fruit appears. God often uses waiting seasons to '
              'mature character, deepen trust, and prepare the believer for what is ahead.\n\n'
              'As Epistle of James 5:7 encourages believers to be patient like a farmer '
              'waiting for precious fruit, spiritual maturity learns to trust God’s '
              'process without becoming consumed by frustration or comparison.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading: 'Perseverance Produces Spiritual Maturity',
          body:
              'Continual faithfulness through difficulty develops endurance, stability, '
              'and deeper dependence upon God. Perseverance shapes character because '
              'it teaches the believer to remain anchored even when emotions fluctuate '
              'and circumstances become difficult.\n\n'
              'A mature believer is not someone who never struggles, but someone who '
              'continues walking with God through struggle. Perseverance strengthens '
              'faith because it repeatedly proves God’s sustaining grace through '
              'difficult seasons.\n\n'
              'Over time, the believer who refuses to give up develops deeper confidence '
              'in God’s faithfulness. What once felt impossible becomes testimony, and '
              'seasons of endurance eventually reveal the fruit God was producing all along.',
        ),
      ],
      finalRevelation: 'The harvest often grows invisibly\n'
          'before it becomes visible.',
      reflectionQuestions: const [
        'Have discouragement or delays caused me to grow weary recently?',
        'Am I tempted to quit in areas where God is calling me to persevere?',
        'What would change if I trusted God’s timing more deeply?',
      ],
      prayer: 'Lord,\n'
          'Strengthen me when weariness, discouragement, and frustration begin '
          'overwhelming my heart. Help me not to lose hope or abandon the good '
          'work You have called me to continue faithfully.\n\n'
          'Teach me to trust Your timing even when results seem delayed or invisible. '
          'Renew my strength where emotional exhaustion and disappointment have '
          'weakened my faith. Remind me that no act of obedience, prayer, love, '
          'or faithfulness is ever wasted before You.\n\n'
          'Help me to persevere with patience and confidence, knowing that You are '
          'working beyond what I can presently see. Let my heart remain steadfast '
          'through every difficult season and anchored in the certainty of Your '
          'faithfulness.\n\n'
          'May I continue sowing faithfully without losing heart, and may my life '
          'eventually reveal the harvest You have prepared in due season.\n\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 30),
    ),


    // ── 31. GUIDANCE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'hearing_voice',
      theme: 'Guidance',
      title: 'Hearing the Voice That Leads',
      scripture:
          'Your ears shall hear a word behind you, saying, ‘This is the way,\n'
          'walk in it,’ whenever you turn to the right hand or whenever you turn\n'
          'to the left.',
      scriptureReference: 'Isaiah 30:21',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'God Desires to Lead His People Personally',
          body:
              'Isaiah 30:21 reveals a deeply personal aspect of God’s relationship\n'
              'with His people: He desires to guide them continually. God is not\n'
              'distant or uninterested in the direction of our lives. He speaks,\n'
              'leads, corrects, and directs those who are willing to walk closely\n'
              'with Him.\n'
              '\n'
              'Many people search desperately for direction while overlooking the\n'
              'importance of relationship with the One who gives direction. God’s\n'
              'guidance flows most clearly where intimacy, surrender, and spiritual\n'
              'attentiveness are growing. He does not merely give commands from\n'
              'afar—He walks with His people and leads them step by step.\n'
              '\n'
              'The believer was never designed to navigate life independently from\n'
              'God’s wisdom. Divine guidance becomes one of the greatest expressions\n'
              'of His care and faithfulness.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'The Noise of Life Can Drown Out God’s Voice',
          body:
              'The phrase “your ears shall hear” reveals that spiritual hearing\n'
              'requires attentiveness. One of the greatest challenges believers face\n'
              'is not necessarily that God is silent, but that the heart is often\n'
              'distracted by fear, pressure, emotions, opinions, and worldly noise.\n'
              '\n'
              'A restless and crowded mind struggles to discern spiritual direction\n'
              'clearly. Constant distraction weakens sensitivity to God’s leading.\n'
              'This is why stillness, prayer, meditation on Scripture, and time in\n'
              'God’s presence remain spiritually essential.\n'
              '\n'
              'As Book of Psalms 46:10 teaches, stillness helps the soul recognize\n'
              'God more clearly. Spiritual clarity grows where the heart learns to\n'
              'quiet competing voices and remain attentive before Him.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'God’s Guidance Often Protects Us from Wrong Paths',
          body:
              'Isaiah 30:21 speaks about turning “to the right hand” or “to the\n'
              'left,” revealing that God’s guidance often functions as protection and\n'
              'correction. Human understanding is limited, and emotions can easily\n'
              'pull people toward decisions rooted in fear, pride, impatience, or\n'
              'worldly influence.\n'
              '\n'
              'The enemy often attempts to distort judgment through confusion,\n'
              'deception, and impulsive thinking. Without God’s guidance, people can\n'
              'drift gradually away from His will while believing they are moving in\n'
              'the right direction.\n'
              '\n'
              'Yet God faithfully warns, redirects, and corrects those who remain\n'
              'sensitive to Him. As Book of Proverbs 14:12 reminds believers, there\n'
              'are ways that seem right to humanity but ultimately lead to\n'
              'destruction. Divine guidance protects the soul from unnecessary harm\n'
              'and wandering.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God’s Direction Requires Trust and Obedience',
          body:
              'Hearing God’s direction is only part of the journey; obedience must\n'
              'follow revelation. Sometimes God’s leading may not fully align with\n'
              'personal preference, visible logic, or immediate comfort. Faith\n'
              'becomes necessary when the path ahead is not completely clear.\n'
              '\n'
              'Many believers desire clarity while resisting surrender. Yet\n'
              'spiritual direction becomes more consistent where obedience becomes\n'
              'more willing. God often reveals the next step progressively rather\n'
              'than showing the entire journey at once because dependence deepens\n'
              'through continual trust.\n'
              '\n'
              'As Book of Proverbs 3:5–6 teaches, believers are called to trust the\n'
              'Lord rather than lean entirely upon their own understanding. Obedience\n'
              'positions the heart beneath God’s wisdom and care.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Walking with God Produces Confidence and Peace',
          body:
              'When believers learn to follow God’s leading consistently, greater\n'
              'peace and confidence begin developing internally. Life may still\n'
              'contain uncertainty, but the soul becomes steadier because trust rests\n'
              'in the One who sees beyond human limitation.\n'
              '\n'
              'God’s guidance does not guarantee an easy path, but it does guarantee\n'
              'His presence along the path. The believer who walks closely with Him\n'
              'becomes less controlled by fear because confidence grows through\n'
              'repeated experiences of His faithfulness and direction.\n'
              '\n'
              'Over time, spiritual sensitivity deepens. What once felt confusing\n'
              'becomes clearer as the believer learns to recognize God’s voice\n'
              'through Scripture, conviction, wisdom, peace, and the leading of the\n'
              'Holy Spirit.',
        ),
      ],
      finalRevelation:
          'God’s guidance is not merely about finding the right path—it is about\n'
          'walking closely with the One who leads.',
      reflectionQuestions: const [
        'Have distractions and worries been weakening my ability to hear God\n'
        'clearly?',
        'Am I fully willing to obey God’s direction even when it challenges my\n'
        'comfort?',
        'What areas of my life currently need clearer guidance from God?',
      ],
      prayer:
          'Lord,\n'
          'Teach me to recognize and follow Your voice above every competing\n'
          'distraction around me. Quiet every fear, confusion, and anxious\n'
          'thought that prevents me from hearing Your guidance clearly.\n'
          '\n'
          'Help me to remain spiritually attentive through prayer, stillness,\n'
          'and continual meditation on Your Word. Strengthen me to trust Your\n'
          'direction even when I cannot fully see the path ahead.\n'
          '\n'
          'Correct me gently when I begin drifting toward wrong paths, and keep\n'
          'my heart sensitive to Your leading daily. Let obedience become natural\n'
          'within me as my relationship with You grows deeper.\n'
          '\n'
          'May my life remain guided by Your wisdom, and may my heart walk\n'
          'confidently in the path You have prepared for me.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 1, 31),
    ),

    // ── 32. FOCUS ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'knowing_christ',
      theme: 'Focus',
      title: 'Knowing Christ Beyond Knowledge',
      scripture:
          'That I may know Him and the power of His resurrection, and the\n'
          'fellowship of His sufferings, being conformed to His death.',
      scriptureReference: 'Philippians 3:10',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'The Greatest Pursuit of Life Is to Know Christ Personally',
          body:
              'When Paul wrote Philippians 3:10, he had already experienced\n'
              'remarkable spiritual encounters, planted churches, and received\n'
              'profound revelations. Yet his deepest desire remained unchanged: “That\n'
              'I may know Him.” This reveals that Christianity is not primarily about\n'
              'acquiring information about God but developing an intimate\n'
              'relationship with Christ Himself.\n'
              '\n'
              'Many believers spend years learning biblical facts while neglecting\n'
              'personal fellowship with Jesus. Knowledge has value, but true\n'
              'transformation comes from knowing Christ personally through prayer,\n'
              'worship, obedience, and daily communion. Eternal life itself is\n'
              'defined by this relationship, as Jesus declares in Gospel of John\n'
              '17:3, that knowing God is the essence of eternal life.\n'
              '\n'
              'The closer a believer walks with Christ, the more His character,\n'
              'priorities, and heart become reflected in their own life.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Resurrection Power Is Available for Daily Living',
          body:
              'Paul desired not only to know Christ but also “the power of His\n'
              'resurrection.” Resurrection power is more than the miracle that raised\n'
              'Jesus from the dead; it is the divine power that transforms lives,\n'
              'breaks spiritual bondage, strengthens weak hearts, and enables\n'
              'believers to live victoriously.\n'
              '\n'
              'Many believers acknowledge God\'s power intellectually while living as\n'
              'though they are powerless against fear, temptation, discouragement, or\n'
              'difficult circumstances. Yet the same power that raised Christ from\n'
              'the grave is available to those who belong to Him. As Epistle to the\n'
              'Ephesians 1:19–20 reveals, God\'s immeasurable power is at work within\n'
              'believers today.\n'
              '\n'
              'Resurrection power gives strength to overcome what human effort alone\n'
              'cannot conquer. It empowers believers to live beyond their natural\n'
              'limitations.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Spiritual Growth Often Develops Through Suffering',
          body:
              'Paul also speaks of “the fellowship of His sufferings,” a phrase that\n'
              'many would naturally avoid. Yet Paul understood that suffering can\n'
              'become a place of deeper intimacy with Christ. Trials, losses,\n'
              'disappointments, and seasons of testing often teach lessons that\n'
              'comfort and success cannot.\n'
              '\n'
              'The enemy seeks to use suffering to create bitterness,\n'
              'discouragement, and distance from God. But God often uses suffering to\n'
              'produce humility, dependence, perseverance, and spiritual maturity. As\n'
              'Epistle of James 1:2–4 teaches, trials develop endurance and\n'
              'strengthen faith when surrendered to God.\n'
              '\n'
              'Suffering does not automatically draw people closer to God, but\n'
              'surrendered suffering often becomes one of the greatest classrooms of\n'
              'spiritual growth.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Transformation Requires Dying to Self',
          body:
              'Paul speaks of being “conformed to His death,” revealing that\n'
              'following Christ involves more than receiving blessings—it involves\n'
              'surrender. The cross was not only an event Jesus experienced; it also\n'
              'became a pattern for the believer’s life. Pride, self-centeredness,\n'
              'worldly ambitions, and fleshly desires must continually be surrendered\n'
              'to God\'s will.\n'
              '\n'
              'Human nature naturally resists this process because it prefers\n'
              'control and self-preservation. Yet spiritual maturity grows where\n'
              'self-rule decreases and Christ’s rule increases. As Epistle to the\n'
              'Galatians 2:20 declares, believers are crucified with Christ so that\n'
              'His life may be revealed through them.\n'
              '\n'
              'Every act of surrender creates more room for Christ’s character to be\n'
              'formed within the heart.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Knowing Christ Is a Lifelong Journey',
          body:
              'Paul’s words reveal that knowing Christ is not a destination reached\n'
              'once and completed. It is a continual pursuit that deepens throughout\n'
              'life. No matter how much a believer grows spiritually, there is always\n'
              'more of Christ’s wisdom, love, power, and presence to discover.\n'
              '\n'
              'This journey requires humility because it acknowledges that spiritual\n'
              'growth is ongoing. The believer who remains hungry for God continues\n'
              'growing, learning, and being transformed. Intimacy with Christ is not\n'
              'built through occasional encounters but through daily faithfulness and\n'
              'continual pursuit.\n'
              '\n'
              'As believers seek Him consistently, they begin experiencing deeper\n'
              'levels of His presence, greater spiritual maturity, and a stronger\n'
              'reflection of His nature in everyday life.',
        ),
      ],
      finalRevelation:
          'The highest goal of the Christian life is not merely to receive from\n'
          'Christ, but to know Him deeply.',
      reflectionQuestions: const [
        'Do I desire Christ Himself more than the blessings He provides?',
        'Am I allowing God to use both victories and struggles to deepen my\n'
        'relationship with Him?',
        'What areas of my life still need greater surrender to Christ?',
      ],
      prayer:
          'Lord,\n'
          'Create within me a deeper desire to know You beyond knowledge,\n'
          'religion, or routine. Let my greatest pursuit be intimacy with Christ\n'
          'and not merely the blessings that come from following Him.\n'
          '\n'
          'Help me to experience the power of Your resurrection in every area of\n'
          'my life. Strengthen me to overcome fear, discouragement, temptation,\n'
          'and every obstacle through Your divine power working within me.\n'
          '\n'
          'Teach me to trust You during seasons of suffering and to allow every\n'
          'trial to draw me closer to Your heart. Help me surrender pride,\n'
          'self-will, and every area where I resist Your transforming work.\n'
          '\n'
          'May my life continually reflect the character of Christ, and may my\n'
          'relationship with You grow deeper each day until knowing You becomes\n'
          'the greatest joy of my heart.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 1),
    ),

    // ── 33. RENEWAL ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'god_works_in_you',
      theme: 'Renewal',
      title: 'The God Who Works Within Us',
      scripture:
          'For it is God who works in you both to will and to do for His good\n'
          'pleasure.',
      scriptureReference: 'Philippians 2:13',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Spiritual Transformation Begins with God’s Work Within',
          body:
              'Philippians 2:13 reveals a profound truth: the Christian life is not\n'
              'sustained merely by human effort. God Himself is actively working\n'
              'within every believer. While many people focus on outward actions, God\n'
              'begins His work inwardly, shaping desires, attitudes, motives, and\n'
              'character before those changes become visible externally.\n'
              '\n'
              'This means that spiritual growth is not simply self-improvement. It\n'
              'is the result of divine activity within the heart. The same God who\n'
              'calls believers to live according to His will also provides the inner\n'
              'strength necessary to do so. Transformation becomes possible because\n'
              'God is already at work beneath the surface.\n'
              '\n'
              'The believer can find encouragement knowing that growth is not\n'
              'dependent solely upon personal ability. God is continually working\n'
              'even when progress feels slow or invisible.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'God Changes Our Desires Before He Changes Our Actions',
          body:
              'Paul says that God works in us “to will,” meaning He influences our\n'
              'desires and inclinations. Before God changes behavior, He often begins\n'
              'by transforming what the heart loves, values, and pursues. This is one\n'
              'of the clearest evidences of spiritual growth: desires gradually\n'
              'become aligned with God\'s heart.\n'
              '\n'
              'Many believers become discouraged when they notice areas of weakness,\n'
              'yet the very desire to seek God, obey Him, and grow spiritually is\n'
              'evidence of His work within them. Left to itself, the human heart\n'
              'naturally drifts toward self-centeredness. But God\'s Spirit creates\n'
              'new desires that draw believers toward righteousness and intimacy with\n'
              'Him.\n'
              '\n'
              'As Book of Ezekiel 36:26 teaches, God gives His people a new heart\n'
              'and a new spirit. Divine transformation begins at the level of desire\n'
              'before it manifests through action.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'God Provides the Power to Obey What He Commands',
          body:
              'Philippians 2:13 does not stop with desire; it also says God works in\n'
              'believers “to do.” God not only inspires the willingness to obey but\n'
              'also supplies the strength necessary to carry it out. Many believers\n'
              'feel overwhelmed by their weaknesses, forgetting that God\'s power is\n'
              'available to enable obedience.\n'
              '\n'
              'The enemy often whispers that change is impossible, that old habits\n'
              'cannot be broken, or that spiritual victory is beyond reach. But God\'s\n'
              'power accomplishes what human effort alone cannot achieve. His grace\n'
              'strengthens believers to walk in obedience, overcome temptation, and\n'
              'persevere through challenges.\n'
              '\n'
              'As Second Epistle to the Corinthians 12:9 declares, God\'s grace is\n'
              'sufficient and His strength is perfected in weakness. Where human\n'
              'strength ends, divine empowerment begins.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God’s Work Is Motivated by His Good Pleasure',
          body:
              'This verse reveals that God works in believers “for His good\n'
              'pleasure.” God is not reluctantly involved in our growth; He delights\n'
              'in transforming His children into the image of Christ. Spiritual\n'
              'growth is not merely beneficial for believers—it brings pleasure to\n'
              'God because it reflects His purpose and character.\n'
              '\n'
              'Many people view God as constantly disappointed or distant. Yet\n'
              'Scripture reveals a Father who lovingly works within His people\n'
              'because He delights in seeing them grow spiritually. His correction,\n'
              'guidance, and refining work flow from love rather than rejection.\n'
              '\n'
              'As Book of Zephaniah 3:17 teaches, God rejoices over His people with\n'
              'gladness. Understanding His heart changes how believers view the\n'
              'process of growth and sanctification.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Cooperation with God Produces Lasting Growth',
          body:
              'Although God is the One working within believers, He invites them to\n'
              'cooperate with His work. Spiritual maturity develops when believers\n'
              'respond to His leading through obedience, prayer, surrender, and\n'
              'continual dependence upon Him. Growth accelerates where the heart\n'
              'becomes willing and responsive.\n'
              '\n'
              'God will not force intimacy, obedience, or spiritual maturity upon\n'
              'anyone. He works within, but believers must continually yield to His\n'
              'guidance. Every act of surrender allows His transforming work to flow\n'
              'more deeply into the heart and life.\n'
              '\n'
              'Over time, the believer begins noticing changes that once seemed\n'
              'impossible. Old patterns lose their power, spiritual desires grow\n'
              'stronger, and Christ’s character becomes increasingly visible through\n'
              'daily life.',
        ),
      ],
      finalRevelation:
          'God never asks believers to transform themselves alone— He provides\n'
          'both the desire and the power for transformation.',
      reflectionQuestions: const [
        'Can I recognize areas where God has been changing my desires\n'
        'recently?',
        'Am I relying more on my own strength or on God\'s power to grow\n'
        'spiritually?',
        'What area of my life is God currently inviting me to surrender more\n'
        'fully?',
      ],
      prayer:
          'Lord,\n'
          'Thank You for continually working within me even when I do not always\n'
          'see it. Help me to recognize Your transforming hand in my heart and to\n'
          'trust that You are shaping me according to Your purpose.\n'
          '\n'
          'Create within me desires that honor You and remove anything that\n'
          'competes with Your will. Strengthen me where I feel weak and empower\n'
          'me to obey You faithfully through the power of Your Spirit.\n'
          '\n'
          'Teach me to cooperate with Your work through surrender, humility, and\n'
          'dependence upon You. Let my life increasingly reflect the character of\n'
          'Christ as You continue transforming me from the inside out.\n'
          '\n'
          'May I never rely solely on my own strength, but rest in the\n'
          'confidence that You are faithfully working within me every day.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 2),
    ),

    // ── 34. PRESENCE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'sealed_by_spirit',
      theme: 'Presence',
      title: 'Sealed by the Holy Spirit',
      scripture:
          'In Him you also trusted, after you heard the word of truth, the\n'
          'gospel of your salvation; in whom also, having believed, you were\n'
          'sealed with the Holy Spirit of promise.',
      scriptureReference: 'Ephesians 1:13',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Salvation Begins with Hearing and Believing the Truth',
          body:
              'Ephesians 1:13 reveals a beautiful progression in God\'s plan of\n'
              'salvation. First, people hear the Word of truth—the Gospel of Jesus\n'
              'Christ. Then they respond in faith by believing. Salvation is not\n'
              'achieved through human effort, religious rituals, or personal\n'
              'goodness; it comes through trusting in Christ and His finished work on\n'
              'the cross.\n'
              '\n'
              'Faith begins when the heart receives God\'s truth. Many voices compete\n'
              'for attention in the world, but only the Gospel has the power to bring\n'
              'eternal life. As Epistle to the Romans 10:17 teaches, faith comes by\n'
              'hearing the Word of God. Every genuine spiritual journey begins when\n'
              'truth enters the heart and produces faith.\n'
              '\n'
              'The believer\'s confidence rests not in personal performance but in\n'
              'the saving work of Christ. Salvation is received by faith before it is\n'
              'expressed through transformed living.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'The Holy Spirit Is God\'s Mark of Ownership',
          body:
              'Paul says that believers are "sealed with the Holy Spirit of\n'
              'promise." In biblical times, a seal was used to signify ownership,\n'
              'authenticity, authority, and protection. When God places His Spirit\n'
              'within a believer, He is declaring that person belongs to Him.\n'
              '\n'
              'This truth brings tremendous security. The believer is not merely\n'
              'associated with God but is marked as His own possession. The Holy\n'
              'Spirit becomes God\'s divine signature upon the life of every true\n'
              'believer. As Second Epistle to Timothy 2:19 declares, "The Lord knows\n'
              'those who are His."\n'
              '\n'
              'The world may define identity through achievements, status, or\n'
              'possessions, but the believer\'s highest identity is that they belong\n'
              'to God. The Spirit\'s seal confirms this eternal relationship.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'The Holy Spirit Protects and Preserves the Believer',
          body:
              'A seal was also used to secure something valuable from tampering or\n'
              'interference. Spiritually, this points to God\'s preserving work in the\n'
              'life of His people. Though believers face temptations, trials, and\n'
              'spiritual warfare, God\'s Spirit remains within them as a continual\n'
              'witness of His saving grace.\n'
              '\n'
              'The enemy constantly seeks to create fear, doubt, and insecurity\n'
              'regarding one\'s relationship with God. Yet Ephesians 1:13 reminds\n'
              'believers that their salvation rests upon God\'s faithfulness, not\n'
              'merely their feelings. The Spirit continually testifies that they are\n'
              'children of God.\n'
              '\n'
              'As Epistle to the Romans 8:16 teaches, the Spirit bears witness with\n'
              'our spirit that we belong to God. His presence provides assurance even\n'
              'during seasons of weakness and uncertainty.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'The Holy Spirit Continually Works Within Us',
          body:
              'Being sealed by the Spirit is not merely a past event—it is an\n'
              'ongoing relationship. The Holy Spirit actively teaches, convicts,\n'
              'comforts, guides, empowers, and transforms believers throughout their\n'
              'spiritual journey. God\'s work did not end at salvation; it continues\n'
              'daily through the ministry of His Spirit.\n'
              '\n'
              'Many believers focus on what God has done for them while overlooking\n'
              'what He is doing within them. The Spirit continually shapes character,\n'
              'renews the mind, and produces spiritual fruit. As Epistle to the\n'
              'Galatians 5:22–23 reveals, the Spirit develops qualities such as love,\n'
              'joy, peace, patience, and self-control within the believer.\n'
              '\n'
              'Spiritual maturity grows as believers learn to yield to the Holy\n'
              'Spirit\'s leading rather than resisting His work.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'The Seal of the Spirit Points to an Eternal Future',
          body:
              'The Holy Spirit is called the "Spirit of promise" because His\n'
              'presence guarantees the fulfillment of God\'s promises. The believer\'s\n'
              'future is not uncertain or accidental. The Spirit serves as a divine\n'
              'assurance that what God has begun, He will complete.\n'
              '\n'
              'Life often contains uncertainty, suffering, and unanswered questions.\n'
              'Yet the presence of the Holy Spirit reminds believers that their\n'
              'ultimate destiny is secure in Christ. God\'s promises extend beyond\n'
              'this present life into eternity. As Epistle to the Philippians 1:6\n'
              'teaches, He who began a good work will carry it to completion.\n'
              '\n'
              'The Spirit\'s presence is both a present comfort and a future\n'
              'guarantee. Every day He reminds believers that they belong to God now\n'
              'and forever.',
        ),
      ],
      finalRevelation:
          'The Holy Spirit is not merely a gift from God—He is God\'s seal,\n'
          'confirming that you belong to Him and securing your eternal\n'
          'inheritance.',
      reflectionQuestions: const [
        'Do I truly understand my identity as someone who belongs to God?',
        'Am I allowing the Holy Spirit to guide and transform my daily life?',
        'How would my confidence change if I fully embraced the security of\n'
        'being sealed by God\'s Spirit?',
      ],
      prayer:
          'Lord,\n'
          'Thank You for the gift of salvation through Jesus Christ and for\n'
          'sealing me with Your Holy Spirit. Help me to live with the confidence\n'
          'that I belong to You and that my identity is secure in Your love and\n'
          'grace.\n'
          '\n'
          'Teach me to become more sensitive to the leading of Your Spirit. Let\n'
          'Him guide my thoughts, shape my character, and strengthen my faith\n'
          'daily. Help me not to resist His work but to surrender fully to His\n'
          'transforming presence.\n'
          '\n'
          'When fear, doubt, or insecurity arise, remind me that I have been\n'
          'marked as Your own. Strengthen my assurance that You are preserving me\n'
          'and faithfully completing the work You began in my life.\n'
          '\n'
          'May the presence of Your Spirit continually draw me closer to You,\n'
          'and may my life reflect the reality that I am sealed, secured, and\n'
          'forever Yours.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 3),
    ),

    // ── 35. TRUST ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'god_goes_before',
      theme: 'Trust',
      title: 'The God Who Goes Before You',
      scripture:
          'Thus says the Lord to His anointed, to Cyrus, whose right hand I have\n'
          'held—To subdue nations before him and loose the armor of kings, to\n'
          'open before him the double doors, so that the gates will not be shut:\n'
          '‘I will go before you and make the crooked places straight; I will\n'
          'break in pieces the gates of bronze and cut the bars of iron. I will\n'
          'give you the treasures of darkness and hidden riches of secret places,\n'
          'that you may know that I, the Lord, who call you by your name, am the\n'
          'God of Israel.',
      scriptureReference: 'Isaiah 45:1–3',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'God Goes Ahead of Those He Has Called',
          body:
              'One of the most comforting truths in Isaiah 45:1–3 is God\'s promise:\n'
              '“I will go before you.” Before Cyrus faced obstacles, battles, or\n'
              'responsibilities, God had already gone ahead of him. This reveals that\n'
              'God does not merely send His people into assignments; He precedes\n'
              'them. He prepares what they cannot see and arranges circumstances\n'
              'beyond their control.\n'
              '\n'
              'Many believers become anxious about the future because they focus on\n'
              'the unknown. Yet God is already present in tomorrow before we arrive\n'
              'there. The path may seem uncertain to us, but it is fully visible to\n'
              'Him. The God who calls also prepares the way for the fulfillment of\n'
              'His purpose.\n'
              '\n'
              'Faith grows when we realize we are not trying to find our way alone.\n'
              'We are following a God who has already gone before us.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'God Has the Power to Open What No One Can Shut',
          body:
              'God promised to open doors before Cyrus and ensure that gates would\n'
              'not remain closed. Throughout Scripture, doors often represent\n'
              'opportunities, favor, access, and divine advancement. What God\n'
              'determines to open cannot ultimately be stopped by human opposition,\n'
              'limitations, or circumstances.\n'
              '\n'
              'Many people spend their lives trying to force doors open through\n'
              'their own strength. Yet divine favor accomplishes what human striving\n'
              'cannot. When God opens a door, resistance may still exist, but His\n'
              'purpose cannot be permanently hindered. As Book of Revelation 3:8\n'
              'declares, God sets before His people open doors that no one can shut.\n'
              '\n'
              'The believer\'s confidence should rest not in personal influence but\n'
              'in God\'s sovereign ability to create opportunities beyond human\n'
              'ability.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'God Breaks Through Obstacles That Seem Impossible',
          body:
              'The Lord promised to break gates of bronze and cut through bars of\n'
              'iron. These images symbolize strong resistance, impossible barriers,\n'
              'and obstacles that appear immovable. What seemed secure and\n'
              'unbreakable before human strength was no challenge to God.\n'
              '\n'
              'Many believers face barriers that appear permanent—spiritual\n'
              'strongholds, delayed promises, closed opportunities, financial\n'
              'difficulties, or seemingly impossible situations. Yet Isaiah 45\n'
              'reminds us that God\'s power exceeds every obstacle. What appears\n'
              'impossible to man remains entirely possible with God.\n'
              '\n'
              'As Book of Jeremiah 32:27 declares, nothing is too hard for the Lord.\n'
              'Obstacles may be real, but they are never greater than the God who\n'
              'stands above them.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Hidden Blessings Often Exist in Unexpected Places',
          body:
              'God promised to give Cyrus “the treasures of darkness and hidden\n'
              'riches of secret places.” This does not refer merely to material\n'
              'wealth but also to blessings, wisdom, opportunities, and provisions\n'
              'hidden beyond present visibility. God often places valuable lessons\n'
              'and blessings in places people would least expect to find them.\n'
              '\n'
              'Many believers focus only on what they can presently see and become\n'
              'discouraged by difficult seasons. Yet some of God\'s greatest treasures\n'
              'are discovered during seasons of waiting, hardship, and uncertainty.\n'
              'Trials often reveal deeper faith, greater dependence on God, and\n'
              'spiritual riches that comfort could never produce.\n'
              '\n'
              'What appears to be a dark season may contain hidden provisions that\n'
              'God intends to reveal in His perfect timing.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'God\'s Ultimate Goal Is That We Know Him More Deeply',
          body:
              'The passage concludes with God\'s declaration that these things would\n'
              'happen “that you may know that I am the Lord.” More important than the\n'
              'open doors, broken barriers, or hidden treasures was the revelation of\n'
              'God\'s identity. God\'s greatest purpose is not merely to bless His\n'
              'people but to bring them into deeper knowledge of Himself.\n'
              '\n'
              'Too often believers become focused on the breakthrough and forget the\n'
              'One who provides it. Yet every answered prayer, every divine\n'
              'provision, and every victory is ultimately intended to reveal God\'s\n'
              'faithfulness and draw the heart closer to Him. Blessings are\n'
              'wonderful, but knowing God remains the highest treasure.\n'
              '\n'
              'As believers walk through life, they discover that God\'s greatest\n'
              'gift is not simply what He gives—it is His presence, His character,\n'
              'and His relationship with them.',
        ),
      ],
      finalRevelation:
          'God does not simply remove obstacles— He goes before you, opens\n'
          'doors, breaks barriers, and reveals Himself through the journey.',
      reflectionQuestions: const [
        'What obstacle in my life seems impossible for me but possible for\n'
        'God?',
        'Am I trusting God to go before me, or am I trying to force my own\n'
        'way?',
        'What hidden treasures might God be developing in my current season?',
      ],
      prayer:
          'Lord,\n'
          'Thank You for being the God who goes before me. When I face\n'
          'uncertainty, remind me that You have already prepared the way and that\n'
          'nothing catches You by surprise.\n'
          '\n'
          'Help me trust Your ability to open doors that no one can shut and to\n'
          'break through barriers that seem impossible. Strengthen my faith when\n'
          'circumstances appear discouraging or when progress feels delayed.\n'
          '\n'
          'Teach me to recognize the hidden treasures You are developing within\n'
          'my life, even during difficult seasons. Let every challenge become an\n'
          'opportunity to know You more deeply and experience Your faithfulness\n'
          'more fully.\n'
          '\n'
          'May I walk confidently knowing that You are leading, preparing, and\n'
          'providing ahead of me, and may my greatest desire always be to know\n'
          'You more intimately.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 4),
    ),

    // ── 36. FOCUS ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'battle_of_mind',
      theme: 'Focus',
      title: 'Winning the Battle of the Mind',
      scripture:
          'Casting down arguments and every high thing that exalts itself\n'
          'against the knowledge of God, bringing every thought into captivity to\n'
          'the obedience of Christ.',
      scriptureReference: '2 Corinthians 10:5',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'The Greatest Battles Are Often Fought Within the Mind',
          body:
              'Before battles manifest in behavior, relationships, or circumstances,\n'
              'they often begin within the mind. Thoughts shape beliefs, beliefs\n'
              'influence decisions, and decisions ultimately determine the direction\n'
              'of life. This is why Paul emphasizes bringing thoughts into captivity.\n'
              'The mind is one of the primary battlegrounds where spiritual victories\n'
              'and defeats are first experienced.\n'
              '\n'
              'The enemy understands the power of thoughts and frequently attacks\n'
              'through fear, doubt, discouragement, lies, and distorted perspectives.\n'
              'If a thought remains unchallenged long enough, it can become a belief,\n'
              'and beliefs eventually shape actions. This is why believers must learn\n'
              'to guard their minds carefully and evaluate every thought according to\n'
              'God\'s truth.\n'
              '\n'
              'As Book of Proverbs 23:7 teaches, a person becomes what they\n'
              'continually think. Victory begins when the mind is surrendered to\n'
              'God\'s truth.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Not Every Thought Deserves Agreement',
          body:
              'Paul speaks about casting down arguments and everything that exalts\n'
              'itself against the knowledge of God. This reveals that not every\n'
              'thought entering the mind should be accepted as truth. Some thoughts\n'
              'originate from fear, past wounds, cultural influences, or spiritual\n'
              'opposition rather than from God.\n'
              '\n'
              'Many people struggle because they automatically believe every thought\n'
              'they think. Yet spiritual maturity involves learning to examine\n'
              'thoughts before agreeing with them. A thought may feel convincing\n'
              'while still being contrary to God\'s Word. Truth is not determined by\n'
              'emotion or repetition but by alignment with what God has spoken.\n'
              '\n'
              'As Gospel of John 8:32 declares, truth brings freedom. The more\n'
              'believers align their thinking with God\'s truth, the less influence\n'
              'deception gains over their lives.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Strongholds Are Built Through Repeated Agreement',
          body:
              'The arguments Paul describes are not merely isolated thoughts; they\n'
              'can become strongholds when repeatedly embraced. A stronghold develops\n'
              'when a lie is believed long enough to establish itself as a pattern of\n'
              'thinking. Fear, insecurity, bitterness, pride, and unbelief often\n'
              'begin as thoughts before becoming entrenched mindsets.\n'
              '\n'
              'The enemy seeks to establish strongholds because he knows that wrong\n'
              'thinking eventually produces wrong living. However, God has given\n'
              'believers spiritual weapons capable of tearing down these mental\n'
              'fortresses. Through Scripture, prayer, the Holy Spirit, and obedience,\n'
              'every stronghold can be confronted and dismantled.\n'
              '\n'
              'As Epistle to the Romans 12:2 teaches, transformation occurs through\n'
              'the renewing of the mind. Lasting change begins when truth replaces\n'
              'deception.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Captive Thoughts Lead to a Renewed Life',
          body:
              'Paul calls believers to bring every thought into obedience to Christ.\n'
              'This does not mean suppressing thoughts but submitting them to God\'s\n'
              'authority. The believer learns to ask whether a thought reflects God\'s\n'
              'character, promises, and truth before allowing it to shape attitudes\n'
              'or actions.\n'
              '\n'
              'A renewed mind gradually becomes more peaceful, discerning, and\n'
              'spiritually stable. Fear loses influence when faith governs thinking.\n'
              'Bitterness weakens when forgiveness shapes perspective. Anxiety\n'
              'decreases when trust becomes stronger than uncertainty. The quality of\n'
              'life often changes when the quality of thinking changes.\n'
              '\n'
              'God desires to transform believers from the inside out. As His truth\n'
              'fills the mind, His character becomes increasingly reflected in\n'
              'everyday life.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Mental Freedom Comes Through Daily Surrender',
          body:
              'Winning the battle of the mind is not a one-time event but a daily\n'
              'process. Every day presents new opportunities either to entertain\n'
              'destructive thoughts or surrender them to Christ. Spiritual freedom\n'
              'grows through continual dependence upon God rather than occasional\n'
              'moments of discipline.\n'
              '\n'
              'The believer who consistently fills their mind with God\'s Word\n'
              'becomes stronger in discernment and less vulnerable to deception. Over\n'
              'time, the voice of truth becomes easier to recognize than the voice of\n'
              'fear. The mind that remains submitted to Christ experiences greater\n'
              'peace, stability, and spiritual confidence.\n'
              '\n'
              'As Epistle to the Philippians 4:8 encourages, believers should\n'
              'intentionally focus on things that are true, noble, just, pure,\n'
              'lovely, and praiseworthy. What fills the mind eventually shapes life.',
        ),
      ],
      finalRevelation:
          'The mind will always serve whatever it consistently agrees\n'
          'with—therefore, freedom begins when every thought is brought under the\n'
          'authority of Christ.',
      reflectionQuestions: const [
        'What thoughts have I been accepting without testing them against\n'
        'God\'s truth?',
        'Are there strongholds of fear, doubt, insecurity, or bitterness\n'
        'influencing my thinking?',
        'What would change if I intentionally surrendered every thought to\n'
        'Christ each day?',
      ],
      prayer:
          'Lord,\n'
          'Search my mind and reveal every thought that does not align with Your\n'
          'truth. Help me recognize the lies, fears, and arguments that seek to\n'
          'exalt themselves above the knowledge of who You are.\n'
          '\n'
          'Teach me to reject every thought that contradicts Your Word and to\n'
          'replace it with truth. Strengthen me to tear down strongholds that\n'
          'have developed through fear, doubt, pride, or unbelief. Renew my mind\n'
          'daily through the power of Your Spirit and the truth of Scripture.\n'
          '\n'
          'Help me bring every thought into obedience to Christ so that my\n'
          'thinking, decisions, and actions reflect Your will. Fill my mind with\n'
          'peace, wisdom, and spiritual discernment.\n'
          '\n'
          'May my thoughts be governed by Your truth, and may my life reveal the\n'
          'freedom that comes from a mind surrendered completely to You.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 5),
    ),

    // ── 37. SURRENDER ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'life_on_altar',
      theme: 'Surrender',
      title: 'A Life Placed on the Altar',
      scripture:
          'I beseech you therefore, brethren, by the mercies of God, that you\n'
          'present your bodies a living sacrifice, holy, acceptable to God, which\n'
          'is your reasonable service.',
      scriptureReference: 'Romans 12:1',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'God\'s Mercy Is the Foundation of Our Surrender',
          body:
              'Paul begins Romans 12:1 by appealing to believers "by the mercies of\n'
              'God." Before speaking about sacrifice, obedience, or service, he\n'
              'points to God\'s mercy. The Christian life is never built upon earning\n'
              'God\'s favor but upon responding to the mercy already received through\n'
              'Christ. Every act of surrender flows from gratitude for what God has\n'
              'done.\n'
              '\n'
              'When believers truly understand the depth of God\'s mercy, surrender\n'
              'becomes a response of love rather than obligation. The cross reveals a\n'
              'God who forgives, restores, and adopts sinners into His family. Such\n'
              'mercy demands more than casual appreciation—it calls for wholehearted\n'
              'devotion. The more deeply we understand His grace, the more willing we\n'
              'become to place our lives in His hands.\n'
              '\n'
              'A heart captivated by God\'s mercy does not ask, "How little can I\n'
              'give God?" but rather, "How much of myself can I offer to Him?"',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'God Desires the Whole Life, Not Just Occasional Acts of Worship',
          body:
              'Paul urges believers to present their bodies as a living sacrifice.\n'
              'Under the Old Covenant, sacrifices were placed on an altar and\n'
              'completely given to God. Unlike those sacrifices, however, believers\n'
              'are called to become living sacrifices—continually surrendered and\n'
              'available for God\'s purposes every day.\n'
              '\n'
              'True worship extends beyond church services, songs, or spiritual\n'
              'activities. Worship includes how we think, speak, work, serve, and\n'
              'live. Every area of life becomes an offering to God. As First Epistle\n'
              'to the Corinthians 6:19–20 teaches, believers belong to God because\n'
              'they were purchased at a great price.\n'
              '\n'
              'God is not seeking occasional expressions of devotion while other\n'
              'parts of life remain untouched. He desires complete ownership of the\n'
              'heart, mind, body, and will.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Living Sacrifices Must Continually Choose Surrender',
          body:
              'One challenge of being a living sacrifice is that living sacrifices\n'
              'can climb off the altar. Every day presents opportunities to either\n'
              'yield to God\'s will or return to self-rule. The battle between\n'
              'self-centered living and God-centered living continues throughout the\n'
              'believer\'s journey.\n'
              '\n'
              'The flesh naturally desires control, comfort, recognition, and\n'
              'independence. Yet spiritual maturity develops as believers repeatedly\n'
              'surrender their desires to God\'s greater purpose. Jesus demonstrated\n'
              'this perfectly when He prayed in Gospel of Luke 22:42, "Not My will,\n'
              'but Yours, be done."\n'
              '\n'
              'Surrender is not a one-time decision but a daily posture. Each act of\n'
              'obedience strengthens the believer\'s commitment to remain on God\'s\n'
              'altar.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Holiness Is the Result of Belonging to God',
          body:
              'Paul describes the sacrifice as holy and acceptable to God. Holiness\n'
              'is not merely avoiding sin; it is being set apart for God\'s purposes.\n'
              'When believers surrender themselves to God, He begins transforming\n'
              'them into people who increasingly reflect His character and values.\n'
              '\n'
              'The world constantly pressures believers to conform to its patterns,\n'
              'but God calls His people to live differently. Holiness becomes the\n'
              'visible evidence of a life dedicated to Him. As First Epistle of Peter\n'
              '1:15–16 teaches, believers are called to be holy because God Himself\n'
              'is holy.\n'
              '\n'
              'Holiness is not achieved through human striving alone. It grows as\n'
              'believers remain surrendered to the transforming work of God\'s Spirit.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Surrender Is the Most Reasonable Response to God\'s Grace',
          body:
              'Paul concludes by describing this offering as our "reasonable\n'
              'service." In light of God\'s mercy, salvation, forgiveness, and eternal\n'
              'promises, wholehearted surrender is not extreme—it is reasonable. When\n'
              'we consider all that Christ has done, giving Him our lives becomes the\n'
              'most logical and appropriate response.\n'
              '\n'
              'Many people fear surrender because they view it as loss. Yet biblical\n'
              'surrender leads to greater freedom, purpose, and fulfillment. What is\n'
              'surrendered to God is never wasted. The believer discovers that God\'s\n'
              'plans are higher, wiser, and more rewarding than anything self-will\n'
              'could produce.\n'
              '\n'
              'The life fully yielded to God becomes a testimony of His grace,\n'
              'power, and transforming love in the world.',
        ),
      ],
      finalRevelation:
          'The altar is not a place where life is lost— it is a place where life\n'
          'is transformed by the mercy of God.',
      reflectionQuestions: const [
        'Have I truly surrendered every area of my life to God, or only\n'
        'selected parts?',
        'What areas of self-will am I still holding onto?',
        'How can I present myself more fully to God as a living sacrifice\n'
        'today?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for the abundance of Your mercy that has rescued, forgiven,\n'
          'and restored me through Jesus Christ. Help me never to take Your grace\n'
          'lightly or forget the price that was paid for my salvation.\n'
          '\n'
          'Teach me to present my life to You completely as a living sacrifice.\n'
          'Take every area that I have withheld from Your control and help me\n'
          'surrender it willingly. Remove pride, self-centeredness, and every\n'
          'desire that competes with Your will.\n'
          '\n'
          'Shape me into a vessel that is holy, useful, and pleasing in Your\n'
          'sight. Let my thoughts, words, actions, and decisions become acts of\n'
          'worship that honor You. Strengthen me to remain faithful on the altar\n'
          'even when surrender feels difficult.\n'
          '\n'
          'May my life continually reflect gratitude for Your mercy, and may\n'
          'everything I am belong completely to You.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 6),
    ),

    // ── 38. TRUST ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'gods_plans',
      theme: 'Trust',
      title: 'God\'s Plans Are Greater Than Your Present Circumstances',
      scripture:
          'For I know the thoughts that I think toward you, says the Lord,\n'
          'thoughts of peace and not of evil, to give you a future and a hope.',
      scriptureReference: 'Jeremiah 29:11',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'God\'s Plans Are Rooted in His Perfect Knowledge',
          body:
              'One of the most comforting truths in Jeremiah 29:11 is that God says,\n'
              '"I know." While people often face uncertainty about the future, God\n'
              'never does. He possesses complete knowledge of every detail, every\n'
              'challenge, every delay, and every opportunity that lies ahead. Nothing\n'
              'about your life is hidden from Him or catches Him by surprise.\n'
              '\n'
              'When circumstances become confusing, believers can find peace in\n'
              'knowing that God\'s plans are not based on guesswork. He sees the end\n'
              'from the beginning and understands what is necessary to accomplish His\n'
              'purpose. What appears chaotic to us is often part of a larger design\n'
              'that God is carefully orchestrating according to His wisdom.\n'
              '\n'
              'The believer\'s confidence rests not in understanding every detail of\n'
              'the journey, but in trusting the God who already knows the\n'
              'destination.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'God\'s Thoughts Toward You Are Filled with Peace',
          body:
              'God declares that His thoughts toward His people are thoughts of\n'
              'peace and not of evil. This does not mean life will be free from\n'
              'difficulties, but it reveals God\'s heart and intentions. His desire is\n'
              'not to harm, destroy, or abandon His children. Even when He allows\n'
              'seasons of discipline, waiting, or testing, His ultimate purpose\n'
              'remains rooted in love and restoration.\n'
              '\n'
              'Many believers wrongly assume that difficult circumstances are\n'
              'evidence of God\'s displeasure. Yet Jeremiah 29:11 was spoken to people\n'
              'living in exile, a season of hardship and uncertainty. Even there, God\n'
              'assured them that His heart toward them remained good. His plans\n'
              'extended beyond their present pain and pointed toward future\n'
              'restoration.\n'
              '\n'
              'As Epistle to the Romans 8:28 teaches, God works all things together\n'
              'for good for those who love Him and are called according to His\n'
              'purpose.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Present Circumstances Do Not Define Your Future',
          body:
              'The people who first received this promise were living in Babylonian\n'
              'captivity. Their current situation seemed hopeless, yet God reminded\n'
              'them that their present reality was not their final destination. What\n'
              'they could see did not fully reflect what God was doing behind the\n'
              'scenes.\n'
              '\n'
              'The enemy often attempts to convince believers that current struggles\n'
              'will last forever. Disappointment, failure, delays, and setbacks can\n'
              'create the illusion that God\'s promises have been forgotten. Yet God\'s\n'
              'plans are not limited by present circumstances. He specializes in\n'
              'bringing hope where despair exists and restoration where loss has\n'
              'occurred.\n'
              '\n'
              'Throughout Scripture, God repeatedly transformed impossible\n'
              'situations into testimonies of His faithfulness. What seems permanent\n'
              'today may only be a chapter in the story God is writing.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God\'s Timing Is Part of His Plan',
          body:
              'Jeremiah 29:11 was given alongside a promise that restoration would\n'
              'come after a season of waiting. This reminds believers that God\'s\n'
              'plans often unfold according to His timing rather than human\n'
              'expectations. Waiting can be difficult because it requires faith when\n'
              'visible progress appears slow.\n'
              '\n'
              'Yet God uses waiting seasons to develop trust, maturity, character,\n'
              'and dependence upon Him. What feels like delay is often preparation.\n'
              'As Book of Isaiah 40:31 teaches, those who wait upon the Lord renew\n'
              'their strength because waiting draws them closer to God\'s presence and\n'
              'purpose.\n'
              '\n'
              'Faith learns to trust not only God\'s promises but also His timing.\n'
              'The God who makes promises is also wise enough to determine when and\n'
              'how they should be fulfilled.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Hope Is Anchored in God\'s Faithfulness',
          body:
              'Jeremiah 29:11 ends with a promise of a future and a hope. Biblical\n'
              'hope is not wishful thinking; it is a confident expectation based upon\n'
              'God\'s faithfulness. Hope remains alive because it is anchored in the\n'
              'character of God rather than the uncertainty of circumstances.\n'
              '\n'
              'When believers place their hope in temporary situations,\n'
              'disappointment often follows. But when hope is rooted in God, it\n'
              'remains steady even during storms. His faithfulness in the past\n'
              'becomes evidence of His faithfulness in the future. Every fulfilled\n'
              'promise throughout Scripture points to a God who always keeps His\n'
              'word.\n'
              '\n'
              'The believer who trusts God\'s heart can face uncertainty with\n'
              'confidence, knowing that God\'s plans are still unfolding even when\n'
              'they cannot yet be fully seen.',
        ),
      ],
      finalRevelation:
          'Your future is not being shaped by your circumstances— it is being\n'
          'shaped by the God who holds your future.',
      reflectionQuestions: const [
        'Am I allowing present circumstances to define my expectations for the\n'
        'future?',
        'Do I truly believe that God\'s thoughts toward me are good and filled\n'
        'with peace?',
        'What area of my life requires greater trust in God\'s timing and plan?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for knowing every detail of my life and for holding my\n'
          'future securely in Your hands. When uncertainty, fear, or\n'
          'disappointment try to overwhelm me, help me remember that Your plans\n'
          'are greater than my present circumstances.\n'
          '\n'
          'Teach me to trust Your heart even when I cannot fully understand Your\n'
          'ways. Help me believe that Your thoughts toward me are filled with\n'
          'peace, hope, and purpose. Strengthen my faith during seasons of\n'
          'waiting and remind me that delays do not mean abandonment.\n'
          '\n'
          'Guard me from discouragement and help me fix my eyes on Your promises\n'
          'rather than my problems. Let hope rise within me as I remember Your\n'
          'faithfulness and goodness.\n'
          '\n'
          'May I walk confidently into each day knowing that You are working all\n'
          'things according to Your perfect plan, and that the future You hold is\n'
          'filled with the hope found only in You.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 7),
    ),


    // ── 39. TRUST ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'stability',
      theme: 'Trust',
      title: 'The Stability Found in God',
      scripture:
          'Wisdom and knowledge will be the stability of your times, and the\n'
          'strength of salvation; the fear of the Lord is His treasure.',
      scriptureReference: 'Isaiah 33:6',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'True Stability Comes from God, Not Circumstances',
          body:
              'Isaiah 33:6 was spoken during a time of uncertainty, conflict, and\n'
              'national instability. Yet God revealed that the stability of His\n'
              'people would not come from political power, financial security, or\n'
              'favorable circumstances. Their stability would come from wisdom and\n'
              'knowledge rooted in Him. This truth remains relevant today because the\n'
              'world is constantly changing, but God remains unchanging.\n'
              'Many people seek security in things that can easily be shaken.\n'
              'Careers change, economies fluctuate, relationships can disappoint, and\n'
              'human strength has limitations. However, the believer who builds life\n'
              'upon God\'s truth possesses an anchor that remains firm through every\n'
              'storm. As Jesus taught in 7:24–25, the house built upon the rock\n'
              'remains standing when the winds and floods come.\n'
              'Lasting stability is not found in controlling circumstances but in\n'
              'trusting the God who controls all things.',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Wisdom Is More Valuable Than Information',
          body:
              'The verse highlights wisdom before knowledge. Knowledge is the\n'
              'accumulation of facts, but wisdom is the God-given ability to apply\n'
              'truth correctly. Many people possess information yet still make\n'
              'destructive decisions because wisdom is absent. God desires His people\n'
              'not merely to know truth but to live according to it.\n'
              'Biblical wisdom begins with understanding life from God\'s\n'
              'perspective. It helps believers navigate challenges, relationships,\n'
              'opportunities, and decisions with discernment. As 9:10 teaches, the\n'
              'fear of the Lord is the beginning of wisdom. The closer believers walk\n'
              'with God, the clearer they see life\'s complexities through the lens of\n'
              'His truth.\n'
              'Wisdom protects the believer from unnecessary mistakes and provides\n'
              'direction when circumstances seem confusing.',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Knowledge of God Strengthens the Soul',
          body:
              'Isaiah speaks not merely of knowledge, but knowledge connected to\n'
              'God. There is a significant difference between knowing about God and\n'
              'truly knowing Him. A personal knowledge of God\'s character, promises,\n'
              'and faithfulness strengthens the heart during difficult seasons.\n'
              'When challenges arise, believers often draw strength from what they\n'
              'know about God. They remember His faithfulness in the past, His\n'
              'promises in Scripture, and His power to sustain them. As 11:32\n'
              'declares, those who know their God shall be strong and carry out great\n'
              'exploits.\n'
              'The deeper a believer\'s knowledge of God becomes, the less vulnerable\n'
              'they are to fear, confusion, and spiritual instability.',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Salvation Is More Than Rescue—It Is Daily Strength',
          body:
              'Isaiah describes salvation as strength. Many believers think of\n'
              'salvation only as forgiveness of sins and the promise of heaven, but\n'
              'God\'s salvation also provides present-day strength. Through Christ,\n'
              'believers receive grace to endure trials, overcome temptation, and\n'
              'walk faithfully through life\'s challenges.\n'
              'God\'s saving work affects every aspect of life. His presence\n'
              'strengthens weary hearts, restores hope, and provides courage when\n'
              'circumstances seem overwhelming. As 8:10 declares, the joy of the Lord\n'
              'becomes strength for His people.\n'
              'The believer\'s confidence is not rooted in personal ability but in\n'
              'the saving power and sustaining grace of God.',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'The Fear of the Lord Is Heaven\'s Greatest Treasure',
          body:
              'The verse concludes by declaring that the fear of the Lord is His\n'
              'treasure. Biblical fear is not terror but reverence, honor, awe, and\n'
              'deep respect for God. It is the recognition of His greatness,\n'
              'holiness, authority, and worthiness. A heart that fears God places Him\n'
              'above every other influence and priority.\n'
              'In a culture that often values independence and self-reliance, the\n'
              'fear of the Lord anchors believers in humility and obedience. It\n'
              'protects them from pride and keeps their hearts aligned with God\'s\n'
              'purposes. As 14:27 teaches, the fear of the Lord is a fountain of life\n'
              'that leads away from destruction.\n'
              'Those who treasure God above all else discover a stability that the\n'
              'world can never provide.',
        ),
      ],
      finalRevelation:
          'The most stable life is not the one with the fewest problems— it is\n'
          'the one rooted in the wisdom, knowledge, and fear of the Lord.',
      reflectionQuestions: const [
        'What am I currently depending on for stability besides God?',
        'Am I seeking God\'s wisdom or merely relying on my own understanding?',
        'How can I grow deeper in my knowledge of God and reverence for Him?',
      ],
      prayer:
          'Lord,\n'
          'Thank You for being my source of stability in an ever-changing world.\n'
          'When circumstances become uncertain and challenges arise, help me to\n'
          'remain anchored in Your wisdom, truth, and faithfulness.\n'
          'Teach me to seek Your wisdom above human understanding and to grow in\n'
          'the knowledge of who You are. Let my heart be strengthened by Your\n'
          'promises and sustained by Your saving grace. Guard me from placing my\n'
          'confidence in temporary things that cannot provide lasting security.\n'
          'Create within me a deeper fear of the Lord—a heart that honors,\n'
          'reveres, and treasures You above all else. Help me walk in humility,\n'
          'obedience, and dependence upon You every day.\n'
          'May my life remain firmly established in You, and may Your wisdom and\n'
          'knowledge become the stability of my times.\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 8),
    ),

    // ── 40. WARFARE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'invisible_battle',
      theme: 'Warfare',
      title: 'Understanding the Invisible Battle',
      scripture:
          'For we do not wrestle against flesh and blood, but against\n'
          'principalities, against powers, against the rulers of the darkness of\n'
          'this age, against spiritual hosts of wickedness in the heavenly\n'
          'places.',
      scriptureReference: 'Ephesians 6:12',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'The Greatest Battles Are Often Invisible',
          body:
              'Ephesians 6:12 reveals that many of life\'s deepest struggles cannot\n'
              'be understood merely through natural observation. While we encounter\n'
              'visible challenges in relationships, circumstances, workplaces, and\n'
              'society, Scripture teaches that there is also an unseen spiritual\n'
              'dimension influencing the world around us. Paul reminds believers that\n'
              'their true battle is not against flesh and blood but against spiritual\n'
              'forces that oppose God\'s purposes.\n'
              '\n'
              'Many believers become exhausted because they focus solely on visible\n'
              'problems while overlooking the spiritual realities behind them. The\n'
              'enemy desires to keep people distracted by outward conflicts so they\n'
              'fail to recognize the deeper battle. Spiritual awareness helps\n'
              'believers respond with wisdom, prayer, and faith rather than merely\n'
              'reacting emotionally to circumstances.\n'
              '\n'
              'Understanding the nature of the battle changes how we approach the\n'
              'challenges we face every day.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'People Are Not the Real Enemy',
          body:
              'One of the most important lessons from this passage is that human\n'
              'beings are not our ultimate enemies. Although people may hurt, oppose,\n'
              'misunderstand, or disappoint us, Scripture teaches that our primary\n'
              'conflict is spiritual rather than personal. The enemy often works\n'
              'through division, offense, hatred, and misunderstanding to damage\n'
              'relationships and hinder God\'s work.\n'
              '\n'
              'When believers forget this truth, they can become consumed with\n'
              'resentment, bitterness, and retaliation. However, spiritual maturity\n'
              'recognizes that while people may be involved in conflicts, they are\n'
              'not the ultimate source of the battle. As Jesus demonstrated on the\n'
              'cross in Gospel of Luke 23:34, believers are called to respond with\n'
              'grace, forgiveness, and prayer rather than hatred.\n'
              '\n'
              'Seeing people through God\'s perspective helps protect the heart from\n'
              'unnecessary bitterness and keeps the focus on spiritual victory rather\n'
              'than personal revenge.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Spiritual Warfare Requires Spiritual Weapons',
          body:
              'Because the battle is spiritual, human strength alone is insufficient\n'
              'to overcome it. Intelligence, talent, influence, and determination all\n'
              'have value, but they cannot replace the spiritual resources God\n'
              'provides. Prayer, faith, Scripture, righteousness, worship, and\n'
              'dependence upon the Holy Spirit are the weapons God has given His\n'
              'people.\n'
              '\n'
              'The enemy seeks to weaken believers by separating them from these\n'
              'spiritual resources. A neglected prayer life, lack of biblical truth,\n'
              'and spiritual complacency create vulnerability. Yet believers who\n'
              'remain rooted in God\'s Word and empowered by His Spirit become strong\n'
              'and effective in spiritual warfare.\n'
              '\n'
              'As Paul explains in Second Epistle to the Corinthians 10:4, the\n'
              'weapons of our warfare are not carnal but mighty through God for\n'
              'pulling down strongholds. Victory comes through God\'s power, not\n'
              'merely human effort.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Spiritual Discernment Protects the Believer',
          body:
              'Paul identifies various levels of spiritual opposition, emphasizing\n'
              'the need for discernment. Not every challenge is spiritual warfare,\n'
              'but believers must develop sensitivity to recognize when spiritual\n'
              'influences are at work. Discernment helps distinguish between God\'s\n'
              'voice, personal emotions, worldly influences, and the enemy\'s\n'
              'deception.\n'
              '\n'
              'Spiritual discernment grows through prayer, Scripture, obedience, and\n'
              'intimacy with God. The closer believers walk with Him, the more\n'
              'clearly they recognize truth and deception. As First Epistle of John\n'
              '4:1 teaches, believers should test spiritual influences rather than\n'
              'accepting everything without examination.\n'
              '\n'
              'Discernment acts as a safeguard, helping believers navigate life\'s\n'
              'challenges with wisdom and spiritual clarity.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Christ Has Already Secured the Ultimate Victory',
          body:
              'While Ephesians 6:12 describes a real spiritual battle, it does not\n'
              'leave believers in fear. The victory of Christ has already been\n'
              'established through His death and resurrection. The enemy may continue\n'
              'to oppose, deceive, and attack, but his final defeat has already been\n'
              'determined by God\'s power.\n'
              '\n'
              'Believers do not fight for victory; they fight from victory. Their\n'
              'confidence rests not in their own strength but in the finished work of\n'
              'Christ. As Epistle to the Colossians 2:15 reveals, Jesus disarmed\n'
              'spiritual powers and triumphed over them through the cross.\n'
              '\n'
              'This truth transforms the believer\'s perspective. Spiritual warfare\n'
              'is not approached with fear and panic but with faith, confidence, and\n'
              'dependence upon the victorious Lord.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'The greatest danger in spiritual warfare is not the strength of the\n'
          'enemy— it is forgetting the victory already secured through Christ.\n'
          '---',
      reflectionQuestions: const [
        'Am I viewing my struggles only through a natural perspective or also\n'
        'through a spiritual one?',
        'Have I been treating people as enemies rather than recognizing the\n'
        'deeper spiritual battle?',
        'Am I consistently using the spiritual resources God has provided for\n'
        'victory?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for revealing the reality of the spiritual battle and for\n'
          'not leaving me defenseless against the enemy\'s schemes. Help me to see\n'
          'beyond visible circumstances and recognize the spiritual realities\n'
          'that influence my life and surroundings.\n'
          '\n'
          'Guard my heart from bitterness, offense, and misplaced anger toward\n'
          'people. Teach me to respond with wisdom, grace, and discernment while\n'
          'remaining alert to the enemy\'s tactics. Strengthen my prayer life and\n'
          'deepen my dependence upon Your Word and Spirit.\n'
          '\n'
          'Equip me with every spiritual weapon necessary to stand firm in\n'
          'faith. Help me walk confidently in the victory that Jesus has already\n'
          'secured through His death and resurrection. Let fear be replaced with\n'
          'faith and confusion with spiritual clarity.\n'
          '\n'
          'May I remain strong in the Lord and in the power of His might,\n'
          'and may my life continually reflect the victory of Christ over every\n'
          'spiritual opposition.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 9),
    ),

    // ── 41. LOVE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'gods_attention',
      theme: 'Love',
      title: 'The Wonder of God\'s Attention',
      scripture:
          'When I consider Your heavens, the work of Your fingers, the moon and\n'
          'the stars, which You have ordained, What is man that You are mindful\n'
          'of him, and the son of man that You visit him?',
      scriptureReference: 'Psalms 8:3–4',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Creation Reveals the Greatness of God',
          body:
              'David begins by contemplating the heavens, the moon, and the stars.\n'
              'As he observes the vastness of creation, he becomes overwhelmed by the\n'
              'greatness of God. The universe displays God\'s wisdom, power,\n'
              'creativity, and authority. Every star in the sky silently proclaims\n'
              'that there is a Creator whose power is beyond human comprehension.\n'
              '\n'
              'In a world filled with distractions, believers often lose the sense\n'
              'of wonder that creation is meant to inspire. The more we recognize the\n'
              'majesty of God\'s works, the more we appreciate His greatness. As\n'
              'Epistle to the Romans 1:20 teaches, God\'s invisible attributes are\n'
              'clearly seen through the things He has made. Creation continually\n'
              'points humanity back to its Creator.\n'
              '\n'
              'When we behold God\'s greatness, our perspective changes. Problems\n'
              'become smaller, fears lose their grip, and faith grows stronger.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Humility Is the Proper Response to God\'s Majesty',
          body:
              'As David considers the vast universe, he asks, "What is man?" This is\n'
              'not a question of worthlessness but of humility. Compared to the\n'
              'magnitude of creation, humanity appears small and fragile. David\n'
              'recognizes that human achievements, power, and accomplishments are\n'
              'insignificant when measured against God\'s greatness.\n'
              '\n'
              'Modern culture often encourages self-exaltation, yet Scripture\n'
              'teaches that true wisdom begins with humility. The more clearly we see\n'
              'God, the more accurately we see ourselves. As Book of James 4:10\n'
              'teaches, those who humble themselves before the Lord will be lifted up\n'
              'by Him.\n'
              '\n'
              'Humility does not diminish a person\'s value; it positions the heart\n'
              'to receive God\'s grace and guidance.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'God\'s Attention Is a Demonstration of His Love',
          body:
              'Despite humanity\'s smallness, David is astonished that God is mindful\n'
              'of mankind. The Creator of galaxies, stars, and planets knows, sees,\n'
              'and cares for each individual person. This truth reveals the\n'
              'incredible nature of God\'s love. His attention is not limited by the\n'
              'size of the universe or the number of people on earth.\n'
              '\n'
              'Many believers struggle with feelings of insignificance or\n'
              'abandonment. Yet Psalm 8 reminds us that God has never lost sight of\n'
              'us. He knows our struggles, hears our prayers, and understands our\n'
              'needs. As Jesus declares in Gospel of Matthew 10:30, even the hairs of\n'
              'our heads are numbered before God.\n'
              '\n'
              'The God who governs the universe also cares deeply about the details\n'
              'of our lives.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God Not Only Notices Us—He Visits Us',
          body:
              'David goes beyond asking why God is mindful of humanity; he marvels\n'
              'that God "visits" mankind. Throughout Scripture, God\'s visitation\n'
              'represents His presence, involvement, and personal relationship with\n'
              'His people. God is not a distant Creator who merely observes from\n'
              'afar; He actively engages with those He loves.\n'
              '\n'
              'This truth reaches its highest expression in Jesus Christ. The\n'
              'eternal God entered human history, lived among humanity, and\n'
              'demonstrated His love through the cross. As Gospel of John 1:14\n'
              'reveals, the Word became flesh and dwelt among us. God\'s visitation\n'
              'proves that His desire is not merely to rule over humanity but to have\n'
              'fellowship with them.\n'
              '\n'
              'The believer\'s greatest privilege is not simply being noticed by God\n'
              'but walking daily in His presence.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Your Value Is Determined by God\'s Love, Not Human Opinion',
          body:
              'Psalm 8 teaches that human value is not determined by social status,\n'
              'achievements, wealth, or recognition. Humanity\'s worth comes from the\n'
              'fact that God created us, thinks about us, and cares for us. The\n'
              'attention of God gives dignity and purpose to every life.\n'
              '\n'
              'Many people spend years seeking validation from others, only to\n'
              'discover that human approval is temporary and unreliable. God\'s love,\n'
              'however, remains constant. As First Epistle of John 3:1 declares,\n'
              'believers are called children of God. This identity surpasses every\n'
              'earthly title and accomplishment.\n'
              '\n'
              'When believers understand how God sees them, they are freed from the\n'
              'need to constantly prove their worth before others.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'The greatest wonder is not that God created the stars— it is that the\n'
          'God who created the stars knows, loves, and cares for you personally.\n'
          '---',
      reflectionQuestions: const [
        'When was the last time I paused to reflect on God\'s greatness through\n'
        'creation?',
        'Do I view myself through God\'s love or through the opinions of\n'
        'others?',
        'How would my life change if I truly believed that God is mindful of\n'
        'me every day?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'When I consider the vastness of the heavens and the greatness of Your\n'
          'creation, I am humbled by Your power and majesty. Yet I am even more\n'
          'amazed that You know me, care for me, and remain mindful of every\n'
          'detail of my life.\n'
          '\n'
          'Help me to live with a deeper awareness of both Your greatness and\n'
          'Your love. Guard me from pride when I succeed and from discouragement\n'
          'when I feel insignificant. Remind me that my worth is not found in\n'
          'human approval but in the fact that I belong to You.\n'
          '\n'
          'Thank You for drawing near to me and for inviting me into a personal\n'
          'relationship with You through Jesus Christ. Let Your presence become\n'
          'my greatest comfort and Your love my deepest source of identity.\n'
          '\n'
          'May I walk each day in awe of Your majesty, and in confidence that\n'
          'the Creator of the universe is mindful of me.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 10),
    ),

    // ── 42. GRACE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'debt_cancelled',
      theme: 'Grace',
      title: 'The Debt That Was Cancelled',
      scripture:
          'And you, being dead in your trespasses and the uncircumcision of your\n'
          'flesh, He has made alive together with Him, having forgiven you all\n'
          'trespasses, having wiped out the handwriting of requirements that was\n'
          'against us, which was contrary to us. And He has taken it out of the\n'
          'way, having nailed it to the cross.',
      scriptureReference: 'Colossians 2:13–14',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Christ Brings Life to What Was Spiritually Dead',
          body:
              'Paul reminds believers of their condition before salvation: they were\n'
              'spiritually dead in their sins. Spiritual death is separation from\n'
              'God, the source of life. No amount of good works, religious effort, or\n'
              'human morality could bridge that separation. Humanity\'s greatest\n'
              'problem was not merely bad behavior but spiritual death.\n'
              '\n'
              'Yet the gospel is the story of divine intervention. God did not leave\n'
              'humanity in its helpless condition. Through Christ, He made us alive\n'
              'together with Him. The same power that raised Jesus from the dead now\n'
              'gives spiritual life to those who believe. As Epistle to the Ephesians\n'
              '2:4–5 declares, God, rich in mercy, made us alive with Christ even\n'
              'when we were dead in our trespasses.\n'
              '\n'
              'Salvation is not self-improvement; it is resurrection. God does not\n'
              'merely make bad people better—He makes dead people alive.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Forgiveness Is Complete, Not Partial',
          body:
              'Paul declares that God has forgiven "all trespasses." This single\n'
              'word, "all," reveals the magnitude of God\'s grace. Through Christ,\n'
              'forgiveness is not selective or temporary. Every sin—past, present,\n'
              'and future—is covered by the sacrifice of Jesus for those who place\n'
              'their faith in Him.\n'
              '\n'
              'Many believers continue carrying guilt for sins that God has already\n'
              'forgiven. The enemy often reminds them of past failures in an attempt\n'
              'to keep them trapped in condemnation. Yet God\'s forgiveness is not\n'
              'based on the memory of our failures but on the sufficiency of Christ\'s\n'
              'sacrifice. As First Epistle of John 1:9 teaches, God is faithful and\n'
              'just to forgive and cleanse us from all unrighteousness.\n'
              '\n'
              'The cross speaks a better word than guilt. What God has forgiven\n'
              'should no longer define our identity.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'The Record Against You Has Been Destroyed',
          body:
              'Paul describes a "handwriting of requirements" that stood against\n'
              'humanity. This refers to the legal debt created by sin—a record of\n'
              'every violation, failure, and offense before a holy God. Every person\n'
              'stood guilty and unable to erase that debt through personal effort.\n'
              '\n'
              'The beauty of the gospel is that Christ did not merely reduce the\n'
              'debt; He completely removed it. God wiped away the record that\n'
              'condemned us. The charges that stood against us were not hidden,\n'
              'ignored, or postponed—they were fully dealt with through the cross. As\n'
              'Epistle to the Romans 8:1 declares, there is now no condemnation for\n'
              'those who are in Christ Jesus.\n'
              '\n'
              'The believer no longer stands before God as a debtor trying to earn\n'
              'acceptance but as a child fully accepted through grace.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'The Cross Is God\'s Final Answer to Sin',
          body:
              'Paul says that God took the record of debt and nailed it to the\n'
              'cross. In the ancient world, a written charge could be publicly\n'
              'displayed as evidence of guilt. Spiritually speaking, every accusation\n'
              'against the believer was placed upon Christ and dealt with at Calvary.\n'
              '\n'
              'The cross is not merely a symbol of suffering; it is the place where\n'
              'justice and mercy met. God\'s holiness required payment for sin, and\n'
              'God\'s love provided that payment through His Son. Every accusation of\n'
              'the enemy ultimately encounters the finished work of Christ. As Jesus\n'
              'proclaimed in Gospel of John 19:30, "It is finished."\n'
              '\n'
              'Nothing can be added to what Christ accomplished. The cross remains\n'
              'sufficient for every sin, every failure, and every need for\n'
              'redemption.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Freedom Begins When We Live from the Finished Work of Christ',
          body:
              'Many believers know that Christ died for them, yet still live as\n'
              'though they must constantly earn God\'s acceptance. Colossians 2:13–14\n'
              'calls believers to rest in what Christ has already accomplished.\n'
              'Spiritual growth flows from acceptance, not for acceptance.\n'
              '\n'
              'When believers understand the finished work of Christ, fear gives way\n'
              'to confidence, guilt gives way to gratitude, and striving gives way to\n'
              'worship. They no longer live under the burden of proving themselves\n'
              'before God because Christ has already secured their standing before\n'
              'Him. As Epistle to the Hebrews 10:14 teaches, by one sacrifice Christ\n'
              'has perfected forever those who are being sanctified.\n'
              '\n'
              'True freedom begins when believers stop living as debtors and start\n'
              'living as redeemed sons and daughters of God.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'The cross did more than forgive your sins—it erased your debt,\n'
          'silenced your condemnation, and gave you new life in Christ. ---',
      reflectionQuestions: const [
        'Am I living in the freedom of God\'s forgiveness or carrying guilt\n'
        'that Christ has already paid for?',
        'Do I truly believe that my debt before God has been completely\n'
        'cancelled?',
        'How would my daily life change if I fully embraced the finished work\n'
        'of Christ?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for the gift of salvation through Jesus Christ. Thank You\n'
          'for finding me when I was spiritually dead and making me alive through\n'
          'Your grace and mercy. I could never earn what You have freely given\n'
          'through the cross.\n'
          '\n'
          'Help me to fully embrace the reality of Your forgiveness. Remove\n'
          'every burden of guilt, shame, and condemnation that I continue to\n'
          'carry. Remind me that the debt of my sin has been completely cancelled\n'
          'and that every accusation against me was nailed to the cross with\n'
          'Christ.\n'
          '\n'
          'Teach me to live from the victory of Your finished work rather than\n'
          'striving to earn Your acceptance. Fill my heart with gratitude,\n'
          'confidence, and joy as I remember what You have accomplished for me.\n'
          '\n'
          'May I walk each day as one who has been forgiven, redeemed, and made\n'
          'alive in Christ, and may my life continually reflect the freedom found\n'
          'at the cross.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 11),
    ),

    // ── 43. ENDURANCE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'faithful_fire',
      theme: 'Endurance',
      title: 'Faithful Through the Fire',
      scripture:
          'Do not fear any of those things which you are about to suffer.\n'
          'Indeed, the devil is about to throw some of you into prison, that you\n'
          'may be tested... Be faithful until death, and I will give you the\n'
          'crown of life.',
      scriptureReference: 'Revelation 2:10',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Faithfulness Does Not Exempt Us from Trials',
          body:
              'Jesus spoke these words to believers in Smyrna, a church facing\n'
              'intense persecution. Instead of promising immediate deliverance, He\n'
              'prepared them for coming difficulties. This reminds us that following\n'
              'Christ does not guarantee a life free from suffering. Faithfulness to\n'
              'God sometimes leads believers through seasons of testing, opposition,\n'
              'and hardship.\n'
              '\n'
              'Many people mistakenly view trials as evidence that God has abandoned\n'
              'them. Yet Scripture consistently reveals that some of God\'s most\n'
              'faithful servants endured severe challenges. As First Epistle of Peter\n'
              '4:12 teaches, believers should not be surprised by fiery trials as\n'
              'though something strange were happening. God often uses adversity as a\n'
              'tool for refinement and spiritual growth.\n'
              '\n'
              'The presence of a trial does not mean the absence of God. Often, He\n'
              'is working most deeply during the seasons that seem most difficult.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Fear Loses Its Power When God Controls the Outcome',
          body:
              'Jesus begins with the command, "Do not fear." This instruction is\n'
              'remarkable because it was given in the context of real suffering, not\n'
              'imaginary threats. God never asks believers to deny reality, but He\n'
              'calls them to trust His sovereignty above their circumstances.\n'
              '\n'
              'Fear grows when we focus solely on what may happen. Faith grows when\n'
              'we remember who remains in control. The enemy may attack,\n'
              'circumstances may change, and difficulties may arise, but none of\n'
              'these operate outside God\'s knowledge and authority. As Book of Isaiah\n'
              '41:10 declares, God strengthens, helps, and upholds His people with\n'
              'His righteous hand.\n'
              '\n'
              'Courage is not the absence of fear. It is the decision to trust God\n'
              'even when fear attempts to dominate the heart.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Every Test Has a Spiritual Purpose',
          body:
              'Jesus acknowledged that the believers would be tested. Throughout\n'
              'Scripture, testing is not intended to destroy faith but to strengthen\n'
              'it. Just as gold is refined through fire, faith is often purified\n'
              'through trials. God uses difficulties to reveal what is genuine,\n'
              'deepen dependence upon Him, and develop spiritual maturity.\n'
              '\n'
              'The enemy may intend suffering for harm, but God can use the same\n'
              'situation for growth and refinement. What appears to be a setback can\n'
              'become a season of preparation. As Epistle of James 1:2–4 teaches,\n'
              'trials produce perseverance, and perseverance develops spiritual\n'
              'completeness.\n'
              '\n'
              'The believer who remains faithful during testing often discovers\n'
              'dimensions of God\'s faithfulness that could never be learned in easier\n'
              'seasons.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Faithfulness Is More Important Than Comfort',
          body:
              'Jesus did not primarily call His followers to comfort, success, or\n'
              'convenience. He called them to faithfulness. The measure of a\n'
              'believer\'s life is not how easy the journey was, but whether they\n'
              'remained committed to Christ through every season.\n'
              '\n'
              'In a world that values comfort above almost everything else,\n'
              'faithfulness can seem costly. Yet God sees every act of obedience,\n'
              'every sacrifice, every prayer, and every moment of perseverance. As\n'
              'First Epistle to the Corinthians 4:2 teaches, it is required that\n'
              'those entrusted with responsibility be found faithful.\n'
              '\n'
              'Faithfulness means continuing to trust, obey, and follow Christ even\n'
              'when circumstances make it difficult.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Eternal Rewards Outweigh Temporary Suffering',
          body:
              'Jesus concludes with a promise: "I will give you the crown of life."\n'
              'This crown symbolizes eternal reward, victory, and the fullness of\n'
              'life found in God\'s presence. The suffering believers endured on earth\n'
              'would not have the final word. God\'s reward would far exceed their\n'
              'temporary affliction.\n'
              '\n'
              'The Christian perspective is always shaped by eternity. Present\n'
              'trials, no matter how painful, are temporary compared to the eternal\n'
              'glory awaiting God\'s people. As Epistle to the Romans 8:18 declares,\n'
              'the sufferings of this present time are not worthy to be compared with\n'
              'the glory that shall be revealed.\n'
              '\n'
              'Those who keep their eyes on eternity find strength to remain\n'
              'faithful through present challenges.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'God does not promise that the fire will never come—He promises that\n'
          'faithfulness through the fire will lead to eternal reward. ---',
      reflectionQuestions: const [
        'What trial am I currently facing that is testing my faith?',
        'Have I allowed fear to become greater than my trust in God?',
        'How would my perspective change if I viewed my struggles through the\n'
        'lens of eternity?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for reminding me that You remain faithful even in seasons\n'
          'of suffering and testing. When difficulties arise, help me remember\n'
          'that trials do not mean You have abandoned me. Strengthen my heart to\n'
          'trust You when circumstances seem uncertain.\n'
          '\n'
          'Deliver me from fear and fill me with confidence in Your sovereignty.\n'
          'Help me keep my eyes fixed on You rather than on the challenges around\n'
          'me. Teach me to remain faithful in every situation, whether the path\n'
          'is easy or difficult.\n'
          '\n'
          'Use every trial to refine my faith, deepen my dependence upon You,\n'
          'and shape me into the person You desire me to become. Give me the\n'
          'endurance to continue following You with unwavering devotion.\n'
          '\n'
          'May I live with eternity in view, knowing that every act of\n'
          'faithfulness matters in Your kingdom, and may I one day receive the\n'
          'crown of life that You have promised to those who remain faithful to\n'
          'the end.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 12),
    ),

    // ── 44. IDENTITY ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'chosen_shine',
      theme: 'Identity',
      title: 'Chosen to Shine His Light',
      scripture:
          'But you are a chosen generation, a royal priesthood, a holy nation,\n'
          'His own special people, that you may proclaim the praises of Him who\n'
          'called you out of darkness into His marvelous light.',
      scriptureReference: '1 Peter 2:9',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Your Identity Is Defined by God, Not by the World',
          body:
              'Peter begins by reminding believers who they are in God\'s eyes: a\n'
              'chosen generation. In a world where many people struggle with\n'
              'rejection, insecurity, and the pressure to find identity through\n'
              'achievements or human approval, God declares that His people are\n'
              'chosen. This choice was not based on personal merit but on His grace,\n'
              'love, and divine purpose.\n'
              '\n'
              'Many believers live below their spiritual identity because they focus\n'
              'more on their failures than on God\'s declaration over their lives. Yet\n'
              'Scripture teaches that those who belong to Christ are no longer\n'
              'defined by their past, weaknesses, or the opinions of others. As\n'
              'Epistle to the Ephesians 1:4 reveals, God chose His people in Christ\n'
              'before the foundation of the world.\n'
              '\n'
              'Understanding your identity in Christ brings confidence, stability,\n'
              'and freedom from the need for constant human validation.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'You Have Been Called Into a Royal Priesthood',
          body:
              'Peter describes believers as a royal priesthood. In the Old\n'
              'Testament, priests had the privilege of ministering before God and\n'
              'representing Him to the people. Through Christ, every believer now has\n'
              'direct access to God\'s presence and the responsibility of reflecting\n'
              'His character to the world.\n'
              '\n'
              'Royalty speaks of authority, while priesthood speaks of intimacy with\n'
              'God. Believers are called to live with both. They are invited into\n'
              'close fellowship with God while also carrying His influence into their\n'
              'homes, workplaces, communities, and generation. As Epistle to the\n'
              'Hebrews 4:16 teaches, believers can approach God\'s throne of grace\n'
              'with confidence.\n'
              '\n'
              'The Christian life is not merely about receiving blessings from God\n'
              'but also representing Him wherever we go.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'God Calls His People to Be Set Apart',
          body:
              'Peter calls believers a holy nation. Holiness means being set apart\n'
              'for God\'s purposes. In a culture that often encourages compromise and\n'
              'conformity, God calls His people to live differently. Holiness is not\n'
              'about isolation from the world but about living under God\'s values\n'
              'while remaining in the world.\n'
              '\n'
              'The enemy seeks to blur the distinction between God\'s people and the\n'
              'surrounding culture. Yet God\'s desire is that believers reflect His\n'
              'character through their thoughts, words, actions, and priorities. As\n'
              'First Epistle of Peter 1:15–16 teaches, believers are called to be\n'
              'holy because God Himself is holy.\n'
              '\n'
              'A holy life becomes a visible testimony that God is transforming and\n'
              'shaping His people from within.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'You Are God\'s Special Possession',
          body:
              'Peter describes believers as God\'s own special people. This truth\n'
              'speaks of belonging, value, and relationship. God does not merely\n'
              'tolerate His people; He treasures them. They are precious in His sight\n'
              'because they have been redeemed through the blood of Christ.\n'
              '\n'
              'Many people spend their lives searching for acceptance and\n'
              'significance. Yet the greatest security comes from knowing that we\n'
              'belong to God. As Book of Isaiah 43:1 declares, “I have redeemed you;\n'
              'I have called you by your name; you are Mine.” The believer\'s worth is\n'
              'established by God\'s love rather than by earthly accomplishments.\n'
              '\n'
              'When believers understand that they belong to God, fear of rejection\n'
              'begins to lose its power.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'You Were Called Out of Darkness to Display His Light',
          body:
              'Peter concludes by revealing the purpose behind this identity: that\n'
              'believers may proclaim the praises of God who called them out of\n'
              'darkness into His marvelous light. Salvation is not merely about\n'
              'escaping darkness; it is about becoming a reflection of God\'s light in\n'
              'a dark world.\n'
              '\n'
              'Every believer carries a testimony of God\'s grace, mercy, and\n'
              'transforming power. Through words, actions, character, and love, they\n'
              'become living witnesses of what God can do in a surrendered life. As\n'
              'Jesus teaches in Gospel of Matthew 5:16, believers are called to let\n'
              'their light shine before others so that God may be glorified.\n'
              '\n'
              'The more closely we walk with Christ, the brighter His light shines\n'
              'through us to those around us.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'You were not chosen merely to be saved—you were chosen to reveal the\n'
          'glory of the One who called you out of darkness into His marvelous\n'
          'light. ---',
      reflectionQuestions: const [
        'Am I living according to God\'s identity for me or according to the\n'
        'opinions of others?',
        'How am I representing Christ as part of His royal priesthood?',
        'In what ways can I shine God\'s light more clearly in my daily life?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for choosing me and making me part of Your royal priesthood\n'
          'and holy nation. Help me to see myself through Your eyes and not\n'
          'through the limitations, failures, or opinions of this world.\n'
          '\n'
          'Teach me to live in a way that reflects the identity You have given\n'
          'me. Let my life be set apart for Your purposes and help me remain\n'
          'faithful in representing You wherever I go. Draw me deeper into Your\n'
          'presence so that I may know You more intimately and serve You more\n'
          'effectively.\n'
          '\n'
          'Thank You for calling me out of darkness and into Your marvelous\n'
          'light. Let that light shine through my words, actions, and character.\n'
          'May my life become a testimony of Your grace, mercy, and transforming\n'
          'power.\n'
          '\n'
          'May I walk daily as Your chosen possession, bringing honor and glory\n'
          'to the One who redeemed me and called me His own.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 13),
    ),

    // ── 45. PEACE ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'beyond_fear',
      theme: 'Peace',
      title: 'Living Beyond Fear',
      scripture:
          'For God has not given us a spirit of fear, but of power and of love\n'
          'and of a sound mind.',
      scriptureReference: '2 Timothy 1:7',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Fear Is Not God\'s Gift to His Children',
          body:
              'Paul wrote these words to Timothy during a season of growing\n'
              'persecution and uncertainty. Timothy faced pressures, opposition, and\n'
              'responsibilities that could easily have produced fear. Yet Paul\n'
              'reminded him that fear does not originate from God. Fear may come\n'
              'through circumstances, threats, failures, or spiritual attacks, but it\n'
              'is not part of God\'s design for the believer.\n'
              '\n'
              'Many believers mistakenly accept fear as a permanent part of their\n'
              'identity. They begin to define themselves by anxiety, insecurity, or\n'
              'intimidation. However, Scripture teaches that fear is something to\n'
              'confront, not something to embrace. God never intended His children to\n'
              'be controlled by fear because fear distorts perspective and weakens\n'
              'faith.\n'
              '\n'
              'The believer must learn to distinguish between natural emotions and\n'
              'spiritual truth. Fear may knock at the door of the heart, but it does\n'
              'not have the authority to rule there.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'God\'s Power Is Greater Than Every Limitation',
          body:
              'Paul declares that God has given believers a spirit of power. This\n'
              'power is not merely human determination or positive thinking; it is\n'
              'the enabling presence of the Holy Spirit working within the believer.\n'
              'The same God who raised Christ from the dead empowers His people to\n'
              'overcome challenges, endure hardships, and fulfill their divine\n'
              'calling.\n'
              '\n'
              'Many people focus on their weaknesses while forgetting God\'s\n'
              'strength. Moses focused on his speech, Gideon focused on his\n'
              'insignificance, and Jeremiah focused on his youth. Yet God\n'
              'consistently demonstrated that His power is sufficient where human\n'
              'ability falls short. As Second Epistle to the Corinthians 12:9\n'
              'teaches, God\'s strength is perfected in weakness.\n'
              '\n'
              'The believer\'s confidence should not rest in personal ability but in\n'
              'the power of God working through them.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Love Defeats What Fear Tries to Build',
          body:
              'Fear often produces self-protection, suspicion, withdrawal, and\n'
              'insecurity. Love, however, moves in the opposite direction. God\'s love\n'
              'creates confidence, security, compassion, and courage. When believers\n'
              'become rooted in God\'s love, fear begins losing its grip on the heart.\n'
              '\n'
              'The enemy uses fear to isolate people from God and others. Yet God\'s\n'
              'love continually draws believers into relationship, trust, and faith.\n'
              'As First Epistle of John 4:18 declares, perfect love casts out fear\n'
              'because fear involves torment. The deeper believers understand God\'s\n'
              'love, the less room fear has to dominate their lives.\n'
              '\n'
              'Love reminds the believer that they are accepted, protected, and\n'
              'deeply valued by God. This revelation becomes a powerful weapon\n'
              'against anxiety and insecurity.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God Gives a Sound Mind in a Confused World',
          body:
              'Paul also speaks of a sound mind. This refers to a disciplined,\n'
              'balanced, stable, and self-controlled mind. In a world filled with\n'
              'uncertainty, confusion, misinformation, and emotional pressure, God\n'
              'provides believers with the ability to think clearly and wisely.\n'
              '\n'
              'The enemy often attacks the mind through worry, panic, negative\n'
              'thinking, and mental chaos. Fear seeks to cloud judgment and distort\n'
              'reality. But God\'s Spirit produces clarity, discernment, and peace. As\n'
              'Epistle to the Philippians 4:7 teaches, God\'s peace guards the hearts\n'
              'and minds of His people through Christ Jesus.\n'
              '\n'
              'A sound mind is not the absence of challenges; it is the ability to\n'
              'remain stable and focused despite them. God desires His children to\n'
              'live with wisdom rather than confusion.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Courage Grows Through Trust in God\'s Presence',
          body:
              'The opposite of fear is not merely bravery—it is trust. Throughout\n'
              'Scripture, whenever God called people into difficult situations, He\n'
              'often accompanied the call with a promise of His presence. Courage\n'
              'grows when believers realize they do not face life\'s battles alone.\n'
              '\n'
              'Fear magnifies problems, but faith magnifies God. The more believers\n'
              'focus on God\'s character, promises, and faithfulness, the stronger\n'
              'their confidence becomes. As Book of Joshua 1:9 declares, believers\n'
              'can be strong and courageous because the Lord is with them wherever\n'
              'they go.\n'
              '\n'
              'True courage is not the absence of trembling; it is moving forward in\n'
              'obedience despite it. It is trusting that God\'s presence is greater\n'
              'than any challenge ahead.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'Fear may speak loudly, but it can never overpower the spirit of\n'
          'power, love, and soundness of mind that God has placed within His\n'
          'people. ---',
      reflectionQuestions: const [
        'What fears have been influencing my thoughts, decisions, or faith\n'
        'recently?',
        'Am I relying more on my limitations or on God\'s power?',
        'How would my life change if I fully embraced God\'s love and trusted\n'
        'His presence?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for reminding me that fear is not the inheritance You have\n'
          'given me. Forgive me for the times I have allowed fear, anxiety, and\n'
          'insecurity to influence my thoughts more than Your promises.\n'
          '\n'
          'Help me walk in the power You have provided through Your Holy Spirit.\n'
          'Strengthen me where I feel weak and remind me that Your strength is\n'
          'greater than my limitations. Fill my heart with a deeper understanding\n'
          'of Your love so that every fear loses its influence over my life.\n'
          '\n'
          'Guard my mind from confusion, worry, and discouragement. Give me the\n'
          'sound mind that comes from trusting You completely. Teach me to focus\n'
          'on Your faithfulness rather than my circumstances and to move forward\n'
          'with courage knowing that You are always with me.\n'
          '\n'
          'May I live each day in the confidence of Your power, the security of\n'
          'Your love, and the peace of a mind anchored in You.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 14),
    ),

    // ── 46. VICTORY ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'ascended_victory',
      theme: 'Victory',
      title: 'Living in the Victory and Gifts of the Ascended Christ',
      scripture:
          'Therefore He says: ‘When He ascended on high, He led captivity\n'
          'captive, and gave gifts to men.',
      scriptureReference: 'Ephesians 4:8',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'Christ\'s Victory Was Complete and Absolute',
          body:
              'Ephesians 4:8 paints a picture of a victorious King returning from\n'
              'battle. When Paul says Christ "led captivity captive," he is\n'
              'describing the triumph of Jesus over sin, death, Satan, and every\n'
              'power that held humanity in bondage. Through His death, resurrection,\n'
              'and ascension, Christ accomplished a victory that no human effort\n'
              'could ever achieve.\n'
              '\n'
              'Many believers understand the cross but fail to fully appreciate the\n'
              'significance of Christ\'s ascension. The ascension declares that Jesus\n'
              'not only died and rose again but now reigns in complete authority. As\n'
              'Epistle to the Colossians 2:15 reveals, Christ disarmed principalities\n'
              'and powers and triumphed over them openly. The believer serves a\n'
              'Savior who has already won the battle.\n'
              '\n'
              'Every spiritual victory flows from the finished work of Christ. We do\n'
              'not fight for victory; we live from the victory He has already\n'
              'secured.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Christ Breaks Every Form of Captivity',
          body:
              'The phrase "led captivity captive" reveals that Jesus conquered the\n'
              'very things that once enslaved humanity. Sin, fear, condemnation,\n'
              'death, shame, and spiritual bondage no longer have ultimate authority\n'
              'over those who belong to Him. The chains that once held humanity\n'
              'captive were broken through His redemptive work.\n'
              '\n'
              'Many believers continue living as prisoners even after Christ has\n'
              'opened the prison door. They remain trapped by fear, guilt, addiction,\n'
              'bitterness, or feelings of unworthiness. Yet Scripture declares that\n'
              'whom the Son sets free is truly free, as Jesus teaches in Gospel of\n'
              'John 8:36. Freedom begins when believers embrace the reality of what\n'
              'Christ has already accomplished.\n'
              '\n'
              'The enemy wants believers to focus on their chains. God wants them to\n'
              'focus on their Deliverer.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'The Ascended Christ Gives Gifts to His People',
          body:
              'Paul reveals that Christ not only won the victory but also\n'
              'distributed gifts to His people. A victorious king would often share\n'
              'the spoils of victory with his subjects. Likewise, Jesus pours out\n'
              'spiritual gifts, grace, and divine enablement upon believers so they\n'
              'can fulfill His purposes on earth.\n'
              '\n'
              'Every believer has received something from Christ that can be used\n'
              'for His kingdom. Some are called to teach, encourage, lead, serve,\n'
              'give, evangelize, or minister in other ways. As First Epistle to the\n'
              'Corinthians 12:7 teaches, the manifestation of the Spirit is given for\n'
              'the benefit of all. Spiritual gifts are not rewards for spiritual\n'
              'maturity but resources for kingdom service.\n'
              '\n'
              'God never calls believers to a task without also providing the grace\n'
              'necessary to fulfill it.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'Your Calling Is Connected to Christ\'s Purpose',
          body:
              'The gifts Christ gives are not intended for personal recognition or\n'
              'self-promotion. They are given so believers can build up the body of\n'
              'Christ and advance God\'s purposes in the world. Every gift points back\n'
              'to the Giver and reflects His glory.\n'
              '\n'
              'Many people spend their lives searching for purpose while overlooking\n'
              'the gifts God has already placed within them. Purpose becomes clearer\n'
              'when believers begin serving faithfully with what they have received.\n'
              'As First Epistle of Peter 4:10 teaches, believers are stewards of\n'
              'God\'s grace and are called to use their gifts to serve others.\n'
              '\n'
              'The question is not whether God has given you something valuable, but\n'
              'whether you are willing to use it for His glory.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'The Reigning Christ Continues to Work Through His People',
          body:
              'The ascension of Christ was not His withdrawal from the world but the\n'
              'beginning of His reign through His Church. Though seated at the\n'
              'Father\'s right hand, He continues His work through believers empowered\n'
              'by the Holy Spirit. Every act of service, ministry, love, and\n'
              'obedience becomes part of His ongoing mission.\n'
              '\n'
              'This truth gives significance to everyday faithfulness. No act of\n'
              'obedience is insignificant when offered to the King who reigns over\n'
              'all things. As Gospel of Matthew 28:18 declares, all authority in\n'
              'heaven and on earth belongs to Christ. Because He reigns, believers\n'
              'can serve with confidence, knowing their labor is part of His eternal\n'
              'purpose.\n'
              '\n'
              'The ascended Christ is still working today, and He chooses to work\n'
              'through surrendered lives.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'The same Christ who conquered every enemy has entrusted gifts,\n'
          'purpose, and authority to His people so they can reflect His victory\n'
          'in the world. ---',
      reflectionQuestions: const [
        'Am I living in the freedom Christ purchased for me, or am I still\n'
        'holding onto old chains?',
        'What gifts and abilities has God entrusted to me for His kingdom?',
        'How can I use what Christ has given me to serve others and glorify\n'
        'Him?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for the victory You won through Your death, resurrection,\n'
          'and ascension. Thank You that every chain of sin, fear, condemnation,\n'
          'and spiritual bondage has been broken through Your power.\n'
          '\n'
          'Help me live in the freedom You have provided and not return to the\n'
          'things You have already conquered. Open my eyes to recognize the\n'
          'gifts, abilities, and opportunities You have entrusted to me. Teach me\n'
          'to use them faithfully for Your glory and for the strengthening of\n'
          'others.\n'
          '\n'
          'Keep me from seeking personal recognition and help me remain focused\n'
          'on Your purpose. Let my life reflect the victory, authority, and grace\n'
          'of the risen Christ. Empower me through Your Holy Spirit to serve with\n'
          'faithfulness, humility, and courage.\n'
          '\n'
          'May I live each day as a servant of the victorious King, and may\n'
          'everything You have placed in my hands be used to honor You.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 15),
    ),

    // ── 47. PROMISES ──────────────────────────────────────────────────
    DevotionalModel(
      id: 'god_speaks_surely',
      theme: 'Promises',
      title: 'When God Speaks, It Will Surely Come to Pass',
      scripture:
          'Therefore say to them, ‘Thus says the Lord God: None of My words will\n'
          'be postponed anymore, but the word which I speak will be done,’ says\n'
          'the Lord God.',
      scriptureReference: 'Ezekiel 12:28',
      sections: const [
        DevotionalSection(
          icon: '🔑',
          heading:
              'God\'s Promises Are Never Forgotten',
          body:
              'Ezekiel 12:28 was spoken to a people who had grown skeptical about\n'
              'God\'s promises. Because fulfillment seemed delayed, many began\n'
              'believing that God\'s words would never come to pass. In response, God\n'
              'declared that none of His words would be postponed any longer. This\n'
              'reveals a powerful truth: God never forgets what He has spoken.\n'
              '\n'
              'Many believers struggle during seasons of waiting because God\'s\n'
              'promises seem distant. Prayers remain unanswered, circumstances remain\n'
              'unchanged, and hope begins to weaken. Yet divine silence should never\n'
              'be mistaken for divine forgetfulness. God remembers every promise He\n'
              'has made and remains committed to fulfilling His word according to His\n'
              'perfect will.\n'
              '\n'
              'As Book of Numbers 23:19 teaches, God is not a man that He should lie\n'
              'or fail to fulfill what He has spoken. What God promises remains alive\n'
              'even when fulfillment appears delayed.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🔍',
          heading:
              'Delay Does Not Mean Denial',
          body:
              'One of the greatest tests of faith is waiting. Human nature often\n'
              'expects God to work according to personal timelines, but God operates\n'
              'according to eternal wisdom. The people in Ezekiel\'s day assumed that\n'
              'because fulfillment had not yet arrived, it never would. God corrected\n'
              'this misunderstanding by declaring that His timing had not failed.\n'
              '\n'
              'Many believers abandon hope prematurely because they interpret delay\n'
              'as rejection. Yet throughout Scripture, God\'s greatest works often\n'
              'unfolded after long periods of waiting. Abraham waited for Isaac,\n'
              'Joseph waited for restoration, and David waited for the throne. Delay\n'
              'was part of God\'s process, not evidence of His absence.\n'
              '\n'
              'Faith learns to trust not only God\'s promises but also His timing.\n'
              'The God who speaks the promise also determines the season of\n'
              'fulfillment.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '⚔️',
          heading:
              'Unbelief Grows When God\'s Word Is Forgotten',
          body:
              'The people Ezekiel addressed had become discouraged because they\n'
              'focused more on circumstances than on God\'s promises. When believers\n'
              'lose sight of what God has spoken, fear, doubt, and unbelief begin\n'
              'gaining influence. The enemy often attacks faith by magnifying delays\n'
              'and minimizing God\'s faithfulness.\n'
              '\n'
              'This is why believers must continually meditate on God\'s Word. His\n'
              'promises strengthen the heart when circumstances appear contradictory.\n'
              'As Epistle to the Romans 10:17 teaches, faith comes by hearing the\n'
              'Word of God. The more believers focus on God\'s truth, the stronger\n'
              'their confidence becomes.\n'
              '\n'
              'Faith is sustained not by what is seen but by confidence in the\n'
              'character of the One who has spoken.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🌱',
          heading:
              'God\'s Word Carries the Power to Fulfill Itself',
          body:
              'When God says, "The word which I speak will be done," He reveals that\n'
              'His Word is not merely information—it carries divine authority and\n'
              'power. Human promises often fail because people lack the ability to\n'
              'fulfill them. God never faces that limitation. Whatever He speaks\n'
              'possesses the power necessary for its own fulfillment.\n'
              '\n'
              'From creation itself to the fulfillment of prophecy, Scripture\n'
              'repeatedly demonstrates the effectiveness of God\'s Word. As Book of\n'
              'Isaiah 55:11 declares, God\'s Word never returns void but accomplishes\n'
              'the purpose for which it was sent. What God has spoken over your life\n'
              'does not depend on human ability but on divine faithfulness.\n'
              '\n'
              'The believer\'s confidence rests not in circumstances, resources, or\n'
              'personal strength but in the power of God\'s unchanging Word.\n'
              '\n'
              '---',
        ),
        DevotionalSection(
          icon: '🚶',
          heading:
              'Fulfillment Reveals God\'s Faithfulness',
          body:
              'God\'s ultimate purpose in fulfilling His Word is not merely to answer\n'
              'prayers but to reveal His faithfulness. Every fulfilled promise\n'
              'becomes a testimony that God can be trusted completely. What begins as\n'
              'a season of waiting often ends as a story of God\'s reliability and\n'
              'grace.\n'
              '\n'
              'Looking back, believers often recognize that God\'s timing was wiser\n'
              'than their own expectations. What seemed delayed was actually being\n'
              'prepared. What felt forgotten was being preserved for the right\n'
              'season. As Epistle to the Hebrews 10:23 encourages, believers should\n'
              'hold fast to their hope because He who promised is faithful.\n'
              '\n'
              'The longer the wait, the greater the testimony when God\'s\n'
              'faithfulness becomes visible.\n'
              '\n'
              '---',
        ),
      ],
      finalRevelation:
          'God\'s promises are never cancelled by delay—they are fulfilled\n'
          'according to His perfect timing and unchanging faithfulness. ---',
      reflectionQuestions: const [
        'Have I allowed delays to weaken my confidence in God\'s promises?',
        'What word or promise from God am I still waiting to see fulfilled?',
        'Am I focusing more on my circumstances or on God\'s faithfulness?',
      ],
      prayer:
          'Lord,\n'
          '\n'
          'Thank You for being a God who never forgets, abandons, or fails to\n'
          'fulfill what You have spoken. Forgive me for the times I have allowed\n'
          'delays, disappointments, and unanswered questions to weaken my faith.\n'
          '\n'
          'Help me trust Your timing even when I cannot understand Your process.\n'
          'Strengthen my heart to hold firmly to Your promises and to remain\n'
          'confident in Your faithfulness. Teach me to focus on Your Word rather\n'
          'than on circumstances that seem contrary to what You have spoken.\n'
          '\n'
          'Renew my hope where discouragement has entered. Let Your promises\n'
          'become more real to me than my fears and more powerful than my doubts.\n'
          'Remind me that every word You speak carries the power to accomplish\n'
          'exactly what You intend.\n'
          '\n'
          'May I wait with faith, trust with patience, and rejoice with\n'
          'confidence,\n'
          'knowing that what You have spoken will surely come to pass in Your\n'
          'perfect time.\n'
          '\n'
          'Amen.',
      createdAt: DateTime(2024, 2, 16),
    ),
  ];
}
