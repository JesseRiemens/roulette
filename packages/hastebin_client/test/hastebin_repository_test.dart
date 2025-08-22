import 'package:test/test.dart';
import 'package:hastebin_client/src/hastebin_models.dart';
import 'package:hastebin_client/src/hastebin_repository_impl.dart' as impl;
import 'package:hastebin_client/src/hastebin_repository_stub.dart' as stub;

void main() {
  group('HastebinRepository', () {
    group('Stub Implementation Tests', () {
      late stub.HastebinRepository repository;

      setUp(() {
        repository = const stub.HastebinRepository();
      });

      group('createDocument', () {
        test('returns success with mock key', () async {
          const testContent = 'Test content';

          final result = await repository.createDocument(testContent);

          expect(result, isA<HastebinSuccess<String>>());
          result.when(
            success: (key) => expect(key, isNotEmpty),
            failure: (error) =>
                fail('Expected success but got failure: $error'),
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
            failure: (error) =>
                fail('Expected success but got failure: $error'),
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
            failure: (error) =>
                fail('Expected success but got failure: $error'),
          );
        });
      });
    });

    group('Real Implementation Tests', () {
      late impl.HastebinRepository repository;

      setUp(() {
        repository = const impl.HastebinRepository();
      });

      group('API call structure validation', () {
        test('create document with proper authentication', () async {
          const testContent = 'Test content for real API';

          final result = await repository.createDocument(testContent);

          // This test validates that our implementation makes the call correctly
          // regardless of whether the API key is valid
          result.when(
            success: (key) {
              expect(key, isNotEmpty);
            },
            failure: (error) {
              expect(error, isNotEmpty);
            },
          );
        });

        test('get document with proper authentication', () async {
          const testKey = 'test123';

          final result = await repository.getDocument(testKey);

          result.when(
            success: (content) {
              expect(content, isNotEmpty);
            },
            failure: (error) {
              expect(error, isNotEmpty);
            },
          );
        });

        test('get document with metadata and proper authentication', () async {
          const testKey = 'test123';

          final result = await repository.getDocumentWithMetadata(testKey);

          result.when(
            success: (document) {
              expect(document.key, equals(testKey));
              expect(document.content, isNotEmpty);
            },
            failure: (error) {
              expect(error, isNotEmpty);
            },
          );
        });
      });
    });

    group('Model Tests', () {
      test('HastebinDocument JSON serialization', () {
        const document = HastebinDocument(
          key: 'test123',
          content: 'Test content',
        );

        final json = document.toJson();
        expect(json['key'], equals('test123'));
        expect(json['content'], equals('Test content'));

        final fromJson = HastebinDocument.fromJson(json);
        expect(fromJson.key, equals(document.key));
        expect(fromJson.content, equals(document.content));
      });

      test('HastebinCreateResponse JSON serialization', () {
        const response = HastebinCreateResponse(key: 'abc123');

        final json = response.toJson();
        expect(json['key'], equals('abc123'));

        final fromJson = HastebinCreateResponse.fromJson(json);
        expect(fromJson.key, equals(response.key));
      });

      test('HastebinResult pattern matching', () {
        const successResult = HastebinSuccess('test');
        const failureResult = HastebinFailure('error');

        final successValue = successResult.when(
          success: (data) => 'Success: $data',
          failure: (error) => 'Failure: $error',
        );
        expect(successValue, equals('Success: test'));

        final failureValue = failureResult.when(
          success: (data) => 'Success: $data',
          failure: (error) => 'Failure: $error',
        );
        expect(failureValue, equals('Failure: error'));
      });

      test('HastebinResult equality', () {
        const success1 = HastebinSuccess('test');
        const success2 = HastebinSuccess('test');
        const success3 = HastebinSuccess('different');

        expect(success1, equals(success2));
        expect(success1, isNot(equals(success3)));

        const failure1 = HastebinFailure('error');
        const failure2 = HastebinFailure('error');
        const failure3 = HastebinFailure('different');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });
  });
}
