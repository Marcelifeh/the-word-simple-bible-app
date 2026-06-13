import 'package:flutter/material.dart';

import '../services/narration_controller.dart';
import '../models/narration_state.dart';
import 'narration_controls.dart';

class NarrationBar extends StatelessWidget {
  final NarrationController controller;

  const NarrationBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.syncState]),
      builder: (context, _) {
        final session = controller.currentSession;
        if (session == null || session.status == NarrationStatus.idle || session.status == NarrationStatus.error) {
          return const SizedBox.shrink();
        }

        final syncState = controller.syncState.value;

        return Material(
          elevation: 8,
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  const Icon(Icons.multitrack_audio_rounded),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Narrating ${session.sourceType.name}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          '${session.mode.name} mode • ${(syncState.progress * 100).round()}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (session.segments.isNotEmpty && session.currentIndex < session.segments.length)
                          Text(
                            session.segments[session.currentIndex].text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: syncState.progress),
                      ],
                    ),
                  ),
                  PopupMenuButton<double>(
                    tooltip: 'Playback speed',
                    icon: const Icon(Icons.speed),
                    initialValue: controller.preferences.speed,
                    onSelected: controller.setSpeed,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 0.75, child: Text('0.75x')),
                      PopupMenuItem(value: 1.0, child: Text('1.0x')),
                      PopupMenuItem(value: 1.25, child: Text('1.25x')),
                      PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
                  ),
                  IconButton(
                    tooltip: syncState.autoScroll
                        ? 'Disable auto-scroll'
                        : 'Enable auto-scroll',
                    onPressed: () => controller.setAutoScroll(!syncState.autoScroll),
                    icon: Icon(
                      syncState.autoScroll
                          ? Icons.swap_vert_circle_outlined
                          : Icons.swap_vert,
                    ),
                  ),
                  NarrationControls(controller: controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
