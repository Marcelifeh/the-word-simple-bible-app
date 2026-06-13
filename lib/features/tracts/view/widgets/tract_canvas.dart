import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/tract_share_theme.dart';

enum TractLayoutMode { classic, quoteFocus, minimalist, scriptureFocus }

enum TractAspectRatio {
  square('1:1 Square', 1.0),
  portrait('4:5 Portrait', 4.0 / 5.0),
  story('9:16 Story', 9.0 / 16.0),
  landscape('3:2 Landscape', 3.0 / 2.0),
  a4('A4 Print', 210.0 / 297.0);

  final String label;
  final double ratio;
  const TractAspectRatio(this.label, this.ratio);
}

enum TractTextColumns {
  one(1, '1 Col'),
  two(2, '2 Col'),
  three(3, '3 Col');

  final int count;
  final String label;
  const TractTextColumns(this.count, this.label);
}

/// Splits body text into ~300-char paragraph slides.
class TractSlideGenerator {
  static List<String> splitBody(String body) {
    final paragraphs = body.split('\n\n');
    final slides = <String>[];
    String current = '';

    for (final p in paragraphs) {
      final t = p.trim();
      if (t.isEmpty) continue;
      if (current.isNotEmpty && (current.length + t.length) > 300) {
        slides.add(current.trim());
        current = t;
      } else {
        current = current.isEmpty ? t : '$current\n\n$t';
      }
    }

    if (current.isNotEmpty) slides.add(current.trim());
    if (slides.isEmpty) slides.add(body);
    return slides;
  }
}

/// Premium backdrop painter — rays, particles, cross motifs.
class TractBackgroundPainter extends CustomPainter {
  final Color accentColor;
  final bool drawCross, drawRays, drawStars, drawParticles;

  TractBackgroundPainter({
    required this.accentColor,
    this.drawCross = false,
    this.drawRays = false,
    this.drawStars = false,
    this.drawParticles = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);

    if (drawRays) {
      final center = Offset(size.width * 0.5, size.height * 0.2);
      const rayCount = 14;
      final paint = Paint()
        ..color = accentColor.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < rayCount; i++) {
        final a1 = (i * 2 * math.pi) / rayCount - (math.pi / 2);
        final a2 = ((i + 0.35) * 2 * math.pi) / rayCount - (math.pi / 2);
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy)
            ..lineTo(center.dx + 1200 * math.cos(a1),
                center.dy + 1200 * math.sin(a1))
            ..lineTo(center.dx + 1200 * math.cos(a2),
                center.dy + 1200 * math.sin(a2))
            ..close(),
          paint,
        );
      }
    }

    if (drawParticles) {
      final p = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 18; i++) {
        p.color =
            accentColor.withValues(alpha: rand.nextDouble() * 0.12 + 0.03);
        canvas.drawCircle(
          Offset(
              rand.nextDouble() * size.width, rand.nextDouble() * size.height),
          rand.nextDouble() * 5 + 2,
          p,
        );
      }
    }

    if (drawCross) {
      final cp = Paint()
        ..color = accentColor.withValues(alpha: 0.025)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;
      final cx = size.width * 0.5;
      final cy = size.height * 0.35;
      const ch = 110.0, cw = 64.0;
      final path = Path()
        ..moveTo(cx, cy - ch / 2)
        ..lineTo(cx, cy + ch / 2)
        ..moveTo(cx - cw / 2, cy - ch * 0.12)
        ..lineTo(cx + cw / 2, cy - ch * 0.12);
      canvas.drawPath(path, cp);
      canvas.drawPath(
          path,
          Paint()
            ..color = accentColor.withValues(alpha: 0.01)
            ..strokeWidth = 20
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant TractBackgroundPainter old) =>
      old.accentColor != accentColor;
}

/// The main tract card widget — layout always matches preview exactly.
/// High DPI export is handled via pixelRatio in captureFromWidget.
class TractCanvas extends StatelessWidget {
  final String title;
  final String body;
  final String? scripture;
  final String? scriptureRef;
  final String? hook;
  final String? invitationText;
  final TractShareTheme theme;
  final TractLayoutMode layoutMode;
  final double fontSize;
  final TextAlign textAlign;
  final bool isExportMode;
  final bool isUserTract;
  final int selectedPage;
  final TractAspectRatio aspectRatio;
  final TractTextColumns textColumns;

  /// When true wraps content in FittedBox so nothing ever overflows.
  final bool autoFit;

