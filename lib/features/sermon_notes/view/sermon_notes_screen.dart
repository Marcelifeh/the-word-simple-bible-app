import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/state/app_state.dart';
import 'sermon_editor_screen.dart';
import 'sermon_review_screen.dart';
import '../../../core/navigation/app_router.dart' show AppRouter;
import '../model/sermon_note.dart';
import '../utils/scripture_parser.dart';

class SermonNotesScreen extends StatefulWidget {
  const SermonNotesScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends State<SermonNotesScreen> {
  Future<void>? _repoReadyFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = AppScope.of(context).sermonNoteRepo;

    _repoReadyFuture ??= repository.ensureInitialized();

    final content = FutureBuilder<void>(
      future: _repoReadyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to open sermon notes right now.',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ValueListenableBuilder(
          valueListenable: repository.listenable,
          builder: (context, _, __) {
            final notes = repository.list();
            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text('No notes yet.', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Tap the + button to create a sermon note.'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final scriptureCount =
                    ScriptureParser.extractScriptures(note.content).length;
                final hasAudio = note.audioPath?.isNotEmpty ?? false;
                final audioLabel = note.audioDuration == null
                    ? 'Audio'
                    : 'Audio ${_formatDuration(note.audioDuration!)}';
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled Note',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.preacher.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(note.preacher),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMd().format(note.date),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (hasAudio || scriptureCount > 0) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (hasAudio)
                                _SermonMetaChip(
                                  icon: Icons.mic,
                                  label: audioLabel,
                                  color: theme.colorScheme.primary,
                                ),
                              if (scriptureCount > 0)
                                _SermonMetaChip(
                                  icon: Icons.menu_book,
                                  label:
                                      '$scriptureCount scripture${scriptureCount == 1 ? '' : 's'}',
                                  color: theme.colorScheme.secondary,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      AppRouter.push(
                        context,
                        SermonEditorScreen(note: note),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Review sermon',
                          icon: const Icon(Icons.insights_rounded),
                          onPressed: () {
                            AppRouter.push(
                              context,
                              SermonReviewScreen(note: note),
                            );
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value != 'delete') return;
                            final confirmed = await _confirmDelete(note);
                            if (!confirmed || !context.mounted) return;
                            await repository.deleteNote(note.id);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    final fab = FloatingActionButton.extended(
      onPressed: () {
        AppRouter.push(
          context,
          const SermonEditorScreen(),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('New Note'),
    );

    if (widget.isEmbedded) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: fab,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sermon Notes'),
      ),
      body: content,
      floatingActionButton: fab,
    );
  }

  Future<bool> _confirmDelete(SermonNote note) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete sermon note?'),
          content: Text(
            'Delete "${note.title.isNotEmpty ? note.title : 'Untitled Note'}"? '
            'This will also remove the linked local sermon audio from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SermonMetaChip extends StatelessWidget {
  const _SermonMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
