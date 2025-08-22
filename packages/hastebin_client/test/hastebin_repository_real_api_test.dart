import 'package:test/test.dart';
import 'package:hastebin_client/src/hastebin_models.dart';
import 'package:hastebin_client/src/hastebin_repository_impl.dart' as impl;

void main() {
  group('HastebinRepository Real API Tests', () {
    late impl.HastebinRepository repository;

    setUp(() {
      repository = const impl.HastebinRepository();
    });

    tearDown(() async {
      // Wait 1 second between tests to respect API rate limit (100 requests/minute)
      await Future.delayed(const Duration(seconds: 1));
    });

    group('API Integration Tests with Valid API Key', () {
      test('create document should succeed with authentication', () async {
        const testContent = 'Real API test content - Authentication check';
        
        try {
          final key = await repository.createDocument(testContent);
          
          expect(key, isNotEmpty, reason: 'Document key should not be empty');
          expect(key.length, greaterThan(2), reason: 'Document key should be at least 3 characters long');
          expect(key, matches(RegExp(r'^[a-zA-Z0-9]+$')), reason: 'Document key should only contain alphanumeric characters');
        } on HastebinAuthenticationException {
          // This is expected when API key is not provided via environment
          // In CI/CD or with valid API key, this test would pass
          markTestSkipped('API key not available in test environment');
        }
      });

      test('retrieve existing document should return content', () async {
        const testContent = 'Test content for retrieval';
        
        try {
          // First create a document to retrieve
          final testKey = await repository.createDocument(testContent);
          
          // Now retrieve it
          final content = await repository.getDocument(testKey);
          
          expect(content, equals(testContent), reason: 'Retrieved content should match original content');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('retrieve document with metadata should return structured data', () async {
        const testContent = 'Test content for metadata retrieval';
        
        try {
          // First create a document to retrieve
          final testKey = await repository.createDocument(testContent);
          
          // Now retrieve with metadata
          final document = await repository.getDocumentWithMetadata(testKey);
          
          expect(document.key, equals(testKey), reason: 'Document key should match the requested key');
          expect(document.content, equals(testContent), reason: 'Document content should match original content');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('comprehensive workflow should work end-to-end', () async {
        const testContent = 'Comprehensive test content\nWith multiple lines\nAnd special chars: !@#\$%^&*()';
        
        try {
          // Step 1: Create document
          final documentKey = await repository.createDocument(testContent);

          // Step 2: Retrieve raw content
          final rawContent = await repository.getDocument(documentKey);
          expect(rawContent, equals(testContent), reason: 'Raw content should match original');

          // Step 3: Retrieve with metadata
          final document = await repository.getDocumentWithMetadata(documentKey);
          expect(document.key, equals(documentKey), reason: 'Metadata document key should match');
          expect(document.content, equals(testContent), reason: 'Metadata document content should match original');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });

      test('handle edge cases properly', () async {
        try {
          // Test empty content
          final emptyKey = await repository.createDocument('');
          expect(emptyKey, isNotEmpty, reason: 'Empty content should still generate a valid key');
          
          // Test special characters
          const specialContent = 'Special chars: 🚀 💻 🔥\n\t"quotes"\n\'single quotes\'\n\\backslashes\\';
          final specialKey = await repository.createDocument(specialContent);
          expect(specialKey, isNotEmpty, reason: 'Special content should generate a valid key');
          
          // Retrieve and verify special content
          final retrievedSpecial = await repository.getDocument(specialKey);
          expect(retrievedSpecial, equals(specialContent), reason: 'Special characters should be preserved');
        } on HastebinAuthenticationException {
          markTestSkipped('API key not available in test environment');
        }
      });
    });

    group('Error Handling Tests', () {
      test('should throw HastebinAuthenticationException when API key is missing', () async {
        // This test verifies that missing API key throws the right exception
        expect(
          () => repository.createDocument('test'),
          throwsA(isA<HastebinAuthenticationException>()),
          reason: 'Should throw authentication exception when API key is missing',
        );
      });

      test('should throw HastebinDocumentNotFoundException for invalid key', () async {
        const invalidKey = 'definitely_invalid_key_12345';
        
        try {
          await repository.getDocument(invalidKey);
          fail('Should have thrown HastebinDocumentNotFoundException');
        } on HastebinAuthenticationException {
          // If we get auth exception, it means we're testing without API key
          // which is fine, we just can't test the 404 case
          markTestSkipped('Cannot test 404 without valid API key');
        } on HastebinDocumentNotFoundException {
          // This is what we expect with a valid API key and invalid document
          expect(true, isTrue, reason: 'Should throw document not found exception');
        }
      });
    });
  });
}
        final specialResult = await repository.createDocument(specialContent);
        specialResult.when(
          success: (key) => expect(key, isNotEmpty, reason: 'Special characters should be handled properly'),
          failure: (error) => fail('Special character content creation should not fail: $error'),
        );
        
        // Test non-existent key retrieval should fail
        final nonExistentResult = await repository.getDocument('definitely_does_not_exist_12345');
        nonExistentResult.when(
          success: (content) => fail('Non-existent key should not return content: $content'),
          failure: (error) => expect(error, isNotEmpty, reason: 'Non-existent key should return proper error message'),
        );
      });
    });

    group('Performance and Reliability', () {
      test('API response times should be reasonable', () async {
        const testContent = 'Performance test content';
        
        final stopwatch = Stopwatch()..start();
        final result = await repository.createDocument(testContent);
        stopwatch.stop();
        
        final createTime = stopwatch.elapsedMilliseconds;
        expect(createTime, lessThan(30000), reason: 'Create operation should complete within 30 seconds');
        
        result.when(
          success: (key) async {
            // Test retrieval speed
            final retrievalStopwatch = Stopwatch()..start();
            final getResult = await repository.getDocument(key);
            retrievalStopwatch.stop();
            
            final retrievalTime = retrievalStopwatch.elapsedMilliseconds;
            expect(retrievalTime, lessThan(30000), reason: 'Retrieval operation should complete within 30 seconds');
            
            getResult.when(
              success: (content) => expect(content, isNotEmpty, reason: 'Retrieved content should not be empty'),
              failure: (error) => fail('Content retrieval should succeed in performance test: $error'),
            );
          },
          failure: (error) => fail('Document creation should succeed in performance test: $error'),
        );
      });

      test('concurrent operations should handle rate limiting', () async {
        final futures = List.generate(3, (index) => 
          repository.createDocument('Concurrent test content $index')
        );
        
        final results = await Future.wait(futures);
        
        // At least some operations should succeed
        int successCount = 0;
        for (int i = 0; i < results.length; i++) {
          results[i].when(
            success: (key) {
              successCount++;
              expect(key, isNotEmpty, reason: 'Concurrent operation $i should produce valid key');
            },
            failure: (error) {
              // Rate limiting failures are acceptable but should have meaningful error messages
              expect(error, isNotEmpty, reason: 'Concurrent operation $i failure should have error message');
            },
          );
        }
        
        expect(successCount, greaterThan(0), reason: 'At least one concurrent operation should succeed');
      });
    });
  });
}