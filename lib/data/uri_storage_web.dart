// Web implementation
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:webroulette/data/uri_storage.dart';

class UriStorage implements UriStorageInterface {
  const UriStorage();

  void _pushState(String path) => urlStrategy?.pushState('', '', path);

  @override
  Map<String, List<String>> get queryParameters => Uri.base.queryParametersAll;

  @override
  Uri get uri => Uri.base;

  @override
  void storeQueryParameters(Map<String, List<String>> parameters) {
    final uri = Uri.base.replace(queryParameters: parameters);
    final newPath = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    // ignore: avoid_print
    print('[UriStorage] Pushing new path: $newPath');
    _pushState(newPath);
  }
}
