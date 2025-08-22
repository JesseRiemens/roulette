import 'package:webroulette/data/hastebin_repository.dart';

/// Example usage of the hastebin repository
class HastebinUsageExample {
  /// Example of creating and retrieving a hastebin document
  static Future<void> example() async {
    const repository = hastebinRepository;

    // Create a new document
    const content = 'Hello, this is a test document for hastebin!';
    final createResult = await repository.createDocument(content);

    createResult.when(
      success: (key) async {
        print('✅ Document created successfully with key: $key');
        
        // Retrieve the document by key
        final getResult = await repository.getDocument(key);
        
        getResult.when(
          success: (retrievedContent) {
            print('✅ Document retrieved successfully:');
            print('Content: $retrievedContent');
          },
          failure: (error) {
            print('❌ Failed to retrieve document: $error');
          },
        );

        // Get document with metadata
        final metaResult = await repository.getDocumentWithMetadata(key);
        
        metaResult.when(
          success: (document) {
            print('✅ Document with metadata retrieved:');
            print('Key: ${document.key}');
            print('Content: ${document.content}');
          },
          failure: (error) {
            print('❌ Failed to retrieve document metadata: $error');
          },
        );
      },
      failure: (error) {
        print('❌ Failed to create document: $error');
      },
    );
  }

  /// Example of how to integrate with the existing storage system
  static Future<String?> shareRouletteItems(List<String> items) async {
    const repository = hastebinRepository;
    
    // Convert items to a shareable format
    final content = items.map((item) => '- $item').join('\n');
    final shareableContent = 'Roulette Items:\n\n$content';
    
    final result = await repository.createDocument(shareableContent);
    
    return result.when(
      success: (key) {
        print('Roulette items shared to hastebin: https://hastebin.com/$key');
        return key;
      },
      failure: (error) {
        print('Failed to share roulette items: $error');
        return null;
      },
    );
  }

  /// Example of retrieving shared roulette items
  static Future<List<String>?> loadSharedRouletteItems(String key) async {
    const repository = hastebinRepository;
    
    final result = await repository.getDocument(key);
    
    return result.when(
      success: (content) {
        // Parse the content back to items
        final lines = content.split('\n');
        final items = lines
            .where((line) => line.trim().startsWith('- '))
            .map((line) => line.trim().substring(2))
            .toList();
        
        print('Loaded ${items.length} roulette items from hastebin');
        return items;
      },
      failure: (error) {
        print('Failed to load shared roulette items: $error');
        return null;
      },
    );
  }
}