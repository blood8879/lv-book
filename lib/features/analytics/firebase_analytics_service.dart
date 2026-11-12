import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';
import 'analytics_settings_repository.dart';

/// [AnalyticsService] backed by Google Analytics for Firebase.
///
/// Calls are chained onto [_ready] (Firebase init + applying the user's
/// collection preference), so startup never waits for Firebase and nothing is
/// sent before the preference is applied. If init failed (no
/// `google-services.json`, Play services missing, ...) [_ready] yields null
/// and every call is dropped.
class FirebaseAnalyticsService implements AnalyticsService {
  final Future<FirebaseAnalytics?> _ready;

  /// Keeps collection off whatever the user chose (debug builds).
  final bool forceDisabled;

  FirebaseAnalyticsService(this._ready, {this.forceDisabled = kDebugMode});

  void _run(Future<void> Function(FirebaseAnalytics analytics) action) {
    unawaited(
      _ready
          .then((analytics) async {
            if (analytics != null) await action(analytics);
          })
          .catchError((Object error) {
            debugPrint('Analytics call failed: $error');
          }),
    );
  }

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    if (!isValidAnalyticsName(name)) return;
    final parameters = _toFirebaseParams(sanitizeAnalyticsParams(params));
    _run(
      (analytics) => analytics.logEvent(
        name: name,
        parameters: parameters.isEmpty ? null : parameters,
      ),
    );
  }

  @override
  void logScreenView(String screenName) {
    if (!AnalyticsScreens.all.contains(screenName)) return;
    _run(
      (analytics) => analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      ),
    );
  }

  @override
  void setCollectionEnabled(bool enabled) {
    _run(
      (analytics) =>
          analytics.setAnalyticsCollectionEnabled(enabled && !forceDisabled),
    );
  }

  @override
  void setUserProperty(String name, String? value) {
    if (value != null && !AnalyticsValues.all.contains(value)) return;
    _run((analytics) => analytics.setUserProperty(name: name, value: value));
  }

  /// Firebase accepts only String / num values; booleans become "true" /
  /// "false" so they read naturally in GA reports.
  static Map<String, Object> _toFirebaseParams(Map<String, Object> params) => {
    for (final entry in params.entries)
      entry.key: switch (entry.value) {
        final bool value => value.toString(),
        final value => value,
      },
  };
}

/// Creates the app's [AnalyticsService] at startup.
abstract final class AnalyticsBootstrap {
  /// Returns immediately. On Android, Firebase is initialized in the
  /// background and the stored "Share usage statistics" preference is applied
  /// (debug builds: always off) before any event is passed on. Any failure
  /// leaves analytics off; it never throws.
  static AnalyticsService start({AnalyticsSettingsRepository? settings}) {
    if (!isAnalyticsSupportedPlatform) return const NoopAnalyticsService();
    return FirebaseAnalyticsService(
      _initialize(settings ?? AnalyticsSettingsRepository()),
    );
  }

  static Future<FirebaseAnalytics?> _initialize(
    AnalyticsSettingsRepository settings,
  ) async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
      final analytics = FirebaseAnalytics.instance;
      if (kDebugMode) {
        await analytics.setAnalyticsCollectionEnabled(false);
      } else {
        // The manifest starts collection off; a failed read keeps whatever
        // the SDK last persisted (off on a fresh install).
        final enabled = await settings.readUsageStatsEnabled();
        if (enabled != null) {
          await analytics.setAnalyticsCollectionEnabled(enabled);
        }
      }
      return analytics;
    } catch (error) {
      debugPrint('Analytics disabled: $error');
      return null;
    }
  }
}
