import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/main.dart';
import 'package:webroulette/screens/copyright_screen.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHydratedStorage();
  });

  testWidgets('MainApp navigates to copyright screen when copyright button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<StorageCubit>(
        create: (_) => StorageCubit(),
        child: const MainApp(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Find and tap the copyright button
    final copyrightButton = find.text('Copyright');
    expect(copyrightButton, findsOneWidget);
    
    await tester.tap(copyrightButton);
    await tester.pumpAndSettle();

    // Verify we're now on the copyright screen
    expect(find.byType(CopyrightScreen), findsOneWidget);
    expect(find.text('Copyright Information'), findsOneWidget);
  });

  testWidgets('Copyright button is visible on roulette screen', (WidgetTester tester) async {
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
          home: MainApp(),
        ),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify the copyright button exists
    expect(find.text('Copyright'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    
    // Verify the copy URL button also exists
    expect(find.text('Copy URL'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });
}