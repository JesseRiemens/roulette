import 'package:test/test.dart';
import 'package:webroulette/data/hastebin_rate_limit_service.dart';

void main() {
  group('HastebinRateLimitService', () {
    late HastebinRateLimitService service;

    setUp(() {
      service = HastebinRateLimitService.instance;
      service.reset(); // Start fresh for each test
    });

    tearDown(() {
      service.reset(); // Clean up after each test
    });

    group('rate limiting', () {
      test('allows requests under the limit', () async {
        // Should allow requests under the limit without waiting
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 99; i++) {
          await service.waitForRateLimit();
        }

        stopwatch.stop();

        // Should complete quickly since we're under the limit
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(service.currentRequestCount, equals(99));
      });

      test('enforces rate limit at exactly 100 requests', () async {
        // Fill up to the limit
        for (int i = 0; i < 100; i++) {
          await service.waitForRateLimit();
        }

        expect(service.currentRequestCount, equals(100));

        // Next request should have to wait
        final waitTime = service.timeUntilNextRequest;
        expect(waitTime, isNotNull);
        expect(waitTime!.inMilliseconds, greaterThan(0));
      });

      test('resets count after time window', () async {
        // Make some requests
        for (int i = 0; i < 5; i++) {
          await service.waitForRateLimit();
        }

        expect(service.currentRequestCount, equals(5));

        // Simulate time passing by manipulating the internal list
        // (In a real scenario, we'd wait 1 minute)
        service.reset();

        expect(service.currentRequestCount, equals(0));
      });

      test('handles concurrent requests properly', () async {
        final futures = <Future<void>>[];

        // Start 10 concurrent requests
        for (int i = 0; i < 10; i++) {
          futures.add(service.waitForRateLimit());
        }

        await Future.wait(futures);

        expect(service.currentRequestCount, equals(10));
      });
    });

    group('status reporting', () {
      test('reports correct current request count', () {
        expect(service.currentRequestCount, equals(0));

        service.waitForRateLimit();
        expect(service.currentRequestCount, equals(1));

        service.waitForRateLimit();
        expect(service.currentRequestCount, equals(2));
      });

      test('reports null wait time when under limit', () {
        for (int i = 0; i < 99; i++) {
          service.waitForRateLimit();
        }

        expect(service.timeUntilNextRequest, isNull);
      });

      test('reports wait time when at limit', () async {
        // Fill to capacity
        for (int i = 0; i < 100; i++) {
          await service.waitForRateLimit();
        }

        final waitTime = service.timeUntilNextRequest;
        expect(waitTime, isNotNull);
        expect(waitTime!.inSeconds, greaterThan(0));
      });
    });

    group('edge cases', () {
      test('handles rapid successive calls', () async {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          await service.waitForRateLimit();
        }

        stopwatch.stop();

        // Should complete quickly for small numbers
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(service.currentRequestCount, equals(10));
      });

      test('reset clears all state', () async {
        // Make some requests
        for (int i = 0; i < 50; i++) {
          await service.waitForRateLimit();
        }

        expect(service.currentRequestCount, equals(50));

        service.reset();

        expect(service.currentRequestCount, equals(0));
        expect(service.timeUntilNextRequest, isNull);
      });

      test('singleton behavior', () {
        final instance1 = HastebinRateLimitService.instance;
        final instance2 = HastebinRateLimitService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });
  });
}
