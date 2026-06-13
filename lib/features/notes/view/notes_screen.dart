import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/animated_stagger_list.dart';
import '../../bible/view/reading_screen.dart';
import '../../../data/bible/book_catalog.dart';
import '../model/verse_note.dart';
import '../../../core/utils/bible_text_sanitizer.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _filterIndex = 0; // 0 = All, 1 = Highlights, 2 = Notes

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final listenable = state.notesRepo.listenable;

    // If the box isn't open yet, show a loading indicator
    if (listenable == null) {
      return widget.isEmbedded
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(title: const Text('Notes & Highlights')),
              body: const Center(child: CircularProgressIndicator()),
            );
    }

    return ValueListenableBuilder<Box<VerseNote>>(
      valueListenable: listenable,
      builder: (context, box, _) {
        final allNotes = box.values.toList();
        allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final filteredNotes = allNotes.where((n) {
          if (_filterIndex == 1) return n.isHighlightOnly;
          if (_filterIndex == 2) return n.isNote;
          return true;
        }).toList();

        final content = Column(
          children: [
            if (widget.isEmbedded)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Highlights')),
                    ButtonSegment(value: 2, label: Text('Notes')),
                  ],
                  selected: {_filterIndex},
                  onSelectionChanged: (set) =>
                      setState(() => _filterIndex = set.first),
                ),
              ),
            Expanded(
              child: filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📝', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_filterIndex == 1 ? 'highlights' : _filterIndex == 2 ? 'notes' : 'items'} yet.',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Long-press a verse while reading to add one.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredNotes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        final parts = note.verseId.split('-');
                        String friendlyTitle = note.verseId;
                        String? bookId;
                        int? chapter;
                        int? verse;

                        if (parts.length >= 3) {
                          bookId = parts.sublist(0, parts.length - 2).join('-');
                          chapter = int.tryParse(parts[parts.length - 2]);
                          verse = int.tryParse(parts.last);
                          if (chapter != null && verse != null) {
                            final bookIdValue = bookId;
                            final book = BookCatalog.books.firstWhere(
                              (b) =>
                                  b.id.toLowerCase() ==
                                  bookIdValue.toLowerCase(),
                              orElse: () => BookCatalog.books.first,
                            );
                            friendlyTitle = '${book.name} $chapter:$verse';
                          }
                        }

                        return AnimatedStaggerItem(
                          index: index,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Color(note.color).withValues(alpha: 0.3),
                              child: Icon(
                                note.isHighlightOnly
                                    ? Icons.border_color
                                    : Icons.edit_note,
                                color: Color(note.color),
                              ),
                            ),
                            title: Text(
                              friendlyTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber),
                            ),
                            subtitle: note.isNote
                                ? Text(
                                    BibleTextSanitizer.clean(note.text),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(height: 1.4),
                                  )
                                : const Text('Highlight only',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  state.notesRepo.delete(note.verseId),
                            ),
                            onTap: () {
                              if (bookId != null &&
                                  chapter != null &&
                                  verse != null) {
                                final bookIdValue = bookId;
                                final chapterValue = chapter;
                                final verseValue = verse;
                                final book = BookCatalog.books.firstWhere(
                                  (b) =>
                                      b.id.toLowerCase() ==
                                      bookIdValue.toLowerCase(),
                                  orElse: () => BookCatalog.books.first,
                                );
                                AppRouter.push(
                                  context,
                                  ReadingScreen(
                                    book: book,
                                    chapter: chapterValue,
                                    initialVerse: verseValue,
                                  ),
                                  transition: AppTransitionType.slideRight,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

        if (widget.isEmbedded) return content;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notes & Highlights'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Highlights')),
                    ButtonSegment(value: 2, label: Text('Notes')),
                  ],
                  selected: {_filterIndex},
                  onSelectionChanged: (set) =>
                      setState(() => _filterIndex = set.first),
                ),
              ),
            ),
          ),
          body: content,
        );
      },
    );
  }
}
