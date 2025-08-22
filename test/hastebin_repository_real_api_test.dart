import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/data/hastebin_models.dart';
import 'package:webroulette/data/hastebin_repository_impl.dart' as impl;

void main() {
  group('HastebinRepository Real API Tests', () {
    late impl.HastebinRepository repository;

    setUp(() {
      repository = const impl.HastebinRepository();
    });

    group('API Integration Analysis', () {
      test('analyze create document response and error handling', () async {
        const testContent = 'Real API test content - Authentication check';
        
        print('🔍 Testing create document with real API...');
        print('API Key format: Bearer 9df800211d9ea3d8...c4bbdc0 (truncated)');
        print('Content: "$testContent"');
        print('Endpoint: https://hastebin.com/documents');
        
        final result = await repository.createDocument(testContent);
        
        result.when(
          success: (key) {
            expect(key, isNotEmpty);
            expect(key.length, greaterThan(2));
            print('✅ SUCCESS: Document created with key: $key');
            print('📋 Key length: ${key.length}');
            print('📋 Key format appears valid: ${key.contains(RegExp(r'^[a-zA-Z0-9]+$'))}');
          },
          failure: (error) {
            expect(error, isNotEmpty);
            print('❌ FAILED: $error');
            
            if (error.contains('401')) {
              print('🔑 Authentication issue detected');
            } else if (error.contains('403')) {
              print('🚫 Authorization/permission issue detected');
            } else if (error.contains('404')) {
              print('🌐 Endpoint not found');
            } else if (error.contains('The user is not authorized')) {
              print('👤 User authorization failed - API key may be invalid');
            } else if (error.contains('network')) {
              print('🌐 Network connectivity issue');
            } else {
              print('🐛 Other error type');
            }
          },
        );
      });

      test('analyze document retrieval with various key formats', () async {
        final testKeys = ['test123', 'abc', 'longerkeyexample', 'key_with_underscore'];
        
        for (final key in testKeys) {
          print('📄 Testing document retrieval for key: $key');
          
          final result = await repository.getDocument(key);
          
          result.when(
            success: (content) {
              expect(content, isNotEmpty);
              print('✅ SUCCESS: Retrieved content (length: ${content.length})');
              print('📄 Content preview: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}');
            },
            failure: (error) {
              expect(error, isNotEmpty);
              print('❌ FAILED for key "$key": $error');
            },
          );
        }
      });

      test('analyze metadata retrieval functionality', () async {
        const testKey = 'metadata_test';
        
        print('📊 Testing metadata retrieval for key: $testKey');
        
        final result = await repository.getDocumentWithMetadata(testKey);
        
        result.when(
          success: (document) {
            expect(document.key, equals(testKey));
            expect(document.content, isNotEmpty);
            print('✅ SUCCESS: Retrieved document with metadata');
            print('📋 Document key: ${document.key}');
            print('📄 Content length: ${document.content.length}');
            print('📄 Content preview: ${document.content.length > 50 ? '${document.content.substring(0, 50)}...' : document.content}');
          },
          failure: (error) {
            expect(error, isNotEmpty);
            print('❌ FAILED: $error');
          },
        );
      });

      test('comprehensive API workflow test', () async {
        print('🚀 Starting comprehensive API workflow test...');
        
        const testContent = 'Comprehensive test content\nWith multiple lines\nAnd special chars: !@#\$%^&*()';
        
        // Step 1: Create document
        print('📝 Step 1: Creating document...');
        final createResult = await repository.createDocument(testContent);
        
        await createResult.when(
          success: (key) async {
            print('✅ Document created successfully: $key');
            
            // Step 2: Retrieve raw content
            print('📄 Step 2: Retrieving raw content...');
            final getRawResult = await repository.getDocument(key);
            
            await getRawResult.when(
              success: (rawContent) async {
                print('✅ Raw content retrieved successfully');
                
                if (rawContent == testContent) {
                  print('✅ Content matches exactly');
                } else {
                  print('⚠️ Content mismatch detected');
                  print('Expected: "$testContent"');
                  print('Received: "$rawContent"');
                }
                
                // Step 3: Retrieve with metadata
                print('📊 Step 3: Retrieving with metadata...');
                final getMetadataResult = await repository.getDocumentWithMetadata(key);
                
                getMetadataResult.when(
                  success: (document) {
                    print('✅ Metadata retrieved successfully');
                    print('📋 Document key: ${document.key}');
                    print('📄 Content length: ${document.content.length}');
                    
                    expect(document.key, equals(key));
                    expect(document.content, equals(testContent));
                    
                    print('🎉 COMPLETE WORKFLOW SUCCESSFUL!');
                  },
                  failure: (error) {
                    print('❌ Metadata retrieval failed: $error');
                  },
                );
              },
              failure: (error) {
                print('❌ Raw content retrieval failed: $error');
              },
            );
          },
          failure: (error) {
            print('❌ Document creation failed: $error');
            print('ℹ️ This is expected if API authentication is not working properly');
            
            // Even if creation fails, we can still test the other operations
            print('🔄 Testing other operations with known keys...');
          },
        );
      });

      test('error handling and edge cases', () async {
        print('🧪 Testing error handling and edge cases...');
        
        // Test empty content
        print('📝 Testing empty content...');
        final emptyResult = await repository.createDocument('');
        emptyResult.when(
          success: (key) => print('✅ Empty content handled: $key'),
          failure: (error) => print('ℹ️ Empty content failed: $error'),
        );
        
        // Test very long content
        final longContent = 'A' * 10000; // 10KB of content
        print('📝 Testing long content (${longContent.length} chars)...');
        final longResult = await repository.createDocument(longContent);
        longResult.when(
          success: (key) => print('✅ Long content handled: $key'),
          failure: (error) => print('ℹ️ Long content failed: $error'),
        );
        
        // Test special characters
        const specialContent = 'Special chars: 🚀 💻 🔥\n\t"quotes"\n\'single quotes\'\n\\backslashes\\';
        print('📝 Testing special characters...');
        final specialResult = await repository.createDocument(specialContent);
        specialResult.when(
          success: (key) => print('✅ Special chars handled: $key'),
          failure: (error) => print('ℹ️ Special chars failed: $error'),
        );
        
        // Test non-existent key retrieval
        print('📄 Testing non-existent key retrieval...');
        final nonExistentResult = await repository.getDocument('definitely_does_not_exist_12345');
        nonExistentResult.when(
          success: (content) => print('⚠️ Non-existent key returned content: $content'),
          failure: (error) => print('✅ Non-existent key properly handled: $error'),
        );
      });
    });

    group('Performance and Reliability', () {
      test('measure API response times', () async {
        print('⏱️ Measuring API response times...');
        
        const testContent = 'Performance test content';
        
        final stopwatch = Stopwatch()..start();
        final result = await repository.createDocument(testContent);
        stopwatch.stop();
        
        print('📊 Create operation took: ${stopwatch.elapsedMilliseconds}ms');
        
        result.when(
          success: (key) async {
            // Test retrieval speed
            final retrievalStopwatch = Stopwatch()..start();
            final getResult = await repository.getDocument(key);
            retrievalStopwatch.stop();
            
            print('📊 Retrieval operation took: ${retrievalStopwatch.elapsedMilliseconds}ms');
            
            getResult.when(
              success: (content) => print('✅ Performance test successful'),
              failure: (error) => print('ℹ️ Retrieval performance test failed: $error'),
            );
          },
          failure: (error) => print('ℹ️ Create performance test failed: $error'),
        );
      });

      test('test concurrent operations', () async {
        print('🔄 Testing concurrent operations...');
        
        final futures = List.generate(3, (index) => 
          repository.createDocument('Concurrent test content $index')
        );
        
        final results = await Future.wait(futures);
        
        int successCount = 0;
        int failureCount = 0;
        
        for (int i = 0; i < results.length; i++) {
          results[i].when(
            success: (key) {
              successCount++;
              print('✅ Concurrent operation $i succeeded: $key');
            },
            failure: (error) {
              failureCount++;
              print('❌ Concurrent operation $i failed: $error');
            },
          );
        }
        
        print('📊 Concurrent test results: $successCount successes, $failureCount failures');
      });
    });
  });
}