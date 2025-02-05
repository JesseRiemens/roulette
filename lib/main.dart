import 'dart:html';

import 'package:flutter/cupertino.dart';
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
    return CupertinoApp(
      title: 'Roulette',
      onGenerateRoute: (settings) => CustomPageRoute(
        builder: (context) =>
            RouletteScreen(pageURL: Uri.parse(window.location.href)),
        settings: settings,
      ),
      initialRoute: '',
    );
  }
}

class CustomPageRoute extends CupertinoPageRoute {
  CustomPageRoute({
    builder,
    settings,
  }) : super(builder: builder, settings: settings);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
