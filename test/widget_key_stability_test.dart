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

  testWidgets('EditingWidget has stable key and preserves state across rebuilds', (WidgetTester tester) async {
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

    // Find the EditingWidget
    final editingWidgetFinder = find.byType(EditingWidget);
    expect(editingWidgetFinder, findsOneWidget);

    // Verify it has the expected key
    final editingWidget = tester.widget<EditingWidget>(editingWidgetFinder);
    expect(editingWidget.key, equals(const ValueKey('editing_widget')));

    // Get the initial EditingWidget element and state
    final initialElement = tester.element(editingWidgetFinder);
    final initialState = tester.state(editingWidgetFinder);

    // Find the text field and enter some text
    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Test text that should be preserved');
    await tester.pump();

    // Verify the text is there
    expect(find.text('Test text that should be preserved'), findsOneWidget);

    // Trigger multiple state changes to force rebuilds
    final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));

    // First rebuild
    cubit.saveItems(['Item 1']);
    await tester.pump();

    // Second rebuild
    cubit.saveItems(['Item 1', 'Item 2']);
    await tester.pump();

    // Third rebuild - remove an item
    cubit.saveItems(['Item 2']);
    await tester.pump();

    // The EditingWidget element and state should be the same (preserved due to key)
    final currentElement = tester.element(editingWidgetFinder);
    final currentState = tester.state(editingWidgetFinder);

    expect(currentElement, same(initialElement));
    expect(currentState, same(initialState));

    // Most importantly, the text should still be preserved
    expect(find.text('Test text that should be preserved'), findsOneWidget);
  });

  testWidgets('Text input and focus are preserved across multiple rapid rebuilds', (WidgetTester tester) async {
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

    // Find the text field and focus it
    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.pump();

    // Enter text gradually as if user is typing
    await tester.enterText(textField, 'Typ');
    await tester.pump();

    final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));

    // Trigger rebuild while typing
    cubit.saveItems(['Interrupt 1']);
    await tester.pump();

    // Continue typing
    await tester.enterText(textField, 'Typing text...');
    await tester.pump();

    // Another rebuild
    cubit.saveItems(['Interrupt 1', 'Interrupt 2']);
    await tester.pump();

    // Verify text is still preserved and focus is maintained
    expect(find.text('Typing text...'), findsOneWidget);

    final textFieldWidget = tester.widget<TextField>(textField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);
  });
}
