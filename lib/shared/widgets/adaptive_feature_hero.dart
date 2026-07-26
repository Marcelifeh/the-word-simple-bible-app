import 'package:flutter/material.dart';

class AdaptiveFeatureHero extends StatelessWidget {
  const AdaptiveFeatureHero({
    super.key,
    required this.gradient,
    required this.title,
    required this.badge,
    this.eyebrow,
    this.subtitle,
    this.titleStyle,
    this.eyebrowStyle,
    this.subtitleStyle,
    this.horizontalPadding = 24,
    this.onBack,
  });

  final Gradient gradient;
  final String title;
  final Widget badge;
  final String? eyebrow;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? eyebrowStyle;
  final TextStyle? subtitleStyle;
  final double horizontalPadding;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedEyebrow = eyebrow?.trim();
    final trimmedSubtitle = subtitle?.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                color: Colors.white,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 12),
              badge,
              if (trimmedEyebrow?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  trimmedEyebrow!,
                  style: eyebrowStyle ??
                      theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontStyle: FontStyle.italic,
                        height: 1.25,
                      ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                title,
                style: titleStyle ??
                    theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
              ),
              if (trimmedSubtitle?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  trimmedSubtitle!,
                  style: subtitleStyle ??
                      theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.3,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
