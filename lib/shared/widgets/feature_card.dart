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
    final iconBubbleColor = isLight
        ? widget.color.withValues(alpha: _pressed ? 0.20 : 0.14)
        : widget.color.withValues(alpha: _pressed ? 0.26 : 0.20);
    final iconBorderColor = isLight
        ? widget.color.withValues(alpha: _pressed ? 0.48 : 0.34)
        : widget.color.withValues(alpha: _pressed ? 0.65 : 0.5);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: isLight ? scheme.onSurface : null,
      fontWeight: FontWeight.w700,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isLight ? scheme.onSurfaceVariant : null,
      fontWeight: isLight ? FontWeight.w500 : null,
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
          padding: const EdgeInsets.all(16),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBubbleColor,
                        border: Border.all(
                          color: iconBorderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: titleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: subtitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
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
