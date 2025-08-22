import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHydratedStorage();
  });
  testWidgets('EditingWidget and RouletteWidget update via cubit', (WidgetTester tester) async {
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

    // Initially, no items, so RouletteWidget is not shown
    expect(find.byType(RouletteWidget), findsNothing);

    // Add an item
    await tester.enterText(find.byType(TextField), 'Apple');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Add another item
    await tester.enterText(find.byType(TextField), 'Banana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Now, RouletteWidget should be shown
    expect(find.byType(RouletteWidget), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('Apple')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('Banana')),
      findsOneWidget,
    );
  });
}
