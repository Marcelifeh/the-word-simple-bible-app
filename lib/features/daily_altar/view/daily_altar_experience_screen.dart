import 'package:flutter/material.dart';

import '../access/daily_altar_access_decision.dart';
import '../access/daily_altar_access_policy.dart';
import '../access/open_daily_altar_access_policy.dart';
import '../data/curated_daily_altar_content_provider.dart';
import '../data/daily_altar_content_provider.dart';
import '../model/daily_altar_content.dart';
import '../model/daily_altar_evening_response.dart';
import '../model/daily_altar_obedience_response.dart';
import '../model/daily_altar_personal_prayer.dart';
import '../model/daily_altar_posture.dart';
import '../model/daily_altar_reflection_response.dart';
import '../model/daily_altar_session.dart';
import '../model/daily_altar_stage.dart';
import '../model/daily_altar_user_response.dart';
import '../persistence/daily_altar_repository.dart';
import '../persistence/daily_altar_stored_record.dart';
import '../persistence/hive_daily_altar_repository.dart';
import '../services/daily_altar_journey_engine.dart';

/// Internal end-to-end experience for My Daily Altar.
///
/// MDA-2F2 adds isolated local persistence and session restoration.
///
/// This screen is still NOT registered with production Home/navigation.
/// It has no billing, network, AI, notification, Journal, Prayer, Scripture
/// Memory, or AppState dependency.
class DailyAltarExperienceScreen extends StatefulWidget {
  const DailyAltarExperienceScreen({
    super.key,
    this.contentProvider = const CuratedDailyAltarContentProvider(),
    this.accessPolicy = const OpenDailyAltarAccessPolicy(),
    this.journeyEngine = const DailyAltarJourneyEngine(),
    this.repository = const HiveDailyAltarRepository(),
    this.now,
  });

  final DailyAltarContentProvider contentProvider;
  final DailyAltarAccessPolicy accessPolicy;
  final DailyAltarJourneyEngine journeyEngine;
  final DailyAltarRepository repository;

  /// Optional deterministic clock used by tests.
  final DateTime Function()? now;

  @override
  State<DailyAltarExperienceScreen> createState() =>
      _DailyAltarExperienceScreenState();
}

