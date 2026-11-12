import 'package:flutter/foundation.dart';

/// App-facing analytics API (see `analytics_events.dart` for the catalogue).
///
/// Every method is fire-and-forget and never throws: analytics must not be
/// able to break or slow down a UI flow. Production uses
/// `FirebaseAnalyticsService` on Android; tests and other platforms get
/// [NoopAnalyticsService].
abstract class AnalyticsService {
  /// Logs [name] with [params]. Values must be bool, num or one of the fixed
  /// strings in `AnalyticsValues`; anything else is dropped.
  void logEvent(String name, [Map<String, Object?> params = const {}]);

  /// Logs a `screen_view` for [screenName] (an `AnalyticsScreens` name).
  void logScreenView(String screenName);

  /// Turns collection on or off (the user's "Share usage statistics" switch).
  /// Debug builds stay off regardless.
  void setCollectionEnabled(bool enabled);

  /// Sets a user property such as `is_pro`; null clears it.
  void setUserProperty(String name, String? value);
}

/// Analytics is wired up on Android only (there is no iOS Firebase config).
bool get isAnalyticsSupportedPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Does nothing. Default for tests, iOS and builds without Firebase config.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {}

  @override
  void logScreenView(String screenName) {}

  @override
  void setCollectionEnabled(bool enabled) {}

  @override
  void setUserProperty(String name, String? value) {}
}
