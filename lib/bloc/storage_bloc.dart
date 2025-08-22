import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:webroulette/data/uri_storage.dart';
import 'package:webroulette/data/hastebin_storage.dart';

part 'storage_bloc.freezed.dart';
part 'storage_bloc.g.dart';

class StorageCubit extends HydratedCubit<StoredItems> {
  final HastebinStorage _hastebinStorage;
  
  StorageCubit([HastebinStorage? hastebinStorage]) 
      : _hastebinStorage = hastebinStorage ?? HastebinStorage(),
        super(StoredItems.initial);

  StorageCubit.web([HastebinStorage? hastebinStorage]) 
      : _hastebinStorage = hastebinStorage ?? HastebinStorage(),
        super(StoredItems.initial) {
    _initializeFromUrl();
  }
  
  void _initializeFromUrl() async {
    try {
      // Check for Hastebin ID in URL first
      final hastebinId = _extractHastebinId(uriStorage.uri);
      if (hastebinId != null) {
        final items = await _hastebinStorage.downloadItems(hastebinId);
        emit(state.copyWith(items: items));
        return;
      }
      
      // Fall back to legacy URL parameter storage
      if (uriStorage.queryParameters['items'] != null && uriStorage.queryParameters['items']!.isNotEmpty) {
        final items = uriStorage.queryParameters['items']!.map((item) => utf8.decode(base64Url.decode(item))).toList();
        emit(state.copyWith(items: items));
      }
    } catch (e) {
      // If Hastebin loading fails, try legacy format
      if (uriStorage.queryParameters['items'] != null && uriStorage.queryParameters['items']!.isNotEmpty) {
        try {
          final items = uriStorage.queryParameters['items']!.map((item) => utf8.decode(base64Url.decode(item))).toList();
          emit(state.copyWith(items: items));
        } catch (legacyError) {
          // Both methods failed, keep initial empty state
          print('[StorageCubit] Failed to load items from URL: $e, $legacyError');
        }
      }
    }
  }
  
  String? _extractHastebinId(Uri uri) {
    // Check for pattern like /hastebin/{id} or ?hastebin=id
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2 && pathSegments[pathSegments.length - 2] == 'hastebin') {
      return pathSegments.last;
    }
    
    // Check query parameter
    return uri.queryParameters['hastebin'];
  }

  void saveItems(List<String> items) {
    emit(state.copyWith(items: items));
    // ignore: avoid_print
    print('[StorageCubit] Saving items: $items');
    
    // Keep legacy URL storage for backward compatibility
    uriStorage.storeQueryParameters(state.toUriQueryParameters);
  }
  
  /// Generate URL with Hastebin ID for sharing
  Future<Uri> generateHastebinUrl() async {
    final hastebinId = await _hastebinStorage.uploadItems(state.items);
    
    // Create URL with hastebin ID
    final currentUri = uriStorage.uri;
    final segments = currentUri.pathSegments;
    final lastSegment = segments.isNotEmpty ? segments.last : '';
    
    return Uri(
      scheme: currentUri.scheme,
      host: currentUri.host,
      port: currentUri.port,
      path: lastSegment.isNotEmpty ? '/$lastSegment/hastebin/$hastebinId' : '/hastebin/$hastebinId',
    );
  }

  Uri get uriWithData => uriStorage.uri;
  
  @override
  Future<void> close() async {
    _hastebinStorage.dispose();
    return super.close();
  }

  @override
  StoredItems? fromJson(Map<String, dynamic> json) => StoredItems.fromJson(json);

  @override
  Map<String, dynamic>? toJson(StoredItems state) => state.toJson();
}

@freezed
abstract class StoredItems with _$StoredItems {
  const factory StoredItems({required List<String> items}) = _StoredItems;
  const StoredItems._();

  static const initial = StoredItems(items: []);

  factory StoredItems.fromJson(Map<String, dynamic> json) => _$StoredItemsFromJson(json);

  Map<String, List<String>> get toUriQueryParameters => {
    'items': items.map((item) => base64Url.encode(utf8.encode(item))).toList(),
  };
}
