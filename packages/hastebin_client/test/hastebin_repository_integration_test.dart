import 'package:test/test.dart';
import 'package:hastebin_client/src/hastebin_models.dart';
import 'package:hastebin_client/src/hastebin_repository_impl.dart' as impl;

void main() {
  group('HastebinRepository Integration Tests (Real API)', () {
    late impl.HastebinRepository repository;

    setUp(() {
      repository = const impl.HastebinRepository();
    });

    tearDown(() async {
      // Wait 1 second between tests to respect API rate limit (100 requests/minute)
      await Future.delayed(const Duration(seconds: 1));
    });

    group('API Authentication and Connectivity', () {
      test('API authentication should work correctly', () async {
        const testContent = 'Integration test - API auth verification';
        
        final result = await repository.createDocument(testContent);
        
        result.when(
          success: (key) {
            expect(key, isNotEmpty, reason: 'Document key should not be empty when authentication succeeds');
            expect(key.length, greaterThan(3), reason: 'Document key should be at least 4 characters long');
          },
          failure: (error) => fail('API authentication should work with provided API key: $error'),
        );
      });
    });

    group('createDocument', () {
      test('should create document successfully with real API', () async {
        const testContent = 'Integration test content for create operation';
        
        final result = await repository.createDocument(testContent);
        
        result.when(
          success: (key) {
            expect(key, isNotEmpty, reason: 'Created document should have non-empty key');
            expect(key.length, greaterThan(3), reason: 'Document key should be at least 4 characters long');
          },
          failure: (error) => fail('Document creation should succeed with valid API key: $error'),
        );
      });

      test('should handle different content types correctly', () async {
        final testCases = [
          'Simple text content',
          'Content with\nnewlines\nand\ntabs\t\there',
          'Special chars: !@#\$%^&*()_+-=[]{}|;:"\',.<>?',
          '{"json": "content", "with": ["arrays", "and", "objects"]}',
          '<html><body>HTML content</body></html>',
        ];

        for (int i = 0; i < testCases.length; i++) {
          final content = testCases[i];
          final result = await repository.createDocument(content);
          
          result.when(
            success: (key) => expect(key, isNotEmpty, reason: 'Content type ${i + 1} should create valid document'),
            failure: (error) => fail('Content type ${i + 1} creation should succeed: $error'),
          );
        }
      });
    });

    group('getDocument', () {
      test('should retrieve existing document content', () async {
        // First create a document to retrieve
        const testContent = 'Test content for retrieval verification';
        
        final createResult = await repository.createDocument(testContent);
        late String testKey;
        
        createResult.when(
          success: (key) => testKey = key,
          failure: (error) => fail('Failed to create document for retrieval test: $error'),
        );
        
        // Now retrieve it
        final result = await repository.getDocument(testKey);
        
        result.when(
          success: (content) => expect(content, equals(testContent), reason: 'Retrieved content should match original'),
          failure: (error) => fail('Document retrieval should succeed for existing document: $error'),
        );
      });

      test('should handle various key formats when they exist', () async {
        // Create documents with different content to get various key formats
        final testContents = [
          'Content for key format test 1',
          'Content for key format test 2',
          'Content for key format test 3',
        ];

        final createdKeys = <String>[];
        
        // Create the documents first
        for (int i = 0; i < testContents.length; i++) {
          final result = await repository.createDocument(testContents[i]);
          result.when(
            success: (key) => createdKeys.add(key),
            failure: (error) => fail('Failed to create test document $i: $error'),
          );
        }

        // Now test retrieval
        for (int i = 0; i < createdKeys.length; i++) {
          final key = createdKeys[i];
          final expectedContent = testContents[i];
          
          final result = await repository.getDocument(key);
          
          result.when(
            success: (content) => expect(content, equals(expectedContent), reason: 'Content should match for key $key'),
            failure: (error) => fail('Retrieval should succeed for created key $key: $error'),
          );
        }
      });
    });

    group('getDocumentWithMetadata', () {
      test('should retrieve document with metadata for existing documents', () async {
        const testContent = 'Test content for metadata retrieval';
        
        // First create a document
        final createResult = await repository.createDocument(testContent);
        late String testKey;
        
        createResult.when(
          success: (key) => testKey = key,
          failure: (error) => fail('Failed to create document for metadata test: $error'),
        );
        
        // Now retrieve with metadata
        final result = await repository.getDocumentWithMetadata(testKey);
        
        result.when(
          success: (document) {
            expect(document.key, equals(testKey), reason: 'Document key should match requested key');
            expect(document.content, equals(testContent), reason: 'Document content should match original');
          },
          failure: (error) => fail('Metadata retrieval should succeed for existing document: $error'),
        );
      });
    });

    group('Complete workflow test', () {
      test('full create-retrieve-metadata workflow should work end-to-end', () async {
        const testContent = 'Complete workflow test - create, retrieve, metadata';
        
        // Step 1: Create document
        final createResult = await repository.createDocument(testContent);
        late String documentKey;
        
        createResult.when(
          success: (key) => documentKey = key,
          failure: (error) => fail('Document creation failed in workflow: $error'),
        );

        // Step 2: Retrieve raw content
        final getRawResult = await repository.getDocument(documentKey);
        
        getRawResult.when(
          success: (rawContent) => expect(rawContent, equals(testContent), reason: 'Raw content should match original in workflow'),
          failure: (error) => fail('Raw content retrieval failed in workflow: $error'),
        );

        // Step 3: Retrieve with metadata
        final getMetadataResult = await repository.getDocumentWithMetadata(documentKey);
        
        getMetadataResult.when(
          success: (document) {
            expect(document.key, equals(documentKey), reason: 'Metadata document key should match in workflow');
            expect(document.content, equals(testContent), reason: 'Metadata document content should match original in workflow');
          },
          failure: (error) => fail('Metadata retrieval failed in workflow: $error'),
        );
      });
    });

    group('Error handling tests', () {
      test('should handle non-existent documents correctly', () async {
        // Test various edge cases
        const nonExistentKey = 'definitely_does_not_exist_12345';
        
        final result = await repository.getDocument(nonExistentKey);
        
        result.when(
          success: (content) => fail('Non-existent document should not return content: $content'),
          failure: (error) => expect(error, isNotEmpty, reason: 'Non-existent document should return proper error message'),
        );
      });

      test('should handle network conditions gracefully', () async {
        const testContent = 'Network resilience test content';
        
        final result = await repository.createDocument(testContent);
        
        result.when(
          success: (key) {
            expect(key, isA<String>(), reason: 'Result should be a string when successful');
            expect(key, isNotEmpty, reason: 'Document key should not be empty when successful');
          },
          failure: (error) => fail('Network operations should succeed with valid credentials: $error'),
        );
      });
    });
  });
}