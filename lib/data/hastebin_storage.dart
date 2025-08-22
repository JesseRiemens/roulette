import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exception thrown when Hastebin operations fail
class HastebinException implements Exception {
  final String message;
  final int? statusCode;
  
  HastebinException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'HastebinException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Rate limiter for Hastebin API calls
class RateLimiter {
  static const int maxRequestsPerMinute = 100;
  static const Duration _windowDuration = Duration(minutes: 1);
  
  final List<DateTime> _requestTimes = [];
  
  /// For testing purposes only
  List<DateTime> get requestTimes => _requestTimes;
  
  /// Returns the delay needed before the next request can be made
  Duration? getRequiredDelay() {
    final now = DateTime.now();
    
    // Remove requests older than 1 minute
    _requestTimes.removeWhere((time) => now.difference(time) > _windowDuration);
    
    // If we're under the limit, no delay needed
    if (_requestTimes.length < maxRequestsPerMinute) {
      return null;
    }
    
    // Find the oldest request and calculate delay needed
    final oldestRequest = _requestTimes.first;
    final timeSinceOldest = now.difference(oldestRequest);
    final remainingWindow = _windowDuration - timeSinceOldest;
    
    return remainingWindow;
  }
  
  /// Record a request and wait if necessary
  Future<void> recordRequest() async {
    final delay = getRequiredDelay();
    if (delay != null && delay.inMilliseconds > 0) {
      // For testing, limit the maximum wait time to prevent timeouts
      final maxWait = Duration(seconds: 5);
      final waitTime = delay.inMilliseconds > maxWait.inMilliseconds ? maxWait : delay;
      await Future.delayed(waitTime);
    }
    
    _requestTimes.add(DateTime.now());
  }
}

/// Service for interacting with Hastebin API
class HastebinStorage {
  static const String defaultBaseUrl = 'https://hastebin.com';
  
  final String baseUrl;
  final http.Client _client;
  final RateLimiter _rateLimiter = RateLimiter();
  
  /// Access to rate limiter for testing
  RateLimiter get rateLimiter => _rateLimiter;
  
  HastebinStorage({
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();
  
  /// Upload data to Hastebin and return the ID
  Future<String> upload(String data) async {
    await _rateLimiter.recordRequest();
    
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/documents'),
        body: data,
        headers: {
          'Content-Type': 'text/plain',
        },
      );
      
      if (response.statusCode != 200) {
        throw HastebinException(
          'Failed to upload data to Hastebin',
          response.statusCode,
        );
      }
      
      final responseData = json.decode(response.body);
      final key = responseData['key'];
      
      if (key == null || key is! String) {
        throw HastebinException('Invalid response from Hastebin: missing key');
      }
      
      return key;
    } catch (e) {
      if (e is HastebinException) rethrow;
      throw HastebinException('Network error: $e');
    }
  }
  
  /// Download data from Hastebin using the ID
  Future<String> download(String id) async {
    await _rateLimiter.recordRequest();
    
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/raw/$id'),
      );
      
      if (response.statusCode == 404) {
        throw HastebinException('Hastebin document not found', 404);
      }
      
      if (response.statusCode != 200) {
        throw HastebinException(
          'Failed to download data from Hastebin',
          response.statusCode,
        );
      }
      
      return response.body;
    } catch (e) {
      if (e is HastebinException) rethrow;
      throw HastebinException('Network error: $e');
    }
  }
  
  /// Encode a list of items for safe storage
  String encodeItems(List<String> items) {
    final data = {
      'version': 1,
      'items': items,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return json.encode(data);
  }
  
  /// Decode a list of items from storage
  List<String> decodeItems(String data) {
    try {
      final decoded = json.decode(data);
      
      if (decoded is! Map<String, dynamic>) {
        throw HastebinException('Invalid data format: expected JSON object');
      }
      
      final version = decoded['version'];
      if (version != 1) {
        throw HastebinException('Unsupported data version: $version');
      }
      
      final items = decoded['items'];
      if (items is! List) {
        throw HastebinException('Invalid data format: items must be a list');
      }
      
      return items.cast<String>();
    } catch (e) {
      if (e is HastebinException) rethrow;
      throw HastebinException('Failed to decode items: $e');
    }
  }
  
  /// Upload items and return Hastebin ID
  Future<String> uploadItems(List<String> items) async {
    final encodedData = encodeItems(items);
    return await upload(encodedData);
  }
  
  /// Download items using Hastebin ID
  Future<List<String>> downloadItems(String id) async {
    final data = await download(id);
    return decodeItems(data);
  }
  
  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}