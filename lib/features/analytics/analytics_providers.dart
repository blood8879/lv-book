import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';
import 'analytics_settings_repository.dart';

/// App-wide analytics. No-op by default (tests, iOS); `main()` overrides it
/// with the Firebase-backed service from `AnalyticsBootstrap.start()`.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const NoopAnalyticsService(),
);

final analyticsSettingsRepositoryProvider =
    Provider<AnalyticsSettingsRepository>(
      (ref) => AnalyticsSettingsRepository(),
    );

/// "Share usage statistics" switch (default on).
final usageStatsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(analyticsSettingsRepositoryProvider).isUsageStatsEnabled(),
);

/// Persists the switch and applies it to the analytics SDK right away.
Future<void> setUsageStatsEnabled(WidgetRef ref, bool enabled) async {
  await ref
      .read(analyticsSettingsRepositoryProvider)
      .setUsageStatsEnabled(enabled);
  ref.read(analyticsServiceProvider).setCollectionEnabled(enabled);
  ref.invalidate(usageStatsEnabledProvider);
}

/// Logs `screen_view` for page routes named with an [AnalyticsScreens] name
/// (the app's home route `/` is the project list). Dialogs, sheets and
/// unnamed routes are ignored.
class AnalyticsRouteObserver extends NavigatorObserver {
  final AnalyticsService Function() _analytics;

  AnalyticsRouteObserver(this._analytics);

  static String? screenNameOf(Route<dynamic>? route) {
    if (route is! PageRoute) return null;
    final name = route.settings.name;
    if (name == Navigator.defaultRouteName) return AnalyticsScreens.projectList;
    return AnalyticsScreens.all.contains(name) ? name : null;
  }

  void _log(Route<dynamic>? route) {
    final name = screenNameOf(route);
    if (name == null) return;
    try {
      _analytics().logScreenView(name);
    } catch (_) {
      // Analytics never interferes with navigation.
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log(newRoute);

  /// Returning to a page counts as viewing it again (GA4 default behaviour).
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _log(previousRoute);
  }
}
