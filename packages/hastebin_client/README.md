# Hastebin Client

A Dart package for interacting with the Hastebin API, providing text sharing capabilities with Bearer token authentication and exception-based error handling.

## Features

- **Create documents**: Upload text content to hastebin and receive a shareable key
- **Retrieve raw content**: Get document content by key as plain text  
- **Retrieve with metadata**: Get document content along with metadata as a structured object
- **Bearer token authentication**: Secure API access with build-time configurable token
- **Platform support**: Works on web with real HTTP calls, includes stub implementation for testing
- **Exception-based error handling**: Clear exceptions for different error conditions
- **Build-time configuration**: API key injection via compile-time constants

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  hastebin_client:
    path: packages/hastebin_client  # For local development
```

## Configuration

### API Key Setup

The package requires a Hastebin API key to function. You can configure it in several ways:

#### 1. Environment Variable (Recommended for Development)

Create a `.env` file in your project root:
```env
HASTEBIN_API_KEY=your_actual_api_key_here
```

Then run your app with:
```bash
flutter run --dart-define=HASTEBIN_API_KEY="$HASTEBIN_API_KEY"
```

#### 2. Build-time Definition

Pass the API key directly when building:
```bash
flutter run --dart-define=HASTEBIN_API_KEY=your_actual_api_key_here
```

#### 3. CI/CD Integration

In your GitHub Actions or other CI/CD:
```yaml
- name: Run tests
  run: flutter test --dart-define=HASTEBIN_API_KEY="${{ secrets.HASTEBIN_API_KEY }}"
```

### VS Code Integration

The `.vscode/launch.json` is configured to automatically load the API key from environment variables. Set `HASTEBIN_API_KEY` in your environment or load from `.env` file.

## Usage

```dart
import 'package:hastebin_client/hastebin_client.dart';

try {
  // Create a document
  final key = await hastebinRepository.createDocument('Hello World!');
  print('Document created: https://hastebin.com/$key');

  // Retrieve a document
  final content = await hastebinRepository.getDocument(key);
  print('Content: $content');

  // Get document with metadata
  final document = await hastebinRepository.getDocumentWithMetadata(key);
  print('Key: ${document.key}, Content: ${document.content}');
} on HastebinAuthenticationException {
  print('Authentication failed - check your API key');
} on HastebinDocumentNotFoundException catch (e) {
  print('Document not found: $e');
} on HastebinException catch (e) {
  print('Hastebin error: $e');
}
```

## Error Handling

The package uses exception-based error handling with specific exception types:

- **`HastebinAuthenticationException`**: Thrown when API authentication fails (invalid/missing API key)
- **`HastebinDocumentNotFoundException`**: Thrown when trying to retrieve a document that doesn't exist
- **`HastebinException`**: General exception for other API errors (includes HTTP status codes)

## API Reference

### hastebinRepository

Global instance of the hastebin repository.

#### Methods

- **`createDocument(String content)`**: Creates a new document and returns its key
- **`getDocument(String key)`**: Retrieves document content by key
- **`getDocumentWithMetadata(String key)`**: Retrieves document with metadata

All methods are async and throw appropriate exceptions on failure.

## Platform Support

- **Web**: Real HTTP calls to hastebin.com API with full authentication
- **Non-web platforms**: Stub implementation with mock data for testing purposes

## Development

To set up for development:

1. Copy `sample.env` to `.env` and add your API key
2. Run tests: `dart test` (in the package directory)
3. For integration tests with real API: ensure API key is configured

## License

MIT License - see LICENSE file for details.

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