import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../model/sermon_note.dart';
import '../utils/scripture_parser.dart';

class SermonNotePreview extends StatefulWidget {
  const SermonNotePreview({
    super.key,
    required this.controller,
    required this.matchesListenable,
    required this.textAlign,
    required this.textStyle,
    required this.strutStyle,
    required this.textScaler,
    required this.onOpenScripture,
  });

  final TextEditingController controller;
  final ValueNotifier<List<ResolvedScriptureMatch>> matchesListenable;
  final TextAlign textAlign;
  final TextStyle textStyle;
  final StrutStyle strutStyle;
  final TextScaler textScaler;
  final void Function(LinkedScripture scripture) onOpenScripture;

  @override
  State<SermonNotePreview> createState() => _SermonNotePreviewState();
}

class _SermonNotePreviewState extends State<SermonNotePreview> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        return ValueListenableBuilder<List<ResolvedScriptureMatch>>(
          valueListenable: widget.matchesListenable,
          builder: (context, matches, __) {
            _disposeRecognizers();

            final text = value.text;
            if (text.trim().isEmpty) {
              return Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Preview will appear here as you write.',
                  style: widget.textStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: RichText(
                  textAlign: widget.textAlign,
                  textScaler: widget.textScaler,
                  strutStyle: widget.strutStyle,
                  text: TextSpan(
                    style: widget.textStyle,
                    children: _buildSpans(context, text, matches),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<InlineSpan> _buildSpans(
    BuildContext context,
    String text,
    List<ResolvedScriptureMatch> matches,
  ) {
    final spans = <InlineSpan>[];
    final sortedMatches = _validMatches(text, matches);
    final buffer = StringBuffer();
    var index = 0;
    var matchIndex = 0;
    var bold = false;
    var italic = false;
    ResolvedScriptureMatch? activeMatch;
    TapGestureRecognizer? activeRecognizer;
    int? activeMatchEnd;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(
        TextSpan(
          text: buffer.toString(),
          recognizer: activeRecognizer,
          style: _spanStyle(
            context,
            bold: bold,
            italic: italic,
            isScriptureLink: activeRecognizer != null,
          ),
        ),
      );
      buffer.clear();
    }

    while (index < text.length) {
      if (activeMatch != null &&
          activeMatchEnd != null &&
          index >= activeMatchEnd) {
        flush();
        activeMatch = null;
        activeRecognizer = null;
        activeMatchEnd = null;
      }

      while (matchIndex < sortedMatches.length &&
          sortedMatches[matchIndex].start < index) {
        matchIndex++;
      }

      if (activeMatch == null &&
          matchIndex < sortedMatches.length &&
          sortedMatches[matchIndex].start == index) {
        flush();
        activeMatch = sortedMatches[matchIndex];
        activeMatchEnd =
            activeMatch.end > text.length ? text.length : activeMatch.end;
        final scripture = activeMatch.scripture;
        activeRecognizer = TapGestureRecognizer()
          ..onTap = () => widget.onOpenScripture(scripture);
        _recognizers.add(activeRecognizer);
        matchIndex++;
      }

      if (text.startsWith('**', index)) {
        flush();
        bold = !bold;
        index += 2;
        continue;
      }

      if (text[index] == '*') {
        flush();
        italic = !italic;
        index++;
        continue;
      }

      buffer.write(text[index]);
      index++;
    }

    flush();
    return spans;
  }

  List<ResolvedScriptureMatch> _validMatches(
    String text,
    List<ResolvedScriptureMatch> matches,
  ) {
    final valid = <ResolvedScriptureMatch>[];
    var cursor = 0;
    final sorted = List<ResolvedScriptureMatch>.from(matches)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final match in sorted) {
      if (match.start < cursor || match.start < 0) continue;
      if (match.start >= text.length) continue;
      if (match.end <= match.start) continue;
      valid.add(match);
      cursor = match.end > text.length ? text.length : match.end;
    }

    return valid;
  }

  TextStyle _spanStyle(
    BuildContext context, {
    required bool bold,
    required bool italic,
    required bool isScriptureLink,
  }) {
    final linkColor = Theme.of(context).colorScheme.primary;
    return widget.textStyle.copyWith(
      color: isScriptureLink ? linkColor : widget.textStyle.color,
      decoration: isScriptureLink ? TextDecoration.underline : null,
      decorationColor: isScriptureLink ? linkColor : null,
      fontWeight: bold
          ? FontWeight.w700
          : isScriptureLink
              ? FontWeight.w600
              : widget.textStyle.fontWeight,
      fontStyle: italic ? FontStyle.italic : widget.textStyle.fontStyle,
    );
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }
}
