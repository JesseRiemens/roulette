import 'hastebin_models.dart';
import 'hastebin_repository.dart';

/// Stub implementation of hastebin repository for non-web platforms
/// Returns mock data for testing and development purposes
class HastebinRepository implements HastebinRepositoryInterface {
  const HastebinRepository();

  @override
  Future<String> createDocument(String content) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Return a mock key based on content hash
    final mockKey = content.hashCode.abs().toString();
    return mockKey;
  }

  @override
  Future<String> getDocument(String key) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Return mock content
    return 'Mock content for key: $key';
  }

  @override
  Future<HastebinDocument> getDocumentWithMetadata(String key) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Return mock document
    final document = HastebinDocument(
      key: key,
      content: 'Mock content for key: $key',
    );
    return document;
  }
}