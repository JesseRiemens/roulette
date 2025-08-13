// Conditional import for UriStorage
import 'uri_storage_stub.dart' if (dart.library.html) 'uri_storage_web.dart';

abstract interface class UriStorageInterface {
  void storeQueryParameters(Map<String, List<String>> parameters);
  Uri get uri;
  Map<String, List<String>> get queryParameters;
}

const UriStorageInterface uriStorage = UriStorage();
