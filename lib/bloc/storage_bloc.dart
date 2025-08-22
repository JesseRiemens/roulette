import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:webroulette/data/uri_storage.dart';
import 'package:webroulette/data/hastebin_storage_service.dart';
import 'package:hastebin_client/hastebin_client.dart';

part 'storage_bloc.freezed.dart';
part 'storage_bloc.g.dart';

class StorageCubit extends HydratedCubit<StoredItems> {
  StorageCubit({HastebinStorageService? hastebinStorageService}) 
      : _hastebinStorageService = hastebinStorageService ?? const HastebinStorageService(),
        super(StoredItems.initial);

  final HastebinStorageService _hastebinStorageService;

  StorageCubit.web({HastebinStorageService? hastebinStorageService}) 
      : _hastebinStorageService = hastebinStorageService ?? const HastebinStorageService(),
        super(StoredItems.initial) {
    _loadFromUri();
  }

  /// Load items from URI parameters (legacy) or Hastebin
  Future<void> _loadFromUri() async {
    try {
      // Check for Hastebin ID first (new format)
      if (uriStorage.queryParameters['h'] != null && uriStorage.queryParameters['h']!.isNotEmpty) {
        final hastebinId = uriStorage.queryParameters['h']!.first;
        await _loadFromHastebin(hastebinId);
        return;
      }

      // Fall back to legacy URL parameters
      if (uriStorage.queryParameters['items'] != null && uriStorage.queryParameters['items']!.isNotEmpty) {
        final items = uriStorage.queryParameters['items']!.map((item) => utf8.decode(base64Url.decode(item))).toList();
        emit(state.copyWith(items: items));
        return;
      }
    } catch (e) {
      // If loading fails, emit error state but continue with empty items
      emit(state.copyWith(items: [], error: 'Failed to load shared items: ${e.toString()}'));
    }
  }

  /// Load items from Hastebin using the provided ID (public for testing)
  Future<void> loadFromHastebin(String hastebinId) async {
    await _loadFromHastebin(hastebinId);
  }

  /// Load items from Hastebin using the provided ID
  Future<void> _loadFromHastebin(String hastebinId) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      final items = await _hastebinStorageService.downloadItems(hastebinId);
      emit(state.copyWith(items: items, isLoading: false, hastebinId: hastebinId));
    } on HastebinDocumentNotFoundException {
      emit(state.copyWith(
        items: [], 
        isLoading: false, 
        error: 'Shared items not found. The link may be expired or invalid.'
      ));
    } on HastebinException catch (e) {
      emit(state.copyWith(
        items: [], 
        isLoading: false, 
        error: 'Failed to load shared items: ${e.message}'
      ));
    } catch (e) {
      emit(state.copyWith(
        items: [], 
        isLoading: false, 
        error: 'Unexpected error loading shared items: ${e.toString()}'
      ));
    }
  }

  void saveItems(List<String> items) {
    emit(state.copyWith(items: items, error: null));
    // ignore: avoid_print
    print('[StorageCubit] Saving items: $items');
    
    // Clear any Hastebin ID since items changed locally
    emit(state.copyWith(hastebinId: null));
    
    // Update legacy URL parameters for backward compatibility
    uriStorage.storeQueryParameters(state.toUriQueryParameters);
  }

  /// Upload items to Hastebin and return shareable URL
  Future<String> shareItems() async {
    try {
      emit(state.copyWith(isUploading: true, error: null));
      
      final hastebinId = await _hastebinStorageService.uploadItems(state.items);
      
      // Create shareable URL with Hastebin ID
      final currentUri = uriStorage.uri;
      final shareableUri = currentUri.replace(
        queryParameters: {'h': hastebinId},
      );
      
      emit(state.copyWith(
        isUploading: false, 
        hastebinId: hastebinId,
        lastSharedUrl: shareableUri.toString()
      ));
      
      return shareableUri.toString();
    } on HastebinException catch (e) {
      emit(state.copyWith(
        isUploading: false, 
        error: 'Failed to share items: ${e.message}'
      ));
      rethrow;
    } catch (e) {
      emit(state.copyWith(
        isUploading: false, 
        error: 'Unexpected error sharing items: ${e.toString()}'
      ));
      rethrow;
    }
  }

  /// Get rate limit status for UI display
  ({int currentRequests, int maxRequests, Duration? waitTime}) getRateLimitStatus() {
    return _hastebinStorageService.getRateLimitStatus();
  }

  Uri get uriWithData => uriStorage.uri;

  @override
  StoredItems? fromJson(Map<String, dynamic> json) => StoredItems.fromJson(json);

  @override
  Map<String, dynamic>? toJson(StoredItems state) => state.toJson();
}

@freezed
abstract class StoredItems with _$StoredItems {
  const factory StoredItems({
    required List<String> items,
    @Default(false) bool isLoading,
    @Default(false) bool isUploading,
    String? hastebinId,
    String? lastSharedUrl,
    String? error,
  }) = _StoredItems;
  const StoredItems._();

  static const initial = StoredItems(items: []);

  factory StoredItems.fromJson(Map<String, dynamic> json) => _$StoredItemsFromJson(json);

  Map<String, List<String>> get toUriQueryParameters => {
    'items': items.map((item) => base64Url.encode(utf8.encode(item))).toList(),
  };
}
