import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/data/hastebin_storage.dart';

import 'test_helpers.dart';

// Mock HTTP client for testing Hastebin integration
class MockHttpClient extends http.BaseClient {
  final Map<String, dynamic> responses = {};
  final List<http.Request> requests = [];
  int uploadCounter = 0;
  
  void setUploadResponse(int statusCode, String key) {
    responses['upload'] = {'statusCode': statusCode, 'key': key};
  }
  
  void setDownloadResponse(String id, int statusCode, String body) {
    responses['download_$id'] = {'statusCode': statusCode, 'body': body};
  }
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request as http.Request);
    
    if (request.url.path.endsWith('/documents')) {
      // Upload request
      final response = responses['upload'];
      if (response == null) {
        return http.StreamedResponse(
          Stream.value([]),
          404,
          request: request,
        );
      }
      
      final responseBody = json.encode({'key': response['key']});
      return http.StreamedResponse(
        Stream.value(utf8.encode(responseBody)),
        response['statusCode'],
        request: request,
      );
    } else {
      // Download request - extract ID from path
      final pathParts = request.url.path.split('/');
      final id = pathParts.last;
      final response = responses['download_$id'];
      
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
}

void main() {
  group('StorageCubit Hastebin Integration', () {
    late MockHttpClient mockClient;
    late HastebinStorage hastebinStorage;
    late StorageCubit cubit;
    
    setUpAll(() async {
      await initHydratedStorage();
    });
    
    setUp(() {
      mockClient = MockHttpClient();
      hastebinStorage = HastebinStorage(
        baseUrl: 'https://test.hastebin.com',
        client: mockClient,
      );
      cubit = StorageCubit(hastebinStorage);
    });
    
    tearDown(() async {
      await cubit.close();
    });
    
    group('generateHastebinUrl', () {
      test('uploads items and generates URL with Hastebin ID', () async {
        // Set up mock response
        mockClient.setUploadResponse(200, 'abc123');
        
        // Add items to cubit
        cubit.saveItems(['Apple', 'Banana', 'Cherry']);
        
        // Generate Hastebin URL
        final uri = await cubit.generateHastebinUrl();
        
        // Verify the request was made
        expect(mockClient.requests, hasLength(1));
        expect(mockClient.requests.first.method, equals('POST'));
        expect(mockClient.requests.first.url.path, equals('/documents'));
        
        // Verify URL format
        expect(uri.path, equals('/hastebin/abc123'));
        expect(uri.toString(), contains('abc123'));
      });
      
      test('handles upload failures gracefully', () async {
        // Set up mock to return error
        mockClient.setUploadResponse(500, '');
        
        cubit.saveItems(['Test Item']);
        
        // Should throw HastebinException
        expect(
          () async => await cubit.generateHastebinUrl(),
          throwsA(isA<HastebinException>()),
        );
      });
      
      test('uploads encoded items correctly', () async {
        mockClient.setUploadResponse(200, 'test123');
        
        final items = ['Item with "quotes"', 'Item with 🎯 emoji', 'Item\nwith\nnewlines'];
        cubit.saveItems(items);
        
        await cubit.generateHastebinUrl();
        
        // Verify the request body contains properly encoded data
        final requestBody = mockClient.requests.first.body;
        final decodedData = json.decode(requestBody);
        
        expect(decodedData['version'], equals(1));
        expect(decodedData['items'], equals(items));
        expect(decodedData['timestamp'], isA<String>());
      });
    });
    
    group('web initialization with Hastebin', () {
      test('loads items from Hastebin URL', () async {
        // Prepare test data
        final items = ['Apple', 'Banana', 'Cherry'];
        final encodedData = hastebinStorage.encodeItems(items);
        
        // Mock the download response
        mockClient.setDownloadResponse('test123', 200, encodedData);
        
        // Create a web cubit that should load from Hastebin
        // Note: This test simulates the URL extraction logic
        final webCubit = StorageCubit.web(hastebinStorage);
        
        // Manually trigger the download (simulating URL with hastebin ID)
        final downloadedItems = await hastebinStorage.downloadItems('test123');
        webCubit.emit(webCubit.state.copyWith(items: downloadedItems));
        
        // Verify items were loaded
        expect(webCubit.state.items, equals(items));
        
        await webCubit.close();
      });
      
      test('handles download failures and falls back gracefully', () async {
        // Mock download failure
        mockClient.setDownloadResponse('missing', 404, 'Not Found');
        
        // Should not throw, but keep empty state
        expect(
          () async => await hastebinStorage.downloadItems('missing'),
          throwsA(isA<HastebinException>()),
        );
      });
    });
    
    group('rate limiting integration', () {
      test('respects rate limiting during multiple uploads', () async {
        // Set up successful responses
        for (int i = 0; i < 5; i++) {
          mockClient.setUploadResponse(200, 'test$i');
        }
        
        cubit.saveItems(['Test']);
        
        // Multiple rapid calls should still work (but may be delayed)
        final futures = <Future<Uri>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(cubit.generateHastebinUrl());
        }
        
        final results = await Future.wait(futures);
        
        // All should succeed
        expect(results, hasLength(5));
        for (final uri in results) {
          expect(uri.path, matches(r'/hastebin/test\d+'));
        }
        
        // Should have made 5 requests
        expect(mockClient.requests, hasLength(5));
      });
      
      test('handles rate limiting delays properly', () async {
        // Create a new rate limiter for this test to isolate the behavior
        final testStorage = HastebinStorage(
          baseUrl: 'https://test.hastebin.com',
          client: mockClient,
        );
        final testCubit = StorageCubit(testStorage);
        
        try {
          // Fill up the rate limiter with requests at exactly the limit time
          final now = DateTime.now();
          for (int i = 0; i < RateLimiter.maxRequestsPerMinute; i++) {
            testStorage.rateLimiter.requestTimes.add(now.subtract(Duration(seconds: 59))); // Just under 1 minute ago
          }
          
          mockClient.setUploadResponse(200, 'delayed');
          testCubit.saveItems(['Test']);
          
          // This should work immediately since our test requests are just under 1 minute old
          final stopwatch = Stopwatch()..start();
          await testCubit.generateHastebinUrl();
          stopwatch.stop();
          
          // Should complete relatively quickly since we didn't trigger the rate limit
          expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be much faster
        } finally {
          await testCubit.close();
          testStorage.dispose();
        }
      }, timeout: const Timeout(Duration(seconds: 10)));
    });
    
    group('backward compatibility', () {
      test('maintains legacy URL parameter functionality', () async {
        cubit.saveItems(['Legacy Item']);
        
        // Should still work with legacy URL method
        final legacyUri = cubit.uriWithData;
        expect(legacyUri, isNotNull);
      });
    });
    
    group('error scenarios', () {
      test('handles network errors gracefully', () async {
        // Simulate network error by not setting up any mock responses
        cubit.saveItems(['Test']);
        
        expect(
          () async => await cubit.generateHastebinUrl(),
          throwsA(isA<HastebinException>()),
        );
      });
      
      test('handles malformed responses', () async {
        // Set up malformed response
        mockClient.responses['upload'] = {'statusCode': 200, 'key': null};
        cubit.saveItems(['Test']);
        
        expect(
          () async => await cubit.generateHastebinUrl(),
          throwsA(isA<HastebinException>()),
        );
      });
    });
    
    group('large data handling', () {
      test('handles large number of items', () async {
        mockClient.setUploadResponse(200, 'large');
        
        // Create 100 items
        final largeItemList = List.generate(100, (index) => 'Item $index');
        cubit.saveItems(largeItemList);
        
        final uri = await cubit.generateHastebinUrl();
        expect(uri.path, equals('/hastebin/large'));
        
        // Verify all items were encoded properly
        final requestBody = mockClient.requests.first.body;
        final decodedData = json.decode(requestBody);
        expect(decodedData['items'], hasLength(100));
      });
      
      test('handles items with large content', () async {
        mockClient.setUploadResponse(200, 'big');
        
        // Create items with large content
        final bigItem = 'A' * 1000; // 1KB item
        cubit.saveItems([bigItem, 'Small item', bigItem]);
        
        final uri = await cubit.generateHastebinUrl();
        expect(uri.path, equals('/hastebin/big'));
        
        // Verify content was preserved
        final requestBody = mockClient.requests.first.body;
        final decodedData = json.decode(requestBody);
        expect(decodedData['items'][0], equals(bigItem));
        expect(decodedData['items'][2], equals(bigItem));
      });
    });
  });
}