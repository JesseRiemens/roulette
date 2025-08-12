import 'dart:convert';

class UrlUtils {
  // Web-safe separator (not in base64url alphabet)
  static const String _separator = '~';

  /// Encodes a list of strings to a single string using base64url and a web-safe separator.
  static String urlFromList(List<String> list) {
    return list
        .map((item) => base64Url.encode(utf8.encode(item)))
        .join(_separator);
  }

  /// Decodes a string produced by [urlFromList] back to a list of strings.
  static List<String> listFromUrl(String url) {
    if (url.isEmpty) return [];
    return url
        .split(_separator)
        .map((token) => utf8.decode(base64Url.decode(token)))
        .toList();
  }
}
