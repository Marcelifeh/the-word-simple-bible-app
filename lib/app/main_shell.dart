import 'package:flutter/material.dart';

import '../core/navigation/app_transitions.dart';
import '../core/navigation/page_transition_type.dart';
import '../features/bible/view/book_screen.dart';
import '../features/journal/view/journal_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/search/view/search_screen.dart';
import '../features/tracts/view/tracts_screen.dart';
import '../shared/state/app_state.dart';
import '../core/narration/widgets/narration_bar.dart';

/// Tab index constants — use these instead of magic numbers.
const kTabHome = 0;
const kTabBible = 1;
const kTabSearch = 2;
const kTabJournal = 3;
const kTabTracts = 4;

class MainShell extends StatefulWidget {
  MainShell({Key? key}) : super(key: key ?? MainShell.mainKey);

  static final GlobalKey<State<MainShell>> mainKey =
      GlobalKey<State<MainShell>>();

  /// Programmatically switch the active bottom tab.
  static void switchTo(int i) {
    final state = mainKey.currentState;
    if (state is _MainShellState) state._setIndex(i);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<GlobalKey<NavigatorState>> _navKeys = [];

  void _setIndex(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      HomeScreen(),
      BookScreen(),
      SearchScreen(),
      JournalScreen(),
      TractsScreen(),
    ];

    while (_navKeys.length < pages.length) {
      _navKeys.add(GlobalKey<NavigatorState>());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        if (_index != 0) _setIndex(0);
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(pages.length, (i) {
            final active = i == _index;
            return Offstage(
              offstage: !active,
              child: TickerMode(
                enabled: active,
                child: Navigator(
                  key: _navKeys[i],
                  onGenerateRoute: (settings) => AppTransitions.createRoute(
                    page: pages[i],
                    type: _tabTransitionForIndex(i),
                    settings: settings,
                  ),
                ),
              ),
            );
          }),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NarrationBar(controller: AppScope.of(context).narrationController),
            NavigationBar(
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: const Duration(milliseconds: 500),
          selectedIndex: _index,
          onDestinationSelected: (i) {
            if (i == _index) {
              _navKeys[i].currentState?.popUntil((r) => r.isFirst);
            } else {
              _setIndex(i);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Bible',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note_rounded),
              label: 'Journal',
            ),
            NavigationDestination(
              icon: Icon(Icons.share_outlined),
              selectedIcon: Icon(Icons.share_rounded),
              label: 'Tracts',
            ),
          ],
        ),
      ],
    ),
  ),
);
  }

  AppTransitionType _tabTransitionForIndex(int index) {
    switch (index) {
      case kTabBible:
        return AppTransitionType.slideRight;
      case kTabSearch:
        return AppTransitionType.fade;
      case kTabJournal:
        return AppTransitionType.scale;
      case kTabTracts:
        return AppTransitionType.slideUp;
      case kTabHome:
      default:
        return AppTransitionType.fade;
    }
  }
}
