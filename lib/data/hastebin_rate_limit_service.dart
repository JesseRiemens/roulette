/// Service to manage rate limiting for Hastebin API requests
/// Ensures no more than 100 requests per minute
class HastebinRateLimitService {
  HastebinRateLimitService._();
  static final instance = HastebinRateLimitService._();

  final List<DateTime> _requestTimes = [];
  static const int _maxRequestsPerMinute = 100;
  static const Duration _timeWindow = Duration(minutes: 1);

  /// Waits if necessary to respect rate limit, then records the request
  Future<void> waitForRateLimit() async {
    final now = DateTime.now();
    final cutoff = now.subtract(_timeWindow);
    
    // Remove requests older than 1 minute
    _requestTimes.removeWhere((time) => time.isBefore(cutoff));
    
    // If we're at the limit, wait until the oldest request is over 1 minute old
    if (_requestTimes.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = oldestRequest.add(_timeWindow).difference(now);
      
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime);
        
        // Remove expired requests after waiting
        final newNow = DateTime.now();
        final newCutoff = newNow.subtract(_timeWindow);
        _requestTimes.removeWhere((time) => time.isBefore(newCutoff));
      }
    }
    
    // Record this request
    _requestTimes.add(DateTime.now());
  }

  /// Get the current number of requests in the time window
  int get currentRequestCount {
    final now = DateTime.now();
    final cutoff = now.subtract(_timeWindow);
    _requestTimes.removeWhere((time) => time.isBefore(cutoff));
    return _requestTimes.length;
  }

  /// Get the time until the next request can be made (if rate limited)
  Duration? get timeUntilNextRequest {
    final now = DateTime.now();
    final cutoff = now.subtract(_timeWindow);
    _requestTimes.removeWhere((time) => time.isBefore(cutoff));
    
    if (_requestTimes.length < _maxRequestsPerMinute) {
      return null; // No wait needed
    }
    
    final oldestRequest = _requestTimes.first;
    final waitTime = oldestRequest.add(_timeWindow).difference(now);
    return waitTime.isNegative ? null : waitTime;
  }

  /// Reset the rate limiter (useful for testing)
  void reset() {
    _requestTimes.clear();
  }
}