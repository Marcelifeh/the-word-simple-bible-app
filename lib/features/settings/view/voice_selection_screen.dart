import 'package:flutter/material.dart';

import '../../../core/narration/models/narration_state.dart';
import '../../../core/narration/models/narration_voice.dart';
import '../../../core/narration/models/saved_voice.dart';
import '../../../shared/state/app_state.dart';

/// Voice Selection — Premium redesign with quality tiers and preview
class VoiceSelectionScreen extends StatefulWidget {
  const VoiceSelectionScreen({super.key});

  @override
  State<VoiceSelectionScreen> createState() => _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends State<VoiceSelectionScreen> {
  bool _previewing = false;

  /// Map locale prefix → display language group
  static const _languageGroups = <String, String>{
    'en': 'English',
    'ha': 'Hausa',
    'ig': 'Igbo',
    'yo': 'Yoruba',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final controller = state.narrationController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Selection'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final voices = controller.availableVoices;
          final currentVoice = controller.preferences.savedVoice;

          if (voices.isEmpty) {
            return const _EmptyVoicesMessage();
          }

          // Build grouped sections
          final grouped = _groupVoices(voices);

          return CustomScrollView(
            slivers: [
              // Current voice banner
              SliverToBoxAdapter(
                child: _CurrentVoiceBanner(
                  voice: currentVoice,
                  previewing: _previewing,
                  onPreview: currentVoice == null
                      ? null
                      : () => _preview(context, currentVoice),
                ),
              ),

              // Quality tip
              const SliverToBoxAdapter(child: _QualityTipCard()),

              // Language groups
              for (final entry in grouped.entries) ...[
                SliverToBoxAdapter(
                  child: _GroupHeader(label: entry.key),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final voice = entry.value[i];
                      final isSelected = currentVoice?.id == voice.id;
                      return _VoiceTile(
                        voice: voice,
                        isSelected: isSelected,
                        onSelect: () => _selectVoice(context, voice, entry.key),
                        onPreview: () => _previewVoice(context, voice),
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  void _selectVoice(BuildContext ctx, NarrationVoice voice, String langGroup) {
    final saved = SavedVoice(
      id: voice.id,
      locale: voice.locale,
      displayName: '$langGroup · ${_cleanName(voice.name)}',
      provider: voice.provider,
    );
    AppScope.of(ctx).narrationController.setVoice(saved);
  }

  Future<void> _preview(BuildContext ctx, SavedVoice voice) async {
    final controller = AppScope.of(ctx).narrationController;
    if (_previewing) return;
    setState(() => _previewing = true);
    await controller.previewVoice(voice);
    if (mounted) setState(() => _previewing = false);
  }

  Future<void> _previewVoice(BuildContext ctx, NarrationVoice voice) async {
    final saved = SavedVoice(
      id: voice.id,
      locale: voice.locale,
      displayName: _cleanName(voice.name),
      provider: voice.provider,
    );
    await _preview(ctx, saved);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Map<String, List<NarrationVoice>> _groupVoices(List<NarrationVoice> voices) {
    final result = <String, List<NarrationVoice>>{};
    for (final v in voices) {
      final groupLabel = _languageGroups.entries
          .firstWhere(
            (e) => v.locale.toLowerCase().startsWith(e.key),
            orElse: () => const MapEntry('other', 'Other'),
          )
          .value;
      result.putIfAbsent(groupLabel, () => []).add(v);
    }
    // Preserve display order
    const order = ['English', 'Hausa', 'Igbo', 'Yoruba', 'Other'];
    return Map.fromEntries(
      order.where(result.containsKey).map((k) => MapEntry(k, result[k]!)),
    );
  }

  String _cleanName(String name) {
    // Strip locale suffix and "Google" prefix for display
    return name
        .replaceAll(RegExp(r'\s*#.*'), '')
        .replaceAll(RegExp(r'\s*-.*'), '')
        .trim();
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CurrentVoiceBanner extends StatelessWidget {
  final SavedVoice? voice;
  final bool previewing;
  final VoidCallback? onPreview;

  const _CurrentVoiceBanner(
      {this.voice, this.previewing = false, this.onPreview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.record_voice_over_rounded,
                color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Voice',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 2),
                Text(
                  voice?.displayName ?? 'Default System Voice',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (onPreview != null)
            FilledButton.tonal(
              onPressed: previewing ? null : onPreview,
              child: previewing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Preview'),
            ),
        ],
      ),
    );
  }
}

class _QualityTipCard extends StatelessWidget {
  const _QualityTipCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'For the best experience, install Google Text-to-Speech from the Play Store and download a High Quality voice in your device Settings → Accessibility → Text-to-Speech.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  final NarrationVoice voice;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const _VoiceTile({
    required this.voice,
    required this.isSelected,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeural = _isNeuralVoice(voice.name);
    final isCloud = voice.provider == VoiceProvider.cloud;
    final providerLabel = _providerLabel(voice);

    Color qualityColor;
    switch (voice.quality) {
      case VoiceQuality.premium:
        qualityColor = Colors.amber.shade800;
        break;
      case VoiceQuality.excellent:
        qualityColor = Colors.green.shade700;
        break;
      case VoiceQuality.good:
        qualityColor = Colors.blue.shade700;
        break;
      case VoiceQuality.standard:
      case VoiceQuality.basic:
        qualityColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return ListTile(
      isThreeLine: voice.recommendedModes.isNotEmpty,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          isSelected ? Icons.check : Icons.volume_up_outlined,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              _cleanName(voice.name),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _Badge(
            label: voice.quality.stars,
            color: qualityColor,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                voice.locale,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isNeural) ...[
                const SizedBox(width: 6),
                Text('•  Neural',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ] else if (isCloud) ...[
                const SizedBox(width: 6),
                Text('•  Cloud',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '•  $providerLabel',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (voice.recommendedModes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Best for:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 8,
              runSpacing: 3,
              children: voice.recommendedModes.map((mode) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _modeLabel(mode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_outline),
        tooltip: 'Preview voice',
        onPressed: onPreview,
        color: theme.colorScheme.primary,
      ),
      onTap: onSelect,
    );
  }

  String _cleanName(String name) {
    return name
        .replaceAll(RegExp(r'\s*#.*'), '')
        .replaceAll(RegExp(r'\s*-[a-z]{2}-[A-Z]{2}.*'), '')
        .trim();
  }

  bool _isNeuralVoice(String name) {
    final n = name.toLowerCase();
    return n.contains('neural') || n.contains('#');
  }

  String _providerLabel(NarrationVoice voice) {
    final name = voice.name.toLowerCase();
    if (name.contains('google') && _isNeuralVoice(voice.name)) {
      return 'Google Neural';
    }
    if (name.contains('google')) {
      return 'Google';
    }
    switch (voice.provider) {
      case VoiceProvider.device:
        return 'Device Voice';
      case VoiceProvider.piper:
        return 'Piper';
      case VoiceProvider.cloud:
        return 'Cloud Voice';
    }
  }

  String _modeLabel(NarrationMode mode) {
    switch (mode) {
      case NarrationMode.reading:
        return 'Reading';
      case NarrationMode.devotional:
        return 'Devotional';
      case NarrationMode.prayer:
        return 'Prayer';
      case NarrationMode.meditation:
        return 'Meditation';
      case NarrationMode.sermon:
        return 'Sermon';
      case NarrationMode.children:
        return 'Children';
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _EmptyVoicesMessage extends StatelessWidget {
  const _EmptyVoicesMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.voice_over_off,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No Voices Found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Install Google Text-to-Speech from the Play Store for the best narration experience.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
