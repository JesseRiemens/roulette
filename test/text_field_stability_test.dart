import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';
import 'package:webroulette/widgets/editing_widget.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHydratedStorage();
  });

  group('Text Field Stability Tests', () {
    testWidgets('Text field preserves content during rapid state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => StorageCubit(),
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            locale: Locale('en'),
            home: RouletteScreen(),
          ),
        ),
      );

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text but don't submit
      await tester.enterText(textField, 'Test text that should persist');
      await tester.pump();

      // Verify text is there
      expect(find.text('Test text that should persist'), findsOneWidget);

      // Simulate rapid state changes that might occur during keyboard show/hide
      final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));

      // Trigger multiple rapid state changes
      for (int i = 0; i < 5; i++) {
        cubit.saveItems(['Rapid change $i']);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The text should still be preserved
      expect(find.text('Test text that should persist'), findsOneWidget);

      // Verify the TextField widget itself is still the same instance
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.key, equals(const ValueKey('main_text_field')));
    });

    testWidgets('Text field preserves content during window resize simulation', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => StorageCubit(),
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            locale: Locale('en'),
            home: RouletteScreen(),
          ),
        ),
      );

      // Find the text field and enter text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Window resize test');
      await tester.pump();

      // Simulate window resize by changing the window size
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pump();

      // Text should still be there
      expect(find.text('Window resize test'), findsOneWidget);

      // Simulate another resize (like keyboard appearing)
      tester.view.physicalSize = const Size(400, 400);
      await tester.pump();

      // Text should still be preserved
      expect(find.text('Window resize test'), findsOneWidget);

      // Reset to original size
      tester.view.physicalSize = const Size(800, 600);
      await tester.pump();

      // Text should still be there
      expect(find.text('Window resize test'), findsOneWidget);
    });

    testWidgets('EditingWidget maintains identity with stable key', (WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => StorageCubit(),
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            locale: Locale('en'),
            home: RouletteScreen(),
          ),
        ),
      );

      // Get the initial EditingWidget
      final editingWidgetFinder = find.byType(EditingWidget);
      expect(editingWidgetFinder, findsOneWidget);

      final initialEditingWidget = tester.widget<EditingWidget>(editingWidgetFinder);
      final initialElement = tester.element(editingWidgetFinder);

      // Verify it has the expected key
      expect(initialEditingWidget.key, equals(const ValueKey('editing_widget')));

      // Add some text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Identity test');
      await tester.pump();

      // Trigger state changes
      final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));
      cubit.saveItems(['Item 1', 'Item 2']);
      await tester.pump();

      // The EditingWidget should maintain its identity
      final currentElement = tester.element(editingWidgetFinder);
      expect(currentElement, same(initialElement));

      // And the text should still be there
      expect(find.text('Identity test'), findsOneWidget);
    });
  });
}
