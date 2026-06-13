import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/navigation/app_router.dart' show AppRouter;
import '../../../core/utils/env.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../shared/state/app_state.dart';
import '../../bible/view/reading_screen.dart';
import '../../notes/model/verse_note.dart';
import '../model/sermon_note.dart';
import '../services/sermon_ai_service.dart';
import '../utils/scripture_parser.dart';
import '../widgets/sermon_audio_player_card.dart';
import '../widgets/timestamped_note_tile.dart';

class SermonReviewScreen extends StatefulWidget {
  const SermonReviewScreen({
    super.key,
    required this.note,
  });

  final SermonNote note;

  @override
  State<SermonReviewScreen> createState() => _SermonReviewScreenState();
}

class _SermonReviewScreenState extends State<SermonReviewScreen> {
  final GlobalKey<SermonAudioPlayerCardState> _audioKey =
      GlobalKey<SermonAudioPlayerCardState>();
  late SermonNote _note;
  bool _isTranscribing = false;
  bool _isSummarizing = false;
  String _transcriptSearchQuery = '';

  SermonAiService get _sermonAiService =>
      SermonAiService(baseUrl: _sermonApiRoot());

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Future<void> _generateTranscript() async {
    final path = _note.audioPath;
    if (path == null || path.isEmpty || _isTranscribing) return;

    final repository = AppScope.of(context).sermonNoteRepo;
    setState(() => _isTranscribing = true);
    try {
      final result = await _sermonAiService.transcribeAudio(path);
      final updated = _note.copyWith(
        transcript: result.transcript,
        transcriptSegments: result.segments,
        audioDuration: result.duration ?? _note.audioDuration,
      );
      await repository.updateNote(updated);
      if (!mounted) return;
      setState(() => _note = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saved to sermon note.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transcription failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }
  }

  Future<void> _generateSummary() async {
    final transcript = _note.transcript?.trim();
    if (_isSummarizing) return;
    if (transcript == null || transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate transcript first.')),
      );
      return;
    }

    final repository = AppScope.of(context).sermonNoteRepo;
    setState(() => _isSummarizing = true);
    try {
      final result = await _sermonAiService.generateSummary(transcript);
      final updated = _note.copyWith(
        summary: result.summary,
        insight: result.insight,
      );
      await repository.updateNote(updated);
      if (!mounted) return;
      setState(() => _note = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sermon summary saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summary failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  Future<void> _copyInsight() async {
    final text = _sermonInsightText();
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sermon insight copied.')),
    );
  }

  Future<void> _shareInsight() async {
    final text = _sermonInsightText();
    if (text.trim().isEmpty) return;
    await Share.share(
      text,
      subject: _note.title.isEmpty ? 'Sermon Insight' : _note.title,
    );
  }

  void _saveInsightToJournal() {
    final text = _sermonInsightText();
    if (text.trim().isEmpty) return;

    final state = AppScope.of(context);
    final note = VerseNote(
      verseId: 'sermon-insight-${_note.id}',
      text: text,
      color: Theme.of(context).colorScheme.primary.toARGB32(),
      createdAt: DateTime.now(),
    );
    state.notesRepo.save(note);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sermon insight saved to Journal notes.')),
    );
  }

  void _openScripture(LinkedScripture scripture) {
    try {
      final book = BookCatalog.books.firstWhere(
        (candidate) => candidate.id == scripture.bookId,
      );
      AppRouter.push(
        context,
        ReadingScreen(
          book: book,
          chapter: scripture.chapter,
          initialVerse: scripture.startVerse,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open scripture reference.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = _note;
    final hasAudio = note.audioPath?.isNotEmpty ?? false;
    final scriptures = ScriptureParser.extractScriptures(
      '${note.content}\n${note.transcript ?? ''}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sermon Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            note.title.isEmpty ? 'Untitled Sermon' : note.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (note.preacher.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.preacher,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _recordedLabel(note),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SermonAudioPlayerCard(
            key: _audioKey,
            note: note,
          ),
          const SizedBox(height: 16),
          _MetadataWrap(note: note, scriptureCount: scriptures.length),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.schedule,
            title: 'Timestamped Notes',
            trailing: '${note.timestampedNotes.length}',
          ),
          const SizedBox(height: 8),
          if (note.timestampedNotes.isEmpty)
            Text(
              'No timestamped notes yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...note.timestampedNotes.map(
              (item) => TimestampedNoteTile(
                timestamp: item.offset,
                text: _timestampTextFor(item),
                onTap: () => _audioKey.currentState?.seekTo(item.offset),
              ),
            ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.menu_book,
            title: 'Detected Scriptures',
            trailing: '${scriptures.length}',
          ),
          const SizedBox(height: 8),
          if (scriptures.isEmpty)
            Text(
              'No scripture references detected yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scripture in scriptures)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new, size: 16),
                    label: Text(scripture.displayTitle),
                    onPressed: () => _openScripture(scripture),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          _TranscriptCard(
            transcript: note.transcript,
            segments: note.transcriptSegments,
            searchQuery: _transcriptSearchQuery,
            buttonText:
                _isTranscribing ? 'Transcribing...' : 'Generate Transcript',
            disabledText:
                'No audio recording found. Record a sermon first to generate transcript.',
            onPressed:
                hasAudio && !_isTranscribing ? _generateTranscript : null,
            onSeek: (position) => _audioKey.currentState?.seekTo(position),
            onSearchChanged: (value) {
              setState(() => _transcriptSearchQuery = value);
            },
          ),
          const SizedBox(height: 16),
          _SermonInsightCard(
            insight: note.insight,
            fallbackSummary: note.summary,
            buttonText: _isSummarizing
                ? 'Summarizing...'
                : (note.insight?.hasContent ?? false) ||
                        (note.summary?.trim().isNotEmpty ?? false)
                    ? 'Regenerate Summary'
                    : 'Generate Summary',
            disabledText: hasAudio
                ? 'Generate a transcript first to create sermon insights.'
                : 'No audio recording found. Record a sermon first to generate sermon insights.',
            onPressed: hasAudio &&
                    !_isSummarizing &&
                    (note.transcript?.trim().isNotEmpty ?? false)
                ? _generateSummary
                : null,
            onCopy: (note.insight?.hasContent ?? false) ||
                    (note.summary?.trim().isNotEmpty ?? false)
                ? _copyInsight
                : null,
            onShare: (note.insight?.hasContent ?? false) ||
                    (note.summary?.trim().isNotEmpty ?? false)
                ? _shareInsight
                : null,
            onSaveToJournal: (note.insight?.hasContent ?? false) ||
                    (note.summary?.trim().isNotEmpty ?? false)
                ? _saveInsightToJournal
                : null,
            onOpenScripture: _openScripture,
          ),
        ],
      ),
    );
  }

  String _recordedLabel(SermonNote note) {
    final recordedAt = note.recordedAt;
    if (recordedAt == null) {
      return 'Recorded date not available';
    }
    return 'Recorded ${DateFormat.yMMMd().add_jm().format(recordedAt)}';
  }

  String _timestampTextFor(SermonTimestampedNote timestampedNote) {
    if (timestampedNote.text.trim().isNotEmpty) {
      return timestampedNote.text.trim();
    }

    final marker = '[${_formatDuration(timestampedNote.offset)}]';
    final lines = _note.content.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith(marker)) continue;
      final remainder = trimmed.substring(marker.length).trim();
      return remainder.isEmpty ? 'Sermon moment at $marker' : remainder;
    }
    return 'Sermon moment at $marker';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _sermonApiRoot() {
    final explicit = Env.sermonApiUrl;
    if (explicit != null) return _stripPath(explicit);
    return 'http://localhost:8000';
  }

