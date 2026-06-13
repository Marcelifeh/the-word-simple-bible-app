import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../model/sermon_note.dart';

class SermonAudioPlayerCard extends StatefulWidget {
  const SermonAudioPlayerCard({
    super.key,
    required this.note,
  });

  final SermonNote note;

  @override
  State<SermonAudioPlayerCard> createState() => SermonAudioPlayerCardState();
}

class SermonAudioPlayerCardState extends State<SermonAudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> seekTo(Duration position) async {
    if (!_ready) return;
    await _player.seek(position);
    await _player.play();
  }

  Future<void> _loadAudio() async {
    final path = widget.note.audioPath;
    if (path == null || path.isEmpty) {
      setState(() => _error = 'No sermon audio is attached to this note.');
      return;
    }

    try {
      if (path.startsWith('http://') ||
          path.startsWith('https://') ||
          path.startsWith('blob:')) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _error = 'Audio not available for playback.';
      });
    }
  }

  Future<void> _togglePlayback(bool playing) async {
    if (!_ready) return;
    if (playing) {
      await _player.pause();
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_ready) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.audio_file_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error ?? 'Loading sermon audio...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.graphic_eq_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sermon Recording',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 34,
                      ),
                      tooltip: playing ? 'Pause' : 'Play',
                      onPressed: () => _togglePlayback(playing),
                    );
                  },
                ),
              ],
            ),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = widget.note.audioDuration ??
                    _player.duration ??
                    Duration.zero;
                final maxMs = duration.inMilliseconds <= 0
                    ? 1.0
                    : duration.inMilliseconds.toDouble();
                final value =
                    position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

                return Column(
                  children: [
                    Slider(
                      value: value,
                      max: maxMs,
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position)),
                        Text(_formatDuration(duration)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
