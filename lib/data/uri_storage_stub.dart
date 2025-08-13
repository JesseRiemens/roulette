// Stub for non-web platforms
import 'package:webroulette/data/uri_storage.dart';

class UriStorage implements UriStorageInterface {
  const UriStorage();

  @override
  Map<String, List<String>> get queryParameters => {};

  @override
  Uri get uri => Uri();

  @override
  void storeQueryParameters(Map<String, List<String>> parameters) {}
}
