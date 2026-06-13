import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/web_helper.dart';
import '../model/tract_share_theme.dart';
import 'widgets/tract_canvas.dart';

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

  // Customization state
  int _selectedThemeIndex = 0;
  TractLayoutMode _selectedLayout = TractLayoutMode.classic;
  double _fontSize = 18.0;
  TextAlign _alignment = TextAlign.left;
  int _selectedPage = 0;
  TractAspectRatio _aspectRatio = TractAspectRatio.portrait;
  TractTextColumns _textColumns = TractTextColumns.one;
  bool _autoFit = true;

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
  }

  @override
  void dispose() {
    _hookController.dispose();
    _invitationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = tractThemes[_selectedThemeIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Dynamic max sheet height is 85% of available space
            final maxSheetHeight = constraints.maxHeight * 0.85;
            // Preview area fills remaining space
            final previewHeight =
                constraints.maxHeight - _sheetHeight - 56.0; // 56 = top bar

            return Stack(
              children: [
                // ── Studio Top Header ──────────────────────────────────────
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _StudioTopBar(),
                ),

                // ── Live Preview Area (dynamically sized) ──────────────────
                Positioned(
                  top: 56.0,
                  left: 0,
                  right: 0,
                  height: previewHeight.clamp(0.0, double.infinity),
                  child: _PreviewViewport(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 360,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOut,
                          child: TractCanvas(
                            key: ValueKey(
                              '${_selectedThemeIndex}_${_selectedLayout}_${_fontSize}_${_alignment}_${_selectedPage}_${_aspectRatio}_$_textColumns',
                            ),
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
                            isExportMode: false,
                            isUserTract: widget.isUserTract,
                            selectedPage: _selectedPage,
                            aspectRatio: _aspectRatio,
                            textColumns: _textColumns,
                            autoFit: _autoFit,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Draggable Options Sheet ────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _sheetHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF172033),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
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
                        // ── Drag Handle Area ───────────────────────────────
                        GestureDetector(
                          onVerticalDragUpdate: (d) {
                            setState(() {
                              // Dragging UP = negative delta.dy = sheet grows
                              // Dragging Down = positive delta.dy = sheet shrinks
                              _sheetHeight = (_sheetHeight - d.delta.dy)
                                  .clamp(_minSheetHeight, maxSheetHeight);
                            });
                          },
                          onVerticalDragEnd: (_) {
                            // Snap to nearest anchor
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
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                if (_sheetHeight <= _minSheetHeight + 8) ...[
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

                        // ── Scrollable Controls (hidden when nearly collapsed) ──
                        if (_sheetHeight > _minSheetHeight + 8)
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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

                        // ── Static Download Button (only when tall enough) ─────
                        if (_sheetHeight > _minSheetHeight + 32)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
    );
  }

  /// Snaps to nearest anchor (collapsed=64, half=340, expanded=maxHeight*0.85)
  void _snapSheet(double maxH) {
    const anchors = [_minSheetHeight, _defaultSheetHeight];
    final allAnchors = [...anchors, maxH];
    double nearest = allAnchors.reduce((a, b) =>
        ((_sheetHeight - a).abs() < (_sheetHeight - b).abs()) ? a : b);
    setState(() => _sheetHeight = nearest);
  }

  // ── Builder Helpers ──────────────────────────────────────────────────────────

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visual Styles & Gradients',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tractThemes.length,
            itemBuilder: (context, i) {
              final t = tractThemes[i];
              final isSelected = _selectedThemeIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedThemeIndex = i);
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: t.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white24,
                      width: isSelected ? 3.0 : 1.5,
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
                        : [],
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        t.name.split(' ').first,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
      final activeTheme = tractThemes[_selectedThemeIndex];

      // Canvas width in logical pixels for the chosen ratio
      const double exportWidth = 1080.0;
      final double exportHeight = exportWidth / _aspectRatio.ratio;

      final exportWidget = Material(
        color: Colors.transparent,
        child: SizedBox(
          width: exportWidth,
          height: exportHeight,
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
          ),
        ),
      );

      // Fix for "View.of() context" crash on Flutter Web / multi-view:
      // captureFromWidget renders outside the normal tree, so we must
      // provide Directionality + MediaQuery manually, AND pass context.
      final bytes = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 1.0),
            child: exportWidget,
          ),
        ),
        delay: const Duration(milliseconds: 200),
        pixelRatio: 3.0,
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

// ── Shared Sub-Widgets ────────────────────────────────────────────────────────

class _StudioTopBar extends StatelessWidget {
  const _StudioTopBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppBranding.wordStudio,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create • Share • Inspire',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
