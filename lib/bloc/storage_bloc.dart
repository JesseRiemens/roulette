import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:webroulette/utils/url_utils.dart';

class StorageCubit extends HydratedCubit<List<String>> {
  StorageCubit([List<String> initialItems = const []]) : super(initialItems) {
    if (initialItems.isNotEmpty) {
      emit(initialItems);
    }
  }

  void saveItems(List<String> items) {
    emit(items);
  }

  @override
  List<String>? fromJson(Map<String, dynamic> json) {
    print('fromJson called with: $json');
    final items = (json['items'] as List<dynamic>?)!.cast<String>();
    return items;
  }

  @override
  Map<String, dynamic>? toJson(List<String> state) {
    print('toJson called with: $state');
    return {'items': state};
  }

  static StorageCubit fromUrl(String url) {
    final items = UrlUtils.listFromUrl(url);
    return StorageCubit(items);
  }

  String toUrl() => UrlUtils.urlFromList(state);
}
