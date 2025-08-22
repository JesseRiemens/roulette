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

/// Result wrapper for hastebin operations
abstract class HastebinResult<T> {
  const HastebinResult();

  factory HastebinResult.success(T data) = HastebinSuccess<T>;
  factory HastebinResult.failure(String error) = HastebinFailure<T>;

  /// Pattern matching method for handling results
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (this is HastebinSuccess<T>) {
      return success((this as HastebinSuccess<T>).data);
    } else if (this is HastebinFailure<T>) {
      return failure((this as HastebinFailure<T>).error);
    }
    throw StateError('Invalid HastebinResult state');
  }
}

class HastebinSuccess<T> extends HastebinResult<T> {
  final T data;

  const HastebinSuccess(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HastebinSuccess &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'HastebinSuccess(data: $data)';
}

class HastebinFailure<T> extends HastebinResult<T> {
  final String error;

  const HastebinFailure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HastebinFailure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'HastebinFailure(error: $error)';
}