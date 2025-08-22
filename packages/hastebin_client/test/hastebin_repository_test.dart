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
        test('returns key for valid content', () async {
          const testContent = 'Test content';

          final key = await repository.createDocument(testContent);

          expect(key, isNotEmpty);
          expect(key, isA<String>());
        });
      });

      group('getDocument', () {
        test('returns content for valid key', () async {
          const testKey = 'abc123';

          final content = await repository.getDocument(testKey);

          expect(content, isNotEmpty);
          expect(content, contains(testKey));
        });
      });

      group('getDocumentWithMetadata', () {
        test('returns document for valid key', () async {
          const testKey = 'abc123';

          final document = await repository.getDocumentWithMetadata(testKey);

          expect(document, isA<HastebinDocument>());
          expect(document.key, equals(testKey));
          expect(document.content, contains(testKey));
        });
      });
    });

    group('Real Implementation Tests', () {
      late impl.HastebinRepository repository;

      setUp(() {
        repository = const impl.HastebinRepository();
      });

      group('createDocument', () {
        test('throws HastebinAuthenticationException when API key is missing', () async {
          const testContent = 'Test content';

          // Since HASTEBIN_API_KEY is not set in test environment, this should throw
          expect(() => repository.createDocument(testContent), throwsA(isA<HastebinAuthenticationException>()));
        });
      });

      group('getDocument', () {
        test('throws HastebinAuthenticationException when API key is missing', () async {
          const testKey = 'abc123';

          expect(() => repository.getDocument(testKey), throwsA(isA<HastebinAuthenticationException>()));
        });
      });

      group('getDocumentWithMetadata', () {
        test('throws HastebinAuthenticationException when API key is missing', () async {
          const testKey = 'abc123';

          expect(() => repository.getDocumentWithMetadata(testKey), throwsA(isA<HastebinAuthenticationException>()));
        });
      });
    });
  });

  group('Model Tests', () {
    test('HastebinDocument JSON serialization', () {
      const document = HastebinDocument(key: 'test123', content: 'Test content');

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

    test('Exception types', () {
      const authException = HastebinAuthenticationException();
      expect(authException.message, contains('Authentication failed'));
      expect(authException.statusCode, equals(401));

      const notFoundException = HastebinDocumentNotFoundException('test123');
      expect(notFoundException.message, contains('Document not found: test123'));
      expect(notFoundException.statusCode, equals(404));

      const generalException = HastebinException('Test error', 500);
      expect(generalException.message, equals('Test error'));
      expect(generalException.statusCode, equals(500));
    });
  });
}
