import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/utils/bible_text_sanitizer.dart';
import 'animated_stagger_list.dart';
import 'spiritual_section.dart';

class VerseInsightPanel extends StatefulWidget {
  const VerseInsightPanel({
    super.key,
    required this.rawText,
    required this.accentColor,
    this.baseTextStyle,
  });

  final String rawText;
  final Color accentColor;
  final TextStyle? baseTextStyle;

  @override
  State<VerseInsightPanel> createState() => _VerseInsightPanelState();
}

class _VerseInsightPanelState extends State<VerseInsightPanel> {
  int _visibleSections = 0;
  int _revealToken = 0;

  @override
  void initState() {
    super.initState();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(covariant VerseInsightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rawText != oldWidget.rawText) {
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    final sections = _VerseInsightContent.parse(widget.rawText).sections;
    final token = ++_revealToken;
    if (mounted) {
      setState(() => _visibleSections = 0);
    }
    for (var index = 0; index < sections.length; index++) {
      unawaited(
        Future<void>.delayed(Duration(milliseconds: 80 * (index + 1)), () {
          if (!mounted || token != _revealToken) return;
          setState(() => _visibleSections = index + 1);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = _VerseInsightContent.parse(widget.rawText);
    final bodyStyle =
        (widget.baseTextStyle ?? theme.textTheme.bodyMedium)?.copyWith(
      height: 1.7,
      color: scheme.onSurface.withValues(alpha: 0.92),
    );
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: widget.accentColor.withValues(alpha: 0.82),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < data.sections.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: index < _visibleSections
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: AnimatedStaggerItem(
              key: ValueKey('insight-${_revealToken + index}'),
              index: index,
              child: _InsightSectionBlock(
                section: data.sections[index],
                accentColor: widget.accentColor,
                labelStyle: labelStyle,
                bodyStyle: bodyStyle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightSectionBlock extends StatelessWidget {
  const _InsightSectionBlock({
    required this.section,
    required this.accentColor,
    required this.labelStyle,
    required this.bodyStyle,
  });

  final _InsightSection section;
  final Color accentColor;
  final TextStyle? labelStyle;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return SpiritualSection(
      title: section.label,
      body: section.text,
      accentColor: accentColor,
      titleStyle: labelStyle,
      bodyStyle: bodyStyle,
      bodyTextAlign: TextAlign.justify,
      emphasized: section.kind == _InsightSectionKind.keyTruth,
    );
  }
}

enum _InsightSectionKind { understanding, deepInsight, keyTruth, reflection }

class _InsightSection {
  const _InsightSection({
    required this.kind,
    required this.label,
    required this.text,
  });

  final _InsightSectionKind kind;
  final String label;
  final String text;
}

class _VerseInsightContent {
  const _VerseInsightContent({
    this.understanding,
    this.deepInsight,
    this.keyTruth,
    this.reflection,
  });

  final String? understanding;
  final String? deepInsight;
  final String? keyTruth;
  final String? reflection;

  static final RegExp _headingPattern = RegExp(
    r'^[^A-Za-z]*(understanding|simple explanation|meaning|deep insight|key truth|reflection)\b\s*[:\-]?\s*(.*)$',
    caseSensitive: false,
  );

  static _VerseInsightContent parse(String rawText) {
    final normalized =
        BibleTextSanitizer.clean(rawText).replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const _VerseInsightContent();

    final fromJson = _fromJson(normalized);
    if (fromJson != null) return fromJson;

    final buckets = <String, List<String>>{};
    final unlabeled = <String>[];
    String? currentKey;

    for (final rawLine in normalized.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final match = _headingPattern.firstMatch(line);
      if (match != null) {
        currentKey = _normalizeKey(match.group(1)!);
        final inline = _compact(match.group(2) ?? '');
        if (inline.isNotEmpty) {
          buckets.putIfAbsent(currentKey, () => <String>[]).add(inline);
        }
        continue;
      }

      if (currentKey == null) {
        unlabeled.add(line);
      } else {
        buckets.putIfAbsent(currentKey, () => <String>[]).add(line);
      }
    }

    final hasStructuredSections = buckets.isNotEmpty;
    if (!hasStructuredSections) {
      return _fromLegacy(_compact(unlabeled.join(' ')));
    }

    return _VerseInsightContent(
      understanding: _joinBucket(buckets['understanding']),
      deepInsight: _joinBucket(buckets['deepInsight']),
      keyTruth: _joinBucket(buckets['keyTruth']),
      reflection: _joinBucket(buckets['reflection']),
    );
  }

  static _VerseInsightContent? _fromJson(String text) {
    if (!text.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final understanding = _compact(map['understanding']?.toString() ?? '');
      final deepInsight = _compact(map['deepInsight']?.toString() ?? '');
      final keyTruth = _compact(map['keyTruth']?.toString() ?? '');
      final reflection = _compact(map['reflection']?.toString() ?? '');
      if ([understanding, deepInsight, keyTruth, reflection]
          .every((value) => value.isEmpty)) {
        return null;
      }
      return _VerseInsightContent(
        understanding: understanding.isEmpty ? null : understanding,
        deepInsight: deepInsight.isEmpty ? null : deepInsight,
        keyTruth: keyTruth.isEmpty ? null : keyTruth,
        reflection: reflection.isEmpty ? null : reflection,
      );
    } catch (_) {
      return null;
    }
  }

  static _VerseInsightContent _fromLegacy(String text) {
    if (text.isEmpty) return const _VerseInsightContent();

    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map(_compact)
        .where((sentence) => sentence.isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      return _VerseInsightContent(understanding: text);
    }

    final understandingParts = <String>[];
    var understandingWords = 0;
    var index = 0;
    while (index < sentences.length && understandingParts.length < 2) {
      final sentence = sentences[index];
      final words = _wordCount(sentence);
      if (understandingParts.isNotEmpty && understandingWords + words > 40) {
        break;
      }
      understandingParts.add(sentence);
      understandingWords += words;
      index++;
    }

    final remaining = sentences.sublist(index);
    String? reflection;
    if (remaining.isNotEmpty) {
      final candidate = remaining.last;
      if (_looksReflective(candidate) || remaining.length == 1) {
        reflection = candidate;
        remaining.removeLast();
      }
    }

    final understanding = _compact(understandingParts.join(' '));
    final deepInsight = _compact(remaining.join(' '));
    final keyTruth =
        _deriveKeyTruth(deepInsight.isNotEmpty ? deepInsight : understanding);

    return _VerseInsightContent(
      understanding: understanding.isEmpty ? null : understanding,
      deepInsight: deepInsight.isEmpty ? null : deepInsight,
      keyTruth: keyTruth,
      reflection: reflection,
    );
  }

  List<_InsightSection> get sections {
    final items = <_InsightSection>[];

    if (_present(understanding)) {
      items.add(
        _InsightSection(
          kind: _InsightSectionKind.understanding,
          label: '🕊 Understanding',
          text: understanding!,
        ),
      );
    }
    if (_present(deepInsight)) {
      items.add(
        _InsightSection(
          kind: _InsightSectionKind.deepInsight,
          label: '🔥 Deep Insight',
          text: deepInsight!,
        ),
      );
    }
    if (_present(keyTruth)) {
      items.add(
        _InsightSection(
          kind: _InsightSectionKind.keyTruth,
          label: '✨ Key Truth',
          text: keyTruth!,
        ),
      );
    }
    if (_present(reflection)) {
      items.add(
        _InsightSection(
          kind: _InsightSectionKind.reflection,
          label: '🌱 Reflection',
          text: reflection!,
        ),
      );
    }

    return items;
  }

  static String _normalizeKey(String key) {
    switch (_compact(key).toLowerCase()) {
      case 'simple explanation':
      case 'meaning':
        return 'understanding';
      case 'deep insight':
        return 'deepInsight';
      case 'key truth':
        return 'keyTruth';
      default:
        return _compact(key);
    }
  }

  static String? _joinBucket(List<String>? lines) {
    if (lines == null || lines.isEmpty) return null;
    final text = _compact(lines.join(' '));
    return text.isEmpty ? null : text;
  }

  static String _compact(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _present(String? text) => text != null && text.trim().isNotEmpty;

  static int _wordCount(String text) =>
      text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

  static bool _looksReflective(String text) {
    final lower = text.toLowerCase();
    return text.endsWith('?') ||
        lower.startsWith('let ') ||
        lower.startsWith('today') ||
        lower.startsWith('ask yourself') ||
        lower.startsWith('remember') ||
        lower.startsWith('choose') ||
        lower.startsWith('bring') ||
        lower.startsWith('trust');
  }

  static String? _deriveKeyTruth(String text) {
    if (text.isEmpty) return null;
    final firstSentence = _compact(text.split(RegExp(r'(?<=[.!?])\s+')).first);
    if (firstSentence.isEmpty) return null;
    final trimmed = firstSentence.replaceAll(RegExp(r'[.!?]+$'), '');
    final words = _wordCount(trimmed);
    if (words < 6 || words > 16) return null;
    if (trimmed.length > 110) return null;
    return trimmed;
  }
}
