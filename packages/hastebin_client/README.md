# Hastebin Client

A Dart package for interacting with the Hastebin API, providing text sharing capabilities with Bearer token authentication.

## Features

- **Create documents**: Upload text content to hastebin and receive a shareable key
- **Retrieve raw content**: Get document content by key as plain text  
- **Retrieve with metadata**: Get document content along with metadata as a structured object
- **Bearer token authentication**: Secure API access with token-based auth
- **Platform support**: Works on web with real HTTP calls, includes stub implementation for testing
- **Comprehensive error handling**: Structured result types with pattern matching

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  hastebin_client:
    path: packages/hastebin_client  # For local development
```

## Usage

```dart
import 'package:hastebin_client/hastebin_client.dart';

// Create a document
final result = await hastebinRepository.createDocument('Hello World!');
result.when(
  success: (key) => print('Document created: https://hastebin.com/$key'),
  failure: (error) => print('Error: $error'),
);

// Retrieve a document
final getResult = await hastebinRepository.getDocument(key);
getResult.when(
  success: (content) => print('Content: $content'),
  failure: (error) => print('Error: $error'),
);

// Get document with metadata
final metaResult = await hastebinRepository.getDocumentWithMetadata(key);
metaResult.when(
  success: (document) => print('Key: ${document.key}, Content: ${document.content}'),
  failure: (error) => print('Error: $error'),
);
```

## API Reference

### `hastebinRepository`

Global const instance of `HastebinRepositoryInterface` that provides:

#### `createDocument(String content)`
Creates a new hastebin document with the given content.
- **Returns**: `Future<HastebinResult<String>>` - Success contains the document key
- **Parameters**: 
  - `content`: The text content to upload

#### `getDocument(String key)`
Retrieves the raw content of a hastebin document by its key.
- **Returns**: `Future<HastebinResult<String>>` - Success contains the document content
- **Parameters**:
  - `key`: The hastebin document key

#### `getDocumentWithMetadata(String key)`
Retrieves a hastebin document with metadata by its key.
- **Returns**: `Future<HastebinResult<HastebinDocument>>` - Success contains the full document object
- **Parameters**:
  - `key`: The hastebin document key

### Models

#### `HastebinResult<T>`
A result type that provides pattern matching for success/failure cases:

```dart
result.when(
  success: (data) => handleSuccess(data),
  failure: (error) => handleError(error),
);
```

#### `HastebinDocument`
Represents a hastebin document with metadata:
- `key`: The document's unique identifier
- `content`: The document's text content

## Authentication

The package uses Bearer token authentication for API requests. The token is configured in the implementation and handles all authentication automatically.

## Platform Support

- **Web**: Uses real HTTP calls to the hastebin.com API with full authentication
- **Non-web platforms**: Uses a stub implementation with mock data for testing purposes

## Testing

The package includes comprehensive tests:
- Unit tests for both stub and real implementations
- Integration tests for complete workflows
- Real API tests with proper rate limiting (1 second between requests)

Run tests with:
```bash
dart test
```

## License

MIT License - see LICENSE file for details.