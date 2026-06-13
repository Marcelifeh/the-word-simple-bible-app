import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import 'voice_selection_screen.dart';

/// Audio & Narration Settings hub — clean, minimal tiles that navigate to sub-screens
class AudioNarrationSettings extends StatefulWidget {
  const AudioNarrationSettings({super.key});

  @override
  State<AudioNarrationSettings> createState() => _AudioNarrationSettingsState();
}

class _AudioNarrationSettingsState extends State<AudioNarrationSettings> {
  static const _sleepOptions = [0, 10, 20, 30, 45, 60];
  int _sleepTimer = 0;

  @override
  Widget build(BuildContext context) {
    final state      = AppScope.of(context);
    final controller = state.narrationController;

    return Scaffold(
      appBar: AppBar(title: const Text('Audio & Narration'), centerTitle: true),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final prefs = controller.preferences;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── Voice ──────────────────────────────────────────────────
              _SectionHeader(label: '🎙  Voice'),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.record_voice_over_rounded)),
                title: const Text('Voice Selection'),
                subtitle: Text(
                  prefs.savedVoice?.displayName ?? 'Default System Voice',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceSelectionScreen(),
                  ),
                ),
              ),

              // ── Speed ─────────────────────────────────────────────────
              _SectionHeader(label: '⚡  Speed'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.slow_motion_video, size: 18),
                    Expanded(
                      child: Slider(
                        min: 0.3,
                        max: 1.5,
                        divisions: 24,
                        value: prefs.speed,
                        label: _speedLabel(prefs.speed),
                        onChanged: controller.setSpeed,
                      ),
                    ),
                    const Icon(Icons.fast_forward, size: 18),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final s in [0.42, 0.72, 0.90, 1.0])
                      _SpeedChip(
                        label: '${s}x',
                        selected: (prefs.speed - s).abs() < 0.01,
                        onTap: () => controller.setSpeed(s),
                        note: _speedNote(s),
                      ),
                  ],
                ),
              ),

              // ── Sleep Timer ────────────────────────────────────────────
              _SectionHeader(label: '🌙  Sleep Timer'),
              ListTile(
                title: const Text('Stop audio after'),
                trailing: DropdownButton<int>(
                  value: _sleepTimer,
                  underline: const SizedBox.shrink(),
                  items: _sleepOptions.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(v == 0 ? 'Off' : '$v min'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _sleepTimer = v ?? 0),
                ),
              ),

              // ── Reading Experience ─────────────────────────────────────
              _SectionHeader(label: '📖  Reading Experience'),
              SwitchListTile(
                title: const Text('Auto Scroll'),
                subtitle: const Text('Follow along while narrating'),
                value: prefs.autoScroll,
                onChanged: controller.setAutoScroll,
              ),
              SwitchListTile(
                title: const Text('Highlight Verses'),
                subtitle: const Text('Glow on the current verse'),
                value: prefs.highlightVerses,
                onChanged: controller.setHighlightVerses,
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _speedLabel(double s) {
    if (s <= 0.42) return '${s.toStringAsFixed(2)}x — Devotional';
    if (s <= 0.72) return '${s.toStringAsFixed(2)}x — Prayer';
    if (s <= 0.90) return '${s.toStringAsFixed(2)}x — Reading';
    return '${s.toStringAsFixed(2)}x — Normal';
  }

  String _speedNote(double s) {
    if (s == 0.42) return 'Devotional';
    if (s == 0.72) return 'Prayer';
    if (s == 0.90) return 'Reading';
    return 'Normal';
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String note;

  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(note,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}
