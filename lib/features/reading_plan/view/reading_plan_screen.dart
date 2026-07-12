import 'package:flutter/material.dart';
import '../reading_plan_service.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../bible/view/reading_screen.dart';
import '../../../data/bible/book_catalog.dart';

class ReadingPlanScreen extends StatefulWidget {
  const ReadingPlanScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  late DateTime _selectedDate;
  final ReadingPlanService _readingPlanService = ReadingPlanService();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final plan = _readingPlanService.getReadingForDate(_selectedDate);
    final completedPassages = plan.passages
        .where(
          (passage) => state.isReadingPlanPassageCompletedForDate(
              _selectedDate, passage),
        )
        .length;
    final planCompleted =
        state.isReadingPlanCompletedForDate(_selectedDate, plan.passages);
    final dateLabel =
        MaterialLocalizations.of(context).formatMediumDate(_selectedDate);
    final isToday = _isSameDate(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Daily Bible Reading Plan'),
        actions: [
          IconButton(
            tooltip: 'Jump to day',
            onPressed: () => _showJumpSheet(context),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          if (!isToday)
            TextButton(
              onPressed: _jumpToToday,
              child: const Text('Today'),
            ),
          TextButton.icon(
            onPressed: planCompleted
                ? null
                : () async {
                    await state.markReadingPlanCompleted(
                      completedAt: _selectedDate,
                      passages: plan.passages,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isToday
                              ? 'Marked all today\'s passages as complete.'
                              : 'Marked all passages for $dateLabel as complete.',
                        ),
                      ),
                    );
                  },
            icon: Icon(
              planCompleted
                  ? Icons.check_circle_rounded
                  : Icons.task_alt_rounded,
            ),
            label: Text(
              planCompleted ? 'Completed' : 'Complete',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeDay(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous day',
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickDate(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeDay(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next day',
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _showJumpSheet(context),
              icon: const Icon(Icons.event_note_rounded),
              label: Text(
                isToday ? 'Jump To Missed Day' : 'Jump To Another Day',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$completedPassages of ${plan.passages.length} passages completed for ${isToday ? 'today' : dateLabel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: plan.passages.isEmpty
                    ? 0
                    : completedPassages / plan.passages.length,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isToday ? 'Today\'s Passages:' : 'Passages for $dateLabel:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...plan.passages.map(
              (p) {
                final isCompleted = state.isReadingPlanPassageCompletedForDate(
                  _selectedDate,
                  p,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.menu_book,
                      color: isCompleted ? Colors.green : Colors.amber,
                    ),
                    title: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    subtitle: isCompleted
                        ? const Text('Completed')
                        : state.readingPlanLastOpenedPassageForDate(
                                    _selectedDate) ==
                                p
                            ? const Text('Last opened')
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await state.markReadingPlanPassageCompleted(
                              p,
                              completedAt: _selectedDate,
                              completed: !isCompleted,
                            );
                          },
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () async {
                      await state.markReadingPlanPassageOpened(
                        p,
                        openedAt: _selectedDate,
                      );
                      if (!context.mounted) return;
                      final match =
                          RegExp(r'^(.*?) (\d+)(?:-(\d+))?$').firstMatch(p);
                      if (match == null) return;
                      final bookName = match.group(1)?.trim() ?? '';
                      final chapterStr = match.group(2);
                      final book = BookCatalog.books.firstWhere(
                        (b) => b.name.toLowerCase() == bookName.toLowerCase(),
                        orElse: () => BookCatalog.books.first,
                      );
                      final chapter = int.tryParse(chapterStr ?? '1') ?? 1;
                      AppRouter.push(
                        context,
                        ReadingScreen(book: book, chapter: chapter),
                        transition: AppTransitionType.slideRight,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'This plan updates automatically every day. Stay consistent and be blessed!',
            ),
          ],
        ),
      ),
    );
  }

  void _changeDay(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _showJumpSheet(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        return _ReadingPlanJumpSheet(
          initialDate: _selectedDate,
          minYear: now.year - 1,
          maxYear: now.year + 1,
          onOpenCalendar: () async {
            Navigator.of(context).pop<DateTime>();
            await _pickDate(this.context);
          },
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _ReadingPlanJumpSheet extends StatefulWidget {
  const _ReadingPlanJumpSheet({
    required this.initialDate,
    required this.minYear,
    required this.maxYear,
    required this.onOpenCalendar,
  });

  final DateTime initialDate;
  final int minYear;
  final int maxYear;
  final Future<void> Function() onOpenCalendar;

  @override
  State<_ReadingPlanJumpSheet> createState() => _ReadingPlanJumpSheetState();
}

class _ReadingPlanJumpSheetState extends State<_ReadingPlanJumpSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthStart = DateTime(_selectedYear, _selectedMonth, 1);
    final dayCount = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final now = DateTime.now();
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.86;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: mediaQuery.viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jump To A Reading Day',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a month and day to reopen a missed reading quickly.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: _selectedYear > widget.minYear
                        ? () => setState(() => _selectedYear -= 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_selectedYear',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _selectedYear < widget.maxYear
                        ? () => setState(() => _selectedYear += 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(12, (index) {
                  final month = index + 1;
                  final label = MaterialLocalizations.of(context)
                      .formatMonthYear(DateTime(_selectedYear, month))
                      .split(' ')
                      .first;
                  return ChoiceChip(
                    label: Text(label),
                    selected: _selectedMonth == month,
                    onSelected: (_) => setState(() => _selectedMonth = month),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                MaterialLocalizations.of(context).formatMonthYear(monthStart),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 240,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: dayCount,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final date = DateTime(_selectedYear, _selectedMonth, day);
                    final isSelected =
                        DateUtils.isSameDay(date, widget.initialDate);
                    final isToday = DateUtils.isSameDay(date, now);

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(date),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isToday
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.10)
                                  : theme.colorScheme.surfaceContainerHigh,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : isToday
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.35)
                                    : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await widget.onOpenCalendar();
                      },
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: const Text('Open Calendar Picker'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
