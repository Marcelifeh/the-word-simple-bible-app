import 'package:flutter/material.dart';

import '../services/whisper_model_installer.dart';

class WhisperModelCard extends StatelessWidget {
  const WhisperModelCard(
      {super.key, required this.installer, this.enabled = true});

  final WhisperModelInstaller installer;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: installer,
        builder: (context, _) {
          final theme = Theme.of(context);
          final ready = installer.state == WhisperModelState.ready;
          final failed = installer.state == WhisperModelState.failed;
          final active = installer.busy;
          return Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                          ready
                              ? Icons.verified_outlined
                              : Icons.offline_bolt_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('Your words. Kept private.',
                              style: theme.textTheme.titleMedium)),
                    ]),
                    const SizedBox(height: 10),
                    const Text(
                        'Install English speech recognition once, then transcribe '
                        'sermon recordings on this device—even without internet.'),
                    const SizedBox(height: 14),
                    Semantics(
                        liveRegion: true,
                        child: Text(installer.state.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: failed
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ))),
                    if (active) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value:
                              installer.state == WhisperModelState.downloading
                                  ? installer.progress
                                  : null),
                    ],
                    if (installer.state == WhisperModelState.downloading) ...[
                      const SizedBox(height: 6),
                      Text(
                          '${(installer.receivedBytes / 1000000).toStringAsFixed(1)} / '
                          '${(installer.artifact.bytes / 1000000).toStringAsFixed(0)} MB '
                          '· ${(installer.progress * 100).floor()}%'),
                    ],
                    if (installer.message != null) ...[
                      const SizedBox(height: 8),
                      Text(installer.message!),
                    ],
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (!ready && !active)
                        FilledButton.icon(
                          onPressed: enabled ? installer.install : null,
                          icon: Icon(
                              failed ? Icons.refresh : Icons.download_outlined),
                          label:
                              Text(failed ? 'Retry' : 'Install Offline Model'),
                        ),
                      if (installer.canCancel)
                        TextButton(
                            onPressed: installer.cancel,
                            child: const Text('Cancel Download')),
                      if (ready || failed)
                        TextButton.icon(
                          onPressed:
                              enabled && !active ? installer.delete : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete Model'),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        '148 MB download · Allow about 310 MB free for installation. '
                        'Wi-Fi recommended. Audio is never uploaded by offline transcription.',
                        style: theme.textTheme.bodySmall),
                  ]),
            ),
          );
        },
      );
}