  const TractCanvas({
    super.key,
    required this.title,
    required this.body,
    this.scripture,
    this.scriptureRef,
    this.hook,
    this.invitationText,
    required this.theme,
    this.layoutMode = TractLayoutMode.classic,
    this.fontSize = 16,
    this.textAlign = TextAlign.left,
    this.isExportMode = false,
    this.isUserTract = false,
    this.selectedPage = 0,
    this.aspectRatio = TractAspectRatio.portrait,
    this.textColumns = TractTextColumns.one,
    this.autoFit = true,
  });

  double _calculateAutoFitFontSize(
      double baseFontSize, double availWidth, double availHeight) {
    const padding = 36.0; // 18 * 2
    final colCount = textColumns.count;
    final gapWidth = (colCount - 1) * 10.0;
    final totalTextWidth = availWidth - padding - gapWidth;
    final widthPerCol = totalTextWidth / colCount;
    if (widthPerCol <= 0) return 5.0;

    final hasHook = hook != null && hook!.trim().isNotEmpty;
    final hasScripture = scripture != null && scripture!.trim().isNotEmpty;

    final titleFontSize =
        layoutMode == TractLayoutMode.quoteFocus ? 22.0 : 24.0;
    final hookFontSize = layoutMode == TractLayoutMode.quoteFocus ? 10.0 : 11.0;
    const double titleBodyGap = 4.0;
    const double footerReserve = 36.0;
    const double innerPad = 18.0;

    for (double size = baseFontSize; size >= 5.0; size -= 0.5) {
      final contentHeight = _calculateContentHeight(
        size,
        widthPerCol,
        colCount,
        hasHook,
        hasScripture,
        titleFontSize,
        hookFontSize,
        titleBodyGap,
        footerReserve,
        innerPad,
      );

      if (contentHeight <= availHeight) {
        return size;
      }
    }
    return 5.0;
  }

