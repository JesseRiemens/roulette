import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';
import 'package:webroulette/widgets/editing_widget.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

void main() {
  testWidgets(
      'RouletteScreen shows EditingWidget and RouletteWidget conditionally',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      locale: Locale('en'),
      home: RouletteScreen(),
    ));
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsOneWidget);

    // With only one item, RouletteWidget should not be shown
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      locale: Locale('en'),
      home: RouletteScreen(),
    ));
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsNothing);
  });
}
