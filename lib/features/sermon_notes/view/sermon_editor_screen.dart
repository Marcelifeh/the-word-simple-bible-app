import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
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
  bool _isPlayingAudio = false;
  bool _isSaving = false;
  bool _isDisposing = false;
  bool _previewMode = false;
  bool _isClosing = false;
  TextAlign? _textAlign;
  Duration _recordingElapsed = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  DateTime? _recordingStartedAt;

  SermonRecordingClip? _pendingRecordingClip;
  int _currentClipIndex = 0;
  Duration _positionInCurrentClip = Duration.zero;
  String? _loadedClipsSignature;

  Future<void>? _repositoriesReadyFuture;
  ValueNotifier<List<ResolvedScriptureMatch>>? _scriptureMatchesNotifier;
  ValueNotifier<bool>? _hasUnsavedChangesNotifier;
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

    _audioPlayer.currentIndexStream.listen((index) {
      if (!mounted) return;
      final clips = _workingNote.playableClips;
      setState(() {
        _currentClipIndex =
            kIsWeb && clips.length > 1 ? clips.length - 1 : index ?? 0;
      });
    });

    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _positionInCurrentClip = position;
        _playbackPosition = calculateSermonGlobalPosition(
          clips: _workingNote.playableClips,
          currentIndex: _currentClipIndex,
          positionInClip: _positionInCurrentClip,
        );
      });
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
      ..timestampedNotes = _workingNote.timestampedNotes
      ..lastModified = DateTime.now();
    return _workingNote;
  }

  bool _hasMeaningfulContent(SermonNote note) {
    return note.title.isNotEmpty ||
        note.preacher.isNotEmpty ||
        note.content.trim().isNotEmpty ||
        note.hasRecording ||
        note.recordingClips.any((clip) => clip.filePath.trim().isNotEmpty) ||
        _pendingRecordingClip != null;
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final note = _buildCurrentNote();
      if (_hasMeaningfulContent(note)) {
        await _noteRepository.saveNote(note);
      }

      if (_isRecording) {
        await _persistDraft(clearIfEmpty: false);
      } else {
        _skipDraftPersistOnDispose = true;
        await _draftRepository.clearActiveDraft();
        _markDraftSaved();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    SermonNote draftNote = note;
    if (_pendingRecordingClip != null) {
      draftNote = note.copyWith(
        recordingClips: [...note.recordingClips, _pendingRecordingClip!],
      );
    }

    if (!_hasMeaningfulContent(draftNote)) {
      if (clearIfEmpty) {
        await _draftRepository.clearActiveDraft();
      }
      _markDraftSaved();
      return;
    }
    await _draftRepository.saveActiveDraft(draftNote);
    _markDraftSaved();
  }

  void _markDraftSaved() {
    if (_isDisposing) return;
    _hasUnsavedChangesListenable.value = false;
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

    final mayHaveUnfinishedRecording = draft.recordingClips.any(
      (c) =>
          c.status == SermonRecordingClipStatus.recording ||
          c.status == SermonRecordingClipStatus.interrupted,
    );

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
      final normalizedClips = draft.recordingClips.map((c) {
        if (c.status == SermonRecordingClipStatus.recording) {
          return c.copyWith(status: SermonRecordingClipStatus.interrupted);
        }
        return c;
      }).toList();

      _workingNote = draft.copyWith(recordingClips: normalizedClips);
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

  void _invalidateLoadedSource() {
    _loadedClipsSignature = null;
  }

  Duration get _globalRecordingOffset {
    final completedMs =
        _workingNote.playableClips.fold(0, (sum, c) => sum + c.durationMs);
    return Duration(milliseconds: completedMs) + _recordingElapsed;
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
      final nextSequence = nextSermonRecordingClipSequence(
        _workingNote.recordingClips,
      );

      final clipId = const Uuid().v4();
      final tempClip = SermonRecordingClip(
        id: clipId,
        filePath: '',
        createdAtUtc: DateTime.now().toUtc(),
        durationMs: 0,
        sequence: nextSequence,
        status: SermonRecordingClipStatus.recording,
      );

      _pendingRecordingClip = tempClip;

      final path = await _recordingService.start(sermonId: _workingNote.id);
      if (path.isEmpty) {
        _pendingRecordingClip = null;
        throw StateError('Recorder returned an empty file path');
      }

      _pendingRecordingClip = tempClip.copyWith(filePath: path);

      _recordingStartedAt = DateTime.now();
      _recordingElapsed = Duration.zero;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final startedAt = _recordingStartedAt;
        if (!mounted || startedAt == null) return;
        setState(() {
          _recordingElapsed = DateTime.now().difference(startedAt);
        });
      });

      setState(() {
        _isRecording = true;
      });

      await _persistDraft(clearIfEmpty: false);
      _scheduleDraftAutosave();
    } catch (e) {
      _pendingRecordingClip = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording could not start: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final pending = _pendingRecordingClip;
    if (pending == null) return;
    final startedAt = _recordingStartedAt;
    final elapsed = startedAt == null
        ? _recordingElapsed
        : DateTime.now().difference(startedAt);

    try {
      final path = await _recordingService.stop();
      _recordingTimer?.cancel();
      _recordingElapsed = elapsed;

      if (path == null || path.trim().isEmpty) {
        final interruptedClip = pending.copyWith(
          status: SermonRecordingClipStatus.interrupted,
        );
        setState(() {
          _isRecording = false;
          _workingNote = _workingNote.copyWith(
            recordingClips: [
              ..._workingNote.recordingClips,
              interruptedClip,
            ],
          );
          _pendingRecordingClip = null;
        });
        debugPrint('Recording stopped but no valid path was returned');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording stopped without a playable audio file.'),
            ),
          );
        }
        _scheduleDraftAutosave();
        return;
      }

      final sizeBytes = await _tryReadFileSize(path);
      final completed = pending.copyWith(
        filePath: path,
        durationMs: elapsed.inMilliseconds,
        sizeBytes: sizeBytes,
        status: SermonRecordingClipStatus.completed,
      );

      setState(() {
        _isRecording = false;
        _workingNote = _workingNote.copyWith(
          recordingClips: [..._workingNote.recordingClips, completed],
        );
        _pendingRecordingClip = null;
        _invalidateLoadedSource();
      });

      _scheduleDraftAutosave();
    } catch (e) {
      _recordingTimer?.cancel();
      final interruptedClip = pending.copyWith(
        status: SermonRecordingClipStatus.interrupted,
      );
      if (mounted) {
        setState(() {
          _isRecording = false;
          _workingNote = _workingNote.copyWith(
            recordingClips: [
              ..._workingNote.recordingClips,
              interruptedClip,
            ],
          );
          _pendingRecordingClip = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording could not stop cleanly: $e')),
        );
      }
      _scheduleDraftAutosave();
    }
  }

  Future<int?> _tryReadFileSize(String path) async {
    try {
      return await _audioFileService.sizeBytes(path);
    } catch (_) {
      return null;
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
    await _stopRecording();
    await _saveNote();
    return true;
  }

  Future<void> _saveAndClose() async {
    if (_isClosing) return;
    _isClosing = true;
    try {
      if (_isRecording) {
        final shouldLeave = await _confirmLeaveWhileRecording();
        if (!shouldLeave) return;
      } else {
        await _saveNote();
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      _isClosing = false;
    }
  }

  Future<void> _deleteCurrentNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete this note?'),
          content: const Text(
            'The note and its saved recording will be removed permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    if (_isRecording) await _stopRecording();
    await _audioPlayer.stop();

    await _noteRepository.deleteNote(_workingNote.id);
    await _draftRepository.clearActiveDraft();
    _skipDraftPersistOnDispose = true;

    final paths = {
      ..._workingNote.recordingClips.map((c) => c.filePath),
      if (_pendingRecordingClip != null) _pendingRecordingClip!.filePath,
    }.where((p) => p.trim().isNotEmpty).toSet();

    for (final path in paths) {
      try {
        await _recordingService.deleteFile(path);
      } catch (e) {
        debugPrint('Audio cleanup failed for $path: $e');
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _insertTimestampMarker() {
    if (!_isRecording) return;

    final offset = _globalRecordingOffset;
    final pending = _pendingRecordingClip;

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

    final ts = SermonTimestampedNote(
      offset: offset,
      clipId: pending?.id,
      positionInClipMs: _recordingElapsed.inMilliseconds,
    );

    _workingNote = _workingNote.copyWith(
      timestampedNotes: [..._workingNote.timestampedNotes, ts],
    );

    setState(() {});
    _onContentChanged(nextText);
    _contentFocusNode.requestFocus();
  }

  Future<void> _ensureAudioSourceLoaded() async {
    final clips = _workingNote.playableClips;
    final sig = buildSermonClipSignature(clips);
    if (sig == _loadedClipsSignature) return;

    if (clips.isEmpty) return;

    if (kIsWeb) {
      await _audioPlayer.setUrl(clips.last.filePath);
    } else if (clips.length == 1) {
      await _audioPlayer.setFilePath(clips.single.filePath);
    } else {
      await _audioPlayer.setAudioSources(
        clips.map((clip) => AudioSource.file(clip.filePath)).toList(),
      );
    }
    _loadedClipsSignature = sig;
  }

  Future<void> _togglePlayback() async {
    final clips = _workingNote.playableClips;
    if (clips.isEmpty) return;

    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        return;
      }

      await _ensureAudioSourceLoaded();

      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero, index: 0);
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
    final clips = _workingNote.playableClips;
    if (clips.isEmpty) return;

    await _ensureAudioSourceLoaded();

    if (note.clipId != null) {
      final clipIndex = clips.indexWhere((c) => c.id == note.clipId);
      if (clipIndex >= 0) {
        if (kIsWeb && clipIndex != clips.length - 1) {
          _showWebPlaybackLimitation();
          return;
        }
        await _audioPlayer.seek(
          Duration(milliseconds: note.positionInClipMs ?? 0),
          index: kIsWeb ? 0 : clipIndex,
        );
        return;
      }
    }

    var remaining = note.offset.inMilliseconds;
    for (var i = 0; i < clips.length; i++) {
      if (remaining <= clips[i].durationMs || i == clips.length - 1) {
        if (kIsWeb && i != clips.length - 1) {
          _showWebPlaybackLimitation();
          return;
        }
        await _audioPlayer.seek(
          Duration(milliseconds: remaining.clamp(0, clips[i].durationMs)),
          index: kIsWeb ? 0 : i,
        );
        return;
      }
      remaining -= clips[i].durationMs;
    }
  }

  void _handlePlayerState(PlayerState state) {
    if (!mounted) return;
    setState(() {
      _isPlayingAudio = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _isPlayingAudio = false;
      }
    });
  }

  void _showWebPlaybackLimitation() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'That timestamp is in an earlier clip. Web currently plays only the latest clip.',
        ),
      ),
    );
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

  Future<void> _showNoteToolsSheet() async {
    FocusScope.of(context).unfocus();
    final hasAudio = _workingNote.hasRecording;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _SermonNoteDetailsSheet(
            preacherController: _preacherController,
            previewMode: _previewMode,
            onTogglePreview: _togglePreviewMode,
            hasAudio: hasAudio,
            clipCount: _workingNote.clipCount,
            totalDuration: _workingNote.totalRecordingDuration,
            onDeleteNote: _deleteCurrentNote,
            timestampedNotes: _workingNote.timestampedNotes,
            onSeekToTimestamp: (note) => unawaited(_seekToTimestamp(note)),
            onSaveAndClose: _saveAndClose,
            onMetadataChanged: _onMetadataChanged,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingScale = AppScope.of(context).fontScale;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
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
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _saveAndClose();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          toolbarHeight: 56,
          titleSpacing: 0,
          leading: BackButton(onPressed: _saveAndClose),
          title: const Text('LOGOS Notes'),
          actions: [
            _buildCompactSaveStatus(theme),
            IconButton(
              tooltip: 'Note details',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showNoteToolsSheet,
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
              top: false,
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: _isRecording
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: _buildActiveRecordingBar(theme),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildCompactTitleField(theme),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: _previewMode
                            ? SermonNotePreview(
                                key: const ValueKey('preview'),
                                controller: _contentController,
                                matchesListenable: _scriptureMatchesListenable,
                                textAlign: _activeTextAlign,
                                textStyle: noteTextStyle,
                                strutStyle: noteStrutStyle,
                                textScaler: TextScaler.noScaling,
                                onOpenScripture: _openScripture,
                              )
                            : TextField(
                                key: const ValueKey('editor'),
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
                                    const EdgeInsets.only(bottom: 120),
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
                  if (kIsWeb && _workingNote.clipCount > 1)
                    _buildWebPlaybackBanner(theme),
                  _buildFormattingToolbar(
                    theme,
                    keyboardVisible: keyboardVisible,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactTitleField(ThemeData theme) {
    return TextField(
      controller: _titleController,
      onChanged: _onMetadataChanged,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _contentFocusNode.requestFocus(),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      decoration: const InputDecoration(
        hintText: 'Sermon title',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildCompactSaveStatus(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: _hasUnsavedChangesListenable,
      builder: (context, hasUnsavedChanges, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isSaving
                    ? Icons.sync_rounded
                    : hasUnsavedChanges
                        ? Icons.save_rounded
                        : Icons.check_circle_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _isSaving
                    ? 'Saving'
                    : hasUnsavedChanges
                        ? 'Unsaved'
                        : 'Saved',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormattingToolbar(
    ThemeData theme, {
    required bool keyboardVisible,
  }) {
    final activeColor = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isCompact = constraints.maxWidth < 430 || textScale > 1.2;

        final alignmentControls = <Widget>[
          IconButton(
            tooltip: 'Align left',
            icon: const Icon(Icons.format_align_left_rounded),
            color: _activeTextAlign == TextAlign.left ? activeColor : null,
            onPressed: () => _setTextAlign(TextAlign.left),
          ),
          IconButton(
            tooltip: 'Center',
            icon: const Icon(Icons.format_align_center_rounded),
            color: _activeTextAlign == TextAlign.center ? activeColor : null,
            onPressed: () => _setTextAlign(TextAlign.center),
          ),
          IconButton(
            tooltip: 'Justify',
            icon: const Icon(Icons.format_align_justify_rounded),
            color: _activeTextAlign == TextAlign.justify ? activeColor : null,
            onPressed: () => _setTextAlign(TextAlign.justify),
          ),
        ];

        Widget buildAlignmentSelector() {
          if (isCompact) {
            IconData alignIcon;
            switch (_activeTextAlign) {
              case TextAlign.center:
                alignIcon = Icons.format_align_center_rounded;
                break;
              case TextAlign.justify:
                alignIcon = Icons.format_align_justify_rounded;
                break;
              default:
                alignIcon = Icons.format_align_left_rounded;
            }
            return PopupMenuButton<TextAlign>(
              tooltip: 'Align text',
              icon: Icon(alignIcon, color: activeColor),
              onSelected: _setTextAlign,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TextAlign.left,
                  child: Row(
                    children: [
                      Icon(Icons.format_align_left_rounded),
                      SizedBox(width: 8),
                      Text('Left'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: TextAlign.center,
                  child: Row(
                    children: [
                      Icon(Icons.format_align_center_rounded),
                      SizedBox(width: 8),
                      Text('Center'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: TextAlign.justify,
                  child: Row(
                    children: [
                      Icon(Icons.format_align_justify_rounded),
                      SizedBox(width: 8),
                      Text('Justify'),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: alignmentControls,
            );
          }
        }

        return Material(
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 54,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  buildAlignmentSelector(),
                  const Spacer(),
                  IconButton(
                    tooltip: _isRecording ? 'Stop recording' : 'Record audio',
                    icon: Icon(
                      _isRecording
                          ? Icons.stop_circle_rounded
                          : Icons.mic_rounded,
                    ),
                    color: _isRecording ? theme.colorScheme.error : null,
                    onPressed: _toggleRecording,
                  ),
                  IconButton(
                    tooltip: 'Insert timestamp',
                    icon: const Icon(Icons.bookmark_add_rounded),
                    onPressed: _isRecording ? _insertTimestampMarker : null,
                  ),
                  IconButton(
                    tooltip: _isPlayingAudio
                        ? 'Pause playback'
                        : _playbackPosition > Duration.zero
                            ? 'Resume playback at ${_formatDuration(_playbackPosition)}'
                            : 'Play recording',
                    icon: Icon(
                      _isPlayingAudio
                          ? Icons.pause_circle_rounded
                          : Icons.play_circle_rounded,
                    ),
                    onPressed: (_workingNote.hasRecording && !_isRecording)
                        ? _togglePlayback
                        : null,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _hasUnsavedChangesListenable,
                    builder: (context, hasUnsavedChanges, _) {
                      return IconButton(
                        tooltip: _isSaving
                            ? 'Saving'
                            : hasUnsavedChanges
                                ? 'Save changes'
                                : 'Save',
                        icon: AnimatedRotation(
                          turns: _isSaving ? 1 : 0,
                          duration: const Duration(milliseconds: 700),
                          child: Icon(
                            _isSaving
                                ? Icons.sync_rounded
                                : hasUnsavedChanges
                                    ? Icons.save_rounded
                                    : Icons.check_circle_outline_rounded,
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveNote,
                      );
                    },
                  ),
                  if (keyboardVisible)
                    IconButton(
                      tooltip: 'Hide keyboard',
                      icon: const Icon(Icons.keyboard_hide_rounded),
                      onPressed: () => FocusScope.of(context).unfocus(),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebPlaybackBanner(ThemeData theme) {
    final clips = _workingNote.playableClips;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Multi-clip playback is not yet available on web. '
              '${clips.length} clips · Clip ${clips.length} is playing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRecordingBar(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final clipLabel = 'Clip ${_workingNote.clipCount + 1}';
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fiber_manual_record_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Recording ($clipLabel)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_globalRecordingOffset),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                if (compact)
                  IconButton(
                    tooltip: 'Timestamp',
                    onPressed: _insertTimestampMarker,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: _insertTimestampMarker,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Timestamp'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                IconButton(
                  tooltip: 'Stop recording',
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop_rounded),
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),
        );
      },
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

class _SermonNoteDetailsSheet extends StatefulWidget {
  final TextEditingController preacherController;
  final bool previewMode;
  final VoidCallback onTogglePreview;
  final bool hasAudio;
  final int clipCount;
  final Duration totalDuration;
  final VoidCallback onDeleteNote;
  final List<SermonTimestampedNote> timestampedNotes;
  final ValueChanged<SermonTimestampedNote> onSeekToTimestamp;
  final VoidCallback onSaveAndClose;
  final Function(String) onMetadataChanged;

  const _SermonNoteDetailsSheet({
    required this.preacherController,
    required this.previewMode,
    required this.onTogglePreview,
    required this.hasAudio,
    required this.clipCount,
    required this.totalDuration,
    required this.onDeleteNote,
    required this.timestampedNotes,
    required this.onSeekToTimestamp,
    required this.onSaveAndClose,
    required this.onMetadataChanged,
  });

  @override
  State<_SermonNoteDetailsSheet> createState() =>
      _SermonNoteDetailsSheetState();
}

class _SermonNoteDetailsSheetState extends State<_SermonNoteDetailsSheet> {
  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAudio = widget.hasAudio;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.preacherController,
            onChanged: widget.onMetadataChanged,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Preacher / Speaker',
              prefixIcon: Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          if (hasAudio) ...[
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mic_rounded),
              title: const Text('Recording'),
              subtitle: Text(
                '${widget.clipCount} clip${widget.clipCount == 1 ? "" : "s"} · ${_formatDuration(widget.totalDuration)} total',
              ),
            ),
          ],
          if (widget.timestampedNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Saved timestamps',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final note in widget.timestampedNotes)
                  ActionChip(
                    avatar: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(_formatDuration(note.offset)),
                    onPressed: hasAudio
                        ? () {
                            Navigator.pop(context);
                            widget.onSeekToTimestamp(note);
                          }
                        : null,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              widget.previewMode
                  ? Icons.edit_rounded
                  : Icons.visibility_rounded,
            ),
            title: Text(
              widget.previewMode ? 'Return to writing' : 'Preview note',
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onTogglePreview();
            },
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.save_outlined),
            title: const Text('Save and close'),
            onTap: () {
              Navigator.pop(context);
              widget.onSaveAndClose();
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            textColor: theme.colorScheme.error,
            iconColor: theme.colorScheme.error,
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Delete note'),
            onTap: () {
              Navigator.pop(context);
              widget.onDeleteNote();
            },
          ),
        ],
      ),
    );
  }
}
