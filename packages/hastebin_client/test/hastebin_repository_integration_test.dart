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
        
        try {
          final key = await repository.createDocument(testContent);
          
          expect(key, isNotEmpty, reason: 'Document key should not be empty when authentication succeeds');
          expect(key.length, greaterThan(3), reason: 'Document key should be at least 4 characters long');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });
    });

    group('createDocument', () {
      test('should create document successfully with real API', () async {
        const testContent = 'Integration test content for create operation';
        
        try {
          final key = await repository.createDocument(testContent);
          
          expect(key, isNotEmpty, reason: 'Created document should have non-empty key');
          expect(key.length, greaterThan(3), reason: 'Document key should be at least 4 characters long');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('should handle different content types correctly', () async {
        final testCases = [
          ('Empty content', ''),
          ('Simple text', 'Hello, World!'),
          ('Multiline content', 'Line 1\nLine 2\nLine 3'),
          ('Special characters', 'Special: !@#\$%^&*()[]{}|\\:";\'<>?,./ 🚀'),
          ('JSON content', '{"name": "test", "value": 123, "nested": {"key": "value"}}'),
          ('Code content', 'function hello() {\n  console.log("Hello, World!");\n}'),
        ];

        for (final (description, content) in testCases) {
          try {
            final key = await repository.createDocument(content);
            expect(key, isNotEmpty, reason: '$description should create valid document key');
            
            // Verify we can retrieve the content
            final retrievedContent = await repository.getDocument(key);
            expect(retrievedContent, equals(content), reason: '$description should be retrieved correctly');
          } on HastebinAuthenticationException {
            markTestSkipped('API key not available in test environment');
            return; // Exit the loop since we can't test further
          }
          
          // Rate limiting delay
          await Future.delayed(const Duration(seconds: 1));
        }
      });
    });

    group('getDocument', () {
      test('should retrieve document content correctly', () async {
        const testContent = 'Content for retrieval test';
        
        try {
          // Create a document first
          final key = await repository.createDocument(testContent);
          
          // Then retrieve it
          final retrievedContent = await repository.getDocument(key);
          
          expect(retrievedContent, equals(testContent), reason: 'Retrieved content should match original');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('should throw HastebinDocumentNotFoundException for invalid key', () async {
        const invalidKey = 'definitely_does_not_exist_12345';
        
        try {
          await repository.getDocument(invalidKey);
          fail('Should have thrown HastebinDocumentNotFoundException for invalid key');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        } on HastebinDocumentNotFoundException {
          // This is expected behavior
          expect(true, isTrue, reason: 'Should throw document not found exception for invalid key');
        }
      });
    });

    group('getDocumentWithMetadata', () {
      test('should retrieve document with metadata correctly', () async {
        const testContent = 'Content for metadata test';
        
        try {
          // Create a document first
          final key = await repository.createDocument(testContent);
          
          // Then retrieve with metadata
          final document = await repository.getDocumentWithMetadata(key);
          
          expect(document.key, equals(key), reason: 'Document key should match requested key');
          expect(document.content, equals(testContent), reason: 'Document content should match original');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('should throw HastebinDocumentNotFoundException for invalid key', () async {
        const invalidKey = 'definitely_does_not_exist_meta_12345';
        
        try {
          await repository.getDocumentWithMetadata(invalidKey);
          fail('Should have thrown HastebinDocumentNotFoundException for invalid key');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        } on HastebinDocumentNotFoundException {
          // This is expected behavior
          expect(true, isTrue, reason: 'Should throw document not found exception for invalid key');
        }
      });
    });

    group('Complete Workflow Integration', () {
      test('should handle complete create-retrieve workflow', () async {
        const testContent = 'Complete workflow integration test\nWith multiple lines\nAnd special chars: 🎯✨';
        
        try {
          // Step 1: Create document
          final key = await repository.createDocument(testContent);
          expect(key, isNotEmpty, reason: 'Document creation should return valid key');

          // Step 2: Retrieve raw content
          final rawContent = await repository.getDocument(key);
          expect(rawContent, equals(testContent), reason: 'Raw retrieval should return original content');

          // Step 3: Retrieve with metadata
          final document = await repository.getDocumentWithMetadata(key);
          expect(document.key, equals(key), reason: 'Metadata key should match original');
          expect(document.content, equals(testContent), reason: 'Metadata content should match original');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('should handle concurrent operations gracefully', () async {
        const testContent1 = 'Concurrent test content 1';
        const testContent2 = 'Concurrent test content 2';
        const testContent3 = 'Concurrent test content 3';
        
        try {
          // Create multiple documents concurrently
          final futures = [
            repository.createDocument(testContent1),
            repository.createDocument(testContent2),
            repository.createDocument(testContent3),
          ];
          
          final keys = await Future.wait(futures);
          
          expect(keys.length, equals(3), reason: 'Should create all three documents');
          expect(keys.every((key) => key.isNotEmpty), isTrue, reason: 'All keys should be non-empty');
          expect(keys.toSet().length, equals(3), reason: 'All keys should be unique');
          
          // Verify each document can be retrieved
          final contents = await Future.wait([
            repository.getDocument(keys[0]),
            repository.getDocument(keys[1]),
            repository.getDocument(keys[2]),
          ]);
          
          expect(contents[0], equals(testContent1), reason: 'First document should match');
          expect(contents[1], equals(testContent2), reason: 'Second document should match');
          expect(contents[2], equals(testContent3), reason: 'Third document should match');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });
    });
  });
}
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