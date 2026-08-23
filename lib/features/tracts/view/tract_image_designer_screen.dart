import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/web_helper.dart';
import '../model/tract_share_theme.dart';
import '../model/word_studio_custom_background.dart';
import '../repository/word_studio_custom_background_repository.dart';
import 'widgets/tract_canvas.dart';
import 'widgets/word_studio_top_bar.dart';

class TractImageDesignerScreen extends StatefulWidget {
  final String title;
  final String body;
  final String? scripture;
  final String? scriptureRef;
  final String? hook;
  final bool isUserTract;

  const TractImageDesignerScreen({
    super.key,
    required this.title,
    required this.body,
    this.scripture,
    this.scriptureRef,
    this.hook,
    this.isUserTract = false,
  });

  @override
  State<TractImageDesignerScreen> createState() =>
      _TractImageDesignerScreenState();
}

class _TractImageDesignerScreenState extends State<TractImageDesignerScreen> {
  final _screenshotController = ScreenshotController();
  final _imagePicker = ImagePicker();
  final _customBackgroundRepository = WordStudioCustomBackgroundRepository();

  static const double _designCanvasWidth = 360.0;
  static const double _exportPixelRatio = 3.0;
  static const TractShareTheme _customBackgroundTheme = TractShareTheme(
    id: 'custom_photo',
    name: 'My Background',
    gradientColors: <Color>[Colors.black, Color(0xFF111827)],
    textColor: Colors.white,
    accentColor: Color(0xFFFDE68A),
    fontFamily: 'Poppins',
    dark: true,
  );

  // Customization state
  int _selectedThemeIndex = 0;
  TractLayoutMode _selectedLayout = TractLayoutMode.classic;
  double _fontSize = 18.0;
  TextAlign _alignment = TextAlign.left;
  int _selectedPage = 0;
  TractAspectRatio _aspectRatio = TractAspectRatio.portrait;
  TractTextColumns _textColumns = TractTextColumns.one;
  bool _autoFit = true;
  List<WordStudioCustomBackground> _customBackgrounds =
      <WordStudioCustomBackground>[];
  String? _selectedCustomBackgroundId;
  bool _backgroundsLoading = true;
  bool _backgroundImporting = false;
  double _gestureStartScale = 1;

  bool _isExporting = false;

  // Sheet drag state — min = 64 (handle only), max set from layout
  static const double _minSheetHeight = 64.0;
  static const double _defaultSheetHeight = 380.0;
  double _sheetHeight = _defaultSheetHeight;

  late final TextEditingController _hookController;
  late final TextEditingController _invitationController;

  @override
  void initState() {
    super.initState();
    _hookController =
        TextEditingController(text: widget.hook ?? 'Written by .......');
    _invitationController =
        TextEditingController(text: 'You are invited to .......');
    unawaited(_loadCustomBackgrounds());
  }

  @override
  void dispose() {
    _hookController.dispose();
    _invitationController.dispose();
    unawaited(_customBackgroundRepository.close());
    super.dispose();
  }

  double get _designCanvasHeight => _designCanvasWidth / _aspectRatio.ratio;

  String get _canvasSignature =>
      '${_selectedThemeIndex}_${_selectedLayout}_${_fontSize}_${_alignment}_'
      '${_selectedPage}_${_aspectRatio}_${_textColumns}_${_autoFit}_'
      '${_selectedCustomBackgroundId ?? 'default'}_'
      '${_hookController.text}_${_invitationController.text}';

  WordStudioCustomBackground? get _selectedCustomBackground {
    final selectedId = _selectedCustomBackgroundId;
    if (selectedId == null) return null;
    for (final background in _customBackgrounds) {
      if (background.id == selectedId) return background;
    }
    return null;
  }

  TractShareTheme get _activeTheme => _selectedCustomBackground == null
      ? tractThemes[_selectedThemeIndex]
      : _customBackgroundTheme;

  MediaQueryData get _fixedCanvasMediaQuery => MediaQueryData(
        size: Size(_designCanvasWidth, _designCanvasHeight),
        devicePixelRatio: 1.0,
        textScaler: TextScaler.noScaling,
      );

