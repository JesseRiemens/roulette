import 'dart:convert';
import 'package:test/test.dart';
import 'package:hastebin_client/hastebin_client.dart';
import 'package:webroulette/data/hastebin_storage_service.dart';
import 'package:webroulette/data/hastebin_rate_limit_service.dart';

// Mock implementations for testing
class MockHastebinRepository implements HastebinRepositoryInterface {
  final Map<String, String> _storage = {};
  String? _lastStoredContent;
  String? _nextKey;
  Exception? _nextException;

  @override
  Future<String> createDocument(String content) async {
    if (_nextException != null) {
      final exception = _nextException!;
      _nextException = null;
      throw exception;
    }

    _lastStoredContent = content;
    final key = _nextKey ?? 'mock_key_${content.hashCode.abs()}';
    _nextKey = null;
    _storage[key] = content;
    return key;
  }

  @override
  Future<String> getDocument(String key) async {
    if (_nextException != null) {
      final exception = _nextException!;
      _nextException = null;
      throw exception;
    }

    if (!_storage.containsKey(key)) {
      throw HastebinDocumentNotFoundException(key);
    }
    return _storage[key]!;
  }

  @override
  Future<HastebinDocument> getDocumentWithMetadata(String key) async {
    final content = await getDocument(key);
    return HastebinDocument(key: key, content: content);
  }

  // Test helpers
  void setNextKey(String key) => _nextKey = key;
  void setNextException(Exception exception) => _nextException = exception;
  String? get lastStoredContent => _lastStoredContent;
  void reset() {
    _storage.clear();
    _lastStoredContent = null;
    _nextKey = null;
    _nextException = null;
  }
}

class MockRateLimitService implements HastebinRateLimitService {
  bool _shouldWait = false;
  Duration? _waitTime;
  int _requestCount = 0;

  MockRateLimitService._();
  static final instance = MockRateLimitService._();

  @override
  Future<void> waitForRateLimit() async {
    if (_shouldWait && _waitTime != null) {
      await Future.delayed(_waitTime!);
    }
    _requestCount++;
  }

  @override
  int get currentRequestCount => _requestCount;

  @override
  Duration? get timeUntilNextRequest => _shouldWait ? _waitTime : null;

  @override
  void reset() {
    _shouldWait = false;
    _waitTime = null;
    _requestCount = 0;
  }

  // Test helpers
  void setWaitBehavior(bool shouldWait, [Duration? waitTime]) {
    _shouldWait = shouldWait;
    _waitTime = waitTime ?? const Duration(milliseconds: 100);
  }
}

