import 'package:flutter/material.dart';

import '../../favorites/view/favorites_screen.dart';
import '../../notes/view/notes_screen.dart';
import '../../sermon_notes/view/sermon_notes_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Journal'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Favorites', icon: Icon(Icons.star)),
              Tab(text: 'Notes', icon: Icon(Icons.edit_note)),
              Tab(text: 'Sermons', icon: Icon(Icons.edit_document)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FavoritesScreen(isEmbedded: true),
            NotesScreen(isEmbedded: true),
            SermonNotesScreen(isEmbedded: true),
          ],
        ),
      ),
    );
  }
}
