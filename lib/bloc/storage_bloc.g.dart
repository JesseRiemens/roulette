// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoredItems _$StoredItemsFromJson(Map<String, dynamic> json) => _StoredItems(
  items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$StoredItemsToJson(_StoredItems instance) =>
    <String, dynamic>{'items': instance.items};