class _DailyAltarExperienceScreenState
    extends State<DailyAltarExperienceScreen> {
  DailyAltarAccessDecision? _accessDecision;

  DailyAltarPosture? _selectedPosture;
  DailyAltarContent? _content;
  DailyAltarSession? _session;
  DailyAltarUserResponse? _response;

  bool _initializing = true;
  bool _obedienceCompleted = false;

  String? _storageMessage;

  final _aboutGodController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _responseController = TextEditingController();

  final _personalPrayerController = TextEditingController();
  final _obedienceController = TextEditingController();

  final _rememberedWordController = TextEditingController();
  final _obedienceReflectionController = TextEditingController();
  final _relevanceController = TextEditingController();
  final _heartResponseController = TextEditingController();
  final _carryForwardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _aboutGodController.dispose();
    _aboutMeController.dispose();
    _responseController.dispose();

    _personalPrayerController.dispose();
    _obedienceController.dispose();

    _rememberedWordController.dispose();
    _obedienceReflectionController.dispose();
    _relevanceController.dispose();
    _heartResponseController.dispose();
    _carryForwardController.dispose();

    super.dispose();
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  Future<void> _initialize() async {
    final decision = await widget.accessPolicy.evaluate();

    if (!mounted) {
      return;
    }

    if (!decision.isAllowed) {
      setState(() {
        _accessDecision = decision;
        _initializing = false;
      });

      return;
    }

    DailyAltarStoredRecord? restored;
    String? restoreMessage;

    final now = _now();
    final localDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final sessionId = _sessionId(localDate);

    try {
      restored = await widget.repository.load(sessionId);
    } catch (_) {
      restoreMessage = 'Saved Daily Altar progress could not be restored. '
          'You can begin a fresh session.';
    }

    DailyAltarContent? restoredContent;

    if (restored != null) {
      try {
        restoredContent = widget.contentProvider.getById(
          restored.contentId,
        );
      } catch (_) {
        restoreMessage = 'Saved Daily Altar content is no longer available. '
            'Your saved record was left untouched.';
        restored = null;
      }
    }

    if (!mounted) {
      return;
    }

    if (restored != null && restoredContent != null) {
      _hydrateControllers(restored.response);

      setState(() {
        _accessDecision = decision;
        _selectedPosture = restored!.session.posture;
        _content = restoredContent;
        _session = restored.session;
        _response = restored.response;
        _obedienceCompleted = restored.response.obedience?.completed ?? false;
        _storageMessage = restoreMessage;
        _initializing = false;
      });

      return;
    }

    setState(() {
      _accessDecision = decision;
      _storageMessage = restoreMessage;
      _initializing = false;
    });
  }

  Future<void> _start() async {
    final posture = _selectedPosture;

    if (posture == null) {
      return;
    }

    final now = _now();

    final localDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final content = widget.contentProvider.getForPosture(
      posture,
    );

    final session = widget.journeyEngine.start(
      sessionId: _sessionId(localDate),
      localDate: localDate,
      now: now,
      posture: posture,
    );

    final response = DailyAltarUserResponse(
      sessionId: session.id,
      updatedAt: now,
    );

    setState(() {
      _content = content;
      _session = session;
      _response = response;
      _storageMessage = null;
    });

    await _persist();
  }

  String _sessionId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return 'altar-${date.year}-$month-$day';
  }

  Future<void> _advance() async {
    final session = _session;

    if (session == null) {
      await _start();
      return;
    }

    _captureCurrentResponse(
      session.stage,
    );

    if (session.stage == DailyAltarStage.completed) {
      return;
    }

    final advanced = widget.journeyEngine.advance(
      session: session,
      now: _now(),
    );

    setState(() {
      _session = advanced;
    });

    await _persist();
  }

  void _captureCurrentResponse(
    DailyAltarStage stage,
  ) {
    final current = _response;

    if (current == null) {
      return;
    }

    final now = _now();

    switch (stage) {
      case DailyAltarStage.abide:
        _response = DailyAltarUserResponse(
          sessionId: current.sessionId,
          reflection: DailyAltarReflectionResponse(
            aboutGod: _clean(
              _aboutGodController.text,
            ),
            aboutMe: _clean(
              _aboutMeController.text,
            ),
            response: _clean(
              _responseController.text,
            ),
          ),
          personalPrayer: current.personalPrayer,
          obedience: current.obedience,
          evening: current.evening,
          updatedAt: now,
        );

      case DailyAltarStage.pray:
        final prayerText = _clean(
          _personalPrayerController.text,
        );

        _response = DailyAltarUserResponse(
          sessionId: current.sessionId,
          reflection: current.reflection,
          personalPrayer: prayerText == null
              ? null
              : DailyAltarPersonalPrayer(
                  text: prayerText,
                ),
          obedience: current.obedience,
          evening: current.evening,
          updatedAt: now,
        );

      case DailyAltarStage.obey:
        final commitment = _clean(
          _obedienceController.text,
        );

        _response = DailyAltarUserResponse(
          sessionId: current.sessionId,
          reflection: current.reflection,
          personalPrayer: current.personalPrayer,
          obedience: commitment == null
              ? null
              : DailyAltarObedienceResponse(
                  commitment: commitment,
                ),
          evening: current.evening,
          updatedAt: now,
        );

      case DailyAltarStage.returnToAltar:
        var obedience = current.obedience;

        if (_obedienceCompleted && obedience != null && !obedience.completed) {
          obedience = obedience.markCompleted(now);
        }

        _response = DailyAltarUserResponse(
          sessionId: current.sessionId,
          reflection: current.reflection,
          personalPrayer: current.personalPrayer,
          obedience: obedience,
          evening: DailyAltarEveningResponse(
            rememberedWord: _clean(
              _rememberedWordController.text,
            ),
            obedienceReflection: _clean(
              _obedienceReflectionController.text,
            ),
            relevanceReflection: _clean(
              _relevanceController.text,
            ),
            heartResponse: _clean(
              _heartResponseController.text,
            ),
            carryForward: _clean(
              _carryForwardController.text,
            ),
          ),
          updatedAt: now,
        );

      case DailyAltarStage.come:
      case DailyAltarStage.receive:
      case DailyAltarStage.understand:
      case DailyAltarStage.carry:
      case DailyAltarStage.completed:
        break;
    }
  }

  Future<void> _persist() async {
    final session = _session;
    final content = _content;
    final response = _response;

    if (session == null || content == null || response == null) {
      return;
    }

    try {
      await widget.repository.save(
        DailyAltarStoredRecord(
          session: session,
          contentId: content.id,
          response: response,
        ),
      );

      if (mounted && _storageMessage != null) {
        setState(() {
          _storageMessage = null;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _storageMessage =
            'Your Daily Altar progress could not be saved locally. '
            'You may continue, but do not close the app until storage '
            'is available.';
      });
    }
  }

  void _hydrateControllers(
    DailyAltarUserResponse response,
  ) {
    _aboutGodController.text = response.reflection?.aboutGod ?? '';

    _aboutMeController.text = response.reflection?.aboutMe ?? '';

    _responseController.text = response.reflection?.response ?? '';

    _personalPrayerController.text = response.personalPrayer?.text ?? '';

    _obedienceController.text = response.obedience?.commitment ?? '';

    _rememberedWordController.text = response.evening?.rememberedWord ?? '';

    _obedienceReflectionController.text =
        response.evening?.obedienceReflection ?? '';

    _relevanceController.text = response.evening?.relevanceReflection ?? '';

    _heartResponseController.text = response.evening?.heartResponse ?? '';

    _carryForwardController.text = response.evening?.carryForward ?? '';

    _obedienceCompleted = response.obedience?.completed ?? false;
  }

  String? _clean(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final access = _accessDecision;

    if (access == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!access.isAllowed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Daily Altar'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              access.reason ?? 'My Daily Altar is currently unavailable.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final session = _session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Daily Altar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_storageMessage != null)
              Container(
                key: const Key(
                  'dailyAltarStorageMessage',
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  _storageMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24,
                ),
                child: session == null
                    ? _buildComeStage()
                    : _buildJourney(session),
              ),
            ),
            if (session?.stage != DailyAltarStage.completed)
              _buildPrimaryAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildComeStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Come Before the Word',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Take a moment to become still. This is not about rushing through '
          'content, but about meeting God through His Word.',
        ),
        const SizedBox(height: 28),
        const Text(
          'Where are you today?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Choose your posture',
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DailyAltarPosture>(
              key: const Key(
                'dailyAltarPostureDropdown',
              ),
              value: _selectedPosture,
              isExpanded: true,
              hint: const Text('Select one'),
              items: DailyAltarPosture.values.map(
                (posture) {
                  return DropdownMenuItem(
                    value: posture,
                    child: Text(
                      posture.label,
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPosture = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Your selection describes how you are approaching Scripture today. '
          'It is not a diagnosis and does not claim that God has spoken a '
          'personal message through the app.',
          style: TextStyle(
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildJourney(
    DailyAltarSession session,
  ) {
    final content = _content!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgress(
          session.stage,
        ),
        const SizedBox(height: 24),
        Text(
          session.stage.label,
          key: const Key(
            'dailyAltarStageLabel',
          ),
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        _buildStageContent(
          stage: session.stage,
          content: content,
        ),
      ],
    );
  }

  Widget _buildProgress(
    DailyAltarStage stage,
  ) {
    final progress = switch (stage) {
      DailyAltarStage.receive => 1 / 8,
      DailyAltarStage.understand => 2 / 8,
      DailyAltarStage.abide => 3 / 8,
      DailyAltarStage.pray => 4 / 8,
      DailyAltarStage.obey => 5 / 8,
      DailyAltarStage.carry => 6 / 8,
      DailyAltarStage.returnToAltar => 7 / 8,
      DailyAltarStage.completed => 1.0,
      DailyAltarStage.come => 0.0,
    };

    return LinearProgressIndicator(
      value: progress,
      minHeight: 6,
    );
  }

  Widget _buildStageContent({
    required DailyAltarStage stage,
    required DailyAltarContent content,
  }) {
    switch (stage) {
      case DailyAltarStage.come:
        return _buildComeStage();

      case DailyAltarStage.receive:
        return _buildReceive(content);

      case DailyAltarStage.understand:
        return _buildUnderstand(content);

      case DailyAltarStage.abide:
        return _buildAbide(content);

      case DailyAltarStage.pray:
        return _buildPray(content);

      case DailyAltarStage.obey:
        return _buildObey(content);

      case DailyAltarStage.carry:
        return _buildCarry(content);

      case DailyAltarStage.returnToAltar:
        return _buildReturn(content);

      case DailyAltarStage.completed:
        return _buildCompleted();
    }
  }

  Widget _buildReceive(
    DailyAltarContent content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.scripture.reference,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Scripture • '
          '${content.scripture.translationId.toUpperCase()}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          content.scripture.text,
          style: const TextStyle(
            fontSize: 18,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Read slowly. Before moving to explanation, notice the words, '
          'commands, truths, or promises that draw your attention.',
        ),
      ],
    );
  }

  Widget _buildUnderstand(
    DailyAltarContent content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Context',
          content.understanding.context,
        ),
        _section(
          'Central Truth',
          content.understanding.centralTruth,
        ),
        _section(
          'Look Again',
          content.understanding.lookAgain,
        ),
        const Text(
          'These notes are curated explanation, not Scripture.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAbide(
    DailyAltarContent content,
  ) {
    return Column(
      children: [
        _reflectionField(
          prompt: content.reflection.aboutGod,
          controller: _aboutGodController,
          keyName: 'aboutGod',
        ),
        _reflectionField(
          prompt: content.reflection.aboutMe,
          controller: _aboutMeController,
          keyName: 'aboutMe',
        ),
        _reflectionField(
          prompt: content.reflection.response,
          controller: _responseController,
          keyName: 'response',
        ),
      ],
    );
  }

  Widget _buildPray(
    DailyAltarContent content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A Scripture-shaped prayer',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content.prayer.text,
          style: const TextStyle(
            fontSize: 17,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        TextField(
          key: const Key(
            'dailyAltarPersonalPrayer',
          ),
          controller: _personalPrayerController,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'My prayer',
            hintText: 'Continue praying in your own words...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildObey(
    DailyAltarContent content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggested application',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content.obedience.text,
          style: const TextStyle(
            fontSize: 17,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is an application suggestion, not additional Scripture.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 26),
        TextField(
          key: const Key(
            'dailyAltarObedienceCommitment',
          ),
          controller: _obedienceController,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'My obedience step',
            hintText: 'What will I do differently because of today’s Word?',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCarry(
    DailyAltarContent content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Carry this Scripture with you',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          content.carryWord.reference,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.carryWord.text,
          style: const TextStyle(
            fontSize: 22,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Your morning journey is complete. Your progress has been saved '
          'locally so you can return later and reflect on how you walked '
          'with the Word.',
        ),
      ],
    );
  }

  Widget _buildReturn(
    DailyAltarContent content,
  ) {
    final prompts = content.eveningReflection;

    return Column(
      children: [
        CheckboxListTile(
          key: const Key(
            'dailyAltarObedienceCompleted',
          ),
          value: _obedienceCompleted,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I carried out my obedience step today',
          ),
          onChanged: (value) {
            setState(() {
              _obedienceCompleted = value ?? false;
            });
          },
        ),
        const SizedBox(height: 10),
        _reflectionField(
          prompt: prompts.rememberedWordPrompt,
          controller: _rememberedWordController,
          keyName: 'rememberedWord',
        ),
        _reflectionField(
          prompt: prompts.obediencePrompt,
          controller: _obedienceReflectionController,
          keyName: 'obedienceReflection',
        ),
        _reflectionField(
          prompt: prompts.relevancePrompt,
          controller: _relevanceController,
          keyName: 'relevance',
        ),
        _reflectionField(
          prompt: prompts.heartResponsePrompt,
          controller: _heartResponseController,
          keyName: 'heartResponse',
        ),
        _reflectionField(
          prompt: prompts.carryForwardPrompt,
          controller: _carryForwardController,
          keyName: 'carryForward',
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    final response = _response;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 56,
        ),
        const SizedBox(height: 18),
        const Text(
          'Today’s Altar Is Complete',
          key: Key(
            'dailyAltarCompletedTitle',
          ),
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You received the Word, reflected on it, prayed, considered your '
          'response, carried it into the day, and returned to reflect.',
        ),
        const SizedBox(height: 20),
        if (response?.hasAnyResponse ?? false)
          const Text(
            'Your personal responses have been saved locally on this device.',
          ),
        const SizedBox(height: 12),
        const Text(
          'Your Daily Altar record remains private local app data.',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _section(
    String title,
    String body,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reflectionField({
    required String prompt,
    required TextEditingController controller,
    required String keyName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 22,
      ),
      child: TextField(
        key: Key(
          'dailyAltarField_$keyName',
        ),
        controller: controller,
        minLines: 3,
        maxLines: 7,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: prompt,
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    final session = _session;

    final label = switch (session?.stage) {
      null => 'Begin Today’s Altar',
      DailyAltarStage.come => 'Begin Today’s Altar',
      DailyAltarStage.receive => 'Continue',
      DailyAltarStage.understand => 'Continue to Reflection',
      DailyAltarStage.abide => 'Continue to Prayer',
      DailyAltarStage.pray => 'Continue to Obedience',
      DailyAltarStage.obey => 'Carry the Word',
      DailyAltarStage.carry => 'Open Evening Return',
      DailyAltarStage.returnToAltar => 'Complete Today’s Altar',
      DailyAltarStage.completed => 'Completed',
    };

    final enabled = session != null || _selectedPosture != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key(
              'dailyAltarPrimaryAction',
            ),
            onPressed: enabled ? _advance : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
