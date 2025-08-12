// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get beCreative => 'Be Creative :P';

  @override
  String get add => 'Add';

  @override
  String resultSpinResult(Object result) {
    return 'Result: $result';
  }

  @override
  String get spinTheWheel => 'Spin the wheel!';

  @override
  String get spin => 'Spin';

  @override
  String get enterAnItem => 'Enter an item';
}
