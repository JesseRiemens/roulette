import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/data/hastebin_models.dart';
import 'package:webroulette/data/hastebin_repository_stub.dart';

void main() {
  group('HastebinRepository', () {
    late HastebinRepository repository;

    setUp(() {
      repository = const HastebinRepository();
    });

    group('createDocument', () {
      test('returns success with mock key', () async {
        const testContent = 'Test content';
        
        final result = await repository.createDocument(testContent);
        
        expect(result, isA<HastebinSuccess<String>>());
        result.when(
          success: (key) => expect(key, isNotEmpty),
          failure: (error) => fail('Expected success but got failure: $error'),
        );
      });
    });

    group('getDocument', () {
      test('returns success with mock content', () async {
        const testKey = 'abc123';
        
        final result = await repository.getDocument(testKey);
        
        expect(result, isA<HastebinSuccess<String>>());
        result.when(
          success: (content) => expect(content, contains(testKey)),
          failure: (error) => fail('Expected success but got failure: $error'),
        );
      });
    });

    group('getDocumentWithMetadata', () {
      test('returns success with mock document', () async {
        const testKey = 'abc123';
        
        final result = await repository.getDocumentWithMetadata(testKey);
        
        expect(result, isA<HastebinSuccess<HastebinDocument>>());
        result.when(
          success: (document) {
            expect(document.key, testKey);
            expect(document.content, contains(testKey));
          },
          failure: (error) => fail('Expected success but got failure: $error'),
        );
      });
    });
  });
}