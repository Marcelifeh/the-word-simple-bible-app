import 'package:flutter/material.dart';

class JourneyActionTile extends StatelessWidget {
  const JourneyActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                const Color(0xFF151B2A).withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.92),
                      accent.withValues(alpha: 0.38),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          _JourneyBadge(
                            label: badge!,
                            accent: accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.2,
                        color: Colors.white.withValues(alpha: 0.67),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyBadge extends StatelessWidget {
  const _JourneyBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.34),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }
}
