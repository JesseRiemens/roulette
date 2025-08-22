# Hastebin Repository

A data layer repository for interacting with the hastebin API following the existing codebase patterns.

## Features

- **Create documents**: Upload text content to hastebin and get a shareable key
- **Retrieve documents**: Get document content by key (raw text or with metadata)
- **Cross-platform**: Web implementation uses real HTTP calls, non-web uses stub implementation
- **Error handling**: Proper error handling with Result pattern
- **Type-safe**: Full type safety with custom models

## Usage

```dart
import 'package:webroulette/data/hastebin_repository.dart';

// Get the global repository instance
const repository = hastebinRepository;

// Create a document
final createResult = await repository.createDocument('Hello, World!');
createResult.when(
  success: (key) => print('Document created with key: $key'),
  failure: (error) => print('Error: $error'),
);

// Retrieve a document
final getResult = await repository.getDocument('your-key-here');
getResult.when(
  success: (content) => print('Content: $content'),
  failure: (error) => print('Error: $error'),
);

// Get document with metadata
final metaResult = await repository.getDocumentWithMetadata('your-key-here');
metaResult.when(
  success: (document) => print('Key: ${document.key}, Content: ${document.content}'),
  failure: (error) => print('Error: $error'),
);
```

## Integration with Existing Code

The hastebin repository follows the same patterns as the existing `UriStorage`:

- Uses conditional imports for platform-specific implementations
- Provides a const global instance for easy access
- Follows the interface pattern for testability

### Example: Share Roulette Items

```dart
Future<String?> shareRouletteItems(List<String> items) async {
  final content = items.map((item) => '- $item').join('\n');
  final shareableContent = 'Roulette Items:\n\n$content';
  
  final result = await hastebinRepository.createDocument(shareableContent);
  
  return result.when(
    success: (key) {
      // Share URL: https://hastebin.com/$key
      return key;
    },
    failure: (error) => null,
  );
}
```

## API Reference

### HastebinRepositoryInterface

- `createDocument(String content)` → `Future<HastebinResult<String>>`
- `getDocument(String key)` → `Future<HastebinResult<String>>`
- `getDocumentWithMetadata(String key)` → `Future<HastebinResult<HastebinDocument>>`

### Models

#### HastebinDocument
```dart
class HastebinDocument {
  final String key;
  final String content;
}
```

#### HastebinResult<T>
```dart
abstract class HastebinResult<T> {
  factory HastebinResult.success(T data);
  factory HastebinResult.failure(String error);
  
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  });
}
```

## Implementation Details

### Web Platform (hastebin_repository_impl.dart)
- Uses real HTTP calls to hastebin.com API
- POST to `/documents` for creating documents
- GET from `/raw/{key}` for retrieving raw content
- GET from `/documents/{key}` for retrieving with metadata

### Non-Web Platform (hastebin_repository_stub.dart)
- Provides mock implementations for testing and development
- Returns predictable results based on input

### Error Handling
- Network errors are caught and wrapped in `HastebinResult.failure`
- HTTP error codes (404, 500, etc.) are handled appropriately
- Provides meaningful error messages for debugging

## Dependencies

- `http: ^1.1.0` - For making HTTP requests to the hastebin API