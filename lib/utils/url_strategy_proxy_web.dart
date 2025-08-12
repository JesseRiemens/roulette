// Web implementation
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void urlStrategyPushState(String path) {
  urlStrategy?.pushState('', '', path);
}
