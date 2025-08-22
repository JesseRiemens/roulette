import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:webroulette/data/uri_storage.dart';

part 'storage_bloc.freezed.dart';
part 'storage_bloc.g.dart';

class StorageCubit extends HydratedCubit<StoredItems> {
  StorageCubit() : super(StoredItems.initial);

  StorageCubit.web() : super(StoredItems.initial) {
    if (uriStorage.queryParameters['items'] != null && uriStorage.queryParameters['items']!.isNotEmpty) {
      final items = uriStorage.queryParameters['items']!.map((item) => utf8.decode(base64Url.decode(item))).toList();
      emit(state.copyWith(items: items));
    }
  }

  void saveItems(List<String> items) {
    emit(state.copyWith(items: items));
    // ignore: avoid_print
    print('[StorageCubit] Saving items: $items');
    uriStorage.storeQueryParameters(state.toUriQueryParameters);
  }

  Uri get uriWithData => uriStorage.uri;

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