  double _calculateContentHeight(
    double size,
    double widthPerCol,
    int colCount,
    bool hasHook,
    bool hasScripture,
    double titleFontSize,
    double hookFontSize,
    double titleBodyGap,
    double footerReserve,
    double innerPad,
  ) {
    if (widthPerCol <= 0) return 9999.0;
    double totalHeight = 0;

    // 1. Hook
    if (hasHook && (selectedPage == 0 || selectedPage == 1)) {
      final tp = TextPainter(
        text: TextSpan(
          text: hook!.toUpperCase().trim(),
          style: TextStyle(
            fontSize: hookFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontFamily: theme.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: widthPerCol);
      totalHeight += tp.size.height + 4.0;
    }

    // 2. Title & Divider
    if (selectedPage == 0 || selectedPage == 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: title.trim(),
          style: TextStyle(
            fontSize: titleFontSize,
            height: 1.2,
            fontWeight: FontWeight.w900,
            fontFamily: theme.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: widthPerCol);
      totalHeight += tp.size.height + titleBodyGap;

      if (layoutMode == TractLayoutMode.minimalist) {
        totalHeight += 10.0;
      } else {
        totalHeight += 18.0;
      }
    }

    // 3. Body text
    final trimmedBody = body.trim();
    final chunks = TractSlideGenerator.splitBody(trimmedBody);
    String textToMeasure = trimmedBody;
    if (selectedPage >= 1 && selectedPage <= chunks.length) {
      textToMeasure = chunks[selectedPage - 1];
    } else if (selectedPage > chunks.length) {
      textToMeasure = '';
    }

    if (textToMeasure.isNotEmpty) {
      final bodyStyle = TextStyle(
        fontSize: layoutMode == TractLayoutMode.quoteFocus ? size * 0.93 : size,
        height: 1.55,
        fontFamily: theme.fontFamily,
      );

      if (colCount > 1) {
        final paragraphs = textToMeasure
            .split('\n\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        final perCol = (paragraphs.length / colCount).ceil();
        double maxColHeight = 0;

        for (int i = 0; i < colCount; i++) {
          final start = i * perCol;
          final end = (start + perCol).clamp(0, paragraphs.length);
          if (start >= paragraphs.length) continue;
          final colText = paragraphs.sublist(start, end).join('\n\n');

          final tp = TextPainter(
            text: TextSpan(text: colText, style: bodyStyle),
            textDirection: TextDirection.ltr,
          );
          tp.layout(maxWidth: widthPerCol);
          if (tp.size.height > maxColHeight) {
            maxColHeight = tp.size.height;
          }
        }
        totalHeight += maxColHeight;
      } else {
        final tp = TextPainter(
          text: TextSpan(text: textToMeasure, style: bodyStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: widthPerCol);
        totalHeight += tp.size.height;
      }
    }

    // 4. Scripture card & invitation
    final isQuote = layoutMode == TractLayoutMode.quoteFocus;
    final cardFontSize = isQuote ? size * 0.94 : size * 0.82;

    if (colCount == 1) {
      if (selectedPage == 0) {
        if (hasScripture) {
          totalHeight += 10.0;
          totalHeight +=
              _estimateScriptureCardHeight(cardFontSize, widthPerCol, isQuote);
        }
        totalHeight += 10.0;
        totalHeight += _estimateInvitationHeight(widthPerCol);
      } else if (selectedPage >= 1 && selectedPage <= chunks.length) {
        totalHeight += 6.0;
      } else if (selectedPage == chunks.length + 1) {
        if (hasScripture) {
          totalHeight +=
              _estimateScriptureCardHeight(cardFontSize, widthPerCol, isQuote);
          totalHeight += 10.0;
        }
        totalHeight += _estimateInvitationHeight(widthPerCol);
      }
    } else {
      // In multi-column, it always acts like selectedPage == 0 (all content on one page)
      totalHeight += 18.0;
      if (hasScripture) {
        // Multi-column cards span the full width (or we can assume they span widthPerCol? Usually they span the full width of all columns combined).
        // Let's use the full total text width for estimating the card.
        final fullWidth = (widthPerCol * colCount) + ((colCount - 1) * 10.0);
        totalHeight +=
            _estimateScriptureCardHeight(cardFontSize, fullWidth, isQuote);
        totalHeight += 10.0;
      }
      totalHeight += 10.0;
      final fullWidth = (widthPerCol * colCount) + ((colCount - 1) * 10.0);
      totalHeight += _estimateInvitationHeight(fullWidth);
    }

    // 5. Padding
    totalHeight += innerPad;
    totalHeight += footerReserve;

    return totalHeight;
  }

  double _estimateScriptureCardHeight(
      double cardFontSize, double width, bool isQuote) {
    if (scripture == null || scripture!.trim().isEmpty) return 0;
    final double cardPadding = isQuote ? 28.0 : 20.0;
    final double iconHeight = isQuote ? 26.0 : 20.0;
    const double gap = 4.0;

    final cardInnerWidth = width - (isQuote ? 28.0 : 20.0);
    if (cardInnerWidth <= 0) return 0;

    final tpScripture = TextPainter(
      text: TextSpan(
        text: scripture!.trim(),
        style: TextStyle(
          fontSize: cardFontSize,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.45,
          fontFamily: theme.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tpScripture.layout(maxWidth: cardInnerWidth);
    double textHeight = tpScripture.size.height;

    double refHeight = 0;
    if (scriptureRef != null && scriptureRef!.isNotEmpty) {
      final tpRef = TextPainter(
        text: TextSpan(
          text: '— ${scriptureRef!.trim()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: theme.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tpRef.layout(maxWidth: cardInnerWidth);
      refHeight = 6.0 + tpRef.size.height;
    }

    return cardPadding + iconHeight + gap + textHeight + refHeight + 4.0;
  }

  double _estimateInvitationHeight(double width) {
    final invite = (invitationText != null && invitationText!.trim().isNotEmpty)
        ? invitationText!.trim()
        : 'You are invited to .......';
    final cardInnerWidth = width - 24.0;
    if (cardInnerWidth <= 0) return 0;

    final tpInvite = TextPainter(
      text: TextSpan(
        text: invite,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
          fontFamily: theme.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tpInvite.layout(maxWidth: cardInnerWidth);

    return 24.0 + 22.0 + 6.0 + tpInvite.size.height + 4.0;
  }

  @override
  Widget build(BuildContext context) {
    final hasScripture = scripture != null && scripture!.trim().isNotEmpty;
    final hasHook = hook != null && hook!.trim().isNotEmpty;

    final crossAxis = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    // Compact spacings — reduces the large gaps
    const double titleBodyGap = 4.0;
    const double innerPad = 18.0;

    return AspectRatio(
      aspectRatio: aspectRatio.ratio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isExportMode ? 0 : 20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.gradientColors,
          ),
          border: theme.useGoldBorder
              ? Border.all(color: const Color(0xFFFFD700), width: 2.5)
              : null,
          boxShadow: isExportMode
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 7))
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isExportMode ? 0 : 17),
          child: Stack(
            children: [
              // Background decorations
              Positioned.fill(
                child: CustomPaint(
                  painter: TractBackgroundPainter(
                    accentColor: theme.accentColor,
                    drawCross: theme.useParchmentStyle ||
                        theme.id == 'midnight' ||
                        theme.id == 'stars',
                    drawRays: theme.useClouds ||
                        theme.id == 'fire' ||
                        theme.id == 'sunset',
                    drawStars: theme.useStars || theme.id == 'gold',
                    drawParticles: theme.id == 'sunset' ||
                        theme.id == 'emerald' ||
                        theme.id == 'lavender' ||
                        theme.id == 'fire',
                  ),
                ),
              ),
              if (theme.useParchmentStyle) _buildParchmentOverlay(),
              if (theme.useClouds) _buildCloudsOverlay(),
              if (theme.useStars) _buildStarsOverlay(),
              if (theme.useFireGlow) _buildFireGlowOverlay(),

              // Fixed footer pinned at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: innerPad, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.gradientColors.last.withValues(alpha: 0.0),
                        theme.gradientColors.last.withValues(alpha: 0.85),
                        theme.gradientColors.last,
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                  child: _buildBrandingFooter(),
                ),
              ),

              // Content — LayoutBuilder gives us the exact available size
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final availW = constraints.maxWidth;
                    final availH = constraints.maxHeight;

                    // Reserve space for the fixed footer
                    const footerReserve = 36.0;
                    final contentAvailH = availH - footerReserve;
                    const padding = 36.0; // 18 * 2
                    final colCount = textColumns.count;
                    final gapWidth = (colCount - 1) * 10.0;
                    final totalTextWidth = availW - padding - gapWidth;
                    final widthPerCol = totalTextWidth / colCount;

                    // Calculate the active font size
                    final fitSize =
                        _calculateAutoFitFontSize(18.0, availW, contentAvailH);
                    final activeFontSize =
                        autoFit ? fitSize * (fontSize / 18.0) : fontSize;

                    final titleFontSize =
                        layoutMode == TractLayoutMode.quoteFocus
                            ? activeFontSize * 1.375
                            : activeFontSize * 1.5;
                    final hookFontSize =
                        layoutMode == TractLayoutMode.quoteFocus
                            ? activeFontSize * 0.625
                            : activeFontSize * 0.6875;

                    // Header & top children rendered with the calculated active size
                    final contentChildren = <Widget>[
                      if (hasHook &&
                          (selectedPage == 0 || selectedPage == 1)) ...[
                        Text(
                          hook!.toUpperCase().trim(),
                          textAlign: textAlign,
                          style: TextStyle(
                            fontSize: hookFontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: theme.accentColor.withValues(alpha: 0.9),
                            fontFamily: theme.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      if (selectedPage == 0 || selectedPage == 1) ...[
                        Text(
                          title.trim(),
                          textAlign: textAlign,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: theme.textColor,
                            fontFamily: theme.fontFamily,
                          ),
                        ),
                        SizedBox(height: titleBodyGap),
                      ],

                      if (selectedPage == 0 || selectedPage == 1)
                        _buildSectionDivider(),

                      _buildPageContent(hasScripture, activeFontSize),

                      // Bottom spacer to ensure content doesn't overlap the fixed footer
                      SizedBox(height: footerReserve),
                    ];

                    final contentColumn = Column(
                      crossAxisAlignment: crossAxis,
                      mainAxisSize: MainAxisSize.min,
                      children: contentChildren,
                    );

                    final innerContent = Padding(
                      padding: const EdgeInsets.only(
                        left: innerPad,
                        right: innerPad,
                        top: innerPad,
                        bottom: 0,
                      ),
                      child: textColumns.count == 1
                          ? contentColumn
                          : _buildMultiColumnContent(crossAxis, hasScripture,
                              contentChildren, activeFontSize),
                    );

                    final contentHeight = _calculateContentHeight(
                      activeFontSize,
                      widthPerCol,
                      colCount,
                      hasHook,
                      hasScripture,
                      titleFontSize,
                      hookFontSize,
                      titleBodyGap,
                      footerReserve,
                      innerPad,
                    );

                    final bool fits = contentHeight <= contentAvailH;

                    if (autoFit) {
                      if (fits) {
                        return SizedBox(
                          width: availW,
                          height: contentAvailH,
                          child: Center(
                            child: innerContent,
                          ),
                        );
                      } else {
                        // Fallback: use FittedBox to scale down only if it exceeds the boundary at min font size
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: availW,
                            child: innerContent,
                          ),
                        );
                      }
                    } else {
                      // Non-auto-fit: scrollable in preview (never in export)
                      return SingleChildScrollView(
                        physics: isExportMode
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: availW,
                          child: innerContent,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Multi-column layout ───────────────────────────────────────────────────

  Widget _buildMultiColumnContent(
    CrossAxisAlignment crossAxis,
    bool hasScripture,
    List<Widget> headerChildren,
    double activeFontSize,
  ) {
    final paragraphs =
        body.split('\n\n').where((s) => s.trim().isNotEmpty).toList();
    final count = textColumns.count;
    final perCol = (paragraphs.length / count).ceil();

    final bodyColumns = List.generate(count, (i) {
      final start = i * perCol;
      final end = (start + perCol).clamp(0, paragraphs.length);
      if (start >= paragraphs.length) {
        return const Expanded(child: SizedBox.shrink());
      }
      final colText = paragraphs.sublist(start, end).join('\n\n');
      return Expanded(child: _buildBodyText(colText, activeFontSize));
    });

    // Header items (hook + title + divider) stay full-width above the columns
    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hook != null &&
            hook!.trim().isNotEmpty &&
            (selectedPage == 0 || selectedPage == 1)) ...[
          Text(hook!.toUpperCase().trim(),
              textAlign: textAlign,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: theme.accentColor.withValues(alpha: 0.9),
                  fontFamily: theme.fontFamily)),
          const SizedBox(height: 4),
        ],
        if (selectedPage == 0 || selectedPage == 1) ...[
          Text(title.trim(),
              textAlign: textAlign,
              style: TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  fontFamily: theme.fontFamily)),
          const SizedBox(height: 4),
          _buildSectionDivider(),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: bodyColumns
              .expand((col) => [col, const SizedBox(width: 10)])
              .toList()
            ..removeLast(),
        ),
        const SizedBox(height: 18),
        if (hasScripture) ...[
          _buildScriptureCard(activeFontSize),
          const SizedBox(height: 10),
        ],
        _buildInvitationBlock(activeFontSize),
        const SizedBox(
            height: 36.0), // Spacer reserving room for fixed branding footer
      ],
    );
  }

  // ── Page content routing ──────────────────────────────────────────────────

  Widget _buildPageContent(bool hasScripture, double activeFontSize) {
    final chunks = TractSlideGenerator.splitBody(body);

    if (selectedPage == 0) {
      return Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBodyText(body, activeFontSize),
          if (hasScripture) ...[
            SizedBox(height: activeFontSize * 0.6),
            _buildScriptureCard(activeFontSize),
          ],
          SizedBox(height: activeFontSize * 0.6),
          _buildInvitationBlock(activeFontSize),
        ],
      );
    }

    if (selectedPage >= 1 && selectedPage <= chunks.length) {
      return Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: activeFontSize * 0.35),
          _buildBodyText(chunks[selectedPage - 1], activeFontSize),
        ],
      );
    }

    if (selectedPage == chunks.length + 1) {
      return Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasScripture) ...[
            _buildScriptureCard(activeFontSize),
            SizedBox(height: activeFontSize * 0.6),
          ],
          _buildInvitationBlock(activeFontSize),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBodyText(String text, double activeFontSize) {
    final size = layoutMode == TractLayoutMode.quoteFocus
        ? activeFontSize * 0.93
        : activeFontSize;
    return Text(
      text.trim(),
      textAlign: textAlign,
      style: TextStyle(
        fontSize: size,
        height: 1.55,
        color: layoutMode == TractLayoutMode.quoteFocus
            ? theme.textColor.withValues(alpha: 0.85)
            : theme.textColor,
        fontFamily: theme.fontFamily,
      ),
    );
  }

  Widget _buildScriptureCard(double activeFontSize) {
    if (scripture == null || scripture!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final isQuote = layoutMode == TractLayoutMode.quoteFocus;
    final cardFontSize =
        isQuote ? activeFontSize * 0.94 : activeFontSize * 0.82;
    final double paddingVal = isQuote
        ? activeFontSize * (14.0 / 16.0)
        : activeFontSize * (10.0 / 16.0);
    final double iconSize = isQuote
        ? activeFontSize * (26.0 / 16.0)
        : activeFontSize * (20.0 / 16.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(paddingVal.clamp(6.0, 24.0)),
      decoration: BoxDecoration(
        color: theme.dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.accentColor.withValues(alpha: isQuote ? 0.4 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: theme.accentColor.withValues(alpha: 0.6),
            size: iconSize.clamp(12.0, 32.0),
          ),
          SizedBox(height: activeFontSize * 0.25),
          Text(
            scripture!.trim(),
            textAlign: textAlign,
            style: TextStyle(
              fontSize: cardFontSize,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.45,
              color: theme.textColor,
              fontFamily: theme.fontFamily,
            ),
          ),
          if (scriptureRef != null && scriptureRef!.isNotEmpty) ...[
            SizedBox(height: activeFontSize * 0.35),
            Text(
              '— ${scriptureRef!.trim()}',
              style: TextStyle(
                fontSize: activeFontSize * 0.75,
                fontWeight: FontWeight.bold,
                color: theme.accentColor,
                fontFamily: theme.fontFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvitationBlock(double activeFontSize) {
    final invite = (invitationText != null && invitationText!.trim().isNotEmpty)
        ? invitationText!.trim()
        : 'You are invited to .......';
    final double paddingVal = activeFontSize * (12.0 / 16.0);
    final double iconSize = activeFontSize * (22.0 / 16.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(paddingVal.clamp(6.0, 20.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          theme.accentColor.withValues(alpha: 0.14),
          theme.accentColor.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.22), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: theme.accentColor,
            size: iconSize.clamp(12.0, 28.0),
          ),
          SizedBox(height: activeFontSize * 0.35),
          Text(
            invite,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: activeFontSize * (12.0 / 16.0),
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: theme.textColor,
              fontFamily: theme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    if (layoutMode == TractLayoutMode.minimalist) {
      return Container(
          width: 44,
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: theme.accentColor.withValues(alpha: 0.4));
    }
    final char = layoutMode == TractLayoutMode.scriptureFocus ? '✝' : '✦';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 24,
              height: 1,
              color: theme.accentColor.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(char,
                style: TextStyle(fontSize: 10, color: theme.accentColor)),
          ),
          Container(
              width: 24,
              height: 1,
              color: theme.accentColor.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildBrandingFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_rounded,
            color: theme.accentColor.withValues(alpha: 0.6), size: 13),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            isUserTract
                ? 'Created with The Word App'
                : 'Shared from The Word App • Read • Grow • Share',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: theme.textColor.withValues(alpha: 0.5),
                letterSpacing: 0.3,
                fontFamily: theme.fontFamily),
          ),
        ),
      ],
    );
  }

  // ── Overlays ──────────────────────────────────────────────────────────────

  Widget _buildParchmentOverlay() => Positioned.fill(
        child: Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/home_hero_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Color(0xFF8B5A2B), BlendMode.color),
                ),
              ),
            )),
      );

