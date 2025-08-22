import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/widgets/editing_widget.dart';

void main() {
  testWidgets('EditingWidget displays items and adds/removes items', (WidgetTester tester) async {
    List<String> items = ['A', 'B'];
    List<String> changedItems = [];
    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );

    // Items are displayed (RichText)
    expect(
      find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('1: A')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('2: B')),
      findsOneWidget,
    );

    // Add item
    await tester.enterText(find.byType(TextField), 'C');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changedItems.contains('C'), isTrue);

    // Remove item using the remove icon (trash)
    await tester.tap(find.byIcon(Icons.remove_circle_outline_sharp).first);
    await tester.pumpAndSettle();
    expect(changedItems.length, lessThan(items.length + 1));
  });

  testWidgets('EditingWidget edit moves item to text field and removes from list', (WidgetTester tester) async {
    List<String> items = ['A', 'B'];
    List<String> changedItems = [];

    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );

    // Tap the edit icon (pencil) for the first item
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    // Enter a new value in the dialog and submit
    await tester.enterText(find.byType(TextField).last, 'A edited');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // The item should be updated in the list
    expect(changedItems.contains('A edited'), isTrue);
  });
}
