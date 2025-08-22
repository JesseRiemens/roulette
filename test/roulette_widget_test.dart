import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

void main() {
  testWidgets('RouletteWidget displays spin button and items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        locale: Locale('en'),
        home: Scaffold(body: RouletteWidget(rouletteItems: ['A', 'B', 'C'])),
      ),
    );
    // The FloatingActionButton should have the text 'Spin' from localization
    expect(find.text('Spin'), findsOneWidget);
    // The initial text should be 'Spin the wheel!' from localization
    expect(find.text('Spin the wheel!'), findsOneWidget);
  });
}
