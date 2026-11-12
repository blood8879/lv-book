import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/analytics/analytics_events.dart';
import 'package:lv_book/features/analytics/analytics_service.dart';

typedef LoggedEvent = ({String name, Map<String, Object?> params});

/// Records analytics calls and fails the test as soon as a call could leak
/// user content: unknown event names, or parameter values that are not
/// bool / num / a fixed [AnalyticsValues] string.
class FakeAnalyticsService implements AnalyticsService {
  final events = <LoggedEvent>[];
  final screens = <String>[];
  final collection = <bool>[];
  final userProperties = <String, String?>{};

  List<LoggedEvent> named(String name) =>
      events.where((event) => event.name == name).toList();

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    expect(AnalyticsEvents.all, contains(name), reason: 'unknown event');
    expect(isValidAnalyticsName(name), isTrue, reason: name);
    params.forEach((key, value) => expectSafeAnalyticsParam(name, key, value));
    events.add((name: name, params: Map.of(params)));
  }

  @override
  void logScreenView(String screenName) {
    expect(AnalyticsScreens.all, contains(screenName));
    screens.add(screenName);
  }

  @override
  void setCollectionEnabled(bool enabled) => collection.add(enabled);

  @override
  void setUserProperty(String name, String? value) {
    if (value != null) expect(AnalyticsValues.all, contains(value));
    userProperties[name] = value;
  }
}

void expectSafeAnalyticsParam(String event, String key, Object? value) {
  expect(isValidAnalyticsName(key), isTrue, reason: '$event.$key');
  if (value is bool || value is num) return;
  expect(value, isA<String>(), reason: '$event.$key has type');
  expect(
    AnalyticsValues.all,
    contains(value),
    reason: '$event.$key = "$value" is not a fixed analytics value',
  );
}
