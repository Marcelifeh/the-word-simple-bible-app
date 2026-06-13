import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/animated_stagger_list.dart';
import '../model/user_tract.dart';
import '../tract_model.dart';
import 'create_tract_screen.dart';
import 'tract_detail_screen.dart';
import 'user_tract_detail_screen.dart';

class TractsScreen extends StatefulWidget {
  const TractsScreen({super.key});

  @override
  State<TractsScreen> createState() => _TractsScreenState();
}

class _TractsScreenState extends State<TractsScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final systemTracts = TractModel.seeds;
    final userTracts = AppScope.of(context).userTractRepo.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gospel Tracts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await AppRouter.push<bool>(
            context,
            const CreateTractScreen(),
            transition: AppTransitionType.slideUp,
          );
          if (saved == true) _refresh();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Write a Tract'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // ── Header ────────────────────────────────────────────────────
          AnimatedStaggerItem(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
              child: Text('Share the Good News',
                  style: theme.textTheme.headlineMedium),
            ),
          ),
          AnimatedStaggerItem(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
              child: Text(
                'Beautiful scripture cards to share with family and friends.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),

          // ── Official Tracts ────────────────────────────────────────────
          const AnimatedStaggerItem(
            index: 2,
            child: _SectionHeader(
              title: 'Official Tracts',
              icon: Icons.menu_book_rounded,
            ),
          ),
          const SizedBox(height: 10),
          ...systemTracts.asMap().entries.map((e) {
            final tract = e.value;
            final colors = tract.gradientColors.map(Color.new).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedStaggerItem(
                index: e.key + 3,
                child: _TractListCard(
                  tract: tract,
                  colors: colors,
                  onTap: () => AppRouter.push(
                    context,
                    TractDetailScreen(tract: tract),
                    transition: AppTransitionType.slideUp,
                  ),
                ),
              ),
            );
          }),

          // ── Your Tracts ────────────────────────────────────────────────
          const SizedBox(height: 20),
          AnimatedStaggerItem(
            index: systemTracts.length + 3,
            child: const _SectionHeader(
              title: 'Your Tracts',
              icon: Icons.edit_rounded,
            ),
          ),
          const SizedBox(height: 10),

          if (userTracts.isEmpty)
            AnimatedStaggerItem(
              index: systemTracts.length + 4,
              child: _EmptyUserTracts(
                onWrite: () async {
                  final saved = await AppRouter.push<bool>(
                    context,
                    const CreateTractScreen(),
                    transition: AppTransitionType.slideUp,
                  );
                  if (saved == true) _refresh();
                },
              ),
            )
          else
            ...userTracts.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedStaggerItem(
                    index: systemTracts.length + entry.key + 4,
                    child: _UserTractCard(
                      tract: entry.value,
                      onTap: () async {
                        await AppRouter.push<void>(
                          context,
                          UserTractDetailScreen(tract: entry.value),
                          transition: AppTransitionType.slideUp,
                        );
                        _refresh(); // refresh after possible delete
                      },
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }
}

// ── Empty state for user tracts ─────────────────────────────────────────────

class _EmptyUserTracts extends StatelessWidget {
  const _EmptyUserTracts({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            "You haven't written any tracts yet.",
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Share God\'s message in your own words.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onWrite,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Write Your First Tract'),
          ),
        ],
      ),
    );
  }
}

// ── Official tract card (unchanged from original) ───────────────────────────

class _TractListCard extends StatefulWidget {
  const _TractListCard({
    required this.tract,
    required this.colors,
    required this.onTap,
  });

  final TractModel tract;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  State<_TractListCard> createState() => _TractListCardState();
}

class _TractListCardState extends State<_TractListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tract = widget.tract;
    final colors = widget.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                colors.first.withValues(alpha: 0.25),
                colors.last.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colors.first.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryChip(label: tract.category, color: colors.first),
                    const SizedBox(height: 4),
                    Text(tract.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      tract.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colors.first.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User tract card ─────────────────────────────────────────────────────────

class _UserTractCard extends StatefulWidget {
  const _UserTractCard({required this.tract, required this.onTap});

  final UserTract tract;
  final VoidCallback onTap;

  @override
  State<_UserTractCard> createState() => _UserTractCardState();
}

class _UserTractCardState extends State<_UserTractCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = widget.tract.message.length > 80
        ? '${widget.tract.message.substring(0, 80)}…'
        : widget.tract.message;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cs.secondaryContainer.withValues(alpha: 0.35),
            border: Border.all(
              color: cs.secondary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.secondary,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.tract.title,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.secondary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category chip (kept for official tracts) ─────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
    );
  }
}
