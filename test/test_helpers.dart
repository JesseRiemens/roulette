import 'package:hydrated_bloc/hydrated_bloc.dart';

class MockStorage extends Storage {
  final Map<String, dynamic> _store = {};
  @override
  dynamic read(String key) => _store[key];
  @override
  Future<void> write(String key, dynamic value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> clear() async => _store.clear();
  @override
  Future<void> close() async {}
}

Future<void> initHydratedStorage() async {
  HydratedBloc.storage = MockStorage();
}
