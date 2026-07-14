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
import '../widgets/sermon_note_preview.dart';

class SermonEditorScreen extends StatefulWidget {
  final SermonNote? note;
  // TODO: Add save callback

  const SermonEditorScreen({super.key, this.note});

  @override
  State<SermonEditorScreen> createState() => _SermonEditorScreenState();
}

class _SermonEditorScreenState extends State<SermonEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _preacherController;
  late final _SermonContentController _contentController;
  late SermonNote _workingNote;
  final FocusNode _contentFocusNode = FocusNode();

  final ScrollController _inputScrollController = ScrollController();
  final SermonRecordingService _recordingService = SermonRecordingService();
  final SermonAudioFileService _audioFileService =
      const SermonAudioFileService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _draftAutosaveTimer;
  Timer? _recordingTimer;
  bool _didBindRepositories = false;
  bool _didCheckDraft = false;
  bool _skipDraftPersistOnDispose = false;
  bool _isRecording = false;
  bool _isPlaybackReady = false;
  bool _isPlayingAudio = false;
  bool _isDisposing = false;
  bool _previewMode = false;
  TextAlign? _textAlign;
  Duration _recordingElapsed = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  DateTime? _recordingStartedAt;
  String? _loadedAudioPath;
  Future<void>? _repositoriesReadyFuture;
  ValueNotifier<List<ResolvedScriptureMatch>>? _scriptureMatchesNotifier;
  ValueNotifier<bool>? _hasUnsavedChangesNotifier;
  ValueNotifier<DateTime?>? _lastSavedAtNotifier;
  late AppState _appState;
  late SermonNoteRepository _noteRepository;
  late SermonDraftRepository _draftRepository;

  ValueNotifier<List<ResolvedScriptureMatch>> get _scriptureMatchesListenable {
    return _scriptureMatchesNotifier ??=
        ValueNotifier(<ResolvedScriptureMatch>[]);
  }

  ValueNotifier<bool> get _hasUnsavedChangesListenable {
    return _hasUnsavedChangesNotifier ??= ValueNotifier(false);
  }

  ValueNotifier<DateTime?> get _lastSavedAtListenable {
    return _lastSavedAtNotifier ??= ValueNotifier<DateTime?>(null);
  }

  TextAlign get _activeTextAlign => _textAlign ?? TextAlign.left;

  TextAlign _safeTextAlignFromNote(SermonNote note) {
    final align = (note as dynamic).textAlign;
    return align is TextAlign ? align : TextAlign.left;
  }

  String _removeMarkdownFormatting(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'\*\*(.*?)\*\*'),
          (match) => match.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\*(.*?)\*'),
          (match) => match.group(1) ?? '',
        );
  }

  @override
  void initState() {
    super.initState();
    _workingNote = widget.note ?? SermonNote();
    _titleController = TextEditingController(text: _workingNote.title);
    _preacherController = TextEditingController(text: _workingNote.preacher);
    _contentController = _SermonContentController(
      text: _removeMarkdownFormatting(_workingNote.content),
    );
    _textAlign = _safeTextAlignFromNote(_workingNote);
    _audioPlayer.playerStateStream.listen(_handlePlayerState);
    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _playbackPosition = position);
    });

    if (_contentController.text.isNotEmpty) {
      _parseContent(_contentController.text);
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
    _isDisposing = true;
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
    _scriptureMatchesNotifier?.dispose();
    _hasUnsavedChangesNotifier?.dispose();
    _lastSavedAtNotifier?.dispose();
    _contentFocusNode.dispose();
    _inputScrollController.dispose();
    super.dispose();
  }

  SermonNote _buildCurrentNote() {
    _workingNote
      ..title = _titleController.text.trim()
      ..preacher = _preacherController.text.trim()
      ..content = _removeMarkdownFormatting(_contentController.text)
      ..textAlign = _activeTextAlign
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
        note.content.trim().isNotEmpty ||
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
    _markDraftSaved();
  }

  void _scheduleDraftAutosave(
      {Duration delay = const Duration(milliseconds: 800)}) {
    if (!_didBindRepositories) return;
    if (!_hasUnsavedChangesListenable.value) {
      _hasUnsavedChangesListenable.value = true;
    }
    _draftAutosaveTimer?.cancel();
    _draftAutosaveTimer = Timer(
      delay,
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
      _markDraftSaved();
      return;
    }
    await _draftRepository.saveActiveDraft(note);
    _markDraftSaved();
  }

  void _markDraftSaved() {
    if (_isDisposing) return;
    _hasUnsavedChangesListenable.value = false;
    _lastSavedAtListenable.value = DateTime.now();
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
      final cleanContent = _removeMarkdownFormatting(draft.content);
      _contentController.text = cleanContent;
      _textAlign = _safeTextAlignFromNote(draft);
      _parseContent(cleanContent);
      setState(() {});
      return;
    }

    await _draftRepository.clearActiveDraft();
  }

  void _onContentChanged(String text) {
    _scheduleDraftAutosave();
    // Keep the offsets used by highlighting and tap detection synchronized
    // with the controller on every edit.
    _parseContent(text);
  }

  void _onMetadataChanged(String _) {
    _scheduleDraftAutosave();
  }

  void _setTextAlign(TextAlign align) {
    if (_activeTextAlign == align) return;
    setState(() => _textAlign = align);
    _scheduleDraftAutosave(delay: const Duration(milliseconds: 500));
    _contentFocusNode.requestFocus();
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
    setState(() {});
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
    final matches = ScriptureParser.findMatches(text);
    _scriptureMatchesListenable.value = matches;
    _contentController.setScriptureMatches(matches);
  }

  void _openScripture(LinkedScripture scripture) {
    try {
      final book = BookCatalog.byId(scripture.bookId);
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
        SnackBar(
          content: Text('Could not open ${scripture.displayTitle}.'),
        ),
      );
    }
  }

  void _maybeOpenScriptureAtCursor() {
    Future.microtask(() {
      if (!mounted) return;
      final selection = _contentController.selection;
      if (!selection.isValid || !selection.isCollapsed) return;

      final scripture = _scriptureAtTextOffset(selection.baseOffset);
      if (scripture == null) return;

      _openScripture(scripture);
    });
  }

  LinkedScripture? _scriptureAtTextOffset(int offset) {
    return ScriptureParser.matchAtOffset(
      _scriptureMatchesListenable.value,
      offset,
    )?.scripture;
  }

  void _togglePreviewMode() {
    setState(() => _previewMode = !_previewMode);
    if (!_previewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _contentFocusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingScale = AppScope.of(context).fontScale;
    final noteTextStyle = TextStyle(
      fontSize: 16 * readingScale,
      height: 1.45,
      color: theme.colorScheme.onSurface,
    );
    final noteStrutStyle = StrutStyle(
      fontSize: 16 * readingScale,
      height: 1.45,
      forceStrutHeight: true,
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
                        _buildFormattingToolbar(theme),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _previewMode
                              ? SermonNotePreview(
                                  controller: _contentController,
                                  matchesListenable:
                                      _scriptureMatchesListenable,
                                  textAlign: _activeTextAlign,
                                  textStyle: noteTextStyle,
                                  strutStyle: noteStrutStyle,
                                  textScaler: TextScaler.noScaling,
                                  onOpenScripture: _openScripture,
                                )
                              : TextField(
                                  controller: _contentController,
                                  textAlign: _activeTextAlign,
                                  focusNode: _contentFocusNode,
                                  onChanged: _onContentChanged,
                                  onTap: _maybeOpenScriptureAtCursor,
                                  scrollController: _inputScrollController,
                                  style: noteTextStyle,
                                  strutStyle: noteStrutStyle,
                                  cursorColor: theme.colorScheme.primary,
                                  minLines: null,
                                  maxLines: null,
                                  expands: true,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  textAlignVertical: TextAlignVertical.top,
                                  scrollPadding:
                                      const EdgeInsets.only(bottom: 160),
                                  decoration: InputDecoration.collapsed(
                                    hintText:
                                        'Take notes here... Type "John 3:16" to auto-detect scripture references.',
                                    hintStyle: noteTextStyle.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  _buildTimestampBar(theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar(ThemeData theme) {
    final activeColor = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Align left',
            icon: const Icon(Icons.format_align_left),
            color: _activeTextAlign == TextAlign.left ? activeColor : null,
            onPressed: () => _setTextAlign(TextAlign.left),
          ),
          IconButton(
            tooltip: 'Center',
            icon: const Icon(Icons.format_align_center),
            color: _activeTextAlign == TextAlign.center ? activeColor : null,
            onPressed: () => _setTextAlign(TextAlign.center),
          ),
          IconButton(
            tooltip: 'Justify',
            icon: const Icon(Icons.format_align_justify),
            color: _activeTextAlign == TextAlign.justify ? activeColor : null,
            onPressed: () => _setTextAlign(TextAlign.justify),
          ),
          IconButton(
            tooltip: _previewMode ? 'Edit notes' : 'Preview notes',
            icon: Icon(_previewMode ? Icons.edit : Icons.visibility),
            color: _previewMode ? activeColor : null,
            onPressed: _togglePreviewMode,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder<bool>(
                valueListenable: _hasUnsavedChangesListenable,
                builder: (context, hasUnsavedChanges, _) {
                  return ValueListenableBuilder<DateTime?>(
                    valueListenable: _lastSavedAtListenable,
                    builder: (context, lastSavedAt, __) {
                      return Text(
                        hasUnsavedChanges
                            ? 'Saving...'
                            : _formatSavedStatus(lastSavedAt),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSavedStatus(DateTime? savedAt) {
    if (savedAt == null) return 'Saved';
    final hour = savedAt.hour.toString().padLeft(2, '0');
    final minute = savedAt.minute.toString().padLeft(2, '0');
    return 'Saved $hour:$minute';
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
        ],
      ),
    );
  }

  Widget _buildTimestampBar(ThemeData theme) {
    if (_workingNote.timestampedNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasAudio = _workingNote.audioPath?.isNotEmpty ?? false;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          scrollDirection: Axis.horizontal,
          itemCount: _workingNote.timestampedNotes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final note = _workingNote.timestampedNotes[index];
            return ActionChip(
              avatar: const Icon(Icons.schedule, size: 16),
              label: Text(_formatDuration(note.offset)),
              onPressed: hasAudio ? () => _seekToTimestamp(note) : null,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.65,
              ),
            );
          },
        ),
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

class _SermonContentController extends TextEditingController {
  _SermonContentController({super.text});

  List<ResolvedScriptureMatch> _scriptureMatches =
      const <ResolvedScriptureMatch>[];

  void setScriptureMatches(List<ResolvedScriptureMatch> matches) {
    _scriptureMatches = List<ResolvedScriptureMatch>.from(matches);
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final currentText = text;
    if (currentText.isEmpty || _scriptureMatches.isEmpty) {
      return TextSpan(text: currentText, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var currentIndex = 0;
    final sortedMatches = List<ResolvedScriptureMatch>.from(_scriptureMatches)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final match in sortedMatches) {
      if (match.start < currentIndex || match.start >= currentText.length) {
        continue;
      }

      var start = match.start;
      var end = match.end;
      if (end > currentText.length) end = currentText.length;
      if (end <= start) continue;

      if (start > currentIndex) {
        spans.add(
          TextSpan(
            text: currentText.substring(currentIndex, start),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: currentText.substring(start, end),
          style: baseStyle.copyWith(
            color: const Color(0xFFFFD166),
            backgroundColor: const Color(0x332A9D8F),
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.normal,
          ),
        ),
      );
      currentIndex = end;
    }

    if (currentIndex < currentText.length) {
      spans.add(
        TextSpan(
          text: currentText.substring(currentIndex),
          style: baseStyle,
        ),
      );
    }

    return TextSpan(style: baseStyle, children: spans);
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
