import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/screens/roulette_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
  usePathUrlStrategy();

  runApp(BlocProvider(create: (_) => kIsWeb ? StorageCubit.web() : StorageCubit(), child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
      title: 'Roulette',
      onGenerateRoute: (settings) => CustomPageRoute(builder: (context) => const RouletteScreen(), settings: settings),
      initialRoute: '',
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      locale: Locale(PlatformDispatcher.instance.locale.languageCode),
    );
  }
}

class CustomPageRoute extends MaterialPageRoute {
  CustomPageRoute({builder, settings}) : super(builder: builder, settings: settings);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
