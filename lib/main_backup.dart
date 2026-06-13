import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'shared/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final appState = AppState();
  await appState.init();

  runApp(AppScope(state: appState, child: const SimpleBibleApp()));
}