  Widget _buildWordStudioCanvas(
    TractShareTheme activeTheme, {
    Key? key,
  }) {
    return KeyedSubtree(
      key: key,
      child: MediaQuery(
        data: _fixedCanvasMediaQuery,
        child: SizedBox(
          width: _designCanvasWidth,
          height: _designCanvasHeight,
          child: TractCanvas(
            title: widget.title,
            body: widget.body,
            scripture: widget.scripture,
            scriptureRef: widget.scriptureRef,
            hook: _hookController.text,
            invitationText: _invitationController.text,
            theme: activeTheme,
            layoutMode: _selectedLayout,
            fontSize: _fontSize,
            textAlign: _alignment,
            isExportMode: true,
            isUserTract: widget.isUserTract,
            selectedPage: _selectedPage,
            aspectRatio: _aspectRatio,
            textColumns: _textColumns,
            autoFit: _autoFit,
            customBackground: _selectedCustomBackground,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _activeTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            const WordStudioTopBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamic max sheet height is 85% of available space.
                  final maxSheetHeight = constraints.maxHeight * 0.85;
                  final sheetHeight =
                      _sheetHeight.clamp(_minSheetHeight, maxSheetHeight);
                  final previewHeight = constraints.maxHeight - sheetHeight;

                  return Stack(
                    children: [
                      // ── Live Preview Area (dynamically sized) ────────────
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: previewHeight.clamp(0.0, double.infinity),
                        child: _PreviewViewport(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              switchInCurve: Curves.easeOut,
                              child: GestureDetector(
                                key: ValueKey(_canvasSignature),
                                onScaleStart: _selectedCustomBackground == null
                                    ? null
                                    : _startBackgroundGesture,
                                onScaleUpdate: _selectedCustomBackground == null
                                    ? null
                                    : _updateBackgroundGesture,
                                onScaleEnd: _selectedCustomBackground == null
                                    ? null
                                    : _endBackgroundGesture,
                                child: _buildWordStudioCanvas(activeTheme),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Draggable Options Sheet ──────────────────────────
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: sheetHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF172033),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // ── Drag Handle Area ─────────────────────────
                              GestureDetector(
                                onVerticalDragUpdate: (d) {
                                  setState(() {
                                    _sheetHeight =
                                        (_sheetHeight - d.delta.dy).clamp(
                                      _minSheetHeight,
                                      maxSheetHeight,
                                    );
                                  });
                                },
                                onVerticalDragEnd: (_) {
                                  _snapSheet(maxSheetHeight);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white30,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                      ),
                                      if (sheetHeight <=
                                          _minSheetHeight + 8) ...[
                                        const SizedBox(height: 4),
                                        const Text(
                                          '↑ Drag to customise',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white38,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              if (sheetHeight > _minSheetHeight + 8)
                                Expanded(
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      4,
                                      20,
                                      0,
                                    ),
                                    children: [
                                      _buildPageSelectorPanel(),
                                      const _SheetDivider(),
                                      _buildRatioAndColumnsPanel(),
                                      const _SheetDivider(),
                                      _buildThemePresetsRow(),
                                      const _SheetDivider(),
                                      _buildLayoutStylesRow(),
                                      const _SheetDivider(),
                                      _buildTextCustomizationPanel(),
                                      const _SheetDivider(),
                                      _buildTypographyPanel(),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),

                              if (sheetHeight > _minSheetHeight + 32)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: _buildActionButtons(activeTheme),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Snaps to nearest anchor (collapsed=64, half=340, expanded=maxHeight*0.85)
  void _snapSheet(double maxH) {
    final allAnchors = <double>{
      _minSheetHeight,
      _defaultSheetHeight.clamp(_minSheetHeight, maxH),
      maxH,
    }.toList();
    double nearest = allAnchors.reduce((a, b) =>
        ((_sheetHeight - a).abs() < (_sheetHeight - b).abs()) ? a : b);
    setState(() => _sheetHeight = nearest);
  }

  // ── Builder Helpers ──────────────────────────────────────────────────────────

  Future<void> _loadCustomBackgrounds() async {
    try {
      await _customBackgroundRepository.init();
      if (!mounted) return;
      setState(() {
        _customBackgrounds = _customBackgroundRepository.backgrounds;
        _backgroundsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _backgroundsLoading = false);
      _showBackgroundMessage('Custom backgrounds are unavailable: $error');
    }
  }

  Future<void> _pickCustomBackground() async {
    if (_backgroundImporting) return;
    if (_customBackgrounds.length >=
        WordStudioCustomBackgroundRepository.maxBackgrounds) {
      _showBackgroundMessage('You can save up to 20 custom backgrounds.');
      return;
    }

    if (!_customBackgroundRepository.privacyAcknowledged) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Your photo stays private'),
          content: const Text(
            'The selected image is copied into app-private storage and is not '
            'uploaded automatically. It may be included in a portable backup, '
            'and the finished design leaves the app only when you share it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Choose photo'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await _customBackgroundRepository.acknowledgePrivacy();
    }

    try {
      setState(() => _backgroundImporting = true);
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final background = await _customBackgroundRepository.importImage(
        bytes: bytes,
        originalName: image.name,
        mimeType: image.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _customBackgrounds = _customBackgroundRepository.backgrounds;
        _selectedCustomBackgroundId = background.id;
      });
      await HapticFeedback.selectionClick();
    } on WordStudioBackgroundException catch (error) {
      _showBackgroundMessage(error.message);
    } on PlatformException catch (error) {
      _showBackgroundMessage(
        error.message ?? 'The photo picker could not be opened.',
      );
    } catch (error) {
      _showBackgroundMessage('Could not add that image: $error');
    } finally {
      if (mounted) setState(() => _backgroundImporting = false);
    }
  }

  void _startBackgroundGesture(ScaleStartDetails details) {
    _gestureStartScale = _selectedCustomBackground?.scale ?? 1;
  }

  void _updateBackgroundGesture(ScaleUpdateDetails details) {
    final background = _selectedCustomBackground;
    if (background == null) return;
    _replaceCustomBackground(
      background.copyWith(
        scale: _gestureStartScale * details.scale,
        alignmentX: background.alignmentX + (details.focalPointDelta.dx / 140),
        alignmentY: background.alignmentY + (details.focalPointDelta.dy / 140),
      ),
      persist: false,
    );
  }

  void _endBackgroundGesture(ScaleEndDetails details) {
    final background = _selectedCustomBackground;
    if (background != null) {
      unawaited(_customBackgroundRepository.update(background));
    }
  }

  void _replaceCustomBackground(
    WordStudioCustomBackground background, {
    bool persist = true,
  }) {
    if (!_customBackgrounds.any((item) => item.id == background.id)) return;
    setState(() {
      _customBackgrounds = replaceWordStudioCustomBackground(
        _customBackgrounds,
        background,
      );
    });
    if (persist) {
      unawaited(_customBackgroundRepository.update(background));
    }
  }

  Future<void> _renameCustomBackground(
    WordStudioCustomBackground background,
  ) async {
    final controller = TextEditingController(text: background.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename background'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await _customBackgroundRepository.rename(background.id, name);
    if (!mounted) return;
    setState(() {
      _customBackgrounds = _customBackgroundRepository.backgrounds;
    });
  }

  Future<void> _duplicateCustomBackground(
    WordStudioCustomBackground background,
  ) async {
    try {
      final duplicate =
          await _customBackgroundRepository.duplicate(background.id);
      if (!mounted || duplicate == null) return;
      setState(() {
        _customBackgrounds = _customBackgroundRepository.backgrounds;
        _selectedCustomBackgroundId = duplicate.id;
      });
    } on WordStudioBackgroundException catch (error) {
      _showBackgroundMessage(error.message);
    }
  }

  Future<void> _removeCustomBackground(
    WordStudioCustomBackground background,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove background?'),
        content: Text(
          'Remove "${background.displayName}" from Word Studio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _customBackgroundRepository.remove(background.id);
    if (!mounted) return;
    setState(() {
      _customBackgrounds = _customBackgroundRepository.backgrounds;
      if (_selectedCustomBackgroundId == background.id) {
        _selectedCustomBackgroundId = null;
      }
    });
  }

  void _showBackgroundMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPageSelectorPanel() {
    final chunks = TractSlideGenerator.splitBody(widget.body);
    final total = chunks.length;

    final chips = <Widget>[_buildPageChip('Full Page', 0)];
    for (int i = 1; i <= total; i++) {
      chips.add(_buildPageChip('Slide $i', i));
    }
    chips.add(_buildPageChip('Invitation', total + 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'Canvas Slide Mode',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Slides: ${total + 1}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF60A5FA)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                chips.expand((c) => [c, const SizedBox(width: 8)]).toList()
                  ..removeLast(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageChip(String label, int idx) {
    final isSelected = _selectedPage == idx;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (s) {
        if (s) {
          HapticFeedback.selectionClick();
          setState(() => _selectedPage = idx);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side:
            BorderSide(color: isSelected ? Colors.transparent : Colors.white24),
      ),
    );
  }

  Widget _buildRatioAndColumnsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Canvas Ratio ────────────────────────────────────────────────────
        const Text(
          'Canvas Dimensions',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TractAspectRatio.values.map((r) {
              final isSelected = _aspectRatio == r;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _aspectRatio = r);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white24,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Visual ratio box
                      _buildRatioBox(r, isSelected),
                      const SizedBox(height: 6),
                      Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // ── Text Columns ────────────────────────────────────────────────────
        const Text(
          'Text Columns',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          children: TractTextColumns.values.map((c) {
            final isSelected = _textColumns == c;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _textColumns = c);
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: c != TractTextColumns.three ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white24,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildColumnsIcon(c.count, isSelected),
                      const SizedBox(height: 4),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatioBox(TractAspectRatio ratio, bool isSelected) {
    final color =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.white24;

    // Normalise to fit in a 32x32 box
    double w, h;
    if (ratio.ratio >= 1.0) {
      w = 32;
      h = 32 / ratio.ratio;
    } else {
      h = 32;
      w = 32 * ratio.ratio;
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(2),
          color: color.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildColumnsIcon(int count, bool isSelected) {
    final color =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.white38;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          count,
          (i) => Container(
                width: count == 1
                    ? 18
                    : count == 2
                        ? 9
                        : 6,
                height: 18,
                margin: EdgeInsets.only(right: i < count - 1 ? 2 : 0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  border: Border.all(color: color, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
    );
  }

  Widget _buildThemePresetsRow() {
    final selectedCustom = _selectedCustomBackground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var index = 0; index < tractThemes.length; index++)
                _buildDefaultBackgroundTile(index),
              for (final background in _customBackgrounds)
                _buildCustomBackgroundTile(background),
              _buildAddBackgroundTile(),
            ],
          ),
        ),
        if (selectedCustom != null) ...[
          const SizedBox(height: 14),
          _buildCustomBackgroundPanel(selectedCustom),
        ],
      ],
    );
  }

  Widget _buildDefaultBackgroundTile(int index) {
    final theme = tractThemes[index];
    final isSelected =
        _selectedCustomBackgroundId == null && _selectedThemeIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedThemeIndex = index;
          _selectedCustomBackgroundId = null;
        });
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: theme.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: _backgroundTileLabel(theme.name.split(' ').first),
      ),
    );
  }

  Widget _buildCustomBackgroundTile(
    WordStudioCustomBackground background,
  ) {
    final isSelected = _selectedCustomBackgroundId == background.id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCustomBackgroundId = background.id);
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                background.bytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
              const ColoredBox(color: Color(0x42000000)),
              Align(
                alignment: Alignment.bottomCenter,
                child: _backgroundTileLabel(background.displayName),
              ),
              Positioned(
                right: -3,
                top: -3,
                child: PopupMenuButton<_CustomBackgroundAction>(
                  tooltip: 'Background options',
                  padding: EdgeInsets.zero,
                  iconSize: 17,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(30, 30),
                    maximumSize: const Size(30, 30),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (action) =>
                      _handleCustomBackgroundAction(background, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _CustomBackgroundAction.rename,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Rename'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _CustomBackgroundAction.duplicate,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.copy_outlined),
                        title: Text('Duplicate'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _CustomBackgroundAction.remove,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddBackgroundTile() {
    final busy = _backgroundsLoading || _backgroundImporting;
    return Tooltip(
      message: 'Add background',
      child: InkWell(
        onTap: busy ? null : _pickCustomBackground,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'My Background',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _backgroundTileLabel(String label) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCustomBackgroundPanel(
    WordStudioCustomBackground background,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image fit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<BoxFit>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.white70,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.selected)
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white24,
                ),
              ),
            ),
            segments: const [
              ButtonSegment(
                value: BoxFit.cover,
                label: Text('Cover'),
                icon: Icon(Icons.crop),
              ),
              ButtonSegment(
                value: BoxFit.contain,
                label: Text('Contain'),
                icon: Icon(Icons.fit_screen),
              ),
              ButtonSegment(
                value: BoxFit.fill,
                label: Text('Fill'),
                icon: Icon(Icons.aspect_ratio),
              ),
            ],
            selected: <BoxFit>{background.fit},
            onSelectionChanged: (selection) {
              _replaceCustomBackground(
                background.copyWith(fit: selection.first),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Dark overlay',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(background.overlayOpacity * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: background.overlayOpacity,
          min: 0,
          max: 0.8,
          divisions: 16,
          label: '${(background.overlayOpacity * 100).round()}%',
          onChanged: (value) {
            _replaceCustomBackground(
              background.copyWith(overlayOpacity: value),
              persist: false,
            );
          },
          onChangeEnd: (_) {
            final selected = _selectedCustomBackground;
            if (selected != null) {
              unawaited(_customBackgroundRepository.update(selected));
            }
          },
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Zoom',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _replaceCustomBackground(
                  background.copyWith(
                    scale: 1,
                    alignmentX: 0,
                    alignmentY: 0,
                  ),
                );
              },
              tooltip: 'Reset position and zoom',
              icon: const Icon(Icons.center_focus_strong_outlined),
              color: Colors.white70,
            ),
          ],
        ),
        Slider(
          value: background.scale,
          min: 1,
          max: 3,
          divisions: 20,
          label: '${background.scale.toStringAsFixed(1)}x',
          onChanged: (value) {
            _replaceCustomBackground(
              background.copyWith(scale: value),
              persist: false,
            );
          },
          onChangeEnd: (_) {
            final selected = _selectedCustomBackground;
            if (selected != null) {
              unawaited(_customBackgroundRepository.update(selected));
            }
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => _removeCustomBackground(background),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove background'),
          ),
        ),
      ],
    );
  }

  void _handleCustomBackgroundAction(
    WordStudioCustomBackground background,
    _CustomBackgroundAction action,
  ) {
    switch (action) {
      case _CustomBackgroundAction.rename:
        unawaited(_renameCustomBackground(background));
      case _CustomBackgroundAction.duplicate:
        unawaited(_duplicateCustomBackground(background));
      case _CustomBackgroundAction.remove:
        unawaited(_removeCustomBackground(background));
    }
  }

  Widget _buildLayoutStylesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layout Style',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildLayoutTile(
                'Classic', TractLayoutMode.classic, Icons.grid_view_rounded),
            const SizedBox(width: 8),
            _buildLayoutTile('Quote', TractLayoutMode.quoteFocus,
                Icons.format_quote_rounded),
            const SizedBox(width: 8),
            _buildLayoutTile('Scripture', TractLayoutMode.scriptureFocus,
                Icons.menu_book_rounded),
            const SizedBox(width: 8),
            _buildLayoutTile(
                'Minimal', TractLayoutMode.minimalist, Icons.notes_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutTile(String label, TractLayoutMode mode, IconData icon) {
    final isSelected = _selectedLayout == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedLayout = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white24,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypographyPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Typography & Alignment',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),

        // ── Alignment (Left / Center / Justify) ─────────────────────────────
        Row(
          children: [
            _buildAlignBtn(
                Icons.align_horizontal_left_rounded, 'Left', TextAlign.left),
            const SizedBox(width: 8),
            _buildAlignBtn(Icons.align_horizontal_center_rounded, 'Center',
                TextAlign.center),
            const SizedBox(width: 8),
            _buildAlignBtn(Icons.format_align_justify_rounded, 'Justify',
                TextAlign.justify),
          ],
        ),

        const SizedBox(height: 14),

        // ── Font Size ────────────────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.format_size_rounded,
                size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              'Size: ${_fontSize.toStringAsFixed(1)}px',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Slider(
                value: _fontSize,
                min: 8.0,
                max: 28.0,
                divisions: 20, // 1px steps
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _fontSize = v),
              ),
            ),
          ],
        ),

        // ── Auto-Fit Toggle ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _autoFit = !_autoFit);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _autoFit
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: _autoFit
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white24,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fit_screen_rounded,
                  size: 18,
                  color: _autoFit
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Fit Text to Canvas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _autoFit ? Colors.white : Colors.white70,
                        ),
                      ),
                      Text(
                        'Shrinks all text so the full tract fits inside the image',
                        style: TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoFit,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _autoFit = v);
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  trackOutlineColor: WidgetStateProperty.all(Colors.white24),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextCustomizationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customize Text details',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),

        // ── Hook / Writer Input ──
        const Text(
          'Writer / Hook',
          style: TextStyle(
              fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _hookController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. Written by .......',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
        const SizedBox(height: 14),

        // ── Invitation Message Input ──
        const Text(
          'Invitation Card Message (Churches/Org)',
          style: TextStyle(
              fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _invitationController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. You are invited to .......',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildAlignBtn(IconData icon, String label, TextAlign align) {
    final isSelected = _alignment == align;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _alignment = align);
        },
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white60,
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildActionButtons(TractShareTheme activeTheme) {
    return Row(
      children: [
        // ── Download Button ──
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isExporting ? null : () => _exportAndProcess(share: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.white24, width: 1.5),
              ),
            ),
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.0, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'Download',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── Share Button ──
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isExporting ? null : () => _exportAndProcess(share: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.0, color: Colors.white),
                  )
                : const Icon(Icons.share_rounded, size: 18),
            label: const Text(
              'Share',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportAndProcess({required bool share}) async {
    setState(() => _isExporting = true);
    try {
      final activeTheme = _activeTheme;

      final exportWidget = Material(
        color: Colors.transparent,
        child: _buildWordStudioCanvas(activeTheme),
      );

      // Fix for "View.of() context" crash on Flutter Web / multi-view:
      // captureFromWidget renders outside the normal tree, so we must
      // provide Directionality + MediaQuery manually, AND pass context.
      final bytes = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: _fixedCanvasMediaQuery,
            child: exportWidget,
          ),
        ),
        delay: const Duration(milliseconds: 200),
        pixelRatio: _exportPixelRatio,
        context: context,
      );

      final filename = 'tract_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        if (share) {
          // On Web, native sharing is handled via Web Share API if supported
          try {
            final file =
                XFile.fromData(bytes, name: filename, mimeType: 'image/png');
            await Share.shareXFiles(
              [file],
              subject: widget.title,
              text: 'Shared from The Word App ✨',
            );
          } catch (e) {
            // Fallback to download if Web Share is unsupported or fails
            downloadImageWeb(bytes, filename);
          }
        } else {
          downloadImageWeb(bytes, filename);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(share ? 'Design shared!' : 'Design downloaded! 🚀'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = await File('${dir.path}/$filename').create();
        await file.writeAsBytes(bytes);

        if (share) {
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'image/png')],
            subject: widget.title,
            text: 'Shared from The Word App ✨',
          );
        } else {
          // Non-web download / save to temp + notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to temporary files: $filename'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Share',
                  textColor: Colors.white,
                  onPressed: () {
                    Share.shareXFiles(
                      [XFile(file.path, mimeType: 'image/png')],
                      subject: widget.title,
                      text: 'Shared from The Word App ✨',
                    );
                  },
                ),
              ),
            );
          }
        }
      }

      await AppHaptics.shareTriggered();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

enum _CustomBackgroundAction { rename, duplicate, remove }

// ── Shared Sub-Widgets ────────────────────────────────────────────────────────

class _PreviewViewport extends StatelessWidget {
  final Widget child;

  const _PreviewViewport({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: child,
        ),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 28, color: Colors.white10);
  }
}
