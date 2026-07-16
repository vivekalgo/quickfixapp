import 'package:flutter/material.dart';
import 'package:quickfix/core/logging/app_logger.dart';

class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.info(
      'PUSH Route: "${route.settings.name ?? 'unknown'}" (previous: "${previousRoute?.settings.name ?? 'none'}")',
      tag: 'NAV',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.info(
      'POP Route: "${route.settings.name ?? 'unknown'}" (returning to: "${previousRoute?.settings.name ?? 'none'}")',
      tag: 'NAV',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    AppLogger.info(
      'REPLACE Route: "${oldRoute?.settings.name ?? 'none'}" with "${newRoute?.settings.name ?? 'unknown'}"',
      tag: 'NAV',
    );
  }
}