  Widget _buildCloudsOverlay() => Positioned.fill(
        child: Opacity(
            opacity: 0.1,
            child: Stack(children: [
              Positioned(
                  top: -30,
                  right: -40,
                  child: Icon(Icons.cloud_queue_rounded,
                      size: 180, color: Colors.white)),
              Positioned(
                  bottom: -40,
                  left: -50,
                  child: Icon(Icons.cloud_rounded,
                      size: 230, color: Colors.white)),
            ])),
      );

  Widget _buildStarsOverlay() => Positioned.fill(
        child: Opacity(
            opacity: 0.2,
            child: Stack(children: [
              Positioned(
                  top: 40,
                  right: 80,
                  child: Icon(Icons.star_purple500_rounded,
                      size: 14, color: theme.accentColor)),
              Positioned(
                  top: 150,
                  left: 40,
                  child:
                      Icon(Icons.star_rounded, size: 10, color: Colors.white)),
              Positioned(
                  bottom: 120,
                  right: 50,
                  child: Icon(Icons.star_outline_rounded,
                      size: 16, color: theme.accentColor)),
            ])),
      );

  Widget _buildFireGlowOverlay() => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 1.2,
              colors: [
                const Color(0xFFEA580C).withValues(alpha: 0.18),
                Colors.transparent
              ],
            ),
          ),
        ),
      );
}
