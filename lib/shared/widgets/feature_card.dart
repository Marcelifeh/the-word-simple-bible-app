import 'package:flutter/material.dart';

/// Animated, glassmorphic feature card used across Home, Tracts, and future sections.
/// Press animation gives it a native-app "alive" feel without heavy effects.
class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
    this.topRight,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? topRight;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 390;
    final titleSize = isCompact ? 15.5 : 17.0;
    final subtitleSize = isCompact ? 11.5 : 12.5;
    final iconBoxSize = isCompact ? 46.0 : 52.0;
    final iconSize = isCompact ? 22.0 : 25.0;
    final startColor = isLight
        ? Color.alphaBlend(
            widget.color.withValues(alpha: _pressed ? 0.24 : 0.18),
            scheme.surfaceContainerLowest,
          )
        : widget.color.withValues(alpha: _pressed ? 0.40 : 0.30);
    final endColor = isLight
        ? Color.alphaBlend(
            widget.color.withValues(alpha: _pressed ? 0.12 : 0.08),
            scheme.surface,
          )
        : widget.color.withValues(alpha: _pressed ? 0.16 : 0.08);
    final borderColor = isLight
        ? widget.color.withValues(alpha: _pressed ? 0.36 : 0.26)
        : widget.color.withValues(alpha: _pressed ? 0.38 : 0.28);
    final shadowColor = isLight
        ? widget.color.withValues(alpha: _pressed ? 0.18 : 0.10)
        : widget.color.withValues(alpha: _pressed ? 0.26 : 0.12);
    final iconBubbleColor =
        widget.color.withValues(alpha: _pressed ? 0.22 : 0.16);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: isLight ? scheme.onSurface : Colors.white,
      fontSize: titleSize,
      fontWeight: FontWeight.w800,
      height: 1.0,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: isLight
          ? scheme.onSurfaceVariant
          : Colors.white.withValues(alpha: 0.68),
      fontSize: subtitleSize,
      fontWeight: isLight ? FontWeight.w500 : null,
      height: 1.1,
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: _pressed ? 22 : (isLight ? 16 : 12),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: widget.topRight != null ? 10 : 0),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBubbleColor,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: iconSize,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: titleStyle,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.subtitle,
                            style: subtitleStyle,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (widget.trailing != null)
                      widget.trailing!
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isLight
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                  ],
                ),
              ),
              if (widget.topRight != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: widget.topRight!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
