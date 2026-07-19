import 'package:flutter/material.dart';

import '../../../domain/entities/bible_translation.dart';
import '../../../core/utils/scripture_reference_parser.dart';
import '../../../shared/state/app_state.dart';
import '../model/memory_collection.dart';
import '../model/memory_verse.dart';
import '../services/memory_passage_resolver.dart';
import '../widgets/add_to_memory_sheet.dart';

class MemoryCollectionDetailScreen extends StatefulWidget {
  const MemoryCollectionDetailScreen({
    super.key,
    required this.collection,
  });

  final MemoryCollection collection;

  @override
  State<MemoryCollectionDetailScreen> createState() =>
      _MemoryCollectionDetailScreenState();
}

class _MemoryCollectionDetailScreenState
    extends State<MemoryCollectionDetailScreen> {
  BibleTranslation? _translation;
  Future<List<ResolvedMemoryPassage>>? _passages;
  bool _addingAll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selected = AppScope.of(context).translation;
    if (_translation == selected) return;
    _translation = selected;
    _passages = _resolveAll(selected);
  }

  Future<List<ResolvedMemoryPassage>> _resolveAll(
    BibleTranslation translation,
  ) async {
    final state = AppScope.of(context);
    final resolver = MemoryPassageResolver(state.assetBibleRepo);
    final passages = <ResolvedMemoryPassage>[];
    for (final reference in widget.collection.references) {
      passages.add(
        await resolver.resolve(
          reference: ScriptureReferenceRange(
            bookId: reference.bookId,
            bookName: reference.bookName,
            chapter: reference.chapter,
            startVerse: reference.startVerse,
            endVerse: reference.endVerse,
          ),
          translation: translation,
        ),
      );
    }
    return passages;
  }

  Future<void> _addOne(ResolvedMemoryPassage passage) async {
    if (!passage.isAvailable) return;
    await showAddToMemorySheet(
      context,
      draft: _collectionDraft(passage, widget.collection),
    );
  }

  Future<void> _addAll(List<ResolvedMemoryPassage> passages) async {
    if (_addingAll) return;
    final available = passages.where((passage) => passage.isAvailable).toList();
    if (available.isEmpty) return;
    setState(() => _addingAll = true);
    try {
      await AppScope.of(context).memoryVerseRepo.saveCollectionDrafts(
            available
                .map(
                  (passage) => _collectionDraft(passage, widget.collection),
                )
                .toList(growable: false),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${available.length} collection passages added or updated.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = AppScope.of(context).memoryVerseRepo;
    final members = repository
        .list()
        .where((verse) => verse.collectionIds.contains(widget.collection.id))
        .toList(growable: false);
    final established =
        members.where((verse) => verse.schedule.hasReachedEstablished).length;
    final due = members
        .where((verse) => repository.due().any((due) => due.id == verse.id))
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.title)),
      body: FutureBuilder<List<ResolvedMemoryPassage>>(
        future: _passages,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('This collection could not be opened.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final passages = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.collection.description,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Text(
                '${members.length} of ${widget.collection.references.length} '
                'added · $established established · $due due',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addingAll ? null : () => _addAll(passages),
                icon: const Icon(Icons.playlist_add_rounded),
                label: Text(_addingAll ? 'Adding...' : 'Add Available Verses'),
              ),
              const SizedBox(height: 22),
              for (final passage in passages) ...[
                _CollectionPassageTile(
                  passage: passage,
                  isAdded: repository.findByDedupeKey(
                        _collectionDraft(
                          passage,
                          widget.collection,
                        ).dedupeKey,
                      ) !=
                      null,
                  onAdd: () => _addOne(passage),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CollectionPassageTile extends StatelessWidget {
  const _CollectionPassageTile({
    required this.passage,
    required this.isAdded,
    required this.onAdd,
  });

  final ResolvedMemoryPassage passage;
  final bool isAdded;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = passage.translation.label.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            passage.reference.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            passage.isAvailable
                ? passage.text
                : 'This passage is not currently available in $language. '
                    'Choose another translation to add it.',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: isAdded
                ? const Chip(label: Text('Added'))
                : TextButton.icon(
                    onPressed: passage.isAvailable ? onAdd : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
          ),
        ],
      ),
    );
  }
}

MemoryVerseDraft _collectionDraft(
  ResolvedMemoryPassage passage,
  MemoryCollection collection,
) {
  return MemoryVerseDraft(
    bookId: passage.reference.bookId,
    bookName: passage.reference.bookName,
    chapter: passage.reference.chapter,
    startVerse: passage.reference.startVerse,
    endVerse: passage.reference.endVerse,
    translation: passage.translation,
    text: passage.text,
    source: MemoryVerseSource.collection,
    categories: <String>[collection.theme],
    collectionIds: <String>[collection.id],
  );
}
