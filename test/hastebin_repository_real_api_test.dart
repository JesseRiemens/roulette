import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/data/hastebin_models.dart';
import 'package:webroulette/data/hastebin_repository_impl.dart' as impl;

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

    group('API Integration Analysis', () {
      test('create document should succeed with authentication', () async {
        const testContent = 'Real API test content - Authentication check';
        
        final result = await repository.createDocument(testContent);
        
        result.when(
          success: (key) {
            expect(key, isNotEmpty, reason: 'Document key should not be empty');
            expect(key.length, greaterThan(2), reason: 'Document key should be at least 3 characters long');
            expect(key, matches(RegExp(r'^[a-zA-Z0-9]+$')), reason: 'Document key should only contain alphanumeric characters');
          },
          failure: (error) => fail('Expected document creation to succeed but got failure: $error'),
        );
      });

      test('retrieve existing document should return content', () async {
        // First create a document to retrieve
        const testContent = 'Test content for retrieval';
        
        final createResult = await repository.createDocument(testContent);
        late String testKey;
        
        createResult.when(
          success: (key) => testKey = key,
          failure: (error) => fail('Failed to create document for retrieval test: $error'),
        );
        
        // Now retrieve it
        final result = await repository.getDocument(testKey);
        
        result.when(
          success: (content) => expect(content, equals(testContent), reason: 'Retrieved content should match original content'),
          failure: (error) => fail('Expected document retrieval to succeed but got failure: $error'),
        );
      });

      test('retrieve document with metadata should return structured data', () async {
        // First create a document to retrieve
        const testContent = 'Test content for metadata retrieval';
        
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
            expect(document.key, equals(testKey), reason: 'Document key should match the requested key');
            expect(document.content, equals(testContent), reason: 'Document content should match original content');
          },
          failure: (error) => fail('Expected metadata retrieval to succeed but got failure: $error'),
        );
      });

      test('comprehensive workflow should work end-to-end', () async {
        const testContent = 'Comprehensive test content\nWith multiple lines\nAnd special chars: !@#\$%^&*()';
        
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
          success: (rawContent) => expect(rawContent, equals(testContent), reason: 'Raw content should match original'),
          failure: (error) => fail('Raw content retrieval failed in workflow: $error'),
        );

        // Step 3: Retrieve with metadata
        final getMetadataResult = await repository.getDocumentWithMetadata(documentKey);
        
        getMetadataResult.when(
          success: (document) {
            expect(document.key, equals(documentKey), reason: 'Metadata document key should match');
            expect(document.content, equals(testContent), reason: 'Metadata document content should match original');
          },
          failure: (error) => fail('Metadata retrieval failed in workflow: $error'),
        );
      });

      test('handle edge cases properly', () async {
        // Test empty content
        final emptyResult = await repository.createDocument('');
        emptyResult.when(
          success: (key) => expect(key, isNotEmpty, reason: 'Empty content should still generate a valid key'),
          failure: (error) => fail('Empty content creation should not fail: $error'),
        );
        
        // Test special characters
        const specialContent = 'Special chars: 🚀 💻 🔥\n\t"quotes"\n\'single quotes\'\n\\backslashes\\';
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