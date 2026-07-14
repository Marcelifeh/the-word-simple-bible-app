import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/backend_health_service.dart';
import '../../../core/navigation/app_router.dart' show AppRouter;
import '../../../core/utils/env.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/reading_text_scale.dart';
import '../../bible/view/reading_screen.dart';
import '../../notes/model/verse_note.dart';
import '../model/sermon_note.dart';
import '../model/sermon_outline.dart';
import '../services/sermon_ai_service.dart';
import '../services/sermon_document_export_service.dart';
import '../services/sermon_document_file_saver.dart';
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
  static const _cloudTranscriptionUnavailableMessage =
      'Cloud transcription is unavailable during the beta. Your recording remains safely stored on this device.';

  final GlobalKey<SermonAudioPlayerCardState> _audioKey =
      GlobalKey<SermonAudioPlayerCardState>();
  late SermonNote _note;
  bool _isTranscribing = false;
  bool _isSummarizing = false;
  bool _isGeneratingOutline = false;
  bool _isExportingDocument = false;
  String _transcriptSearchQuery = '';

  final SermonDocumentExportService _documentExportService =
      const SermonDocumentExportService();

  final BackendHealthService _backendHealthService = BackendHealthService();
  final SermonAiService _sermonAiService = SermonAiService();

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    Future.microtask(_warmBackend);
  }

  @override
  void dispose() {
    _backendHealthService.dispose();
    _sermonAiService.dispose();
    super.dispose();
  }

  Future<void> _warmBackend() async {
    await _backendHealthService.check();
  }

  Future<void> _generateTranscript() async {
    final path = _note.audioPath;
    if (path == null || path.isEmpty || _isTranscribing) return;
    if (!Env.transcriptionEnabled) {
      _showCloudTranscriptionUnavailable();
      return;
    }
    if (!_sermonCloudProcessingAvailable) {
      _showCloudTranscriptionUnavailable();
      return;
    }
    if (!await _ensureBackendAvailable()) return;
    if (!mounted) return;

    final repository = AppScope.of(context).sermonNoteRepo;
    setState(() => _isTranscribing = true);
    try {
      final result = await _sermonAiService.transcribeAudio(path);
      final updated = _note.copyWith(
        transcript: result.transcript,
        transcriptSegments: result.segments,
        audioDuration: result.duration ?? _note.audioDuration,
        clearSummary: true,
        clearInsight: true,
        clearOutline: true,
      );
      await repository.updateNote(updated);
      if (!mounted) return;
      setState(() => _note = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saved to sermon note.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showCloudError(
        e,
        fallback:
            'Cloud transcription is unavailable during the beta. Your recording remains safely stored on this device.',
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
    if (!_sermonCloudProcessingAvailable) {
      _showCloudTranscriptionUnavailable();
      return;
    }
    if (transcript == null || transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate transcript first.')),
      );
      return;
    }
    if (!await _ensureBackendAvailable()) return;
    if (!mounted) return;

    final repository = AppScope.of(context).sermonNoteRepo;
    setState(() => _isSummarizing = true);
    try {
      final result = await _sermonAiService.generateSummary(transcript);
      final updated = _note.copyWith(
        summary: result.summary,
        insight: result.insight,
        clearOutline: true,
      );
      await repository.updateNote(updated);
      if (!mounted) return;
      setState(() => _note = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sermon summary saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showCloudError(
        e,
        fallback:
            'AI processing is temporarily unavailable. Please try again later.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  Future<void> _generateOutline() async {
    final transcript = _note.transcript?.trim();
    if (_isGeneratingOutline) return;
    if (!_sermonCloudProcessingAvailable) {
      _showCloudTranscriptionUnavailable();
      return;
    }
    if (transcript == null || transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate transcript first.')),
      );
      return;
    }
    if (!await _ensureBackendAvailable()) return;
    if (!mounted) return;

    final repository = AppScope.of(context).sermonNoteRepo;
    setState(() => _isGeneratingOutline = true);
    try {
      final outline = await _sermonAiService.generateOutline(
        transcript: transcript,
        insight: _note.insight,
      );
      final updated = _note.copyWith(outline: outline);
      await repository.updateNote(updated);
      if (!mounted) return;
      setState(() => _note = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preacher outline saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showCloudError(
        e,
        fallback:
            'AI processing is temporarily unavailable. Please try again later.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingOutline = false);
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

  Future<void> _copyOutline() async {
    final text = _note.outline?.toShareText();
    if (text == null || text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preacher outline copied.')),
    );
  }

  Future<void> _shareOutline() async {
    final text = _note.outline?.toShareText();
    if (text == null || text.trim().isEmpty) return;
    await Share.share(
      text,
      subject: _note.outline?.title.trim().isNotEmpty ?? false
          ? _note.outline!.title
          : 'Preacher Outline',
    );
  }

  Future<void> _exportPdf() async {
    await _runDocumentExport(() async {
      final file = await _documentExportService.buildPdf(_note);
      await _shareDocumentFiles([file]);
    });
  }

  Future<void> _exportDocx() async {
    await _runDocumentExport(() async {
      final file = _documentExportService.buildDocx(_note);
      await _shareDocumentFiles([file]);
    });
  }

  Future<void> _shareSermonDocument() async {
    await _runDocumentExport(() async {
      final files = await _buildSermonDocumentFiles();
      await _shareDocumentFiles(files);
    });
  }

  Future<void> _saveSermonDocument() async {
    await _runDocumentExport(() async {
      final files = await _buildSermonDocumentFiles();
      try {
        final paths = await saveSermonDocumentFiles(files);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paths.length == 1
                  ? 'Sermon document saved to ${paths.first}'
                  : 'Sermon documents saved to ${paths.first}',
            ),
          ),
        );
      } on UnsupportedError {
        await _shareDocumentFiles(
          files,
          text:
              'Choose Save to Files or your device storage to keep this sermon document.',
        );
      }
    });
  }

  Future<void> _runDocumentExport(Future<void> Function() action) async {
    if (_isExportingDocument) return;
    setState(() => _isExportingDocument = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingDocument = false);
      }
    }
  }

  Future<List<SermonDocumentFile>> _buildSermonDocumentFiles() async {
    return [
      await _documentExportService.buildPdf(_note),
      _documentExportService.buildDocx(_note),
    ];
  }

  Future<void> _shareDocumentFiles(
    List<SermonDocumentFile> files, {
    String? text,
  }) async {
    await Share.shareXFiles(
      [
        for (final file in files)
          XFile.fromData(
            file.bytes,
            name: file.name,
            mimeType: file.mimeType,
          ),
      ],
      subject: _note.title.isEmpty ? 'Sermon Document' : _note.title,
      text: text,
    );
  }

  void _saveInsightToJournal() {
    final text = _sermonInsightText();
    if (text.trim().isEmpty) return;

    final state = AppScope.of(context);
    final note = VerseNote(
      verseId: 'sermon-${_note.id}-insight',
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
    final hasTranscript = note.transcript?.trim().isNotEmpty ?? false;
    final sermonCloudAvailable = _sermonCloudProcessingAvailable;
    final transcriptionAvailable =
        sermonCloudAvailable && Env.transcriptionEnabled;
    final transcriptDisabledText = !hasAudio
        ? 'No audio recording found. Record a sermon first to generate transcript.'
        : _cloudTranscriptionUnavailableMessage;
    final insightDisabledText = !hasAudio
        ? 'No audio recording found. Record a sermon first to generate sermon insights.'
        : !sermonCloudAvailable
            ? _cloudTranscriptionUnavailableMessage
            : 'Generate a transcript first to create sermon insights.';
    final outlineDisabledText = !sermonCloudAvailable
        ? _cloudTranscriptionUnavailableMessage
        : 'Generate transcript first before creating a sermon outline.';
    final scriptures = ScriptureParser.extractScriptures(
      _scriptureDetectionText(note),
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
          ReadingTextScale(
            child: _TranscriptCard(
              transcript: note.transcript,
              segments: note.transcriptSegments,
              searchQuery: _transcriptSearchQuery,
              hasAudio: hasAudio,
              isTranscribing: _isTranscribing,
              transcriptionAvailable: transcriptionAvailable,
              buttonText: _isTranscribing
                  ? 'Transcribing...'
                  : transcriptionAvailable
                      ? 'Generate Transcript'
                      : 'Unavailable in Beta',
              disabledText: transcriptDisabledText,
              onPressed: hasAudio && transcriptionAvailable && !_isTranscribing
                  ? _generateTranscript
                  : null,
              onSeek: (position) => _audioKey.currentState?.seekTo(position),
              onSearchChanged: (value) {
                setState(() => _transcriptSearchQuery = value);
              },
            ),
          ),
          const SizedBox(height: 16),
          ReadingTextScale(
            child: _SermonInsightCard(
              insight: note.insight,
              fallbackSummary: note.summary,
              isSummarizing: _isSummarizing,
              buttonText: _isSummarizing
                  ? 'Summarizing...'
                  : (note.insight?.hasContent ?? false) ||
                          (note.summary?.trim().isNotEmpty ?? false)
                      ? 'Regenerate Summary'
                      : 'Generate Summary',
              disabledText: insightDisabledText,
              onPressed: hasAudio &&
                      sermonCloudAvailable &&
                      !_isSummarizing &&
                      hasTranscript
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
          ),
          const SizedBox(height: 16),
          ReadingTextScale(
            child: _SermonOutlineCard(
              outline: note.outline,
              hasTranscript: hasTranscript,
              disabledText: outlineDisabledText,
              isGenerating: _isGeneratingOutline,
              onGenerate:
                  hasTranscript && sermonCloudAvailable && !_isGeneratingOutline
                      ? _generateOutline
                      : null,
              onCopy: note.outline?.hasContent ?? false ? _copyOutline : null,
              onShare: note.outline?.hasContent ?? false ? _shareOutline : null,
            ),
          ),
          const SizedBox(height: 16),
          _SermonDocumentExportCard(
            isBusy: _isExportingDocument,
            onExportPdf: _isExportingDocument ? null : _exportPdf,
            onExportDocx: _isExportingDocument ? null : _exportDocx,
            onSaveToDevice: _isExportingDocument ? null : _saveSermonDocument,
            onShareDocument: _isExportingDocument ? null : _shareSermonDocument,
          ),
        ],
      ),
    );
  }

  String _scriptureDetectionText(SermonNote note) {
    final buffer = StringBuffer()
      ..writeln(note.content)
      ..writeln(note.transcript ?? '')
      ..writeln(note.summary ?? '');

    final insight = note.insight;
    if (insight != null) {
      buffer
        ..writeln(insight.mainTheme)
        ..writeln(insight.shortDevotional);
      for (final scripture in insight.scripturesMentioned) {
        buffer.writeln(scripture);
      }
    }

    final outline = note.outline;
    if (outline != null) {
      buffer.writeln(outline.mainText);
      for (final scripture in outline.supportingScriptures) {
        buffer.writeln(scripture);
      }
    }

    return buffer.toString();
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

  bool get _sermonCloudProcessingAvailable {
    final explicit = Env.sermonApiUrl.trim();
    if (explicit.isEmpty) return false;

    final uri = Uri.tryParse(explicit);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<bool> _ensureBackendAvailable() async {
    final available = await _backendHealthService.check();
    if (available || !mounted) return available;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cloud services are waking up. This may take up to a minute.',
        ),
      ),
    );
    return false;
  }

  void _showCloudTranscriptionUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_cloudTranscriptionUnavailableMessage)),
    );
  }

  void _showCloudError(
    Object error, {
    required String fallback,
  }) {
    final message = error is SermonApiException ? error.message : fallback;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    required this.hasAudio,
    required this.isTranscribing,
    required this.transcriptionAvailable,
    required this.buttonText,
    required this.disabledText,
    required this.onPressed,
    required this.onSeek,
    required this.onSearchChanged,
  });

  final String? transcript;
  final List<SermonTranscriptSegment> segments;
  final String searchQuery;
  final bool hasAudio;
  final bool isTranscribing;
  final bool transcriptionAvailable;
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
                    : isTranscribing
                        ? 'Transcribing sermon audio. Please wait...'
                        : hasAudio && transcriptionAvailable
                            ? 'No transcript yet. Generate a transcript from the sermon audio.'
                            : disabledText,
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

