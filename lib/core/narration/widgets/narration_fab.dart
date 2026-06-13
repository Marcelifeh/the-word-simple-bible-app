import 'package:flutter/material.dart';

import '../services/narration_controller.dart';
import '../models/narration_state.dart';

class NarrationFab extends StatelessWidget {
  final NarrationController controller;
  final VoidCallback onPlay;
  
  const NarrationFab({
    super.key,
    required this.controller,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.syncState]),
      builder: (context, _) {
        final session = controller.currentSession;
        final isPlaying = session?.status == NarrationStatus.playing;
        final isLoading = session?.status == NarrationStatus.loading;
        final hasActiveSession = session != null && session.status != NarrationStatus.idle;

        return FloatingActionButton.extended(
          onPressed: () {
            if (hasActiveSession) {
              if (isPlaying) {
                controller.pause();
              } else {
                controller.resume();
              }
            } else {
              onPlay();
            }
          },
          icon: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(isPlaying ? Icons.pause_rounded : Icons.headset_rounded),
          label: Text(isPlaying ? 'Pause' : 'Listen'),
        );
      },
    );
  }
}
