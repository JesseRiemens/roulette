import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/widgets/editing_widget.dart';

void main() {
  group('Edit Dialog Stability Tests', () {
    testWidgets('Edit dialog preserves text during window resize', (WidgetTester tester) async {
      List<String> items = ['abc'];
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

      // Tap the edit icon to open the dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Verify the dialog is open and shows the original text
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('abc'), findsOneWidget);

      // Find the TextField in the dialog and modify the text
      final dialogTextField = find.byType(TextField).last;
      await tester.enterText(dialogTextField, 'type def');
      await tester.pump();

      // Verify the new text is there
      expect(find.text('type def'), findsOneWidget);

      // Simulate window resize (like what happens when keyboard appears/disappears)
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pump();

      // The edited text should still be there (this is where the bug occurs)
      expect(find.text('type def'), findsOneWidget);
      // The original text should NOT be back
      expect(find.text('abc'), findsNothing);

      // Simulate another resize (keyboard disappearing)
      tester.view.physicalSize = const Size(400, 800);
      await tester.pump();

      // The edited text should still be preserved
      expect(find.text('type def'), findsOneWidget);
      expect(find.text('abc'), findsNothing);

      // Reset to original size
      tester.view.physicalSize = const Size(800, 600);
      await tester.pump();

      // Text should still be preserved
      expect(find.text('type def'), findsOneWidget);
      expect(find.text('abc'), findsNothing);
    });

    testWidgets('Edit dialog handles rapid rebuilds without losing text', (WidgetTester tester) async {
      List<String> items = ['original text'];
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

      // Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Enter new text
      final dialogTextField = find.byType(TextField).last;
      await tester.enterText(dialogTextField, 'modified text');
      await tester.pump();

      // Simulate rapid rebuilds that might occur during keyboard interactions
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Text should still be there
      expect(find.text('modified text'), findsOneWidget);
      expect(find.text('original text'), findsNothing);
    });
  });
}