import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/copyright_screen.dart';

void main() {
  testWidgets('CopyrightScreen displays copyright information', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        locale: Locale('en'),
        home: CopyrightScreen(),
      ),
    );

    // Wait for the localization to load
    await tester.pumpAndSettle();

    // Check if the app bar title is displayed
    expect(find.text('Copyright'), findsOneWidget);

    // Check if copyright title is displayed
    expect(find.text('Copyright Information'), findsOneWidget);

    // Check if copyright description is displayed
    expect(find.textContaining('© 2024 Roulette Web Application'), findsOneWidget);

    // Check if third-party licenses section is displayed
    expect(find.text('Third-Party Licenses'), findsOneWidget);

    // Check if view licenses button is displayed
    expect(find.text('View Licenses'), findsOneWidget);

    // Check if back button is displayed
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('CopyrightScreen back button calls Navigator.pop', (WidgetTester tester) async {
    // Create a simple test that verifies the back button exists and is tappable
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CopyrightScreen(),
                  ),
                );
              },
              child: const Text('Go to Copyright'),
            ),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
      ),
    );

    // Wait for the localization to load
    await tester.pumpAndSettle();

    // Tap the button to navigate to copyright screen
    await tester.tap(find.text('Go to Copyright'));
    await tester.pumpAndSettle();

    // Verify we're on the copyright screen
    expect(find.byType(CopyrightScreen), findsOneWidget);

    // Tap the back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify we're back to the original screen
    expect(find.byType(CopyrightScreen), findsNothing);
    expect(find.text('Go to Copyright'), findsOneWidget);
  });

  testWidgets('CopyrightScreen displays Dutch localization', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: [Locale('nl')],
        locale: Locale('nl'),
        home: CopyrightScreen(),
      ),
    );

    // Wait for the localization to load
    await tester.pumpAndSettle();

    // Check if Dutch translations are displayed
    expect(find.text('Auteursrecht'), findsOneWidget);
    expect(find.text('Auteursrecht Informatie'), findsOneWidget);
    expect(find.text('Bekijk Licenties'), findsOneWidget);
  });
}