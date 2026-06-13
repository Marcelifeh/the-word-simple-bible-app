import 'dart:async';

import 'package:flutter/widgets.dart';

import 'narration_controller.dart';

class NarrationLifecycleObserver with WidgetsBindingObserver {
  NarrationLifecycleObserver(this._controller);

  final NarrationController _controller;
  bool _attached = false;

  void attach() {
    if (_attached) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  void detach() {
    if (!_attached) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_controller.isPlaying) {
          unawaited(_controller.pause());
        }
        break;
      case AppLifecycleState.detached:
        unawaited(_controller.stop());
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }
}