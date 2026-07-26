import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../shared/widgets/spiritual_section.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/adaptive_feature_hero.dart';
import '../../../shared/widgets/reading_text_scale.dart';
import '../../../core/narration/models/narration_state.dart';
import '../../../core/narration/widgets/narration_fab.dart';
import '../tract_model.dart';
import '../tract_sharer.dart';
import 'tract_image_designer_screen.dart';

class TractDetailScreen extends StatefulWidget {
  const TractDetailScreen({super.key, required this.tract});

  final TractModel tract;

  @override
  State<TractDetailScreen> createState() => _TractDetailScreenState();
}

class _TractDetailScreenState extends State<TractDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = widget.tract.gradientColors.map((v) => Color(v)).toList();
    final scheme = Theme.of(context).colorScheme;
    final readingScale = AppScope.of(context).fontScale;

    return Scaffold(
      floatingActionButton: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: NarrationFab(
          controller: AppScope.of(context).narrationController,
          onPlay: () {
            AppScope.of(context).narrationController.playContent(
                  widget.tract,
                  id: 'tract_${widget.tract.id}',
                  sourceType: NarrationSourceType.tract,
                );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AdaptiveFeatureHero(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              badge: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.tract.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              eyebrow: widget.tract.hook,
              title: widget.tract.title,
              subtitle: widget.tract.summary,
              eyebrowStyle: TextStyle(
                fontSize: 12 * readingScale,
                color: Colors.white.withValues(alpha: 0.80),
                fontStyle: FontStyle.italic,
                height: 1.25,
              ),
              titleStyle: TextStyle(
                fontSize: 26 * readingScale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.08,
              ),
              subtitleStyle: TextStyle(
                fontSize: 13 * readingScale,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
          ),

          // ── Key Verse ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      colors.first.withValues(alpha: 0.25),
                      colors.last.withValues(alpha: 0.10),
                    ],
                  ),
                  border: Border.all(
                    color: colors.first.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: ReadingTextScale(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SpiritualSection(
                        title: 'Key Verse',
                        body: widget.tract.keyVerse,
                        icon: '📖',
                        accentColor: colors.first,
                        titleStyle:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: colors.first,
                                  fontWeight: FontWeight.w700,
                                ),
                        bodyStyle: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '— ${widget.tract.keyVerseRef}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.first,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: ReadingTextScale(
                child: Text(
                  widget.tract.body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.75,
                    color: scheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ),
          ),

          // ── Share CTAs ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final text = TractSharer.forOfficialTract(
                          hook: widget.tract.hook,
                          title: widget.tract.title,
                          keyVerse: widget.tract.keyVerse,
                          keyVerseRef: widget.tract.keyVerseRef,
                          body: widget.tract.body,
                        );
                        final result = await Share.share(
                          text,
                          subject: widget.tract.title,
                        );
                        await AppHaptics.shareTriggered();
                        debugPrint(
                            '[Tracts] text share result: ${result.status}');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.first,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                            color: colors.first.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.textsms_outlined),
                      label: const Text(
                        'Share Text',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TractImageDesignerScreen(
                              title: widget.tract.title,
                              body: widget.tract.body,
                              scripture: widget.tract.keyVerse,
                              scriptureRef: widget.tract.keyVerseRef,
                              hook: widget.tract.hook,
                              isUserTract: false,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.first,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text(
                        'Share Image',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