  String _stripPath(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return value.trim();
    }
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : 0,
    ).toString();
  }

  String _sermonInsightText() {
    final insight = _note.insight;
    if (insight != null && insight.hasContent) {
      final buffer = StringBuffer()
        ..writeln(insight.title.trim().isEmpty
            ? (_note.title.isEmpty ? 'Sermon Insight' : _note.title)
            : insight.title.trim());
      if (_note.preacher.trim().isNotEmpty) {
        buffer.writeln('Preacher: ${_note.preacher.trim()}');
      }
      buffer.writeln();
      if (insight.mainTheme.trim().isNotEmpty) {
        buffer
          ..writeln('Main Theme')
          ..writeln(insight.mainTheme.trim())
          ..writeln();
      }
      _writeList(buffer, 'Key Lessons', insight.keyLessons);
      _writeList(buffer, 'Scriptures Mentioned', insight.scripturesMentioned);
      _writeList(buffer, 'Prayer Points', insight.prayerPoints);
      _writeList(buffer, 'Action Steps', insight.actionSteps);
      if (insight.shortDevotional.trim().isNotEmpty) {
        buffer
          ..writeln('Short Devotional')
          ..writeln(insight.shortDevotional.trim())
          ..writeln();
      }
      return buffer.toString().trim();
    }
    return (_note.summary ?? '').trim();
  }

  void _writeList(StringBuffer buffer, String title, List<String> items) {
    if (items.isEmpty) return;
    buffer.writeln(title);
    for (final item in items) {
      buffer.writeln('- $item');
    }
    buffer.writeln();
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.transcript,
    required this.segments,
    required this.searchQuery,
    required this.buttonText,
    required this.disabledText,
    required this.onPressed,
    required this.onSeek,
    required this.onSearchChanged,
  });

  final String? transcript;
  final List<SermonTranscriptSegment> segments;
  final String searchQuery;
  final String buttonText;
  final String disabledText;
  final VoidCallback? onPressed;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTranscript = transcript?.trim().isNotEmpty ?? false;
    final hasSegments = segments.isNotEmpty;
    final query = searchQuery.trim().toLowerCase();
    final visibleSegments = query.isEmpty
        ? segments
        : segments
            .where((segment) => segment.text.toLowerCase().contains(query))
            .toList();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.article_outlined,
              title: 'Transcript',
            ),
            const SizedBox(height: 12),
            if (hasSegments) ...[
              TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search transcript',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              if (visibleSegments.isEmpty)
                Text(
                  'No transcript matches found.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...visibleSegments.map(
                  (segment) => _TranscriptSegmentTile(
                    segment: segment,
                    onTap: () => onSeek(segment.start),
                  ),
                ),
            ] else
              Text(
                hasTranscript
                    ? transcript!.trim()
                    : onPressed == null
                        ? disabledText
                        : 'No transcript yet. Generate a transcript from the sermon audio.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      hasTranscript ? null : theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: const Icon(Icons.auto_awesome),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptSegmentTile extends StatelessWidget {
  const _TranscriptSegmentTile({
    required this.segment,
    required this.onTap,
  });

  final SermonTranscriptSegment segment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[${_formatDuration(segment.start)}]',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFeatures: const [],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  segment.text.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SermonInsightCard extends StatelessWidget {
  const _SermonInsightCard({
    required this.insight,
    required this.fallbackSummary,
    required this.buttonText,
    required this.disabledText,
    required this.onPressed,
    required this.onCopy,
    required this.onShare,
    required this.onSaveToJournal,
    required this.onOpenScripture,
  });

  final SermonInsight? insight;
  final String? fallbackSummary;
  final String buttonText;
  final String disabledText;
  final VoidCallback? onPressed;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSaveToJournal;
  final ValueChanged<LinkedScripture> onOpenScripture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInsight = insight?.hasContent ?? false;
    final hasSummary = fallbackSummary?.trim().isNotEmpty ?? false;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.auto_awesome,
              title: 'Sermon Insights',
            ),
            const SizedBox(height: 12),
            if (hasInsight)
              _InsightSections(
                insight: insight!,
                onOpenScripture: onOpenScripture,
              )
            else
              Text(
                hasSummary
                    ? fallbackSummary!.trim()
                    : onPressed == null
                        ? disabledText
                        : 'No insights yet. Generate key lessons, scriptures, prayer points, and action steps.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasSummary ? null : theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                TextButton.icon(
                  onPressed: onSaveToJournal,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save to Journal'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSections extends StatelessWidget {
  const _InsightSections({
    required this.insight,
    required this.onOpenScripture,
  });

  final SermonInsight insight;
  final ValueChanged<LinkedScripture> onOpenScripture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insight.title.trim().isNotEmpty)
          _InsightTextSection(title: 'Title', text: insight.title),
        if (insight.mainTheme.trim().isNotEmpty)
          _InsightTextSection(title: 'Main Theme', text: insight.mainTheme),
        _InsightListSection(title: 'Key Lessons', items: insight.keyLessons),
        _InsightScriptureSection(
          items: insight.scripturesMentioned,
          onOpenScripture: onOpenScripture,
        ),
        _InsightListSection(
            title: 'Prayer Points', items: insight.prayerPoints),
        _InsightListSection(title: 'Action Steps', items: insight.actionSteps),
        if (insight.shortDevotional.trim().isNotEmpty)
          _InsightTextSection(
            title: 'Short Devotional',
            text: insight.shortDevotional,
          ),
      ],
    );
  }
}

