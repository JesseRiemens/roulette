import 'package:flutter_test/flutter_test.dart';
import 'package:hastebin_client/hastebin_client.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/data/hastebin_rate_limit_service.dart';
import 'package:webroulette/data/hastebin_storage_service.dart';

import 'test_helpers.dart';

// Mock implementations for testing
class MockHastebinStorageService implements HastebinStorageService {
  final Map<String, List<String>> _storage = {};
  String? _nextKey;
  Exception? _nextException;
  bool _shouldDelayUpload = false;
  bool _shouldDelayDownload = false;

  @override
  HastebinRepositoryInterface get repository => throw UnimplementedError();

  @override
  HastebinRateLimitService? get rateLimitService => null;

  @override
  Future<String> uploadItems(List<String> items) async {
    if (_shouldDelayUpload) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_nextException != null) {
      final exception = _nextException!;
      _nextException = null;
      throw exception;
    }

    final key = _nextKey ?? 'mock_key_${items.hashCode.abs()}';
    _nextKey = null;
    _storage[key] = List.from(items);
    return key;
  }

  @override
  Future<List<String>> downloadItems(String key) async {
    if (_shouldDelayDownload) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_nextException != null) {
      final exception = _nextException!;
      _nextException = null;
      throw exception;
    }

    if (!_storage.containsKey(key)) {
      throw HastebinDocumentNotFoundException(key);
    }
    return List.from(_storage[key]!);
  }

  @override
  ({int currentRequests, int maxRequests, Duration? waitTime}) getRateLimitStatus() {
    return (currentRequests: 0, maxRequests: 100, waitTime: null);
  }

  // Test helpers
  void setNextKey(String key) => _nextKey = key;
  void setNextException(Exception exception) => _nextException = exception;
  void setUploadDelay(bool delay) => _shouldDelayUpload = delay;
  void setDownloadDelay(bool delay) => _shouldDelayDownload = delay;
  void reset() {
    _storage.clear();
    _nextKey = null;
    _nextException = null;
    _shouldDelayUpload = false;
    _shouldDelayDownload = false;
  }
}

