import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'shared/state/app_state.dart';
import 'features/notes/model/verse_note.dart';
import 'features/tracts/model/user_tract.dart';
import 'features/devotional/model/devotional_journal_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(VerseNoteAdapter());
  Hive.registerAdapter(UserTractAdapter());
  Hive.registerAdapter(DevotionalJournalEntryAdapter());

  final appState = AppState();
  await appState.init();

  runApp(AppScope(state: appState, child: const SimpleBibleApp()));
}