class _SermonDocumentExportCard extends StatelessWidget {
  const _SermonDocumentExportCard({
    required this.isBusy,
    required this.onExportPdf,
    required this.onExportDocx,
    required this.onSaveToDevice,
    required this.onShareDocument,
  });

  final bool isBusy;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportDocx;
  final VoidCallback? onSaveToDevice;
  final VoidCallback? onShareDocument;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.description_outlined,
              title: 'Sermon Document',
            ),
            const SizedBox(height: 12),
            Text(
              isBusy
                  ? 'Preparing sermon document. Please wait...'
                  : 'Export this sermon as a clean preaching document for teaching, sharing, or saving.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(isBusy ? 'Preparing...' : 'Export as PDF'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onExportDocx,
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Export as DOCX'),
                ),
                TextButton.icon(
                  onPressed: onSaveToDevice,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Save to Device'),
                ),
                TextButton.icon(
                  onPressed: onShareDocument,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Sermon Document'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SermonOutlineCard extends StatelessWidget {
  const _SermonOutlineCard({
    required this.outline,
    required this.hasTranscript,
    required this.disabledText,
    required this.isGenerating,
    required this.onGenerate,
    required this.onCopy,
    required this.onShare,
  });

  final SermonOutline? outline;
  final bool hasTranscript;
  final String disabledText;
  final bool isGenerating;
  final VoidCallback? onGenerate;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOutline = outline?.hasContent ?? false;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.format_list_numbered,
              title: 'Preacher Outline',
            ),
            const SizedBox(height: 12),
            if (hasOutline)
              _OutlineSections(outline: outline!)
            else
              Text(
                isGenerating
                    ? 'Generating preacher outline. Please wait...'
                    : onGenerate == null
                        ? disabledText
                        : 'Generate a preacher-friendly outline from this sermon.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                  label: const Text('Copy Outline'),
                ),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Outline'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    isGenerating
                        ? 'Generating...'
                        : hasOutline
                            ? 'Regenerate Outline'
                            : 'Generate Outline',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineSections extends StatelessWidget {
  const _OutlineSections({required this.outline});

  final SermonOutline outline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (outline.title.trim().isNotEmpty)
          _InsightTextSection(title: 'Title', text: outline.title),
        if (outline.mainText.trim().isNotEmpty)
          _InsightTextSection(title: 'Main Text', text: outline.mainText),
        if (outline.introduction.trim().isNotEmpty)
          _InsightTextSection(
            title: 'Introduction',
            text: outline.introduction,
          ),
        _InsightListSection(title: 'Main Points', items: outline.mainPoints),
        _InsightListSection(
          title: 'Supporting Scriptures',
          items: outline.supportingScriptures,
        ),
        if (outline.lifeApplication.trim().isNotEmpty)
          _InsightTextSection(
            title: 'Life Application',
            text: outline.lifeApplication,
          ),
        if (outline.conclusion.trim().isNotEmpty)
          _InsightTextSection(title: 'Conclusion', text: outline.conclusion),
        if (outline.closingPrayer.trim().isNotEmpty)
          _InsightTextSection(
            title: 'Closing Prayer',
            text: outline.closingPrayer,
          ),
      ],
    );
  }
}

class _SermonInsightCard extends StatelessWidget {
  const _SermonInsightCard({
    required this.insight,
    required this.fallbackSummary,
    required this.isSummarizing,
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
  final bool isSummarizing;
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
                    : isSummarizing
                        ? 'Generating sermon insights. Please wait...'
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
