import 'package:flutter/material.dart';

class SpiritualSection extends StatelessWidget {
  const SpiritualSection({
    super.key,
    required this.title,
    required this.body,
    required this.accentColor,
    this.icon,
    this.titleStyle,
    this.bodyStyle,
    this.emphasized = false,
    this.showTitle = true,
    this.padding = const EdgeInsets.all(14),
    this.bodySpacing = 6,
    this.bodyTextAlign,
  });

  final String title;
  final String body;
  final Color accentColor;
  final String? icon;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
  final bool emphasized;
  final bool showTitle;
  final EdgeInsetsGeometry padding;
  final double bodySpacing;
  final TextAlign? bodyTextAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTitleStyle = titleStyle ??
        theme.textTheme.labelLarge?.copyWith(
          color: accentColor.withValues(alpha: 0.82),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    final effectiveBodyStyle = bodyStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          height: emphasized ? 1.55 : 1.7,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
          fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Text(icon!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: effectiveTitleStyle)),
            ],
          ),
          SizedBox(height: bodySpacing),
        ],
        Text(
          body,
          style: effectiveBodyStyle,
          textAlign: bodyTextAlign,
        ),
      ],
    );

    if (!emphasized) {
      return content;
    }

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: content,
    );
  }
}
