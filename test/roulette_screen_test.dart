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

  testWidgets('RouletteScreen shows both widgets when there are multiple items', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<StorageCubit>(
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
    // Set items after creation
    (BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)))..saveItems(['A', 'B']));
    await tester.pump();
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsOneWidget);
  });

  testWidgets('RouletteScreen hides RouletteWidget when there is only one item', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<StorageCubit>(
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
    // Set items after creation
    (BlocProvider.of<StorageCubit>(tester.element(find.byType(RouletteScreen)))..saveItems(['A']));
    await tester.pumpAndSettle();
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsNothing);
  });
}
