import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';
import 'package:webroulette/widgets/editing_widget.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHydratedStorage();
  });
  testWidgets('RouletteScreen shows EditingWidget and RouletteWidget conditionally (Cubit)', (
    WidgetTester tester,
  ) async {
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
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsNothing);

    // Add two items
    await tester.enterText(find.byType(TextField), 'A');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'B');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byType(RouletteWidget), findsOneWidget);

    // Remove one item
    await tester.tap(find.byIcon(Icons.remove_circle_outline_sharp).first);
    await tester.pump();
    // Now only one item, so RouletteWidget should not be shown
    expect(find.byType(RouletteWidget), findsNothing);
  });
}
