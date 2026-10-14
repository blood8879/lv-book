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

  final installedAt = DateTime(2026, 1, 1, 9);

  setUp(() {
    store = _MemoryStore();
    now = installedAt;
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
    test('first launch is recorded once and never overwritten', () async {
      await policy.ensureFirstLaunchRecorded();
      now = installedAt.add(const Duration(days: 10));
      expect(await policy.ensureFirstLaunchRecorded(), installedAt);
    });

    test('needs at least 3 exports', () async {
      await policy.ensureFirstLaunchRecorded();
      now = installedAt.add(const Duration(days: 5));
      await exports(2);
      expect(await policy.isEligible(), isFalse);
      await exports(1);
      expect(await policy.isEligible(), isTrue);
    });

    test('needs the app installed for at least 3 days', () async {
      await policy.ensureFirstLaunchRecorded();
      await exports(5);
      now = installedAt.add(const Duration(days: 2, hours: 23));
      expect(await policy.isEligible(), isFalse);
      now = installedAt.add(const Duration(days: 3));
      expect(await policy.isEligible(), isTrue);
    });

    test('missing first-launch date starts the clock now', () async {
      await exports(3);
      expect(await policy.isEligible(), isFalse);
      expect(store.values[ReviewPromptPolicy.firstLaunchAtKey], isNotNull);
    });

    test('120-day cooldown and at most 3 requests ever', () async {
      await policy.ensureFirstLaunchRecorded();
      await exports(3);
      now = installedAt.add(const Duration(days: 3));

      for (var i = 0; i < 3; i++) {
        expect(await policy.isEligible(), isTrue, reason: 'request #$i');
        await policy.recordRequested();
        now = now.add(const Duration(days: 119));
        expect(await policy.isEligible(), isFalse);
        now = now.add(const Duration(days: 1));
      }
      now = now.add(const Duration(days: 1000));
      expect(await policy.isEligible(), isFalse);
    });
  });

  group('ReviewPromptCoordinator', () {
    Future<void> makeEligibleAfterNextExport() async {
      await policy.ensureFirstLaunchRecorded();
      await exports(2);
      now = installedAt.add(const Duration(days: 4));
    }

    test('requests a review after the qualifying export', () async {
      await makeEligibleAfterNextExport();
      expect(
        await coordinator.onExportShared(interstitialShown: false),
        isTrue,
      );
      expect(client.requests, 1);
      expect(store.values[ReviewPromptPolicy.requestCountKey], '1');
      // Cooldown blocks the next one.
      expect(
        await coordinator.onExportShared(interstitialShown: false),
        isFalse,
      );
      expect(client.requests, 1);
    });

    test(
      'skips (without counting a request) when an interstitial showed',
      () async {
        await makeEligibleAfterNextExport();
        expect(
          await coordinator.onExportShared(interstitialShown: true),
          isFalse,
        );
        expect(client.requests, 0);
        expect(store.values[ReviewPromptPolicy.exportCountKey], '3');
        expect(store.values[ReviewPromptPolicy.requestCountKey], isNull);
        // Next ad-free share asks.
        expect(
          await coordinator.onExportShared(interstitialShown: false),
          isTrue,
        );
      },
    );

    test('does nothing when the review API is unavailable', () async {
      await makeEligibleAfterNextExport();
      client.available = false;
      expect(
        await coordinator.onExportShared(interstitialShown: false),
        isFalse,
      );
      expect(store.values[ReviewPromptPolicy.requestCountKey], isNull);
    });

    test('swallows plugin errors', () async {
      await makeEligibleAfterNextExport();
      client.throwOnRequest = true;
      expect(
        await coordinator.onExportShared(interstitialShown: false),
        isFalse,
      );
      expect(store.values[ReviewPromptPolicy.requestCountKey], isNull);
    });
  });
}
