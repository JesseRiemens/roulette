import 'dart:convert';
import 'package:hastebin_client/hastebin_client.dart';
import 'hastebin_rate_limit_service.dart';

/// Service to handle Hastebin storage operations with rate limiting and robust encoding
class HastebinStorageService {
  const HastebinStorageService({this.repository = const HastebinRepository(), this.rateLimitService});

  final HastebinRepositoryInterface repository;
  final HastebinRateLimitService? rateLimitService;

  HastebinRateLimitService get _rateLimitService => rateLimitService ?? HastebinRateLimitService.instance;

  /// Uploads a list of items to Hastebin and returns the key
  /// Uses JSON encoding for robust data integrity
  Future<String> uploadItems(List<String> items) async {
    await _rateLimitService.waitForRateLimit();

    // Create a robust JSON structure with metadata
    final data = {
      'version': '1.0',
      'type': 'roulette_items',
      'timestamp': DateTime.now().toIso8601String(),
      'items': items,
      'checksum': _calculateChecksum(items),
    };

    final jsonContent = json.encode(data);

    try {
      final key = await repository.createDocument(jsonContent);
      return key;
    } on HastebinException {
      rethrow;
    } catch (e) {
      throw HastebinException('Failed to upload items: ${e.toString()}');
    }
  }

  /// Downloads and decodes items from Hastebin using the key
  /// Validates data integrity and handles various edge cases
  Future<List<String>> downloadItems(String key) async {
    await _rateLimitService.waitForRateLimit();

    try {
      final content = await repository.getDocument(key);
      return _parseContent(content);
    } on HastebinDocumentNotFoundException {
      rethrow;
    } on HastebinException {
      rethrow;
    } catch (e) {
      throw HastebinException('Failed to download items: ${e.toString()}');
    }
  }

  /// Parses content from Hastebin, handling both new JSON format and legacy formats
  List<String> _parseContent(String content) {
    try {
      // Try to parse as JSON first (new format)
      final data = json.decode(content) as Map<String, dynamic>;

      if (data['type'] == 'roulette_items' && data['items'] is List) {
        final items = (data['items'] as List).cast<String>();

        // Validate checksum if present
        if (data['checksum'] != null) {
          final expectedChecksum = _calculateChecksum(items);
          if (data['checksum'] != expectedChecksum) {
            throw const HastebinException('Data integrity check failed - checksum mismatch');
          }
        }

        return items;
      } else {
        throw const HastebinException('Invalid data format - not roulette items');
      }
    } on FormatException {
      // Try to parse as legacy format (line-separated items)
      return _parseLegacyContent(content);
    }
  }

  /// Handles legacy content formats for backward compatibility
  List<String> _parseLegacyContent(String content) {
    // If content looks like JSON but failed to parse, it's truly invalid
    final trimmed = content.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      throw const HastebinException('Invalid JSON format');
    }

    // Check if it's the example format from hastebin_usage_example.dart
    if (content.startsWith('Roulette Items:')) {
      final lines = content.split('\n');
      final items = lines
          .where((line) => line.trim().startsWith('- '))
          .map((line) => line.trim().substring(2))
          .where((item) => item.isNotEmpty)
          .toList();

      if (items.isEmpty) {
        throw const HastebinException('No valid items found in legacy format');
      }

      return items;
    }

    // Try to parse as simple line-separated format
    final lines = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    if (lines.isEmpty) {
      throw const HastebinException('No valid items found in content');
    }

    return lines;
  }

  /// Calculates a simple checksum for data integrity
  String _calculateChecksum(List<String> items) {
    final combined = items.join('|');
    return combined.hashCode.abs().toString();
  }

  /// Gets current rate limit status
  ({int currentRequests, int maxRequests, Duration? waitTime}) getRateLimitStatus() {
    return (
      currentRequests: _rateLimitService.currentRequestCount,
      maxRequests: 100,
      waitTime: _rateLimitService.timeUntilNextRequest,
    );
  }
}
