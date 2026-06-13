import 'package:flutter/material.dart';
import '../../../app/main_shell.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/animated_stagger_list.dart';
import '../../../data/bible/book_catalog.dart';
import '../../bible/view/reading_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => MainShell.switchTo(0),
              ),
              title: const Text('⭐ Saved Verses'),
            ),
      body: ValueListenableBuilder(
        valueListenable: state.favoritesRepo.listenable,
        builder: (context, box, _) {
          final items = state.favoritesRepo.list();

          if (items.isEmpty) {
            return const Center(child: Text('No saved verses yet'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedStaggerItem(
                index: index,
                child: ListTile(
                  title: Text(
                    item.display,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: item.note == null || item.note!.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.note!,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_note, size: 20),
                    tooltip: 'Update Note',
                    onPressed: () async {
                      final note =
                          await _promptNote(context, existing: item.note);
                      if (note == null) return;
                      await state.favoritesRepo.upsertNote(
                        translation: item.translation ?? state.translation,
                        ref: item.ref,
                        display: item.display,
                        note: note,
                      );
                    },
                  ),
                  onTap: () {
                    try {
                      final book = BookCatalog.byId(item.ref.bookId);
                      AppRouter.push(
                        context,
                        ReadingScreen(
                          book: book,
                          chapter: item.ref.chapter,
                          initialVerse:
                              item.ref.verse, // Pass verse to auto-scroll
                        ),
                        transition: AppTransitionType.slideRight,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Could not find book: ${item.ref.bookId}'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _promptNote(BuildContext context, {String? existing}) async {
    final c = TextEditingController(text: existing ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Note'),
          content: TextField(
            controller: c,
            decoration:
                const InputDecoration(hintText: 'Write a short note...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('Save')),
          ],
        );
      },
    );
    c.dispose();
    return result;
  }
}
