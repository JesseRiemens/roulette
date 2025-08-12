import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/main.dart';

void main() {
  testWidgets('MainApp builds and shows MaterialApp',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