class _InsightScriptureSection extends StatelessWidget {
  const _InsightScriptureSection({
    required this.items,
    required this.onOpenScripture,
  });

  final List<String> items;
  final ValueChanged<LinkedScripture> onOpenScripture;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scriptures = items
        .expand((item) => ScriptureParser.extractScriptures(item))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scriptures Mentioned', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (scriptures.isEmpty)
            _InsightListSection(title: '', items: items)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scripture in scriptures)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new, size: 16),
                    label: Text(scripture.displayTitle),
                    onPressed: () => onOpenScripture(scripture),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InsightTextSection extends StatelessWidget {
  const _InsightTextSection({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            text.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _InsightListSection extends StatelessWidget {
  const _InsightListSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
          ],
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '-',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _MetadataWrap extends StatelessWidget {
  const _MetadataWrap({
    required this.note,
    required this.scriptureCount,
  });

  final SermonNote note;
  final int scriptureCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(
          icon: Icons.timer,
          label: _formatDuration(note.audioDuration),
        ),
        if (note.audioSizeBytes != null)
          _MetaChip(
            icon: Icons.storage,
            label: _formatBytes(note.audioSizeBytes!),
          ),
        if (note.audioMimeType != null && note.audioMimeType!.isNotEmpty)
          _MetaChip(
            icon: Icons.audio_file,
            label: note.audioMimeType!,
          ),
        _MetaChip(
          icon: Icons.menu_book,
          label: '$scriptureCount scripture${scriptureCount == 1 ? '' : 's'}',
        ),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Unknown duration';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatBytes(int bytes) {
    final mb = bytes / 1024 / 1024;
    if (mb >= 0.1) return '${mb.toStringAsFixed(1)} MB';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        Text(
          trailing,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
