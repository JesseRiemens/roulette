import 'dart:convert';

import 'package:http/http.dart' as http;

import 'hastebin_models.dart';
import 'hastebin_repository.dart';

/// Implementation of hastebin repository for interacting with hastebin.com API
class HastebinRepository implements HastebinRepositoryInterface {
  const HastebinRepository();

  // Get API key from compile-time constant or environment
  static const String _apiKey = String.fromEnvironment('HASTEBIN_API_KEY');

  String get _resolvedApiKey {
    if (_apiKey.isEmpty) {
      throw const HastebinAuthenticationException();
    }
    return _apiKey;
  }

  @override
  Future<String> createDocument(String content) async {
    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse('https://hastebin.com/documents'),
        headers: {'Authorization': 'Bearer $_resolvedApiKey', 'Content-Type': 'text/plain'},
        body: content,
      );
      client.close();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final hastebinResponse = HastebinCreateResponse.fromJson(jsonResponse);
        return hastebinResponse.key;
      } else if (response.statusCode == 401) {
        throw const HastebinAuthenticationException();
      } else {
        throw HastebinException('Failed to create document: ${response.body}', response.statusCode);
      }
    } catch (e) {
      if (e is HastebinException) rethrow;
      throw HastebinException('Error creating document: ${e.toString()}');
    }
  }

  @override
  Future<String> getDocument(String key) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('https://hastebin.com/raw/$key'),
        headers: {'Authorization': 'Bearer $_resolvedApiKey'},
      );
      client.close();

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw HastebinDocumentNotFoundException(key);
      } else if (response.statusCode == 401) {
        throw const HastebinAuthenticationException();
      } else {
        throw HastebinException('Failed to get document: ${response.body}', response.statusCode);
      }
    } catch (e) {
      if (e is HastebinException) rethrow;
      throw HastebinException('Error getting document: ${e.toString()}');
    }
  }

  @override
  Future<HastebinDocument> getDocumentWithMetadata(String key) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('https://hastebin.com/documents/$key'),
        headers: {'Authorization': 'Bearer $_resolvedApiKey'},
      );
      client.close();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final document = HastebinDocument(key: key, content: jsonResponse['data'] as String);
        return document;
      } else if (response.statusCode == 404) {
        throw HastebinDocumentNotFoundException(key);
      } else if (response.statusCode == 401) {
        throw const HastebinAuthenticationException();
      } else {
        throw HastebinException('Failed to get document: ${response.body}', response.statusCode);
      }
    } catch (e) {
      if (e is HastebinException) rethrow;
      throw HastebinException('Error getting document: ${e.toString()}');
    }
  }
}
