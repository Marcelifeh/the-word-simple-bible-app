import 'package:flutter/material.dart';

import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../shared/state/app_state.dart';
import '../model/memory_verse.dart';

const _suggestedCategories = <String>[
  'Faith',
  'Prayer',
  'Peace',
  'Hope',
  'Love',
  'Wisdom',
];

Future<MemoryVerse?> showAddToMemorySheet(
  BuildContext context, {
  required MemoryVerseDraft draft,
}) async {
  final repository = AppScope.of(context).memoryVerseRepo;
  final existing = repository.findByDedupeKey(draft.dedupeKey);
  final result = await showModalBottomSheet<MemoryVerse>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddToMemorySheet(
      draft: draft,
      existing: existing,
    ),
  );

  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Added to Hide God\'s Word.'
              : 'Memory verse updated.',
        ),
      ),
    );
  }
  return result;
}

class _AddToMemorySheet extends StatefulWidget {
  const _AddToMemorySheet({
    required this.draft,
    required this.existing,
  });

  final MemoryVerseDraft draft;
  final MemoryVerse? existing;

  @override
  State<_AddToMemorySheet> createState() => _AddToMemorySheetState();
}

class _AddToMemorySheetState extends State<_AddToMemorySheet> {
  late MemoryDifficulty _difficulty;
  late Set<String> _categories;
  final _customCategoryController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.existing?.difficulty ?? widget.draft.difficulty;
    _categories = {
      ...(widget.existing?.categories ?? widget.draft.categories),
    };
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  void _addCustomCategory() {
    final value = _customCategoryController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _categories.add(value);
      _customCategoryController.clear();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final source = widget.draft;
      final saved = await AppScope.of(context).memoryVerseRepo.saveDraft(
            MemoryVerseDraft(
              bookId: source.bookId,
              bookName: source.bookName,
              chapter: source.chapter,
              startVerse: source.startVerse,
              endVerse: source.endVerse,
              translation: source.translation,
              text: BibleTextSanitizer.clean(source.text),
              source: source.source,
              categories: _categories.toList(growable: false),
              collectionIds: source.collectionIds,
              difficulty: _difficulty,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final existing = widget.existing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_alt_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    existing == null
                        ? 'Hide this verse in your heart'
                        : 'Update memory verse',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${widget.draft.bookName} ${widget.draft.chapter}:'
              '${widget.draft.startVerse}'
              '${widget.draft.endVerse == widget.draft.startVerse ? '' : '-${widget.draft.endVerse}'}'
              ' · ${widget.draft.translation.name.toUpperCase()}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              BibleTextSanitizer.clean(widget.draft.text),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Practice difficulty',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<MemoryDifficulty>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: MemoryDifficulty.easy,
                  label: Text('Easy'),
                ),
                ButtonSegment(
                  value: MemoryDifficulty.normal,
                  label: Text('Normal'),
                ),
                ButtonSegment(
                  value: MemoryDifficulty.hard,
                  label: Text('Hard'),
                ),
              ],
              selected: {_difficulty},
              onSelectionChanged: (selection) {
                setState(() => _difficulty = selection.first);
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Categories',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in _suggestedCategories)
                  FilterChip(
                    label: Text(category),
                    selected: _categories.contains(category),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _categories.add(category);
                        } else {
                          _categories.remove(category);
                        }
                      });
                    },
                  ),
                for (final category in _categories
                    .where((value) => !_suggestedCategories.contains(value)))
                  InputChip(
                    label: Text(category),
                    onDeleted: () {
                      setState(() => _categories.remove(category));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customCategoryController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addCustomCategory(),
              decoration: InputDecoration(
                labelText: 'Custom category',
                suffixIcon: IconButton(
                  tooltip: 'Add category',
                  onPressed: _addCustomCategory,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology_alt_rounded),
                label:
                    Text(existing == null ? 'Add to Memory' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
