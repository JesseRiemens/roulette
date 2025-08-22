/// Represents a hastebin document for sharing data
class HastebinDocument {
  final String key;
  final String content;

  const HastebinDocument({
    required this.key,
    required this.content,
  });

  factory HastebinDocument.fromJson(Map<String, dynamic> json) {
    return HastebinDocument(
      key: json['key'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'content': content,
    };
  }
}

/// Response from hastebin when creating a document
class HastebinCreateResponse {
  final String key;

  const HastebinCreateResponse({
    required this.key,
  });

  factory HastebinCreateResponse.fromJson(Map<String, dynamic> json) {
    return HastebinCreateResponse(
      key: json['key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
    };
  }
}

/// Exception thrown when hastebin operations fail
class HastebinException implements Exception {
  final String message;
  final int? statusCode;

  const HastebinException(this.message, [this.statusCode]);

  @override
  String toString() {
    if (statusCode != null) {
      return 'HastebinException: $message (HTTP $statusCode)';
    }
    return 'HastebinException: $message';
  }
}

/// Exception thrown when a document is not found
class HastebinDocumentNotFoundException extends HastebinException {
  const HastebinDocumentNotFoundException(String key) 
      : super('Document not found: $key', 404);
}

/// Exception thrown when authentication fails
class HastebinAuthenticationException extends HastebinException {
  const HastebinAuthenticationException() 
      : super('Authentication failed - invalid or missing API key', 401);
}