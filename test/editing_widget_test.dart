import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/widgets/editing_widget.dart';

void main() {
  testWidgets('EditingWidget displays items and adds/removes items',
      (WidgetTester tester) async {
    List<String> items = ['A', 'B'];
    List<String> changedItems = [];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: EditingWidget(
          items: items,
          onItemsChanged: (newItems) => changedItems = newItems,
          backgroundColor: Colors.blue,
        ),
      ),
    ));

    // Items are displayed
    expect(find.text('1: A'), findsOneWidget);
    expect(find.text('2: B'), findsOneWidget);

    // Add item
    await tester.enterText(find.byType(TextField), 'C');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changedItems.contains('C'), isTrue);

    // Remove item
    await tester.tap(find.byIcon(Icons.remove_circle_outline_sharp).first);
    await tester.pump();
    expect(changedItems.length, lessThan(items.length + 1));
  });
}