void main() {
  group('StorageCubit with Hastebin', () {
    late MockHastebinStorageService mockService;
    late StorageCubit cubit;

    setUp(() async {
      await initHydratedStorage();
      mockService = MockHastebinStorageService();
      cubit = StorageCubit(hastebinStorageService: mockService);
    });

    tearDown(() {
      cubit.close();
      mockService.reset();
    });

    group('basic functionality', () {
      test('starts with initial state', () {
        expect(cubit.state, equals(StoredItems.initial));
      });

      test('saves items locally', () {
        final items = ['Apple', 'Banana'];

        cubit.saveItems(items);

        expect(cubit.state.items, equals(items));
        expect(cubit.state.hastebinId, isNull);
        expect(cubit.state.error, isNull);
      });

      test('clears hastebinId when items change locally', () {
        // First set up a state with hastebinId
        cubit.emit(cubit.state.copyWith(hastebinId: 'old_id'));

        cubit.saveItems(['New item']);

        expect(cubit.state.hastebinId, isNull);
      });
    });

    group('shareItems', () {
      test('uploads items and returns shareable URL', () async {
        cubit.saveItems(['Apple', 'Banana']);
        mockService.setNextKey('test123');

        final url = await cubit.shareItems();

        expect(url, contains('h=test123'));
        expect(cubit.state.hastebinId, equals('test123'));
        expect(cubit.state.lastSharedUrl, equals(url));
        expect(cubit.state.isUploading, isFalse);
        expect(cubit.state.error, isNull);
      });

      test('sets uploading state during upload', () async {
        cubit.saveItems(['Apple']);
        mockService.setUploadDelay(true);

        final future = cubit.shareItems();

        // Should be uploading immediately
        expect(cubit.state.isUploading, isTrue);

        await future;

        // Should finish uploading
        expect(cubit.state.isUploading, isFalse);
      });

      test('handles upload errors gracefully', () async {
        cubit.saveItems(['Apple']);
        mockService.setNextException(const HastebinException('Upload failed'));

        try {
          await cubit.shareItems();
          fail('Expected HastebinException to be thrown');
        } catch (e) {
          expect(e, isA<HastebinException>());
        }

        // State should reflect the error
        expect(cubit.state.isUploading, isFalse);
        expect(cubit.state.error, contains('Upload failed'));
        expect(cubit.state.hastebinId, isNull);
      });

      test('handles authentication errors', () async {
        cubit.saveItems(['Apple']);
        mockService.setNextException(const HastebinAuthenticationException());

        try {
          await cubit.shareItems();
          fail('Expected HastebinAuthenticationException to be thrown');
        } catch (e) {
          expect(e, isA<HastebinAuthenticationException>());
        }

        expect(cubit.state.error, contains('Authentication failed'));
      });

      test('handles unexpected errors', () async {
        cubit.saveItems(['Apple']);
        mockService.setNextException(Exception('Network error'));

        try {
          await cubit.shareItems();
          fail('Expected Exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        expect(cubit.state.error, contains('Unexpected error'));
      });
    });

    group('loadFromHastebin', () {
      test('loads items from valid Hastebin ID', () async {
        mockService._storage['test123'] = ['Apple', 'Banana'];

        await cubit.loadFromHastebin('test123');

        expect(cubit.state.items, equals(['Apple', 'Banana']));
        expect(cubit.state.hastebinId, equals('test123'));
        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.error, isNull);
      });

      test('sets loading state during download', () async {
        mockService._storage['test123'] = ['Apple'];
        mockService.setDownloadDelay(true);

        final future = cubit.loadFromHastebin('test123');

        // Should be loading immediately
        expect(cubit.state.isLoading, isTrue);

        await future;

        // Should finish loading
        expect(cubit.state.isLoading, isFalse);
      });

      test('handles document not found gracefully', () async {
        await cubit.loadFromHastebin('nonexistent');

        expect(cubit.state.items, isEmpty);
        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.error, contains('not found'));
      });

      test('handles download errors gracefully', () async {
        mockService.setNextException(const HastebinException('Download failed'));

        await cubit.loadFromHastebin('test123');

        expect(cubit.state.items, isEmpty);
        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.error, contains('Download failed'));
      });

      test('handles unexpected download errors', () async {
        mockService.setNextException(Exception('Network timeout'));

        await cubit.loadFromHastebin('test123');

        expect(cubit.state.items, isEmpty);
        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.error, contains('Unexpected error'));
      });
    });

    group('rate limit status', () {
      test('returns rate limit status from service', () {
        final status = cubit.getRateLimitStatus();

        expect(status.currentRequests, equals(0));
        expect(status.maxRequests, equals(100));
        expect(status.waitTime, isNull);
      });
    });

    group('end-to-end flow', () {
      test('share and load round trip preserves data', () async {
        final originalItems = ['Apple', 'Banana', 'Cherry'];
        cubit.saveItems(originalItems);

        await cubit.shareItems();
        final hastebinId = cubit.state.hastebinId!;

        // Create new cubit to simulate loading from URL
        final newCubit = StorageCubit(hastebinStorageService: mockService);
        await newCubit.loadFromHastebin(hastebinId);

        expect(newCubit.state.items, equals(originalItems));
        expect(newCubit.state.hastebinId, equals(hastebinId));

        newCubit.close();
      });

      test('handles empty items list', () async {
        cubit.saveItems([]);

        await cubit.shareItems();
        final hastebinId = cubit.state.hastebinId!;

        final newCubit = StorageCubit(hastebinStorageService: mockService);
        await newCubit.loadFromHastebin(hastebinId);

        expect(newCubit.state.items, isEmpty);

        newCubit.close();
      });

      test('handles large item lists', () async {
        final largeItems = List.generate(100, (i) => 'Item $i with some content');
        cubit.saveItems(largeItems);

        await cubit.shareItems();
        final hastebinId = cubit.state.hastebinId!;

        final newCubit = StorageCubit(hastebinStorageService: mockService);
        await newCubit.loadFromHastebin(hastebinId);

        expect(newCubit.state.items, equals(largeItems));

        newCubit.close();
      });
    });

    group('state management', () {
      test('error is cleared when successful operation occurs', () async {
        // Set an error state
        cubit.emit(cubit.state.copyWith(error: 'Previous error'));

        cubit.saveItems(['Apple']);

        expect(cubit.state.error, isNull);
      });

      test('preserves items when upload fails', () async {
        final items = ['Apple', 'Banana'];
        cubit.saveItems(items);
        mockService.setNextException(const HastebinException('Upload failed'));

        try {
          await cubit.shareItems();
        } catch (e) {
          // Expected to fail
        }

        expect(cubit.state.items, equals(items));
      });

      test('tracks last shared URL', () async {
        cubit.saveItems(['Apple']);

        final url = await cubit.shareItems();

        expect(cubit.state.lastSharedUrl, equals(url));
      });
    });
  });
}
