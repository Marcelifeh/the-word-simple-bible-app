import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/main_shell.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../daily_verse/view/daily_verse_screen.dart';
import '../../devotional/view/devotional_detail_screen.dart';
import '../../devotional/view/devotional_history_screen.dart';
import '../../devotional/view/devotional_screen.dart';
import '../../reading_plan/reading_plan_service.dart';
import '../../reading_plan/view/reading_plan_screen.dart';
import '../../tracts/view/tracts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Verse? _dailyVerse;
  bool _verseLoading = true;

  bool _initDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initDone) {
      _initDone = true;
      _loadDailyVerse();
    }
  }

  Future<void> _loadDailyVerse() async {
    if (!mounted) return;
    final state = AppScope.of(context);
    try {
      final v = await state.dailyVerseService
          .getDailyVerse(translation: state.translation);
      if (mounted) {
        setState(() {
          _dailyVerse = v;
          _verseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verseLoading = false);
    }
  }

  String _greeting() {
    final h = TimeOfDay.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 🌙';
  }

  _ReadingPlanIndicator? _readingPlanIndicator(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayReading = readingPlanService.getReadingForDate(today);
    final todayCompleted =
        state.isReadingPlanCompletedForDate(today, todayReading.passages);

    var cursor = DateTime(today.year, 1, 1);
    while (cursor.isBefore(today)) {
      final reading = readingPlanService.getReadingForDate(cursor);
      if (!state.isReadingPlanCompletedForDate(cursor, reading.passages)) {
        return _ReadingPlanIndicator(
          label: 'Missed',
          color: Color(0xFFFB7185),
          missedDate: cursor,
          missedDayNumber: readingPlanService.dayIndexForDate(cursor) + 1,
          missedFirstPassage:
              reading.passages.isEmpty ? null : reading.passages.first,
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (!todayCompleted) {
      return const _ReadingPlanIndicator(
        label: 'Unread',
        color: Color(0xFFF59E0B),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final devotionalService = state.devotionalService;
    final todayDevotional = devotionalService.getTodaysDevotional();
    final todayReadAt = state.devotionalReadHistory[todayDevotional.id];
    final hasReadToday =
        todayReadAt != null && _isSameDay(todayReadAt, DateTime.now());
    final devotionalHistory = devotionalService.getHistoryDevotionals(
      readHistory: state.devotionalReadHistory,
    );
    final readingPlanIndicator =
        _readingPlanIndicator(state, ReadingPlanService());
    final lastReadDevotional =
        devotionalHistory.isEmpty ? null : devotionalHistory.first;
    final lastReadAt = lastReadDevotional == null
        ? null
        : state.devotionalReadHistory[lastReadDevotional.id];
    final isLight = Theme.of(context).brightness == Brightness.light;
    final featureCardTrailingColor = isLight ? Colors.black38 : Colors.white54;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBanner(greeting: _greeting()),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: () => AppRouter.pushNamed(
                      context,
                      AppRouter.settingsRoute,
                      rootNavigator: true,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content below the hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Daily Verse ──────────────────────────────────────────────
                  _DailyVerseCard(
                    verse: _dailyVerse,
                    loading: _verseLoading,
                    readingPlanIndicator: readingPlanIndicator,
                    onCatchUpTap: readingPlanIndicator?.missedDate == null
                        ? null
                        : () => AppRouter.push(
                              context,
                              ReadingPlanScreen(
                                initialDate: readingPlanIndicator!.missedDate,
                              ),
                              transition: AppTransitionType.slideRight,
                            ),
                    onTap: () => AppRouter.push(
                      context,
                      DailyVerseScreen(initialVerse: _dailyVerse),
                      transition: AppTransitionType.devotional,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Feature Grid ─────────────────────────────────────────────
                  GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      FeatureCard(
                        title: 'Read Bible',
                        subtitle: "Dive into God's Word",
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => MainShell.switchTo(kTabBible),
                        trailing: Icon(Icons.chevron_right_rounded,
                            size: 16, color: featureCardTrailingColor),
                      ),
                      FeatureCard(
                        title: 'Search',
                        subtitle: 'Find verses and topics',
                        icon: Icons.search_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () => MainShell.switchTo(kTabSearch),
                        trailing: Icon(Icons.chevron_right_rounded,
                            size: 16, color: featureCardTrailingColor),
                      ),
                      FeatureCard(
                        title: hasReadToday
                            ? 'Today\'s Devotion'
                            : AppBranding.logosDevotional,
                        subtitle: hasReadToday
                            ? 'Read today · Prayer · Reflection'
                            : 'New today · Scripture · Prayer',
                        icon: hasReadToday
                            ? Icons.check_circle_rounded
                            : Icons.wb_sunny_rounded,
                        color: hasReadToday
                            ? const Color(0xFF10B981)
                            : const Color(0xFF4F46E5),
                        onTap: () => AppRouter.push(
                          context,
                          const DevotionalScreen(),
                          rootNavigator: true,
                          transition: AppTransitionType.devotional,
                        ),
                        trailing: Icon(Icons.chevron_right_rounded,
                            size: 16, color: featureCardTrailingColor),
                      ),
                      FeatureCard(
                        title: AppBranding.logosNotes,
                        subtitle: 'Notes & Highlights',
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFF14B8A6),
                        onTap: () => MainShell.switchTo(kTabJournal),
                        trailing: Icon(Icons.chevron_right_rounded,
                            size: 16, color: featureCardTrailingColor),
                      ),
                    ],
                  ),

                  if (lastReadDevotional != null && lastReadAt != null) ...[
                    const SizedBox(height: 12),
                    FeatureCard(
                      title: 'Continue Devotional',
                      subtitle:
                          '${lastReadDevotional.title} · ${_formatDevotionalReadAt(context, lastReadAt)}',
                      icon: Icons.history_edu_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () => AppRouter.push(
                        context,
                        DevotionalDetailScreen(
                          devotional: lastReadDevotional,
                          activeDate: lastReadAt,
                        ),
                        rootNavigator: true,
                        transition: AppTransitionType.devotional,
                      ),
                      topRight: _InlineHistoryChip(
                        onTap: () => AppRouter.push(
                          context,
                          const DevotionalHistoryScreen(),
                          rootNavigator: true,
                          transition: AppTransitionType.devotional,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded,
                          size: 16, color: featureCardTrailingColor),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Gospel Tracts ─────────────────────────────────────────────
                  _GospelTractsCard(),

                  const SizedBox(height: 20),

                  // ── Translation Selector ──────────────────────────────────────
                  _TranslationSelector(
                    current: state.translation,
                    onChanged: (t) {
                      if (t == null) return;
                      if (t.isLicensed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('${t.label} requires licensed data.')),
                        );
                        return;
                      }
                      state.setTranslation(t);
                      setState(() {
                        _verseLoading = true;
                        _dailyVerse = null;
                      });
                      _loadDailyVerse();
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDevotionalReadAt(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final dateOnly = DateTime(value.year, value.month, value.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final daysDifference = todayOnly.difference(dateOnly).inDays;
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: false,
    );

    if (daysDifference == 0) {
      return 'Today at $time';
    }
    if (daysDifference == 1) {
      return 'Yesterday at $time';
    }
    return '${localizations.formatShortDate(value)} · $time';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _InlineHistoryChip extends StatelessWidget {
  const _InlineHistoryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final chipColor = isLight
        ? Colors.white.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.12);
    final chipBorderColor = isLight
        ? scheme.primary.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.18);
    final chipForeground = isLight ? scheme.primary : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 11, color: chipForeground),
            const SizedBox(width: 4),
            Text(
              'History',
              style: TextStyle(
                color: chipForeground,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/home_hero_bg.png',
            fit: BoxFit.cover,
          ),
          // Dark gradient overlay (bottom fade)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
          // Text content
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppBranding.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppBranding.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily Verse Card ──────────────────────────────────────────────────────────
class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard({
    required this.verse,
    required this.loading,
    required this.readingPlanIndicator,
    required this.onCatchUpTap,
    required this.onTap,
  });

  final Verse? verse;
  final bool loading;
  final _ReadingPlanIndicator? readingPlanIndicator;
  final VoidCallback? onCatchUpTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final isLight = theme.brightness == Brightness.light;
    final amber = const Color(0xFFF59E0B);
    final violet = const Color(0xFF8B5CF6);
    final cardBackground = isLight
        ? theme.colorScheme.surfaceContainerLowest
        : Colors.white.withValues(alpha: 0.05);
    final cardBorder = isLight
        ? amber.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.10);
    final shadowColor = isLight
        ? amber.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.14);
    final labelColor = isLight ? Colors.black54 : Colors.white70;
    final verseTextColor = isLight ? Colors.black87 : Colors.white;
    final trailingColor = isLight ? Colors.black26 : Colors.white38;
    final catchUpDateLabel = readingPlanIndicator?.missedDate == null
        ? null
        : localizations.formatShortDate(readingPlanIndicator!.missedDate!);
    final catchUpPassage = readingPlanIndicator?.missedFirstPassage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [
                    cardBackground,
                    amber.withValues(alpha: 0.05),
                  ]
                : [
                    cardBackground,
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isLight ? 18 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: amber.withValues(alpha: 0.20),
                border: Border.all(color: amber.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.menu_book_rounded, color: amber, size: 24),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loading)
                    Row(
                      children: [
                        Text(
                          'Daily Verse / Bible In One Year',
                          style: TextStyle(
                            color: amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (readingPlanIndicator != null) ...[
                          const SizedBox(width: 8),
                          _ReadingPlanIndicatorChip(
                            indicator: readingPlanIndicator!,
                          ),
                        ],
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            color: violet,
                            backgroundColor: violet.withValues(alpha: 0.15),
                            minHeight: 2,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text(
                          'Daily Verse / Bible In One Year',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (readingPlanIndicator != null) ...[
                          const SizedBox(width: 8),
                          _ReadingPlanIndicatorChip(
                            indicator: readingPlanIndicator!,
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: amber,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            verse != null
                                ? '${verse!.book} ${verse!.ref.chapter}:${verse!.ref.verse}'
                                : '',
                            style: TextStyle(
                              color: amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    verse == null
                        ? '"The Lord is my shepherd, I shall not want."'
                        : '"${BibleTextSanitizer.clean(verse!.text)}"',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: verseTextColor,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      height: 1.55,
                    ),
                  ),
                  if (catchUpPassage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Catch up starts with $catchUpPassage',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFFB7185),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (!loading && verse != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MicroAction(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          color: amber,
                          onTap: () {
                            final text =
                                '"${BibleTextSanitizer.clean(verse!.text)}" — ${verse!.book} ${verse!.ref.chapter}:${verse!.ref.verse}';
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verse copied!')),
                            );
                          },
                        ),
                        _MicroAction(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          color: amber,
                          onTap: () {
                            final text =
                                '"${BibleTextSanitizer.clean(verse!.text)}" — ${verse!.book} ${verse!.ref.chapter}:${verse!.ref.verse}';
                            Share.share(text);
                          },
                        ),
                        if (readingPlanIndicator?.missedDate != null &&
                            onCatchUpTap != null) ...[
                          _MicroAction(
                            icon: Icons.event_repeat_rounded,
                            label: catchUpDateLabel == null
                                ? 'Catch up Day ${readingPlanIndicator!.missedDayNumber}'
                                : 'Catch up D${readingPlanIndicator!.missedDayNumber} · $catchUpDateLabel',
                            color: const Color(0xFFFB7185),
                            onTap: onCatchUpTap!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: trailingColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MicroAction extends StatelessWidget {
  const _MicroAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

class _ReadingPlanIndicator {
  const _ReadingPlanIndicator({
    required this.label,
    required this.color,
    this.missedDate,
    this.missedDayNumber,
    this.missedFirstPassage,
  });

  final String label;
  final Color color;
  final DateTime? missedDate;
  final int? missedDayNumber;
  final String? missedFirstPassage;
}

class _ReadingPlanIndicatorChip extends StatelessWidget {
  const _ReadingPlanIndicatorChip({required this.indicator});

  final _ReadingPlanIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final chipLabel = indicator.missedDayNumber == null
        ? indicator.label
        : '${indicator.label} · D${indicator.missedDayNumber}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: indicator.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: indicator.color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: indicator.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            chipLabel,
            style: TextStyle(
              color: indicator.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gospel Tracts Card ────────────────────────────────────────────────────────
class _GospelTractsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF8B5CF6);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight
        ? const Color(0xFFF3EEFF)
        : Colors.white.withValues(alpha: 0.05);
    final borderColor = isLight
        ? violet.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.10);
    final titleColor = isLight ? const Color(0xFF1F1637) : Colors.white;
    final bodyColor = isLight ? const Color(0xFF5D5474) : Colors.white60;
    final buttonBorderColor =
        isLight ? violet.withValues(alpha: 0.35) : Colors.white38;
    final buttonTextColor = isLight ? violet : Colors.white;
    final dividerColor = isLight
        ? scheme.outlineVariant.withValues(alpha: 0.65)
        : Colors.white12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: violet.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple icon box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Gospel Tracts',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: violet.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: violet.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'New ✨',
                            style: TextStyle(
                              color: Color(0xFFB78BFC),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share the Good News with beautiful gospel tracts.',
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Explore button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => AppRouter.push(
                context,
                const TractsScreen(),
                transition: AppTransitionType.slideUp,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: buttonBorderColor),
                  color: isLight ? Colors.white.withValues(alpha: 0.65) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore Tracts',
                      style: TextStyle(
                        color: buttonTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: buttonTextColor, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 14),
          // Mini features
          Row(
            children: const [
              _TractMiniFeature(
                icon: Icons.share_outlined,
                label: 'Share Easily',
                sublabel: 'Share on any\nsocial platform',
              ),
              _TractMiniFeature(
                icon: Icons.palette_outlined,
                label: 'Beautiful Designs',
                sublabel: 'Engaging and\ninspiring tracts',
              ),
              _TractMiniFeature(
                icon: Icons.favorite_outline_rounded,
                label: 'Spread Hope',
                sublabel: 'Touch lives with\nthe Gospel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TractMiniFeature extends StatelessWidget {
  const _TractMiniFeature({
    required this.icon,
    required this.label,
    required this.sublabel,
  });
  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF8B5CF6);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: violet, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLight ? const Color(0xFF251B41) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLight ? const Color(0xFF6A6282) : Colors.white54,
              fontSize: 10,
              fontFamily: 'Poppins',
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Translation Selector ──────────────────────────────────────────────────────
class _TranslationSelector extends StatelessWidget {
  const _TranslationSelector({required this.current, required this.onChanged});
  final BibleTranslation current;
  final ValueChanged<BibleTranslation?> onChanged;

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF8B5CF6);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final containerColor = isLight
        ? const Color(0xFFF3EEFF)
        : Colors.white.withValues(alpha: 0.05);
    final borderColor = isLight
        ? violet.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.10);
    final labelColor = isLight ? scheme.onSurfaceVariant : Colors.white60;
    final iconColor = isLight ? scheme.onSurfaceVariant : Colors.white54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: containerColor,
        border: Border.all(color: borderColor),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: violet.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.language_rounded, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Text(
            'Translation:',
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BibleTranslation>(
                value: current,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: violet),
                onChanged: onChanged,
                style: const TextStyle(
                  color: violet,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                items: BibleTranslation.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.isLicensed ? '${t.label} (licensed)' : t.label,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
