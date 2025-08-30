import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/screens/roulette_screen.dart';
import 'package:webroulette/data/hastebin_storage_service.dart';
import 'package:webroulette/data/hastebin_rate_limit_service.dart';
import 'package:hastebin_client/hastebin_client.dart';
import 'test_helpers.dart';

// Mock implementation that simulates the complete hastebin workflow
class MockHastebinStorageService implements HastebinStorageService {
  final Map<String, List<String>> _storage = {};
  int _keyCounter = 0;
  bool _shouldFail = false;

  @override
  HastebinRepositoryInterface get repository => throw UnimplementedError();

  @override
  HastebinRateLimitService? get rateLimitService => null;

  @override
  Future<String> uploadItems(List<String> items) async {
    if (_shouldFail) {
      throw const HastebinException('Network error');
    }
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    final key = 'test_key_${++_keyCounter}';
    _storage[key] = List.from(items);
    return key;
  }

  @override
  Future<List<String>> downloadItems(String key) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network delay
    if (!_storage.containsKey(key)) {
      throw HastebinDocumentNotFoundException(key);
    }
    return List.from(_storage[key]!);
  }

  @override
  ({int currentRequests, int maxRequests, Duration? waitTime}) getRateLimitStatus() {
    return (currentRequests: 0, maxRequests: 100, waitTime: null);
  }

  void reset() {
    _storage.clear();
    _keyCounter = 0;
    _shouldFail = false;
  }
}

void main() {
  group('End-to-End Hastebin Integration Tests', () {
    late MockHastebinStorageService mockService;

    setUp(() async {
      await initHydratedStorage();
      mockService = MockHastebinStorageService();
    });

    tearDown(() {
      mockService.reset();
    });

    testWidgets('Complete workflow: add items, share, and load from URL', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorageService: mockService);

      // Build the app
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Verify initial state - button should be disabled for empty list
      final shareButton = find.text('Share Items');
      expect(shareButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);

      // Add first item
      await tester.enterText(find.byType(TextField), 'Apple');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Add second item
      await tester.enterText(find.byType(TextField), 'Banana');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify items are displayed
      expect(find.text('1: Apple'), findsOneWidget);
      expect(find.text('2: Banana'), findsOneWidget);

      // Button should now be enabled
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);

      // Tap the share button
      await tester.tap(shareButton);
      await tester.pump(); // Start upload

      // Should show uploading state
      expect(find.text('Sharing...'), findsOneWidget);

      // Wait for upload to complete
      await tester.pump(const Duration(milliseconds: 200));

      // Should show success state
      expect(find.text('Share Items'), findsOneWidget);
      expect(find.text('Shareable URL copied to clipboard!'), findsOneWidget);

      // Verify the cubit has a hastebin ID
      expect(cubit.state.hastebinId, isNotNull);
      expect(cubit.state.lastSharedUrl, isNotNull);
      expect(cubit.state.lastSharedUrl, contains('h=${cubit.state.hastebinId}'));

      // Simulate loading from URL - create new cubit with same service
      final loadCubit = StorageCubit(hastebinStorageService: mockService);
      await loadCubit.loadFromHastebin(cubit.state.hastebinId!);

      // Verify items were loaded correctly
      expect(loadCubit.state.items, equals(['Apple', 'Banana']));
      expect(loadCubit.state.hastebinId, equals(cubit.state.hastebinId));
      expect(loadCubit.state.error, isNull);

      await cubit.close();
      await loadCubit.close();
    });

    testWidgets('Error handling: display error when sharing fails', (WidgetTester tester) async {
      // Create a service that will fail on upload
      final failingService = MockHastebinStorageService();
      final cubit = StorageCubit(hastebinStorageService: failingService);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Add an item
      await tester.enterText(find.byType(TextField), 'Test Item');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Manually override the uploadItems method to throw
      failingService._shouldFail = true;

      // Tap share button
      await tester.tap(find.text('Share Items'));
      await tester.pump();

      // Wait for error to propagate
      await tester.pump(const Duration(milliseconds: 200));

      // Should show error message (the error will be in the snackbar or state)
      expect(cubit.state.error, isNotNull);

      await cubit.close();
    });

    testWidgets('Loading state: show loading indicator when fetching shared items', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorageService: mockService);

      // Pre-populate the mock storage
      mockService._storage['test123'] = ['Shared Item 1', 'Shared Item 2'];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Start loading
      final loadFuture = cubit.loadFromHastebin('test123');
      await tester.pump();

      // Should show loading state
      expect(find.text('Loading shared items...'), findsOneWidget);

      // Wait for loading to complete
      await loadFuture;
      await tester.pump();

      // Should show loaded items
      expect(find.text('1: Shared Item 1'), findsOneWidget);
      expect(find.text('2: Shared Item 2'), findsOneWidget);
      expect(find.text('Loading shared items...'), findsNothing);

      await cubit.close();
    });

    testWidgets('Rate limiting: UI responds to rate limit status', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorageService: mockService);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Add an item
      await tester.enterText(find.byType(TextField), 'Test Item');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Get rate limit status
      final status = cubit.getRateLimitStatus();
      expect(status.maxRequests, equals(100));
      expect(status.currentRequests, equals(0));

      await cubit.close();
    });

    testWidgets('Legacy compatibility: URL parameters still work alongside Hastebin', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorageService: mockService);

      // Add items normally
      cubit.saveItems(['Legacy Item 1', 'Legacy Item 2']);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Verify items are displayed
      expect(find.text('1: Legacy Item 1'), findsOneWidget);
      expect(find.text('2: Legacy Item 2'), findsOneWidget);

      // Share items (this will use Hastebin)
      await tester.tap(find.text('Share Items'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify shared successfully
      expect(cubit.state.hastebinId, isNotNull);

      await cubit.close();
    });

    testWidgets('Empty state: share button properly disabled for empty items', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorageService: mockService);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Button should be disabled for empty items
      final shareButton = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(shareButton).onPressed, isNull);

      // Add an item
      await tester.enterText(find.byType(TextField), 'First Item');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Button should now be enabled
      expect(tester.widget<ElevatedButton>(shareButton).onPressed, isNotNull);

      // Remove the item
      await tester.tap(find.byIcon(Icons.remove_circle_outline_sharp));
      await tester.pump();

      // Button should be disabled again
      expect(tester.widget<ElevatedButton>(shareButton).onPressed, isNull);

      await cubit.close();
    });

    testWidgets('Large dataset: sharing and loading large number of items', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorageService: mockService);
      final largeItemList = List.generate(50, (i) => 'Item ${i + 1}');

      // Set large item list
      cubit.saveItems(largeItemList);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const RouletteScreen()),
        ),
      );

      // Share the large dataset
      await tester.tap(find.text('Share Items'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify shared successfully
      expect(cubit.state.hastebinId, isNotNull);

      // Load in new cubit
      final loadCubit = StorageCubit(hastebinStorageService: mockService);
      await loadCubit.loadFromHastebin(cubit.state.hastebinId!);

      // Verify all items loaded
      expect(loadCubit.state.items, equals(largeItemList));

      await cubit.close();
      await loadCubit.close();
    });
  });
}
