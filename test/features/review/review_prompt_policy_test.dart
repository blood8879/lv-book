import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/review/review_prompt_policy.dart';

class _MemoryStore implements ReviewPromptStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _FakeClient implements AppReviewClient {
  bool available = true;
  bool throwOnRequest = false;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    if (throwOnRequest) throw Exception('play services missing');
    requests++;
  }

  @override
  Future<void> openStoreListing() async {}
}

void main() {
  late _MemoryStore store;
  late DateTime now;
  late ReviewPromptPolicy policy;
  late _FakeClient client;
  late ReviewPromptCoordinator coordinator;

  final start = DateTime(2026, 1, 1, 9);

  setUp(() {
    store = _MemoryStore();
    now = start;
    policy = ReviewPromptPolicy(store: store, clock: () => now);
    client = _FakeClient();
    coordinator = ReviewPromptCoordinator(policy: policy, client: client);
  });

  Future<void> exports(int count) async {
    for (var i = 0; i < count; i++) {
      await policy.recordSuccessfulExport();
    }
  }

  group('ReviewPromptPolicy', () {
    test('1 export is not eligible, 2 exports are', () async {
      await exports(1);
      expect(await policy.isEligible(), isFalse);
      await exports(1);
      expect(await policy.isEligible(), isTrue);
    });

    test('no install-age requirement (eligible on day one)', () async {
      await exports(2);
      expect(await policy.isEligible(), isTrue);
    });

    test('30-day cooldown after a request', () async {
      await exports(2);
      await policy.recordRequested();
      now = start.add(const Duration(days: 29, hours: 23));
      expect(await policy.isEligible(), isFalse);
      now = start.add(const Duration(days: 30));
      expect(await policy.isEligible(), isTrue);
    });

    test('no lifetime cap on requests', () async {
      await exports(2);
      for (var i = 0; i < 3; i++) {
        expect(await policy.isEligible(), isTrue, reason: 'request #$i');
        await policy.recordRequested();
        now = now.add(const Duration(days: 30));
      }
      now = now.add(const Duration(days: 90));
      expect(await policy.isEligible(), isTrue, reason: '4th request');
      expect(store.values[ReviewPromptPolicy.requestCountKey], '3');
    });

    test('legacy stored values do not block eligibility', () async {
      // Written by the old policy (install age + max 3 requests).
      store.values['review_first_launch_at'] = now.toIso8601String();
      store.values[ReviewPromptPolicy.requestCountKey] = '3';
      store.values[ReviewPromptPolicy.lastRequestedAtKey] = start
          .subtract(const Duration(days: 31))
          .toIso8601String();
      await exports(2);
      expect(await policy.isEligible(), isTrue);
    });

    test('unparseable stored values are treated as missing', () async {
      store.values[ReviewPromptPolicy.exportCountKey] = 'garbage';
      store.values[ReviewPromptPolicy.lastRequestedAtKey] = 'garbage';
      expect(await policy.isEligible(), isFalse);
      await exports(2);
      expect(await policy.isEligible(), isTrue);
    });
  });

  group('ReviewPromptCoordinator', () {
    test('onExportSucceeded counts and reports eligibility', () async {
      expect(await coordinator.onExportSucceeded(), isFalse);
      expect(await coordinator.onExportSucceeded(), isTrue);
      expect(store.values[ReviewPromptPolicy.exportCountKey], '2');
      expect(client.requests, 0, reason: 'only reports, never requests');
    });

    test('onExportSucceeded is false when the API is unavailable', () async {
      client.available = false;
      await exports(1);
      expect(await coordinator.onExportSucceeded(), isFalse);
    });

    test('onExportSucceeded swallows store errors', () async {
      final throwing = ReviewPromptCoordinator(
        policy: ReviewPromptPolicy(store: _ThrowingStore()),
        client: client,
      );
      expect(await throwing.onExportSucceeded(), isFalse);
    });

    test('requestReview records the cooldown after the request', () async {
      expect(await coordinator.requestReview(), isTrue);
      expect(client.requests, 1);
      expect(
        store.values[ReviewPromptPolicy.lastRequestedAtKey],
        start.toIso8601String(),
      );
    });

    test(
      'requestReview returns false without throwing when the client throws',
      () async {
        client.throwOnRequest = true;
        expect(await coordinator.requestReview(), isFalse);
        // Attempted, so the cooldown still starts (no ad suppression loop).
        expect(store.values[ReviewPromptPolicy.lastRequestedAtKey], isNotNull);
      },
    );

    group('handleShareResult', () {
      late int adsShown;
      Future<void> showAd() async => adsShown++;

      setUp(() => adsShown = 0);

      Future<bool> share({bool dismissed = false}) => coordinator
          .handleShareResult(dismissed: dismissed, showInterstitial: showAd);

      test('not eligible: interstitial shows, no review', () async {
        expect(await share(), isFalse);
        expect(adsShown, 1);
        expect(client.requests, 0);
        expect(store.values[ReviewPromptPolicy.exportCountKey], '1');
      });

      test('eligible: review is requested and the ad is skipped', () async {
        await share();
        expect(await share(), isTrue);
        expect(client.requests, 1);
        expect(adsShown, 1, reason: 'only the first share showed an ad');
        // Cooldown: the next share shows the ad again.
        expect(await share(), isFalse);
        expect(adsShown, 2);
        expect(client.requests, 1);
      });

      test('dismissed share: ad as before, no count, no review', () async {
        await exports(5);
        expect(await share(dismissed: true), isFalse);
        expect(adsShown, 1);
        expect(client.requests, 0);
        expect(store.values[ReviewPromptPolicy.exportCountKey], '5');
      });

      test('client throwing: does not throw into the export flow', () async {
        client.throwOnRequest = true;
        await exports(1);
        expect(await share(), isTrue);
        expect(adsShown, 0);
      });

      test('API unavailable: falls back to the interstitial', () async {
        client.available = false;
        await exports(1);
        expect(await share(), isFalse);
        expect(adsShown, 1);
      });
    });

    test('onExportSharedWithoutAd requests once eligible', () async {
      expect(await coordinator.onExportSharedWithoutAd(), isFalse);
      expect(await coordinator.onExportSharedWithoutAd(), isTrue);
      expect(client.requests, 1);
    });
  });
}

class _ThrowingStore implements ReviewPromptStore {
  @override
  Future<String?> read(String key) => throw Exception('db closed');

  @override
  Future<void> write(String key, String value) => throw Exception('db closed');
}
