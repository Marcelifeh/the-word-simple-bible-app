import 'package:flutter/material.dart';
// import 'package:web/web.dart' as web; // Commented out: not a declared dependencyrial.dart';
// Removed unused AppBranding import
// import '../../../core/config/app_branding.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/reading_text_scale.dart';
import '../../devotional_audio/view/devotional_player_screen.dart';

import '../../devotional/model/devotional_model.dart';
import '../../devotional/model/devotional_journal_entry.dart';
import '../../notes/model/verse_note.dart';
import 'widgets/closing_prayer_card.dart';
import 'widgets/final_revelation_card.dart';
import 'widgets/insight_section_tile.dart';
import 'widgets/scripture_card.dart';

class DevotionalDetailScreen extends StatefulWidget {
  const DevotionalDetailScreen({
    super.key,
    required this.devotional,
    this.activeDate,
  });

  final DevotionalModel devotional;
  final DateTime? activeDate;

  @override
  State<DevotionalDetailScreen> createState() => _DevotionalDetailScreenState();
}

class _DevotionalDetailScreenState extends State<DevotionalDetailScreen> {
  // User-written reflection answers (one per question)
  late final List<TextEditingController> _reflectionCtrls;
  bool _saved = false;
  bool _didInitProgress = false;
  double _highestProgress = 0.0;
  double _lastSavedProgress = 0.0;

  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _accentColor = Color(0xFF818CF8);

