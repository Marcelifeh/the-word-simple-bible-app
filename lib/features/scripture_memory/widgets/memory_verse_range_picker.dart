import 'package:flutter/material.dart';

import '../../../core/utils/scripture_reference_parser.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse.dart';
import '../../../shared/state/app_state.dart';
import '../model/memory_verse.dart';
import '../services/memory_range_selection.dart';
import '../services/memory_passage_resolver.dart';
import 'add_to_memory_sheet.dart';

Future<void> showDevotionalMemoryVersePicker(
  BuildContext context, {
  required String scriptureReference,
  required String category,
}) async {
  const parser = ScriptureReferenceParser();
  final reference = parser.tryParse(scriptureReference);
  if (reference == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('This Scripture reference could not be read.')),
    );
    return;
  }
  final state = AppScope.of(context);
  final translation = state.translation;
  final resolved = await MemoryPassageResolver(
    state.assetBibleRepo,
  ).resolve(reference: reference, translation: translation);
  if (!context.mounted) return;
  final verses = resolved.verses;
  if (!resolved.isAvailable) {
    final language = translation.label.split(' ').first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This passage is not currently available in $language. '
          'Choose another translation to add it.',
        ),
      ),
    );
    return;
  }

  final drafts = reference.isSingleVerse
      ? const MemoryRangeSelection().buildDrafts(
          reference: reference,
          verses: verses,
          selectedVerseNumbers: <int>{reference.startVerse},
          translation: translation,
          source: MemoryVerseSource.devotional,
          categories: <String>[category],
        )
      : await showModalBottomSheet<List<MemoryVerseDraft>>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => MemoryVerseRangePicker(
            reference: reference,
            verses: verses,
            translation: translation,
            category: category,
          ),
        );
  if (drafts == null || drafts.isEmpty || !context.mounted) return;
  for (final draft in drafts) {
    if (!context.mounted) return;
    await showAddToMemorySheet(context, draft: draft);
  }
}

class MemoryVerseRangePicker extends StatefulWidget {
  const MemoryVerseRangePicker({
    super.key,
    required this.reference,
    required this.verses,
    required this.translation,
    required this.category,
  });

  final ScriptureReferenceRange reference;
  final List<Verse> verses;
  final BibleTranslation translation;
  final String category;

  @override
  State<MemoryVerseRangePicker> createState() => _MemoryVerseRangePickerState();
}

class _MemoryVerseRangePickerState extends State<MemoryVerseRangePicker> {
  late final Set<int> _selected =
      widget.verses.map((verse) => verse.ref.verse).toSet();

  void _finish() {
    if (_selected.isEmpty) return;
    final drafts = const MemoryRangeSelection().buildDrafts(
      reference: widget.reference,
      verses: widget.verses,
      selectedVerseNumbers: _selected,
      translation: widget.translation,
      source: MemoryVerseSource.devotional,
      categories: <String>[widget.category],
    );
    Navigator.of(context).pop(drafts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose verses to memorize',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${widget.reference.label} · '
            '${widget.translation.name.toUpperCase()}',
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final verse in widget.verses)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(verse.ref.verse),
                    title: Text('Verse ${verse.ref.verse}'),
                    subtitle: Text(
                      verse.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selected.add(verse.ref.verse);
                        } else {
                          _selected.remove(verse.ref.verse);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _finish,
              icon: const Icon(Icons.psychology_alt_rounded),
              label: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
