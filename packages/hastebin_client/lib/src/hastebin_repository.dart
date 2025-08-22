import 'hastebin_models.dart';
// Conditional import for HastebinRepository
export 'hastebin_repository_stub.dart' if (dart.library.html) 'hastebin_repository_impl.dart';

/// Interface for hastebin operations following the existing data layer pattern
abstract interface class HastebinRepositoryInterface {
  /// Creates a new hastebin document with the given content
  /// Returns the key that can be used to retrieve the document
  /// Throws [HastebinException] if the operation fails
  Future<String> createDocument(String content);

  /// Retrieves a hastebin document by its key
  /// Returns the document content
  /// Throws [HastebinDocumentNotFoundException] if the document is not found
  /// Throws [HastebinException] if the operation fails
  Future<String> getDocument(String key);

  /// Retrieves a hastebin document with metadata by its key
  /// Returns the full document object
  /// Throws [HastebinDocumentNotFoundException] if the document is not found
  /// Throws [HastebinException] if the operation fails
  Future<HastebinDocument> getDocumentWithMetadata(String key);
}