  DateTime get _activeDate => widget.activeDate ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _reflectionCtrls = List.generate(
      widget.devotional.reflectionQuestions.length,
      (_) => TextEditingController(),
    );
  }

  bool _didMarkAsRead = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitProgress) {
      final state = AppScope.of(context);
      final existingProgress = state.devotionalProgressForDate(_activeDate);
      _highestProgress = existingProgress;
      _lastSavedProgress = existingProgress;
      _didInitProgress = true;
    }
    if (_didMarkAsRead) return;
    _didMarkAsRead = true;
    AppScope.of(context).markDevotionalRead(
      widget.devotional.id,
      activeDate: _activeDate,
    );
  }

  @override
  void dispose() {
    for (final c in _reflectionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save full devotional to journal ────────────────────────────────────────
  void _saveToJournal() {
    final state = AppScope.of(context);
    final d = widget.devotional;
    final entry = DevotionalJournalEntry(
      id: '${d.id}-${DateTime.now().millisecondsSinceEpoch}',
      devotionalId: d.id,
      devotionalTitle: d.title,
      theme: d.theme,
      scriptureReference: d.scriptureReference,
      scripture: d.scripture,
      prayer: d.prayer,
      reflections: _reflectionCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      savedAt: DateTime.now(),
    );
    // Persist in the devotional-specific repository
    state.devotionalJournalRepo.save(entry);

    // Also create a visible note in the main Journal (notesRepo)
    final note = VerseNote(
      verseId: 'devotional-${entry.id}',
      text:
          'Devotional: ${entry.devotionalTitle}\n\n${entry.scriptureReference}\n"${entry.scripture}"\n\n${entry.reflections.join('\n')}\n\nPrayer:\n${entry.prayer}',
      color: Theme.of(context).colorScheme.primary.toARGB32(),
      createdAt: DateTime.now(),
    );
    state.notesRepo.save(note);

    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Devotional saved to your Journal ✨'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Share full devotional ───────────────────────────────────────────────────
  void _share() {
    final d = widget.devotional;
    final text = '''🌿 ${d.title}

📖 ${d.scriptureReference}
"${d.scripture}"

${d.sections.map((s) => '${s.icon} ${s.heading}\n${s.body}').join('\n\n')}

✨ Final Revelation
${d.finalRevelation}

🙏 Prayer
${d.prayer}

—————
📖 The Word – The Word App
https://play.google.com/store/apps/details?id=com.theword.simplebible''';
    Share.share(text, subject: d.title);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final maxExtent = notification.metrics.maxScrollExtent;
    final rawProgress = maxExtent <= 0
        ? 0.0
        : (notification.metrics.pixels / maxExtent).clamp(0.0, 1.0);
    final nextProgress = rawProgress >= 0.98 ? 1.0 : rawProgress;
    if (nextProgress <= _highestProgress + 0.0001) {
      return false;
    }

    _highestProgress = nextProgress;
    final shouldPersist =
        nextProgress >= 1.0 || nextProgress >= _lastSavedProgress + 0.05;
    if (!shouldPersist) {
      return false;
    }

    _lastSavedProgress = nextProgress;
    AppScope.of(context).setDevotionalProgress(
      widget.devotional.id,
      activeDate: _activeDate,
      progress: nextProgress,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingScale = AppScope.of(context).fontScale;
    final d = widget.devotional;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DevotionalPlayerScreen(devotional: widget.devotional),
            ),
          );
        },
        icon: const Icon(Icons.headphones_rounded),
        label: const Text('Listen & Reflect'),
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          slivers: [
            // ── Gradient header ───────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: _indigo,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Theme badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🌿  ${d.theme.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.title,
                            style: TextStyle(
                              fontSize: 24 * readingScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.scriptureReference,
                            style: TextStyle(
                              fontSize: (13 * readingScale).clamp(13, 18),
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 📖 Scripture
                  ReadingTextScale(
                    child: ScriptureCard(
                      scripture: d.scripture,
                      reference: d.scriptureReference,
                      accentColor: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔑 Insight sections label
                  ReadingTextScale(
                    child: Row(
                      children: [
                        const Text('🔑', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Insight',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Expandable insight tiles
                  ...d.sections.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReadingTextScale(
                          child: InsightSectionTile(
                            section: e.value,
                            accentColor: _accentColor,
                            initiallyExpanded: e.key == 0,
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),

                  // ✨ Final Revelation
                  ReadingTextScale(
                    child: FinalRevelationCard(text: d.finalRevelation),
                  ),
                  const SizedBox(height: 28),

                  // 🌅 Reflection Questions
                  ReadingTextScale(
                    child: Row(
                      children: [
                        const Text('🌅', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Reflection',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...d.reflectionQuestions.asMap().entries.map(
                        (e) => ReadingTextScale(
                          child: _ReflectionQuestion(
                            number: e.key + 1,
                            question: e.value,
                            controller: _reflectionCtrls[e.key],
                          ),
                        ),
                      ),
                  const SizedBox(height: 28),

                  // 🙏 Closing Prayer
                  ReadingTextScale(
                    child: ClosingPrayerCard(
                      prayer: d.prayer,
                      devotionalTitle: d.title,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Actions ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: _accentColor,
                            side: BorderSide(
                                color: _accentColor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saved ? null : _saveToJournal,
                          icon: Icon(
                            _saved
                                ? Icons.check_circle_rounded
                                : Icons.bookmark_add_rounded,
                            size: 18,
                          ),
                          label: Text(_saved ? 'Saved!' : 'Save to Journal'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _saved ? Colors.green : _indigo,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reflection question with expandable text-entry ─────────────────────────

class _ReflectionQuestion extends StatefulWidget {
  const _ReflectionQuestion({
    required this.number,
    required this.question,
    required this.controller,
  });

  final int number;
  final String question;
  final TextEditingController controller;

  @override
  State<_ReflectionQuestion> createState() => _ReflectionQuestionState();
}

class _ReflectionQuestionState extends State<_ReflectionQuestion> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const amber = Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _open
              ? amber.withValues(alpha: 0.07)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
          border: Border.all(
            color: _open
                ? amber.withValues(alpha: 0.35)
                : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _open = !_open),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: amber.withValues(alpha: 0.15),
                      border: Border.all(color: amber.withValues(alpha: 0.40)),
                    ),
                    child: Text(
                      '${widget.number}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: amber,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.edit_outlined,
                    size: 18,
                    color: amber.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              TextField(
                controller: widget.controller,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write your reflection here…',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withValues(alpha: 0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
