import 'package:flutter/material.dart';
// Removed unused AppBranding import
// import '../../../../core/config/app_branding.dart';

import '../../../../shared/widgets/spiritual_section.dart';
import '../../model/devotional_section.dart';

class InsightSectionTile extends StatefulWidget {
  const InsightSectionTile({
    super.key,
    required this.section,
    required this.accentColor,
    this.initiallyExpanded = false,
  });

  final DevotionalSection section;
  final Color accentColor;
  final bool initiallyExpanded;

  @override
  State<InsightSectionTile> createState() => _InsightSectionTileState();
}

class _InsightSectionTileState extends State<InsightSectionTile>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (_expanded) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _expanded
              ? widget.accentColor.withValues(alpha: 0.08)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(
            color: _expanded
                ? widget.accentColor.withValues(alpha: 0.35)
                : cs.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Row(
              children: [
                Text(widget.section.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.section.heading,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _expanded ? widget.accentColor : null,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _expanded
                      ? widget.accentColor
                      : cs.onSurface.withValues(alpha: 0.4),
                  size: 22,
                ),
              ],
            ),

            // ── Body (animated) ──────────────────────────────────────────
            FadeTransition(
              opacity: _fade,
              child: SizeTransition(
                sizeFactor: _fade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Divider(color: widget.accentColor.withValues(alpha: 0.20)),
                    const SizedBox(height: 10),
                    SpiritualSection(
                      title: widget.section.heading,
                      body: widget.section.body,
                      icon: widget.section.icon,
                      accentColor: widget.accentColor,
                      showTitle: false,
                      bodySpacing: 0,
                      bodyTextAlign: TextAlign.justify,
                      bodyStyle: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.65,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