void main() {
  group('HastebinStorageService', () {
    late MockHastebinRepository mockRepository;
    late MockRateLimitService mockRateLimitService;
    late HastebinStorageService service;

    setUp(() {
      mockRepository = MockHastebinRepository();
      mockRateLimitService = MockRateLimitService.instance;
      mockRateLimitService.reset();
      service = HastebinStorageService(repository: mockRepository, rateLimitService: mockRateLimitService);
    });

    tearDown(() {
      mockRepository.reset();
      mockRateLimitService.reset();
    });

    group('uploadItems', () {
      test('uploads items with proper JSON format', () async {
        final items = ['Apple', 'Banana', 'Cherry'];

        final key = await service.uploadItems(items);

        expect(key, isNotEmpty);
        expect(mockRepository.lastStoredContent, isNotNull);

        final content = json.decode(mockRepository.lastStoredContent!) as Map<String, dynamic>;
        expect(content['version'], equals('1.0'));
        expect(content['type'], equals('roulette_items'));
        expect(content['items'], equals(items));
        expect(content['checksum'], isA<String>());
        expect(content['timestamp'], isA<String>());
      });

      test('includes checksum for data integrity', () async {
        final items = ['Test1', 'Test2'];

        await service.uploadItems(items);

        final content = json.decode(mockRepository.lastStoredContent!) as Map<String, dynamic>;
        final expectedChecksum = items.join('|').hashCode.abs().toString();
        expect(content['checksum'], equals(expectedChecksum));
      });

      test('handles empty items list', () async {
        final items = <String>[];

        final key = await service.uploadItems(items);

        expect(key, isNotEmpty);
        final content = json.decode(mockRepository.lastStoredContent!) as Map<String, dynamic>;
        expect(content['items'], equals([]));
      });

      test('handles items with special characters', () async {
        final items = ['Special: éñ 中文', 'Unicode: 🎯🎲', 'Quotes: "test"'];

        final key = await service.uploadItems(items);

        expect(key, isNotEmpty);
        final content = json.decode(mockRepository.lastStoredContent!) as Map<String, dynamic>;
        expect(content['items'], equals(items));
      });

      test('respects rate limiting', () async {
        mockRateLimitService.setWaitBehavior(true, const Duration(milliseconds: 50));

        final stopwatch = Stopwatch()..start();
        await service.uploadItems(['Test']);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(45));
        expect(mockRateLimitService.currentRequestCount, equals(1));
      });

      test('throws HastebinException on repository error', () async {
        mockRepository.setNextException(const HastebinException('Test error'));

        expect(() => service.uploadItems(['Test']), throwsA(isA<HastebinException>()));
      });

      test('handles large payload', () async {
        final items = List.generate(1000, (i) => 'Item $i with some longer text to test payload size');

        final key = await service.uploadItems(items);

        expect(key, isNotEmpty);
        final content = json.decode(mockRepository.lastStoredContent!) as Map<String, dynamic>;
        expect(content['items'], hasLength(1000));
      });
    });

    group('downloadItems', () {
      test('downloads and parses JSON format correctly', () async {
        final originalItems = ['Apple', 'Banana', 'Cherry'];
        final checksum = originalItems.join('|').hashCode.abs().toString();
        final jsonData = {
          'version': '1.0',
          'type': 'roulette_items',
          'timestamp': DateTime.now().toIso8601String(),
          'items': originalItems,
          'checksum': checksum,
        };

        mockRepository._storage['test_key'] = json.encode(jsonData);

        final items = await service.downloadItems('test_key');

        expect(items, equals(originalItems));
      });

      test('validates checksum on download', () async {
        final jsonData = {
          'version': '1.0',
          'type': 'roulette_items',
          'timestamp': DateTime.now().toIso8601String(),
          'items': ['Apple', 'Banana'],
          'checksum': 'invalid_checksum',
        };

        mockRepository._storage['test_key'] = json.encode(jsonData);

        expect(
          () => service.downloadItems('test_key'),
          throwsA(isA<HastebinException>().having((e) => e.message, 'message', contains('checksum mismatch'))),
        );
      });

      test('handles legacy format from example', () async {
        const legacyContent = '''Roulette Items:

- Apple
- Banana
- Cherry''';

        mockRepository._storage['test_key'] = legacyContent;

        final items = await service.downloadItems('test_key');

        expect(items, equals(['Apple', 'Banana', 'Cherry']));
      });

      test('handles simple line-separated legacy format', () async {
        const legacyContent = '''Apple
Banana
Cherry

Orange''';

        mockRepository._storage['test_key'] = legacyContent;

        final items = await service.downloadItems('test_key');

        expect(items, equals(['Apple', 'Banana', 'Cherry', 'Orange']));
      });

      test('respects rate limiting', () async {
        mockRateLimitService.setWaitBehavior(true, const Duration(milliseconds: 50));
        mockRepository._storage['test_key'] = json.encode({
          'version': '1.0',
          'type': 'roulette_items',
          'items': ['Test'],
          'checksum': 'Test'.hashCode.abs().toString(),
        });

        final stopwatch = Stopwatch()..start();
        await service.downloadItems('test_key');
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(45));
        expect(mockRateLimitService.currentRequestCount, equals(1));
      });

      test('throws HastebinDocumentNotFoundException for missing documents', () async {
        expect(() => service.downloadItems('nonexistent_key'), throwsA(isA<HastebinDocumentNotFoundException>()));
      });

      test('throws HastebinException for invalid JSON', () async {
        mockRepository._storage['test_key'] = '{"invalid": json}';

        expect(() => service.downloadItems('test_key'), throwsA(isA<HastebinException>()));
      });

      test('throws HastebinException for wrong data type', () async {
        final jsonData = {
          'version': '1.0',
          'type': 'wrong_type',
          'items': ['Apple'],
        };

        mockRepository._storage['test_key'] = json.encode(jsonData);

        expect(
          () => service.downloadItems('test_key'),
          throwsA(isA<HastebinException>().having((e) => e.message, 'message', contains('not roulette items'))),
        );
      });

      test('handles empty content gracefully', () async {
        mockRepository._storage['test_key'] = '';

        expect(() => service.downloadItems('test_key'), throwsA(isA<HastebinException>()));
      });
    });

    group('end-to-end flow', () {
      test('upload and download round trip preserves data', () async {
        final originalItems = ['🎯', 'Test "quoted"', 'Special éñ 中文', 'Multi\nLine\nItem'];

        final key = await service.uploadItems(originalItems);
        final downloadedItems = await service.downloadItems(key);

        expect(downloadedItems, equals(originalItems));
      });

      test('handles empty list round trip', () async {
        final originalItems = <String>[];

        final key = await service.uploadItems(originalItems);
        final downloadedItems = await service.downloadItems(key);

        expect(downloadedItems, equals(originalItems));
      });

      test('handles large data set round trip', () async {
        final originalItems = List.generate(500, (i) => 'Item $i: ${DateTime.now().toIso8601String()}');

        final key = await service.uploadItems(originalItems);
        final downloadedItems = await service.downloadItems(key);

        expect(downloadedItems, equals(originalItems));
      });
    });

    group('rate limit status', () {
      test('reports correct status', () {
        final status = service.getRateLimitStatus();

        expect(status.maxRequests, equals(100));
        expect(status.currentRequests, equals(0));
        expect(status.waitTime, isNull);
      });

      test('reports wait time when rate limited', () {
        mockRateLimitService.setWaitBehavior(true, const Duration(seconds: 30));

        final status = service.getRateLimitStatus();

        expect(status.waitTime, isNotNull);
        expect(status.waitTime!.inSeconds, equals(30));
      });
    });
  });
}
