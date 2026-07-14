import 'package:flutter/material.dart';

import '../state/app_state.dart';

class ReadingTextScale extends StatelessWidget {
  const ReadingTextScale({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = AppScope.of(context).fontScale;
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}
