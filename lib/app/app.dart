import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';

import '../core/navigation/app_router.dart';
import '../core/theme/app_theme.dart';
import '../shared/state/app_state.dart';
import 'main_shell.dart';
import '../features/splash/view/splash_screen.dart';

class SimpleBibleApp extends StatelessWidget {
  const SimpleBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          title: AppBranding.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(state),
          darkTheme: AppTheme.dark(state),
          themeMode: state.themeMode,
          home: SplashScreen(nextScreen: MainShell()),
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            final data = MediaQuery.of(context);
            return MediaQuery(
              data: data.copyWith(
                textScaler: TextScaler.linear(state.fontScale),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
