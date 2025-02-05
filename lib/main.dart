import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:webroulette/screens/roulette_screen.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, brightness: Brightness.dark)),
      title: 'Roulette',
      onGenerateRoute: (settings) => CustomPageRoute(
        builder: (context) =>
            RouletteScreen(pageURL: Uri.parse(window.location.href)),
        settings: settings,
      ),
      initialRoute: '',
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // get locale from system

      locale: Locale(window.navigator.language.split('-').first),
    );
  }
}

class CustomPageRoute extends MaterialPageRoute {
  CustomPageRoute({
    builder,
    settings,
  }) : super(builder: builder, settings: settings);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
