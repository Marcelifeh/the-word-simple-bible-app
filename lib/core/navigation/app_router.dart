import 'package:flutter/material.dart';

import '../../features/reading_plan/view/reading_plan_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import 'app_transitions.dart';
import 'page_transition_type.dart';
import 'route_policy.dart';

class AppRouter {
  const AppRouter._();

  static const String settingsRoute = RoutePolicy.settingsRoute;
  static const String readingPlanRoute = RoutePolicy.readingPlanRoute;

  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    AppTransitionType transition = AppTransitionType.fade,
    bool rootNavigator = false,
    RouteSettings? settings,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator).push<T>(
      AppTransitions.createRoute<T>(
        page: page,
        type: transition,
        settings: settings,
      ),
    );
  }

  static Future<T?> replace<T, TO>(
    BuildContext context,
    Widget page, {
    AppTransitionType transition = AppTransitionType.fade,
    bool rootNavigator = false,
    RouteSettings? settings,
    TO? result,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator)
        .pushReplacement<T, TO>(
      AppTransitions.createRoute<T>(
        page: page,
        type: transition,
        settings: settings,
      ),
      result: result,
    );
  }

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool rootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = _pageFor(settings);
    if (page == null) {
      return AppTransitions.createRoute(
        page: const _UnknownRouteScreen(),
        settings: settings,
      );
    }

    return AppTransitions.createRoute(
      page: page,
      type: RoutePolicy.forRoute(settings.name),
      settings: settings,
    );
  }

  static Widget? _pageFor(RouteSettings settings) {
    switch (settings.name) {
      case settingsRoute:
        return const SettingsScreen();
      case readingPlanRoute:
        return const ReadingPlanScreen();
      default:
        return null;
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: const Center(
        child: Text('The requested page could not be opened.'),
      ),
    );
  }
}
