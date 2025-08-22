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

  testWidgets('EditingWidget should preserve text input context when items change', (WidgetTester tester) async {
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

    // Enter some text but don't submit it yet
    await tester.enterText(textField, 'Partial text input');
    await tester.pump();

    // Verify the text is there
    expect(find.text('Partial text input'), findsOneWidget);

    // Now add an item through a different action to trigger rebuild
    // This simulates what happens when keyboard appears and causes rebuilds
    final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));
    cubit.saveItems(['Item 1']);
    await tester.pump();

    // The partial text input should still be preserved
    // This will fail with current implementation due to ValueKey rebuild
    expect(find.text('Partial text input'), findsOneWidget);
  });

  testWidgets('EditingWidget should preserve focus when items change during typing', (WidgetTester tester) async {
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

    // Find the text field and tap it to focus
    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.pump();

    // Enter some text
    await tester.enterText(textField, 'Typing...');
    await tester.pump();

    // Verify focus by checking if cursor is visible (focused state)
    final textFieldWidget = tester.widget<TextField>(textField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);

    // Now trigger a rebuild by changing items
    final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));
    cubit.saveItems(['Item 1']);
    await tester.pump();

    // Focus should be preserved after rebuild
    // This will fail with current implementation
    final textFieldWidgetAfter = tester.widget<TextField>(textField);
    expect(textFieldWidgetAfter.focusNode?.hasFocus, isTrue);
    expect(find.text('Typing...'), findsOneWidget);
  });

  testWidgets('EditingWidget widget identity should be stable across item changes', (WidgetTester tester) async {
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

    // Get the initial EditingWidget state
    final editingWidgetFinder = find.byType(EditingWidget);
    expect(editingWidgetFinder, findsOneWidget);

    final initialState = tester.state(editingWidgetFinder);

    // Change the items
    final cubit = BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)));
    cubit.saveItems(['Item 1']);
    await tester.pump();

    // The EditingWidget state should be the same (not recreated)
    final currentState = tester.state(editingWidgetFinder);
    expect(currentState, same(initialState));
  });
}
