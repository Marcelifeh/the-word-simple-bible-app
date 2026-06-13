import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/config/app_branding.dart';

import '../../../core/navigation/app_router.dart' show AppRouter;
import '../../../data/bible/book_catalog.dart';
import '../../../shared/state/app_state.dart';
import '../../bible/view/reading_screen.dart';
import '../model/sermon_note.dart';
import '../repository/sermon_draft_repository.dart';
import '../repository/sermon_note_repository.dart';
import '../services/sermon_audio_file_service.dart';
import '../services/sermon_recording_service.dart';
import '../utils/scripture_parser.dart';

class SermonEditorScreen extends StatefulWidget {
  final SermonNote? note;
  // TODO: Add save callback

  const SermonEditorScreen({super.key, this.note});

  @override
  State<SermonEditorScreen> createState() => _SermonEditorScreenState();
}

class _SermonEditorScreenState extends State<SermonEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _preacherController;
  late TextEditingController _contentController;
  late SermonNote _workingNote;
  final FocusNode _contentFocusNode = FocusNode();

  final ScrollController _inputScrollController = ScrollController();
  final ScrollController _highlightScrollController = ScrollController();
  final SermonRecordingService _recordingService = SermonRecordingService();
  final SermonAudioFileService _audioFileService =
      const SermonAudioFileService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _debounce;
  Timer? _draftAutosaveTimer;
  Timer? _recordingTimer;
  bool _syncingScroll = false;
  bool _didBindRepositories = false;
  bool _didCheckDraft = false;
  bool _skipDraftPersistOnDispose = false;
  bool _isRecording = false;
  bool _isPlaybackReady = false;
  bool _isPlayingAudio = false;
  Duration _recordingElapsed = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  DateTime? _recordingStartedAt;
  String? _loadedAudioPath;
  Future<void>? _repositoriesReadyFuture;
  List<ResolvedScriptureMatch> _scriptureMatches = [];
  late AppState _appState;
  late SermonNoteRepository _noteRepository;
  late SermonDraftRepository _draftRepository;

  @override
  void initState() {
    super.initState();
    _workingNote = widget.note ?? SermonNote();
    _titleController = TextEditingController(text: _workingNote.title);
    _preacherController = TextEditingController(text: _workingNote.preacher);
    _contentController = TextEditingController(text: _workingNote.content);
    _inputScrollController.addListener(_syncHighlightScroll);
    _audioPlayer.playerStateStream.listen(_handlePlayerState);
    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _playbackPosition = position);
    });

    if (_workingNote.content.isNotEmpty) {
      _parseContent(_workingNote.content);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindRepositories) return;

    _appState = AppScope.of(context);
    _noteRepository = _appState.sermonNoteRepo;
    _draftRepository = _appState.sermonDraftRepo;
    _repositoriesReadyFuture ??= Future.wait([
      _noteRepository.ensureInitialized(),
      _draftRepository.ensureInitialized(),
    ]);
    _didBindRepositories = true;

    if (!_didCheckDraft) {
      _didCheckDraft = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_maybeRestoreDraft());
      });
    }
  }

  @override
  void dispose() {
    _inputScrollController.removeListener(_syncHighlightScroll);
    _debounce?.cancel();
    _draftAutosaveTimer?.cancel();
    _recordingTimer?.cancel();
    if (_isRecording) {
      unawaited(_recordingService.stop());
    }
    unawaited(_recordingService.dispose());
    unawaited(_audioPlayer.dispose());
    if (_didBindRepositories && !_skipDraftPersistOnDispose) {
      unawaited(_persistDraft(clearIfEmpty: true));
    }
    _titleController.dispose();
    _preacherController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _inputScrollController.dispose();
    _highlightScrollController.dispose();
    super.dispose();
  }

  SermonNote _buildCurrentNote() {
    _workingNote
      ..title = _titleController.text.trim()
      ..preacher = _preacherController.text.trim()
      ..content = _contentController.text.trim()
      ..audioPath = _workingNote.audioPath
      ..audioDuration = _workingNote.audioDuration
      ..audioSizeBytes = _workingNote.audioSizeBytes
      ..audioMimeType = _workingNote.audioMimeType
      ..recordedAt = _workingNote.recordedAt
      ..timestampedNotes = _workingNote.timestampedNotes
      ..lastModified = DateTime.now();
    return _workingNote;
  }

  bool _hasMeaningfulContent(SermonNote note) {
    return note.title.isNotEmpty ||
        note.preacher.isNotEmpty ||
        note.content.isNotEmpty ||
        (note.audioPath?.isNotEmpty ?? false);
  }

  Future<void> _saveNote() async {
    if (_isRecording) {
      await _stopRecording();
    }
    final note = _buildCurrentNote();
    if (_hasMeaningfulContent(note)) {
      await _noteRepository.saveNote(note);
    }
    _skipDraftPersistOnDispose = true;
    await _draftRepository.clearActiveDraft();
  }

  void _scheduleDraftAutosave() {
    if (!_didBindRepositories) return;
    _draftAutosaveTimer?.cancel();
    _draftAutosaveTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_persistDraft(clearIfEmpty: true)),
    );
  }

  Future<void> _persistDraft({required bool clearIfEmpty}) async {
    if (!_didBindRepositories) return;
    final note = _buildCurrentNote();
    if (!_hasMeaningfulContent(note)) {
      if (clearIfEmpty) {
        await _draftRepository.clearActiveDraft();
      }
      return;
    }
    await _draftRepository.saveActiveDraft(note);
  }

  Future<void> _maybeRestoreDraft() async {
    final draft = _draftRepository.getActiveDraft();
    if (draft == null || !_hasMeaningfulContent(draft)) {
      return;
    }

    final isNewDraft =
        widget.note == null && !_hasMeaningfulContent(_workingNote);
    final isMatchingExistingDraft = widget.note != null &&
        draft.id == _workingNote.id &&
        (draft.lastModified.isAfter(_workingNote.lastModified) ||
            draft.title != _workingNote.title ||
            draft.preacher != _workingNote.preacher ||
            draft.content != _workingNote.content);

    if (!isNewDraft && !isMatchingExistingDraft) {
      return;
    }

    final mayHaveUnfinishedRecording =
        (draft.audioPath?.isNotEmpty ?? false) && draft.audioDuration == null;

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            mayHaveUnfinishedRecording
                ? 'Recover sermon recording?'
                : 'Restore draft?',
          ),
          content: Text(
            mayHaveUnfinishedRecording
                ? 'A sermon recording may not have been saved properly. Restore this sermon draft and review the audio?'
                : 'An unsaved sermon draft was found. Restore it and continue writing?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(mayHaveUnfinishedRecording ? 'Discard' : 'Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                mayHaveUnfinishedRecording ? 'Recover' : 'Restore',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (shouldRestore == true) {
      _workingNote = draft;
      _titleController.text = draft.title;
      _preacherController.text = draft.preacher;
      _contentController.text = draft.content;
      _parseContent(draft.content);
      setState(() {});
      return;
    }

    await _draftRepository.clearActiveDraft();
  }

  void _onContentChanged(String text) {
    setState(() {});
    _scheduleDraftAutosave();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _parseContent(text);
    });
  }

  void _onMetadataChanged(String _) {
    _scheduleDraftAutosave();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recordingService.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      await _showMicrophonePermissionDialog();
      return;
    }

    try {
      final previousPath = _workingNote.audioPath;
      final path = await _recordingService.start(sermonId: _workingNote.id);
      if (previousPath != null && previousPath != path) {
        await _audioFileService.delete(previousPath);
      }
      _recordingStartedAt = DateTime.now();
      _recordingElapsed = Duration.zero;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final startedAt = _recordingStartedAt;
        if (!mounted || startedAt == null) return;
        setState(
            () => _recordingElapsed = DateTime.now().difference(startedAt));
      });
      setState(() {
        _isRecording = true;
        _workingNote.audioPath = path;
        _workingNote.audioDuration = null;
        _workingNote.audioSizeBytes = null;
        _workingNote.audioMimeType = 'audio/mp4';
        _workingNote.recordedAt = _recordingStartedAt;
        _isPlaybackReady = false;
      });
      await _persistDraft(clearIfEmpty: false);
      _scheduleDraftAutosave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording could not start: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recordingService.stop();
      _recordingTimer?.cancel();
      final recordedAt = _recordingStartedAt;
      final duration = _recordingElapsed;
      final effectivePath =
          path != null && path.isNotEmpty ? path : _workingNote.audioPath;
      final sizeBytes = await _audioFileService.sizeBytes(effectivePath);
      setState(() {
        _isRecording = false;
        if (path != null && path.isNotEmpty) {
          _workingNote.audioPath = path;
        }
        _workingNote.audioDuration = duration;
        _workingNote.audioSizeBytes = sizeBytes;
        _workingNote.audioMimeType = 'audio/mp4';
        _workingNote.recordedAt = recordedAt ?? DateTime.now();
        _isPlaybackReady = _workingNote.audioPath != null;
      });
      _scheduleDraftAutosave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording could not stop cleanly: $e')),
      );
    }
  }

  Future<void> _showMicrophonePermissionDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Microphone access needed'),
          content: const Text(
            'The Word needs microphone access to record sermon audio. '
            'Allow microphone access in your browser or device settings, then try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmLeaveWhileRecording() async {
    final shouldStopAndSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recording is still active'),
          content: const Text(
            'Stop and save this sermon recording before leaving?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Stop & Save'),
            ),
          ],
        );
      },
    );

    if (shouldStopAndSave != true) return false;
    await _saveNote();
    return true;
  }

  void _insertTimestampMarker() {
    final offset = _isRecording ? _recordingElapsed : _playbackPosition;
    final marker = '[${_formatDuration(offset)}] ';
    final current = _contentController.value;
    final text = current.text;
    final selection = current.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final prefix =
        start > 0 && !text.substring(0, start).endsWith('\n') ? '\n' : '';
    final insertion = '$prefix$marker';
    final nextText = text.replaceRange(start, end, insertion);
    final nextOffset = start + insertion.length;

    _contentController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
    _workingNote.timestampedNotes.add(SermonTimestampedNote(offset: offset));
    _onContentChanged(nextText);
    _contentFocusNode.requestFocus();
  }

  Future<void> _togglePlayback() async {
    final audioPath = _workingNote.audioPath;
    if (audioPath == null || audioPath.isEmpty) return;

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        return;
      }

      if (_loadedAudioPath != audioPath) {
        if (audioPath.startsWith('http://') ||
            audioPath.startsWith('https://') ||
            audioPath.startsWith('blob:')) {
          await _audioPlayer.setUrl(audioPath);
        } else {
          await _audioPlayer.setFilePath(audioPath);
        }
        _loadedAudioPath = audioPath;
        _isPlaybackReady = true;
      }

      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio playback failed: $e')),
      );
    }
  }

  Future<void> _seekToTimestamp(SermonTimestampedNote note) async {
    final audioPath = _workingNote.audioPath;
    if (audioPath == null || audioPath.isEmpty) return;
    if (_loadedAudioPath != audioPath) {
      await _togglePlayback();
      await _audioPlayer.pause();
    }
    await _audioPlayer.seek(note.offset);
  }

  void _handlePlayerState(PlayerState state) {
    if (!mounted) return;
    setState(() {
      _isPlayingAudio = state.playing;
      _isPlaybackReady = _workingNote.audioPath != null &&
          state.processingState != ProcessingState.idle;
      if (state.processingState == ProcessingState.completed) {
        _isPlayingAudio = false;
      }
    });
  }

  void _parseContent(String text) {
    setState(() {
      _scriptureMatches = ScriptureParser.findMatches(text);
    });
  }

  void _syncHighlightScroll() {
    if (_syncingScroll || !_highlightScrollController.hasClients) {
      return;
    }

    _syncingScroll = true;
    final nextOffset = _inputScrollController.offset.clamp(
      0.0,
      _highlightScrollController.position.maxScrollExtent,
    );
    _highlightScrollController.jumpTo(nextOffset);
    _syncingScroll = false;
  }

  void _openScripture(LinkedScripture link) {
    try {
      final book = BookCatalog.books.firstWhere((b) => b.id == link.bookId);

      AppRouter.push(
        context,
        ReadingScreen(
          book: book,
          chapter: link.chapter,
          initialVerse: link.startVerse,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open scripture references.')),
      );
    }
  }

  void _handleContentTap({
    required Offset localPosition,
    required double maxWidth,
    required ThemeData theme,
    required TextStyle noteTextStyle,
  }) {
    final text = _contentController.text;
    if (text.isEmpty) {
      return;
    }

    final painter = TextPainter(
      text: _buildHighlightedText(theme, noteTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    final contentOffset = Offset(
      localPosition.dx,
      localPosition.dy + _highlightScrollController.offset,
    );

    ResolvedScriptureMatch? tappedMatch;
    final textLen = text.length;
    for (final match in _scriptureMatches) {
      if (match.start < 0 || match.start >= textLen) continue;
      var start = match.start;
      var end = match.end;
      if (end > textLen) end = textLen;
      if (end <= start) continue;

      final selection = TextSelection(baseOffset: start, extentOffset: end);
      List<TextBox> boxes;
      try {
        boxes = painter.getBoxesForSelection(selection);
      } catch (_) {
        continue;
      }

      if (boxes.any((box) => box.toRect().inflate(6).contains(contentOffset))) {
        tappedMatch = match;
        break;
      }
    }

    if (tappedMatch != null) {
      _openScripture(tappedMatch.scripture);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteTextStyle = theme.textTheme.bodyLarge?.copyWith(
          height: 1.65,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 16,
          height: 1.65,
          color: theme.colorScheme.onSurface,
        );

    return PopScope(
      canPop: !_isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_isRecording) return;
        final shouldLeave = await _confirmLeaveWhileRecording();
        if (!shouldLeave || !context.mounted) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppBranding.logosNotes,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                await _saveNote();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: FutureBuilder<void>(
          future: _repositoriesReadyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to open this sermon note right now.',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          onChanged: _onMetadataChanged,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Sermon Title...',
                            border: InputBorder.none,
                          ),
                        ),
                        TextField(
                          controller: _preacherController,
                          onChanged: _onMetadataChanged,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Preacher / Speaker (optional)',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.person_outline),
                            prefixIconConstraints: BoxConstraints(minWidth: 40),
                          ),
                        ),
                        const Divider(),
                        _buildSermonIntelligencePanel(theme),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.axis == Axis.vertical) {
                            _syncHighlightScroll();
                          }
                          return false;
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                TextField(
                                  controller: _contentController,
                                  focusNode: _contentFocusNode,
                                  onChanged: _onContentChanged,
                                  scrollController: _inputScrollController,
                                  style: noteTextStyle.copyWith(
                                    color: Colors.transparent,
                                  ),
                                  cursorColor: theme.colorScheme.primary,
                                  maxLines: null,
                                  expands: true,
                                  keyboardType: TextInputType.multiline,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration.collapsed(
                                    hintText:
                                        'Take notes here... Type "John 3:16" to auto-highlight scripture references.',
                                    hintStyle: noteTextStyle.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: SingleChildScrollView(
                                      controller: _highlightScrollController,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: RichText(
                                          textScaler:
                                              MediaQuery.textScalerOf(context),
                                          text: _buildHighlightedText(
                                            theme,
                                            noteTextStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerUp: (event) => _handleContentTap(
                                      localPosition: event.localPosition,
                                      maxWidth: constraints.maxWidth,
                                      theme: theme,
                                      noteTextStyle: noteTextStyle,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(ThemeData theme, TextStyle baseStyle) {
    final text = _contentController.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    if (_scriptureMatches.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final children = <InlineSpan>[];
    var currentIndex = 0;

    final matches = List<ResolvedScriptureMatch>.from(_scriptureMatches)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final match in matches) {
      if (match.start < 0) continue;
      if (match.start >= text.length) continue;

      var start = match.start;
      var end = match.end;
      if (end > text.length) end = text.length;
      if (end <= start) continue;

      if (start > currentIndex) {
        children.add(
          TextSpan(
            text: text.substring(currentIndex, start),
            style: baseStyle,
          ),
        );
      }

      children.add(
        TextSpan(
          text: text.substring(start, end),
          style: baseStyle.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            backgroundColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
          ),
        ),
      );
      currentIndex = end;
    }

    if (currentIndex < text.length) {
      children.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: baseStyle,
        ),
      );
    }

    return TextSpan(style: baseStyle, children: children);
  }

  Widget _buildSermonIntelligencePanel(ThemeData theme) {
    final hasAudio = _workingNote.audioPath?.isNotEmpty ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'Stop' : 'Record'),
              ),
              OutlinedButton.icon(
                onPressed: _isRecording || _isPlaybackReady
                    ? _insertTimestampMarker
                    : null,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Timestamp'),
              ),
              if (_isRecording)
                _StatusPill(
                  icon: Icons.fiber_manual_record,
                  label: _formatDuration(_recordingElapsed),
                  color: theme.colorScheme.error,
                )
              else if (hasAudio)
                OutlinedButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(_isPlayingAudio ? Icons.pause : Icons.play_arrow),
                  label: Text(_formatDuration(_playbackPosition)),
                ),
            ],
          ),
          if (_workingNote.timestampedNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _workingNote.timestampedNotes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final note = _workingNote.timestampedNotes[index];
                  return ActionChip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text(_formatDuration(note.offset)),
                    onPressed: hasAudio ? () => _seekToTimestamp(note) : null,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
