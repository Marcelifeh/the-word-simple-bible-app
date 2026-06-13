import 'package:flutter/material.dart';

import '../services/narration_controller.dart';
import '../models/narration_state.dart';

class NarrationControls extends StatelessWidget {
  final NarrationController controller;
  
  const NarrationControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.syncState]),
      builder: (context, _) {
        final session = controller.currentSession;
        if (session == null) return const SizedBox.shrink();

        final status = session.status;
        final isPlaying = status == NarrationStatus.playing;
        final isLoading = status == NarrationStatus.loading;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.stop_rounded),
              onPressed: () => controller.stop(),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                onPressed: () {
                  if (isPlaying) {
                    controller.pause();
                  } else {
                    controller.resume();
                  }
                },
              ),
          ],
        );
      },
    );
  }
}
