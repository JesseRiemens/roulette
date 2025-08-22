import 'dart:convert';
import 'package:http/http.dart' as http;
import 'hastebin_models.dart';
import 'hastebin_repository.dart';

/// Implementation of hastebin repository for interacting with hastebin.com API
class HastebinRepository implements HastebinRepositoryInterface {
  const HastebinRepository();

  @override
  Future<HastebinResult<String>> createDocument(String content) async {
    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse('https://hastebin.com/documents'),
        headers: {'Content-Type': 'text/plain'},
        body: content,
      );
      client.close();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final hastebinResponse = HastebinCreateResponse.fromJson(jsonResponse);
        return HastebinResult.success(hastebinResponse.key);
      } else {
        return HastebinResult.failure(
          'Failed to create document: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return HastebinResult.failure('Error creating document: ${e.toString()}');
    }
  }

  @override
  Future<HastebinResult<String>> getDocument(String key) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('https://hastebin.com/raw/$key'),
      );
      client.close();

      if (response.statusCode == 200) {
        return HastebinResult.success(response.body);
      } else if (response.statusCode == 404) {
        return HastebinResult.failure('Document not found');
      } else {
        return HastebinResult.failure(
          'Failed to get document: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return HastebinResult.failure('Error getting document: ${e.toString()}');
    }
  }

  @override
  Future<HastebinResult<HastebinDocument>> getDocumentWithMetadata(
    String key,
  ) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('https://hastebin.com/documents/$key'),
      );
      client.close();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final document = HastebinDocument(
          key: key,
          content: jsonResponse['data'] as String,
        );
        return HastebinResult.success(document);
      } else if (response.statusCode == 404) {
        return HastebinResult.failure('Document not found');
      } else {
        return HastebinResult.failure(
          'Failed to get document: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return HastebinResult.failure('Error getting document: ${e.toString()}');
    }
  }
}