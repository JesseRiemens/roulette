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
    final uri = Uri.parse('https://test?items=A,B');
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: RouletteScreen(pageURL: uri),
    ));
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsOneWidget);

    // With only one item, RouletteWidget should not be shown
    final uri2 = Uri.parse('https://test?items=A');
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: RouletteScreen(pageURL: uri2),
    ));
    expect(find.byType(EditingWidget), findsOneWidget);
    expect(find.byType(RouletteWidget), findsNothing);
  });
}
