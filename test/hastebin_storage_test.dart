import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:webroulette/data/hastebin_storage.dart';

// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final Map<String, dynamic> responses = {};
  final List<http.Request> requests = [];
  
  void setResponse(String url, int statusCode, String body) {
    responses[url] = {'statusCode': statusCode, 'body': body};
  }
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request as http.Request);
    
    final response = responses[request.url.toString()];
    if (response == null) {
      return http.StreamedResponse(
        Stream.value([]),
        404,
        request: request,
      );
    }
    
    return http.StreamedResponse(
      Stream.value(utf8.encode(response['body'])),
      response['statusCode'],
      request: request,
    );
  }
}

void main() {
  group('RateLimiter', () {
    test('allows requests under the limit', () {
      final rateLimiter = RateLimiter();
      
      // Should allow requests under the limit
      expect(rateLimiter.getRequiredDelay(), isNull);
    });
    
    test('requires delay when at rate limit', () {
      final rateLimiter = RateLimiter();
      
      // Add 100 requests (at the limit)
      for (int i = 0; i < RateLimiter.maxRequestsPerMinute; i++) {
        rateLimiter.requestTimes.add(DateTime.now());
      }
      
      // Should now require a delay
      final delay = rateLimiter.getRequiredDelay();
      expect(delay, isNotNull);
      expect(delay!.inMilliseconds, greaterThan(0));
    });
    
    test('cleans up old requests', () async {
      final rateLimiter = RateLimiter();
      
      // Add requests from more than a minute ago
      final oldTime = DateTime.now().subtract(const Duration(minutes: 2));
      for (int i = 0; i < 50; i++) {
        rateLimiter.requestTimes.add(oldTime);
      }
      
      // Add recent requests
      for (int i = 0; i < 50; i++) {
        rateLimiter.requestTimes.add(DateTime.now());
      }
      
      // Should allow more requests after cleanup
      expect(rateLimiter.getRequiredDelay(), isNull);
    });
    
    test('recordRequest waits for required delay', () async {
      final rateLimiter = RateLimiter();
      
      // Fill up to just under the limit
      for (int i = 0; i < RateLimiter.maxRequestsPerMinute - 1; i++) {
        rateLimiter.requestTimes.add(DateTime.now());
      }
      
      // This should complete quickly
      final stopwatch = Stopwatch()..start();
      await rateLimiter.recordRequest();
      stopwatch.stop();
      
      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
  
  group('HastebinStorage', () {
    late MockHttpClient mockClient;
    late HastebinStorage storage;
    
    setUp(() {
      mockClient = MockHttpClient();
      storage = HastebinStorage(
        baseUrl: 'https://test.hastebin.com',
        client: mockClient,
      );
    });
    
    tearDown(() {
      storage.dispose();
    });
    
    group('upload', () {
      test('successful upload returns key', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/documents',
          200,
          '{"key": "test123"}',
        );
        
        final result = await storage.upload('test data');
        
        expect(result, equals('test123'));
        expect(mockClient.requests, hasLength(1));
        expect(mockClient.requests.first.method, equals('POST'));
        expect(mockClient.requests.first.body, equals('test data'));
      });
      
      test('handles HTTP error responses', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/documents',
          500,
          'Internal Server Error',
        );
        
        expect(
          () async => await storage.upload('test data'),
          throwsA(isA<HastebinException>()
              .having((e) => e.statusCode, 'statusCode', equals(500))),
        );
      });
      
      test('handles invalid JSON response', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/documents',
          200,
          'invalid json',
        );
        
        expect(
          () async => await storage.upload('test data'),
          throwsA(isA<HastebinException>()),
        );
      });
      
      test('handles missing key in response', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/documents',
          200,
          '{"success": true}',
        );
        
        expect(
          () async => await storage.upload('test data'),
          throwsA(isA<HastebinException>()
              .having((e) => e.message, 'message', contains('missing key'))),
        );
      });
    });
    
    group('download', () {
      test('successful download returns data', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/raw/test123',
          200,
          'test data content',
        );
        
        final result = await storage.download('test123');
        
        expect(result, equals('test data content'));
        expect(mockClient.requests, hasLength(1));
        expect(mockClient.requests.first.method, equals('GET'));
      });
      
      test('handles 404 not found', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/raw/missing',
          404,
          'Not Found',
        );
        
        expect(
          () async => await storage.download('missing'),
          throwsA(isA<HastebinException>()
              .having((e) => e.statusCode, 'statusCode', equals(404))
              .having((e) => e.message, 'message', contains('not found'))),
        );
      });
      
      test('handles other HTTP errors', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/raw/test123',
          403,
          'Forbidden',
        );
        
        expect(
          () async => await storage.download('test123'),
          throwsA(isA<HastebinException>()
              .having((e) => e.statusCode, 'statusCode', equals(403))),
        );
      });
    });
    
    group('encoding/decoding', () {
      test('encodes and decodes simple items', () {
        final items = ['Apple', 'Banana', 'Cherry'];
        
        final encoded = storage.encodeItems(items);
        final decoded = storage.decodeItems(encoded);
        
        expect(decoded, equals(items));
      });
      
      test('encodes and decodes empty list', () {
        final items = <String>[];
        
        final encoded = storage.encodeItems(items);
        final decoded = storage.decodeItems(encoded);
        
        expect(decoded, equals(items));
      });
      
      test('encodes and decodes items with special characters', () {
        final items = [
          'Item with spaces',
          'Item with "quotes"',
          'Item with 🎯 emoji',
          'Item with \\backslashes\\',
          'Item with\nnewlines\nand\ttabs',
        ];
        
        final encoded = storage.encodeItems(items);
        final decoded = storage.decodeItems(encoded);
        
        expect(decoded, equals(items));
      });
      
      test('encodes and decodes large number of items', () {
        final items = List.generate(1000, (index) => 'Item $index');
        
        final encoded = storage.encodeItems(items);
        final decoded = storage.decodeItems(encoded);
        
        expect(decoded, equals(items));
      });
      
      test('encodes and decodes items with very long content', () {
        final longItem = 'A' * 10000; // 10KB item
        final items = [longItem, 'Short item', longItem];
        
        final encoded = storage.encodeItems(items);
        final decoded = storage.decodeItems(encoded);
        
        expect(decoded, equals(items));
      });
      
      test('includes version and timestamp in encoded data', () {
        final items = ['Test'];
        final encoded = storage.encodeItems(items);
        final data = json.decode(encoded);
        
        expect(data['version'], equals(1));
        expect(data['items'], equals(items));
        expect(data['timestamp'], isA<String>());
        
        // Verify timestamp is valid ISO 8601
        expect(() => DateTime.parse(data['timestamp']), returnsNormally);
      });
      
      test('handles decoding errors gracefully', () {
        expect(
          () => storage.decodeItems('invalid json'),
          throwsA(isA<HastebinException>()),
        );
        
        expect(
          () => storage.decodeItems('{"version": 2, "items": []}'),
          throwsA(isA<HastebinException>()
              .having((e) => e.message, 'message', contains('Unsupported data version'))),
        );
        
        expect(
          () => storage.decodeItems('{"version": 1, "items": "not a list"}'),
          throwsA(isA<HastebinException>()
              .having((e) => e.message, 'message', contains('items must be a list'))),
        );
      });
    });
    
    group('uploadItems and downloadItems', () {
      test('round trip upload and download', () async {
        final items = ['Apple', 'Banana', 'Cherry'];
        
        // Mock the upload response
        mockClient.setResponse(
          'https://test.hastebin.com/documents',
          200,
          '{"key": "abc123"}',
        );
        
        // Mock the download response
        final expectedData = storage.encodeItems(items);
        mockClient.setResponse(
          'https://test.hastebin.com/raw/abc123',
          200,
          expectedData,
        );
        
        // Upload items
        final hastebinId = await storage.uploadItems(items);
        expect(hastebinId, equals('abc123'));
        
        // Download items
        final downloadedItems = await storage.downloadItems(hastebinId);
        expect(downloadedItems, equals(items));
        
        expect(mockClient.requests, hasLength(2));
      });
      
      test('handles upload failure', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/documents',
          503,
          'Service Unavailable',
        );
        
        expect(
          () async => await storage.uploadItems(['test']),
          throwsA(isA<HastebinException>()),
        );
      });
      
      test('handles download failure', () async {
        mockClient.setResponse(
          'https://test.hastebin.com/raw/missing',
          404,
          'Not Found',
        );
        
        expect(
          () async => await storage.downloadItems('missing'),
          throwsA(isA<HastebinException>()),
        );
      });
    });
    
    group('error handling', () {
      test('HastebinException toString includes status code', () {
        final exception = HastebinException('Test error', 500);
        expect(exception.toString(), contains('Test error'));
        expect(exception.toString(), contains('HTTP 500'));
      });
      
      test('HastebinException toString without status code', () {
        final exception = HastebinException('Test error');
        expect(exception.toString(), contains('Test error'));
        expect(exception.toString(), isNot(contains('HTTP')));
      });
    });
  });
}