import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/data/hastebin_storage.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';

import 'test_helpers.dart';

// Mock HTTP client for end-to-end testing
class EndToEndMockHttpClient extends http.BaseClient {
  final Map<String, String> hastebinData = {};
  int uploadCounter = 0;
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith('/documents')) {
      // Upload request
      uploadCounter++;
      final id = 'e2e_test_$uploadCounter';
      
      // Get body from Request type
      if (request is http.Request) {
        hastebinData[id] = request.body;
      } else {
        hastebinData[id] = 'unknown body type';
      }
      
      final responseBody = '{"key": "$id"}';
      return http.StreamedResponse(
        Stream.value(responseBody.codeUnits),
        200,
        request: request,
      );
    } else {
      // Download request - extract ID from path
      final pathParts = request.url.path.split('/');
      final id = pathParts.last;
      final data = hastebinData[id];
      
      if (data == null) {
        return http.StreamedResponse(
          Stream.value([]),
          404,
          request: request,
        );
      }
      
      return http.StreamedResponse(
        Stream.value(data.codeUnits),
        200,
        request: request,
      );
    }
  }
}

void main() {
  group('End-to-End Hastebin Workflow', () {
    late EndToEndMockHttpClient mockClient;
    late HastebinStorage hastebinStorage;
    
    setUpAll(() async {
      await initHydratedStorage();
    });
    
    setUp(() {
      // Create fresh mock client for each test 
      mockClient = EndToEndMockHttpClient();
      hastebinStorage = HastebinStorage(
        baseUrl: 'https://test.hastebin.com',
        client: mockClient,
      );
    });
    
    tearDown(() {
      hastebinStorage.dispose();
    });
    
    testWidgets('complete workflow: add items, copy URL, restore from URL', (WidgetTester tester) async {
      // Step 1: Start with empty roulette - create fresh cubit for this test
      final cubit = StorageCubit(hastebinStorage);
      
      // Ensure clean state
      cubit.emit(const StoredItems(items: []));
      
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            locale: Locale('en'),
            home: RouletteScreen(),
          ),
        ),
      );
      
      // Verify initial empty state
      expect(find.text('Copy URL'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      
      // Step 2: Add items to the roulette programmatically (avoiding UI input issues)
      final testItems = ['Apple', 'Banana', 'Cherry'];
      cubit.saveItems(testItems);
      await tester.pump();
      
      // Step 3: Test Copy URL button functionality
      await tester.tap(find.text('Copy URL'));
      await tester.pump();
      
      // Wait for async operations to complete
      await tester.pump(const Duration(milliseconds: 100));
      
      // Verify upload was triggered
      expect(mockClient.uploadCounter, equals(1));
      expect(mockClient.hastebinData.keys, hasLength(1));
      
      final hastebinId = mockClient.hastebinData.keys.first;
      expect(hastebinId, startsWith('e2e_test_'));
      
      // Verify the uploaded data contains our items
      final uploadedData = mockClient.hastebinData[hastebinId]!;
      expect(uploadedData, contains('Apple'));
      expect(uploadedData, contains('Banana'));
      expect(uploadedData, contains('Cherry'));
      expect(uploadedData, contains('"version":1'));
      
      // Step 4: Test restoration from Hastebin
      final restoredItems = await hastebinStorage.downloadItems(hastebinId);
      expect(restoredItems, equals(testItems));
      
      // Clean up
      await cubit.close();
    });
    
    testWidgets('Copy URL button shows error message when Hastebin fails', (WidgetTester tester) async {
      // Create a failing HTTP client
      final failingClient = FailingHttpClient();
      final failingStorage = HastebinStorage(
        baseUrl: 'https://test.hastebin.com',
        client: failingClient,
      );
      
      final cubit = StorageCubit(failingStorage);
      
      // Ensure clean state
      cubit.emit(const StoredItems(items: []));
      
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            locale: Locale('en'),
            home: RouletteScreen(),
          ),
        ),
      );
      
      // Add an item programmatically
      cubit.saveItems(['Test Item']);
      await tester.pump();
      
      // Try to copy URL (should fail and show fallback)
      await tester.tap(find.text('Copy URL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should show error message in snackbar
      expect(find.textContaining('Hastebin upload failed'), findsOneWidget);
      
      await cubit.close();
      failingStorage.dispose();
    });
    
    testWidgets('handles large amounts of data correctly', (WidgetTester tester) async {
      final cubit = StorageCubit(hastebinStorage);
      
      // Ensure clean state
      cubit.emit(const StoredItems(items: []));
      
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            locale: Locale('en'),
            home: RouletteScreen(),
          ),
        ),
      );
      
      // Add many items programmatically
      final largeItemList = List.generate(20, (index) => 'Item number $index with some extra content');
      cubit.saveItems(largeItemList);
      await tester.pump();
      
      // Verify all items are present
      expect(cubit.state.items, hasLength(20));
      
      // Copy URL with large dataset
      await tester.tap(find.text('Copy URL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Verify upload succeeded
      expect(mockClient.uploadCounter, equals(1));
      
      // Verify all data was preserved
      final hastebinId = mockClient.hastebinData.keys.first;
      final restoredItems = await hastebinStorage.downloadItems(hastebinId);
      expect(restoredItems, hasLength(20));
      expect(restoredItems.first, equals('Item number 0 with some extra content'));
      expect(restoredItems.last, equals('Item number 19 with some extra content'));
      
      await cubit.close();
    });
  });
}

// HTTP client that always fails for testing error scenarios
class FailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value([]),
      500,
      request: request,
    );
  }
}