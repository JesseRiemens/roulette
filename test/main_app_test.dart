import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/main.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHydratedStorage();
  });
  testWidgets('MainApp builds and shows MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(BlocProvider<StorageCubit>(create: (_) => StorageCubit(), child: const MainApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
