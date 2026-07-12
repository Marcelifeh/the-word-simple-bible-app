import 'package:flutter/material.dart';

import '../../core/utils/bible_text_sanitizer.dart';
import '../../domain/entities/verse.dart';
import '../state/app_state.dart';

class BibleReadingTextStyles {
  const BibleReadingTextStyles({
    required this.verseNumberStyle,
    required this.verseTextStyle,
    required this.commentaryTextStyle,
  });

  static const double verseNumberWidth = 38;
  static const double verseNumberGap = 4;
  static const double expandIndicatorClearance = 12;
  static const EdgeInsets verseTilePadding = EdgeInsets.fromLTRB(8, 8, 8, 4);
  static const EdgeInsets expandedInsightPadding =
      EdgeInsets.fromLTRB(16, 0, 16, 16);

  final TextStyle verseNumberStyle;
  final TextStyle verseTextStyle;
  final TextStyle commentaryTextStyle;

  factory BibleReadingTextStyles.of(
    BuildContext context,
    AppState state, {
    required bool isFallback,
  }) {
    final theme = Theme.of(context);
    final titleLarge = theme.textTheme.titleLarge ??
        TextStyle(
          fontSize: 22,
          color: theme.colorScheme.onSurface,
        );
    final bodyLarge = theme.textTheme.bodyLarge ??
        TextStyle(
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        );
    final verseFontSize = (titleLarge.fontSize ?? 22) * state.fontScale;

    return BibleReadingTextStyles(
      verseNumberStyle: titleLarge.copyWith(
        color: Colors.amber,
        fontSize: verseFontSize,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      verseTextStyle: titleLarge.copyWith(
        fontSize: verseFontSize,
        fontWeight: isFallback ? FontWeight.normal : FontWeight.w500,
        fontStyle: isFallback ? FontStyle.italic : FontStyle.normal,
        color: isFallback ? Colors.grey : titleLarge.color,
        height: 1.35,
      ),
      commentaryTextStyle: bodyLarge.copyWith(
        fontSize: (bodyLarge.fontSize ?? 16) * state.fontScale,
      ),
    );
  }
}

class BibleVerseText extends StatelessWidget {
  const BibleVerseText({
    super.key,
    required this.verse,
    this.styles,
    this.text,
    this.textAlign = TextAlign.justify,
  });

  final Verse verse;
  final BibleReadingTextStyles? styles;
  final String? text;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyles = styles ??
        BibleReadingTextStyles.of(
          context,
          AppScope.of(context),
          isFallback: verse.isFallback,
        );
    final verseText = BibleTextSanitizer.clean(text ?? verse.text);

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            baseline: TextBaseline.alphabetic,
            alignment: PlaceholderAlignment.baseline,
            child: SizedBox(
              width: BibleReadingTextStyles.verseNumberWidth +
                  BibleReadingTextStyles.verseNumberGap,
              child: Text(
                '${verse.ref.verse}',
                style: effectiveStyles.verseNumberStyle,
              ),
            ),
          ),
          TextSpan(
            text: verseText,
            style: effectiveStyles.verseTextStyle,
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
