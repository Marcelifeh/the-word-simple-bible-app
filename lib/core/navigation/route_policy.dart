import 'page_transition_type.dart';

class RoutePolicy {
  const RoutePolicy._();

  static const String homeRoute = '/';
  static const String settingsRoute = '/settings';
  static const String readingPlanRoute = '/reading-plan';
  static const String devotionalRoute = '/devotional';
  static const String readingRoute = '/reading';
  static const String tractsRoute = '/tracts';
  static const String journalRoute = '/journal';
  static const String searchRoute = '/search';

  static AppTransitionType forRoute(String? routeName) {
    switch (routeName) {
      case devotionalRoute:
        return AppTransitionType.devotional;
      case readingPlanRoute:
      case readingRoute:
        return AppTransitionType.slideRight;
      case tractsRoute:
        return AppTransitionType.slideUp;
      case journalRoute:
        return AppTransitionType.scale;
      case homeRoute:
      case settingsRoute:
      case searchRoute:
      default:
        return AppTransitionType.fade;
    }
  }
}
