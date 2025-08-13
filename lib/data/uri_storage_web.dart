// Web implementation
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:webroulette/data/uri_storage.dart';

class UriStorage implements UriStorageInterface {
  const UriStorage();

  void _replaceState(String path) => urlStrategy?.replaceState('', '', path);

  @override
  Map<String, List<String>> get queryParameters => Uri.base.queryParametersAll;

  @override
  Uri get uri => Uri.base;

  @override
  void storeQueryParameters(Map<String, List<String>> parameters) {
    final segments = Uri.base.pathSegments;
    final lastSegment = segments.isNotEmpty ? segments.last : '';
    final uri = Uri(
      path: lastSegment.isNotEmpty ? '/$lastSegment' : '/',
      queryParameters: parameters.isNotEmpty ? parameters : null,
    );
    final lastSegmentWithQuery = uri.toString();
    // ignore: avoid_print
    print(
      '[UriStorage] pushing last segment with query: $lastSegmentWithQuery',
    );
    _replaceState(lastSegmentWithQuery);
  }
}
