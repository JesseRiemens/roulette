// ignore_for_file: avoid_print

import 'package:hastebin_client/hastebin_client.dart';

/// Example usage of the hastebin repository
class HastebinUsageExample {
  /// Example of creating and retrieving a hastebin document
  static Future<void> example() async {
    const repository = HastebinRepository();

    try {
      // Create a new document
      const content = 'Hello, this is a test document for hastebin!';
      final key = await repository.createDocument(content);
      print('✅ Document created successfully with key: $key');

      // Retrieve the document by key
      final retrievedContent = await repository.getDocument(key);
      print('✅ Document retrieved successfully:');
      print('Content: $retrievedContent');

      // Get document with metadata
      final document = await repository.getDocumentWithMetadata(key);
      print('✅ Document with metadata retrieved:');
      print('Key: ${document.key}');
      print('Content: ${document.content}');
    } on HastebinAuthenticationException {
      print('❌ Authentication failed - check your API key configuration');
    } on HastebinDocumentNotFoundException catch (e) {
      print('❌ Document not found: $e');
    } on HastebinException catch (e) {
      print('❌ Hastebin error: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Example of how to integrate with the existing storage system
  static Future<String?> shareRouletteItems(List<String> items) async {
    const repository = HastebinRepository();

    try {
      // Convert items to a shareable format
      final content = items.map((item) => '- $item').join('\n');
      final shareableContent = 'Roulette Items:\n\n$content';

      final key = await repository.createDocument(shareableContent);
      print('Roulette items shared to hastebin: https://hastebin.com/$key');
      return key;
    } on HastebinException catch (e) {
      print('Failed to share roulette items: $e');
      return null;
    }
  }

  /// Example of retrieving shared roulette items
  static Future<List<String>?> loadSharedRouletteItems(String key) async {
    const repository = HastebinRepository();

    try {
      final content = await repository.getDocument(key);

      // Parse the content back to items
      final lines = content.split('\n');
      final items = lines
          .where((line) => line.trim().startsWith('- '))
          .map((line) => line.trim().substring(2))
          .toList();

      print('Loaded ${items.length} roulette items from hastebin');
      return items;
    } on HastebinDocumentNotFoundException {
      print('Failed to load shared roulette items: Document not found');
      return null;
    } on HastebinException catch (e) {
      print('Failed to load shared roulette items: $e');
      return null;
    }
  }
}
