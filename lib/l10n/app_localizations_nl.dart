// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get beCreative => 'Wees creatief :P';

  @override
  String get add => 'Voeg toe';

  @override
  String resultSpinResult(Object result) {
    return 'Resultaat: $result';
  }

  @override
  String get spinTheWheel => 'Draai aan het wiel!';

  @override
  String get spin => 'Draai';

  @override
  String get enterAnItem => 'Voer een item in';
}
